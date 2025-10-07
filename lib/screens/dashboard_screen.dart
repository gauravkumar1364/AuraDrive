import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../services/kalman_gps_service.dart';
import '../services/ble_mesh_service.dart';
import '../services/mobile_cluster_manager.dart';
import '../services/enhanced_collision_detection_service.dart';

/// Main Dashboard Screen for Autonomous Vehicle System
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late KalmanGPSService _kalmanService;
  late BLEMeshService _bleService;
  late MobileClusterManager _clusterManager;
  late CollisionDetectionService _collisionService;
  
  LatLng _currentPosition = const LatLng(0, 0);
  double _currentSpeed = 0.0;
  double _currentHeading = 0.0;
  int _nearbyVehicles = 0;
  int _clusterSize = 0;
  bool _isCoordinator = false;
  List<Map<String, dynamic>> _collisionWarnings = [];
  
  // Route points
  LatLng? _sourcePosition;
  LatLng? _destinationPosition;
  bool _isSelectingSource = false;
  bool _isSelectingDestination = false;
  
  // Map optimization: throttle updates to prevent buffer overflow
  DateTime _lastMapUpdate = DateTime.now();
  static const Duration _mapUpdateThrottle = Duration(milliseconds: 500);
  late MapController _mapController;
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    _kalmanService = context.read<KalmanGPSService>();
    _bleService = context.read<BLEMeshService>();
    _clusterManager = context.read<MobileClusterManager>();
    _collisionService = context.read<CollisionDetectionService>();
    
    // Listen to position updates with throttling to prevent excessive map redraws
    _kalmanService.onPositionUpdate = (position, speed, heading) {
      if (mounted) {
        final now = DateTime.now();
        final shouldUpdateMap = now.difference(_lastMapUpdate) > _mapUpdateThrottle;
        
        setState(() {
          _currentPosition = position;
          _currentSpeed = speed;
          _currentHeading = heading;
        });
        
        // Only update map center if enough time has passed and position changed significantly
        if (shouldUpdateMap) {
          _lastMapUpdate = now;
          // Move map to follow current position smoothly
          _mapController.move(position, _mapController.camera.zoom);
        }
      }
    };
    
    // Listen to cluster updates
    _clusterManager.clusterStream.listen((cluster) {
      if (mounted) {
        setState(() {
          _clusterSize = cluster?.size ?? 0;
          _isCoordinator = cluster?.coordinatorId == _bleService.getCurrentCluster()?.coordinatorId;
        });
      }
    });
    
    // Listen to collision alerts
    _collisionService.alertStream.listen((alert) {
      if (mounted) {
        setState(() {
          _collisionWarnings.add(alert);
        });
        _showCollisionAlert(alert);
      }
    });
    
    // Listen to BLE devices
    _bleService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _nearbyVehicles = devices.length;
        });
      }
    });
  }
  
  void _showCollisionAlert(Map<String, dynamic> alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'COLLISION WARNING: ${alert['severity']} - Distance: ${alert['distance'].toStringAsFixed(1)}m',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NaviSafe - Autonomous Vehicle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showRouteSearchDialog(),
            tooltip: 'Search Route',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status cards
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Speed',
                    '${_currentSpeed.toStringAsFixed(1)} m/s',
                    Icons.speed,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatusCard(
                    'Nearby',
                    '$_nearbyVehicles vehicles',
                    Icons.car_rental,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatusCard(
                    'Cluster',
                    '$_clusterSize members',
                    Icons.group,
                    _isCoordinator ? Colors.orange : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Map view
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 16.0,
                    // Reduce update frequency to prevent buffer overflow
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onTap: (tapPosition, point) {
                      setState(() {
                        if (_isSelectingSource) {
                          _sourcePosition = point;
                          _isSelectingSource = false;
                        } else if (_isSelectingDestination) {
                          _destinationPosition = point;
                          _isSelectingDestination = false;
                        }
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.navisafe.app',
                    ),
                    // Route polyline (if both source and destination are set)
                    if (_sourcePosition != null && _destinationPosition != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_sourcePosition!, _destinationPosition!],
                            strokeWidth: 4.0,
                            color: Colors.blue.withOpacity(0.7),
                            borderStrokeWidth: 2.0,
                            borderColor: Colors.white,
                          ),
                        ],
                      ),
                    // Markers
                    MarkerLayer(
                      markers: [
                        // Current position marker
                        Marker(
                          point: _currentPosition,
                          width: 50,
                          height: 50,
                          child: Transform.rotate(
                            angle: _currentHeading * 3.14159 / 180,
                            child: const Icon(
                              Icons.navigation,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                        ),
                        // Source marker
                        if (_sourcePosition != null)
                          Marker(
                            point: _sourcePosition!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 40,
                            ),
                          ),
                        // Destination marker
                        if (_destinationPosition != null)
                          Marker(
                            point: _destinationPosition!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.flag,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // Route control buttons
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'source',
                        onPressed: () {
                          setState(() {
                            _isSelectingSource = !_isSelectingSource;
                            _isSelectingDestination = false;
                          });
                        },
                        backgroundColor: _isSelectingSource ? Colors.green : Colors.white,
                        child: Icon(
                          Icons.location_on,
                          color: _isSelectingSource ? Colors.white : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'destination',
                        onPressed: () {
                          setState(() {
                            _isSelectingDestination = !_isSelectingDestination;
                            _isSelectingSource = false;
                          });
                        },
                        backgroundColor: _isSelectingDestination ? Colors.red : Colors.white,
                        child: Icon(
                          Icons.flag,
                          color: _isSelectingDestination ? Colors.white : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Clear route button
                      if (_sourcePosition != null || _destinationPosition != null)
                        FloatingActionButton.small(
                          heroTag: 'clear',
                          onPressed: () {
                            setState(() {
                              _sourcePosition = null;
                              _destinationPosition = null;
                              _isSelectingSource = false;
                              _isSelectingDestination = false;
                            });
                          },
                          backgroundColor: Colors.grey,
                          child: const Icon(Icons.clear, color: Colors.white),
                        ),
                      const SizedBox(height: 8),
                      // Set current location as source
                      FloatingActionButton.small(
                        heroTag: 'current',
                        onPressed: () {
                          setState(() {
                            _sourcePosition = _currentPosition;
                          });
                        },
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.my_location, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Selection mode indicator
                if (_isSelectingSource || _isSelectingDestination)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isSelectingSource 
                            ? 'Tap on map to set SOURCE location'
                            : 'Tap on map to set DESTINATION location',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                // Route info
                if (_sourcePosition != null && _destinationPosition != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.straighten, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'Distance: ${_calculateDistance(_sourcePosition!, _destinationPosition!).toStringAsFixed(0)}m',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'ETA: ${_calculateETA(_sourcePosition!, _destinationPosition!)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Collision warnings
          if (_collisionWarnings.isNotEmpty)
            Container(
              height: 120,
              color: Colors.red.shade50,
              child: ListView.builder(
                itemCount: _collisionWarnings.length,
                itemBuilder: (context, index) {
                  final warning = _collisionWarnings[index];
                  return ListTile(
                    leading: Icon(
                      Icons.warning,
                      color: warning['severity'] == 'CRITICAL' 
                          ? Colors.red 
                          : Colors.orange,
                    ),
                    title: Text(
                      '${warning['severity']} COLLISION RISK',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Distance: ${warning['distance'].toStringAsFixed(1)}m - Risk: ${(warning['risk'] * 100).toStringAsFixed(0)}%',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _collisionWarnings.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          
          // System info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Position: ${_currentPosition.latitude.toStringAsFixed(6)}, ${_currentPosition.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Heading: ${_currentHeading.toStringAsFixed(1)}° - ${_isCoordinator ? "COORDINATOR" : "Member"}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Calculate distance between two points in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.distance(point1, point2);
  }
  
  /// Calculate estimated time of arrival
  String _calculateETA(LatLng source, LatLng destination) {
    final distance = _calculateDistance(source, destination);
    
    // Use current speed, or assume walking speed if stationary
    final speed = _currentSpeed > 0.5 ? _currentSpeed : 1.5; // m/s (1.5 m/s ≈ 5.4 km/h walking)
    
    final timeInSeconds = distance / speed;
    
    if (timeInSeconds < 60) {
      return '${timeInSeconds.toStringAsFixed(0)}s';
    } else if (timeInSeconds < 3600) {
      final minutes = (timeInSeconds / 60).toStringAsFixed(0);
      return '${minutes}min';
    } else {
      final hours = (timeInSeconds / 3600).toStringAsFixed(1);
      return '${hours}h';
    }
  }
  
  /// Show route search dialog
  void _showRouteSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _RouteSearchDialog(
        currentPosition: _currentPosition,
        onRouteSelected: (source, destination) {
          setState(() {
            _sourcePosition = source;
            _destinationPosition = destination;
          });
        },
      ),
    );
  }
  
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

/// Route Search Dialog Widget
class _RouteSearchDialog extends StatefulWidget {
  final LatLng currentPosition;
  final Function(LatLng? source, LatLng? destination) onRouteSelected;

  const _RouteSearchDialog({
    required this.currentPosition,
    required this.onRouteSelected,
  });

  @override
  State<_RouteSearchDialog> createState() => _RouteSearchDialogState();
}

class _RouteSearchDialogState extends State<_RouteSearchDialog> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  
  bool _isSearchingSource = false;
  bool _isSearchingDestination = false;
  LatLng? _selectedSource;
  LatLng? _selectedDestination;
  String? _sourceError;
  String? _destinationError;

  /// Search for location by address
  Future<LatLng?> _searchLocation(String query) async {
    if (query.trim().isEmpty) return null;
    
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    return null;
  }

  /// Search source location
  Future<void> _searchSource() async {
    setState(() {
      _isSearchingSource = true;
      _sourceError = null;
    });

    final location = await _searchLocation(_sourceController.text);
    
    setState(() {
      _isSearchingSource = false;
      if (location != null) {
        _selectedSource = location;
        _sourceError = null;
      } else {
        _sourceError = 'Location not found. Try a different address.';
      }
    });
  }

  /// Search destination location
  Future<void> _searchDestination() async {
    setState(() {
      _isSearchingDestination = true;
      _destinationError = null;
    });

    final location = await _searchLocation(_destinationController.text);
    
    setState(() {
      _isSearchingDestination = false;
      if (location != null) {
        _selectedDestination = location;
        _destinationError = null;
      } else {
        _destinationError = 'Location not found. Try a different address.';
      }
    });
  }

  /// Use current location as source
  void _useCurrentLocation() {
    setState(() {
      _selectedSource = widget.currentPosition;
      _sourceController.text = 'Current Location';
      _sourceError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Search Route',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Source section
                    const Text(
                      'Source Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sourceController,
                            decoration: InputDecoration(
                              hintText: 'Enter address or place',
                              prefixIcon: const Icon(Icons.location_on),
                              border: const OutlineInputBorder(),
                              errorText: _sourceError,
                              suffixIcon: _isSearchingSource
                                  ? const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : null,
                            ),
                            onSubmitted: (_) => _searchSource(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchSource,
                          color: Theme.of(context).primaryColor,
                          tooltip: 'Search',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _useCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use Current Location'),
                    ),
                    if (_selectedSource != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Source set: ${_selectedSource!.latitude.toStringAsFixed(4)}, ${_selectedSource!.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Destination section
                    const Text(
                      'Destination Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _destinationController,
                            decoration: InputDecoration(
                              hintText: 'Enter address or place',
                              prefixIcon: const Icon(Icons.flag),
                              border: const OutlineInputBorder(),
                              errorText: _destinationError,
                              suffixIcon: _isSearchingDestination
                                  ? const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : null,
                            ),
                            onSubmitted: (_) => _searchDestination(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchDestination,
                          color: Theme.of(context).primaryColor,
                          tooltip: 'Search',
                        ),
                      ],
                    ),
                    if (_selectedDestination != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Destination set: ${_selectedDestination!.latitude.toStringAsFixed(4)}, ${_selectedDestination!.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick tips
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Search Tips:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('• Use full addresses for better results', style: TextStyle(fontSize: 12)),
                          Text('• Include city and country when possible', style: TextStyle(fontSize: 12)),
                          Text('• Famous landmarks work well', style: TextStyle(fontSize: 12)),
                          Text('• Example: "Eiffel Tower, Paris"', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: (_selectedSource != null || _selectedDestination != null)
                        ? () {
                            widget.onRouteSelected(_selectedSource, _selectedDestination);
                            Navigator.pop(context);
                          }
                        : null,
                    icon: const Icon(Icons.directions),
                    label: const Text('Set Route'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
}
