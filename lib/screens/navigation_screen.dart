import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math' as math;
import 'dart:async';
import '../services/gnss_service.dart';
import '../services/mesh_network_service.dart';
import '../services/collision_detection_service.dart';
import '../services/routing_service.dart';
import '../models/models.dart';
import '../widgets/safety_alerts_widget.dart';
import '../widgets/mesh_network_widget.dart';
import '../config/app_config.dart';
import 'settings_screen.dart';

/// Main navigation screen with real-time OpenStreetMap and safety features
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  double _currentZoom = AppConfig.defaultZoomLevel;
  bool _isFollowingLocation = true;
  bool _showSafetyPanel = true;
  bool _showNetworkPanel = false;
  
  // Route points
  LatLng? _sourcePosition;
  LatLng? _destinationPosition;
  List<LatLng> _routePoints = []; // Actual road-based route
  RouteInfo? _routeInfo; // Route details (distance, duration)
  final RoutingService _routingService = RoutingService();
  bool _isCalculatingRoute = false;

  Timer? _dataTimer;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _startPeriodicDataTransfer();
  }

  void _startPeriodicDataTransfer() {
    // Cancel any existing timer
    _dataTimer?.cancel();

    // Create a new timer that fires every second
    _dataTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _sendData();
    });
  }

  Future<void> _sendData() async {
    if (_currentPosition == null) return;

    final meshService = Provider.of<MeshNetworkService>(context, listen: false);

    // Create position data from current position
    final positionData = PositionData(
      deviceId: '', // Device ID will be handled by the mesh service
      timestamp: DateTime.now(),
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      accuracy: 0.0, // You might want to get this from your location service
      speed: 0.0, // You might want to get this from your location service
      heading: 0.0, // You might want to get this from your location service
    );

    // Broadcast position to connected devices
    await meshService.broadcastPositionData(positionData);
  }

  /// Initialize all services
  Future<void> _initializeServices() async {
    final gnssService = Provider.of<GnssService>(context, listen: false);
    final meshService = Provider.of<MeshNetworkService>(context, listen: false);
    final collisionService = Provider.of<CollisionDetectionService>(
      context,
      listen: false,
    );

    // Initialize services
    await gnssService.initialize();
    await meshService.initialize();
    await collisionService.initialize();

    // Start services
    await gnssService.startPositioning();
    await meshService.startScanning();
    await collisionService.startMonitoring();

    // Listen to position updates
    gnssService.positionStream.listen(_onPositionUpdate);

    // Listen to mesh network updates
    meshService.positionReceivedStream.listen(_onPeerPositionUpdate);

    // Listen to collision alerts
    collisionService.alertStream.listen(_onCollisionAlert);
  }

  /// Handle position updates
  void _onPositionUpdate(PositionData position) {
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    // Auto-follow location if enabled
    if (_isFollowingLocation && _currentPosition != null) {
      _mapController.move(_currentPosition!, _currentZoom);
    }
  }

  /// Handle peer position updates
  void _onPeerPositionUpdate(PositionData peerPosition) {
    // Add peer position to GNSS service for cooperative positioning
    final gnssService = Provider.of<GnssService>(context, listen: false);
    gnssService.addPeerPosition(peerPosition);

    setState(() {}); // Refresh markers
  }

  /// Handle collision alerts
  void _onCollisionAlert(CollisionAlert alert) {
    if (alert.isUrgent) {
      _showUrgentAlert(alert);
    }
  }

  /// Show urgent collision alert
  void _showUrgentAlert(CollisionAlert alert) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white, size: 32),
            SizedBox(width: 8),
            Text(
              'COLLISION ALERT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              alert.recommendedAction,
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'ACKNOWLEDGE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build map markers for OpenStreetMap
  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];
    final meshService = Provider.of<MeshNetworkService>(context, listen: false);
    final gnssService = Provider.of<GnssService>(context, listen: false);

    // Current position marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: AppConfig.vehicleIconSize,
          height: AppConfig.vehicleIconSize,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.navigation, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    // Peer vehicle markers
    for (final peerPosition in meshService.sharedPositions.values) {
      final distance = _currentPosition != null
          ? gnssService.currentPosition?.distanceTo(peerPosition)
          : null;

      markers.add(
        Marker(
          point: LatLng(peerPosition.latitude, peerPosition.longitude),
          width: AppConfig.vehicleIconSize,
          height: AppConfig.vehicleIconSize,
          child: Container(
            decoration: BoxDecoration(
              color: distance != null && distance < 25.0
                  ? Colors.red
                  : Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.directions_car,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      );
    }

    // Collision alert markers
    final collisionService = Provider.of<CollisionDetectionService>(
      context,
      listen: false,
    );
    for (final alert in collisionService.activeAlerts) {
      // Skip alerts without position data or if current position is unknown
      if (_currentPosition == null) continue;

      // Calculate approximate position based on relative position
      // This is a simplified calculation - in real implementation you'd need more sophisticated positioning
      final distance = alert.relativePosition.distance;
      final bearing =
          alert.relativePosition.bearing *
          (math.pi / 180); // Convert to radians

      final lat =
          _currentPosition!.latitude +
          (distance * math.cos(bearing)) / 111320; // Rough conversion
      final lng =
          _currentPosition!.longitude +
          (distance * math.sin(bearing)) /
              (111320 * math.cos(_currentPosition!.latitude * math.pi / 180));

      Color alertColor = Colors.yellow;
      IconData alertIcon = Icons.warning;

      switch (alert.alertType) {
        case AlertType.collision:
          alertColor = Colors.orange;
          alertIcon = Icons.warning_amber;
          break;
        case AlertType.crash:
          alertColor = Colors.red;
          alertIcon = Icons.error;
          break;
        case AlertType.emergency:
          alertColor = Colors.red.shade900;
          alertIcon = Icons.emergency;
          break;
        default:
          alertColor = Colors.yellow;
          alertIcon = Icons.warning;
          break;
      }

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: alertColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(alertIcon, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    // Source marker (green pin)
    if (_sourcePosition != null) {
      markers.add(
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
      );
    }

    // Destination marker (red flag)
    if (_destinationPosition != null) {
      markers.add(
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
      );
    }

    return markers;
  }

  /// Build proximity circles
  List<CircleMarker> _buildProximityCircles() {
    final List<CircleMarker> circles = [];

    if (_currentPosition != null) {
      // Warning radius circle
      circles.add(
        CircleMarker(
          point: _currentPosition!,
          radius: AppConfig.warningDistanceMeters,
          color: Colors.orange.withValues(alpha: 0.2),
          borderColor: Colors.orange.withValues(alpha: 0.7),
          borderStrokeWidth: 2,
        ),
      );

      // Critical radius circle
      circles.add(
        CircleMarker(
          point: _currentPosition!,
          radius: AppConfig.criticalDistanceMeters,
          color: Colors.red.withValues(alpha: 0.2),
          borderColor: Colors.red.withValues(alpha: 0.7),
          borderStrokeWidth: 2,
        ),
      );
    }

    return circles;
  }

  /// Build status bar widget
  Widget _buildStatusBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusItem(
              'GNSS',
              Icons.satellite_alt,
              Consumer<GnssService>(
                builder: (context, service, child) {
                  if (!service.isInitialized)
                    return const Text('Initializing...');
                  if (service.currentQuality == null)
                    return const Text('No signal');

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${service.satelliteCount} sats',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        service.currentQuality!.qualityDescription,
                        style: TextStyle(fontSize: 10, color: Colors.grey[300]),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          Expanded(
            child: _buildStatusItem(
              'Network',
              Icons.bluetooth,
              Consumer<MeshNetworkService>(
                builder: (context, service, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${service.connectedDeviceCount} devices',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        service.isScanning ? 'Scanning...' : 'Idle',
                        style: TextStyle(fontSize: 10, color: Colors.grey[300]),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          Expanded(
            child: _buildStatusItem(
              'Safety',
              Icons.shield,
              Consumer<CollisionDetectionService>(
                builder: (context, service, child) {
                  final alertCount = service.activeAlerts.length;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$alertCount alerts',
                        style: TextStyle(
                          fontSize: 12,
                          color: alertCount > 0 ? Colors.red : Colors.white,
                        ),
                      ),
                      Text(
                        service.isMonitoring ? 'Monitoring' : 'Stopped',
                        style: TextStyle(fontSize: 10, color: Colors.grey[300]),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual status item
  Widget _buildStatusItem(String title, IconData icon, Widget content) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        content,
      ],
    );
  }

  /// Build floating controls
  Widget _buildFloatingControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          mini: true,
          heroTag: 'location',
          onPressed: () {
            setState(() {
              _isFollowingLocation = !_isFollowingLocation;
            });
            if (_isFollowingLocation && _currentPosition != null) {
              _mapController.move(_currentPosition!, _currentZoom);
            }
          },
          backgroundColor: _isFollowingLocation ? Colors.blue : Colors.grey,
          child: Icon(
            _isFollowingLocation ? Icons.my_location : Icons.location_disabled,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          mini: true,
          heroTag: 'zoom_in',
          onPressed: () {
            setState(() {
              _currentZoom = (_currentZoom + 1).clamp(3.0, 18.0);
            });
            _mapController.move(
              _currentPosition ?? const LatLng(28.6139, 77.2090),
              _currentZoom,
            );
          },
          child: const Icon(Icons.zoom_in),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          mini: true,
          heroTag: 'zoom_out',
          onPressed: () {
            setState(() {
              _currentZoom = (_currentZoom - 1).clamp(3.0, 18.0);
            });
            _mapController.move(
              _currentPosition ?? const LatLng(28.6139, 77.2090),
              _currentZoom,
            );
          },
          child: const Icon(Icons.zoom_out),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          mini: true,
          heroTag: 'network',
          onPressed: () {
            setState(() {
              _showNetworkPanel = !_showNetworkPanel;
              if (_showNetworkPanel) _showSafetyPanel = false;
            });
          },
          backgroundColor: _showNetworkPanel
              ? Theme.of(context).primaryColor
              : Colors.grey[600],
          child: const Icon(Icons.device_hub, color: Colors.white),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          mini: true,
          heroTag: 'safety',
          onPressed: () {
            setState(() {
              _showSafetyPanel = !_showSafetyPanel;
              if (_showSafetyPanel) _showNetworkPanel = false;
            });
          },
          backgroundColor: _showSafetyPanel
              ? Theme.of(context).primaryColor
              : Colors.grey[600],
          child: const Icon(Icons.security, color: Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AuraDrive'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showRouteSearchDialog,
            tooltip: 'Search Route',
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          // Safety score indicator
          Consumer<CollisionDetectionService>(
            builder: (context, collisionService, child) {
              final safetyScore = collisionService.safetyScore;
              final color = safetyScore >= 80
                  ? Colors.green
                  : safetyScore >= 60
                  ? Colors.orange
                  : Colors.red;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Safety: $safetyScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap using flutter_map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _currentPosition ??
                  const LatLng(28.6139, 77.2090), // Default to Delhi
              initialZoom: _currentZoom,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _isFollowingLocation = false;
                });
              },
            ),
            children: [
              // OpenStreetMap tiles
              TileLayer(
                urlTemplate: AppConfig.osmTileServerUrl,
                userAgentPackageName: 'com.navisafe.app',
                maxZoom: 18,
              ),

              // Proximity circles
              CircleLayer(circles: _buildProximityCircles()),

              // Route polyline (if both source and destination are set)
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue.withOpacity(0.7),
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.white,
                    ),
                  ],
                ),

              // Vehicle and alert markers
              MarkerLayer(markers: _buildMarkers()),

              // Attribution
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    AppConfig.osmAttributionText,
                    onTap: () {
                      // TODO: Open OSM attribution page
                    },
                  ),
                ],
              ),
            ],
          ),

          // Route info banner (top center)
          if (_routeInfo != null)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_car, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_routeInfo!.formattedDistance} • ${_routeInfo!.formattedDuration}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_isCalculatingRoute)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _sourcePosition = null;
                                _destinationPosition = null;
                                _routePoints = [];
                                _routeInfo = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Calculating route overlay
          if (_isCalculatingRoute)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Calculating route...',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Safety alerts overlay
          if (_showSafetyPanel)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafetyAlertsWidget(),
            ),

          // Network panel overlay
          if (_showNetworkPanel)
            const Positioned(
              top: 0,
              right: 0,
              child: SizedBox(width: 300, child: MeshNetworkWidget()),
            ),

          // Bottom status bar
          Positioned(bottom: 0, left: 0, right: 0, child: _buildStatusBar()),
        ],
      ),
      floatingActionButton: _buildFloatingControls(),
    );
  }

  /// Show route search dialog
  void _showRouteSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _RouteSearchDialog(
        currentPosition: _currentPosition ?? const LatLng(28.6139, 77.2090),
        onRouteSelected: (source, destination) async {
          setState(() {
            _sourcePosition = source;
            _destinationPosition = destination;
            _isCalculatingRoute = true;
            _routePoints = []; // Clear old route
            // Disable auto-follow when route is set
            if (source != null || destination != null) {
              _isFollowingLocation = false;
            }
          });
          
          // Calculate actual road-based route
          if (source != null && destination != null) {
            final routeInfo = await _routingService.getRouteInfo(
              start: source,
              end: destination,
              profile: 'driving',
            );
            
            if (mounted) {
              setState(() {
                _routeInfo = routeInfo;
                _routePoints = routeInfo?.points ?? [source, destination];
                _isCalculatingRoute = false;
              });
              
              // Show route info
              if (routeInfo != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Route: ${routeInfo.formattedDistance} • ${routeInfo.formattedDuration}',
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          } else {
            setState(() {
              _isCalculatingRoute = false;
            });
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
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

  /// Search for location by address with enhanced geocoding
  Future<LatLng?> _searchLocation(String query) async {
    if (query.trim().isEmpty) return null;
    
    // First, check predefined locations (offline fallback)
    final predefinedLocation = _getPredefinedLocation(query);
    if (predefinedLocation != null) {
      debugPrint('Found in predefined locations: ${predefinedLocation.latitude}, ${predefinedLocation.longitude}');
      return predefinedLocation;
    }
    
    // Try online geocoding with multiple search strategies
    final searchQueries = _buildSearchQueries(query);
    
    for (final searchQuery in searchQueries) {
      try {
        debugPrint('Trying geocoding: $searchQuery');
        final locations = await locationFromAddress(searchQuery).timeout(
          const Duration(seconds: 5),
          onTimeout: () => [],
        );
        if (locations.isNotEmpty) {
          debugPrint('Found location: ${locations.first.latitude}, ${locations.first.longitude}');
          return LatLng(locations.first.latitude, locations.first.longitude);
        }
      } catch (e) {
        debugPrint('Geocoding error for "$searchQuery": $e');
        continue; // Try next query variant
      }
    }
    
    return null;
  }

  /// Get predefined locations (offline fallback)
  LatLng? _getPredefinedLocation(String query) {
    final normalized = query.toLowerCase().trim();
    
    // Common Delhi locations with coordinates
    final locations = {
      // Educational Institutions
      'iit': const LatLng(28.5450, 77.1920), // IIT Delhi
      'iit delhi': const LatLng(28.5450, 77.1920),
      'indian institute of technology delhi': const LatLng(28.5450, 77.1920),
      'dtu': const LatLng(28.7501, 77.1177), // DTU
      'delhi technological university': const LatLng(28.7501, 77.1177),
      'aiims': const LatLng(28.5672, 77.2100), // AIIMS Delhi
      'all india institute of medical sciences': const LatLng(28.5672, 77.2100),
      'jnu': const LatLng(28.5394, 77.1662), // JNU
      'jawaharlal nehru university': const LatLng(28.5394, 77.1662),
      'du': const LatLng(28.6863, 77.2060), // Delhi University North Campus
      'delhi university': const LatLng(28.6863, 77.2060),
      'nsut': const LatLng(28.6115, 77.0365), // NSUT
      'netaji subhas university of technology': const LatLng(28.6115, 77.0365),
      'nit delhi': const LatLng(28.6115, 77.0365),
      'iim delhi': const LatLng(28.5494, 77.1736),
      
      // Landmarks
      'india gate': const LatLng(28.6129, 77.2295),
      'red fort': const LatLng(28.6562, 77.2410),
      'qutub minar': const LatLng(28.5244, 77.1855),
      'lotus temple': const LatLng(28.5535, 77.2588),
      'akshardham': const LatLng(28.6127, 77.2773),
      'akshardham temple': const LatLng(28.6127, 77.2773),
      'jantar mantar': const LatLng(28.6271, 77.2166),
      'rashtrapati bhavan': const LatLng(28.6143, 77.1996),
      'parliament house': const LatLng(28.6172, 77.2082),
      'humayun tomb': const LatLng(28.5933, 77.2507),
      'humayuns tomb': const LatLng(28.5933, 77.2507),
      
      // Commercial Areas
      'connaught place': const LatLng(28.6315, 77.2167),
      'cp': const LatLng(28.6315, 77.2167),
      'karol bagh': const LatLng(28.6510, 77.1906),
      'chandni chowk': const LatLng(28.6506, 77.2303),
      'sarojini nagar': const LatLng(28.5753, 77.1953),
      'lajpat nagar': const LatLng(28.5677, 77.2430),
      'nehru place': const LatLng(28.5494, 77.2501),
      'dwarka': const LatLng(28.5921, 77.0460),
      'rajouri garden': const LatLng(28.6415, 77.1214),
      'pitampura': const LatLng(28.6974, 77.1311),
      'rohini': const LatLng(28.7496, 77.0669),
      
      // Transport Hubs
      'igi airport': const LatLng(28.5562, 77.1000),
      'indira gandhi airport': const LatLng(28.5562, 77.1000),
      'delhi airport': const LatLng(28.5562, 77.1000),
      'new delhi railway station': const LatLng(28.6431, 77.2197),
      'old delhi railway station': const LatLng(28.6644, 77.2294),
      'anand vihar': const LatLng(28.6469, 77.3158),
      'kashmere gate': const LatLng(28.6679, 77.2273),
      
      // Metro Stations (Major)
      'rajiv chowk': const LatLng(28.6328, 77.2197),
      'kashmiri gate metro': const LatLng(28.6679, 77.2273),
      'dwarka sector 21': const LatLng(28.5522, 77.0580),
    };
    
    // Try exact match first
    if (locations.containsKey(normalized)) {
      return locations[normalized];
    }
    
    // Try partial match
    for (final entry in locations.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }
    
    return null;
  }

  /// Build multiple search query variants for better geocoding results
  List<String> _buildSearchQueries(String query) {
    final queries = <String>[];
    final normalizedQuery = query.trim();
    
    // Common abbreviations and their full forms for Indian institutions
    final expansions = {
      r'\bIIT\b': ['IIT', 'Indian Institute of Technology'],
      r'\bDTU\b': ['DTU', 'Delhi Technological University'],
      r'\bNIT\b': ['NIT', 'National Institute of Technology'],
      r'\bAIIMS\b': ['AIIMS', 'All India Institute of Medical Sciences'],
      r'\bJNU\b': ['JNU', 'Jawaharlal Nehru University'],
      r'\bDU\b': ['DU', 'Delhi University', 'University of Delhi'],
      r'\bIIM\b': ['IIM', 'Indian Institute of Management'],
      r'\bIISc\b': ['IISc', 'Indian Institute of Science'],
      r'\bNSUT\b': ['NSUT', 'Netaji Subhas University of Technology'],
      r'\bIGI\b': ['IGI Airport', 'Indira Gandhi International Airport'],
    };
    
    // Strategy 1: Original query
    queries.add(normalizedQuery);
    
    // Strategy 2: Add "New Delhi, India" if not present
    if (!normalizedQuery.toLowerCase().contains('delhi') && 
        !normalizedQuery.toLowerCase().contains('india')) {
      queries.add('$normalizedQuery, New Delhi, India');
      queries.add('$normalizedQuery, Delhi, India');
    } else if (!normalizedQuery.toLowerCase().contains('india')) {
      queries.add('$normalizedQuery, India');
    }
    
    // Strategy 3: Expand abbreviations
    for (final expansion in expansions.entries) {
      final regex = RegExp(expansion.key, caseSensitive: false);
      if (regex.hasMatch(normalizedQuery)) {
        for (final fullForm in expansion.value) {
          final expanded = normalizedQuery.replaceFirstMapped(
            regex,
            (match) => fullForm,
          );
          queries.add(expanded);
          
          // Also add with location suffix
          if (!expanded.toLowerCase().contains('delhi') && 
              !expanded.toLowerCase().contains('india')) {
            queries.add('$expanded, New Delhi, India');
            queries.add('$expanded, Delhi, India');
          }
        }
      }
    }
    
    // Strategy 4: Common landmarks - add specific identifiers
    final landmarkPatterns = {
      'india gate': 'India Gate, Rajpath, New Delhi',
      'red fort': 'Red Fort, Chandni Chowk, Delhi',
      'qutub minar': 'Qutub Minar, Mehrauli, Delhi',
      'lotus temple': 'Lotus Temple, Kalkaji, New Delhi',
      'connaught place': 'Connaught Place, New Delhi',
      'cp': 'Connaught Place, New Delhi',
      'jantar mantar': 'Jantar Mantar, Connaught Place, New Delhi',
      'akshardham': 'Akshardham Temple, New Delhi',
    };
    
    for (final pattern in landmarkPatterns.entries) {
      if (normalizedQuery.toLowerCase().contains(pattern.key)) {
        queries.add(pattern.value);
      }
    }
    
    // Remove duplicates while preserving order
    return queries.toSet().toList();
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
        _sourceError = 'Location not found. Try: "IIT Delhi", "India Gate", etc.';
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
        _destinationError = 'Location not found. Try: "DTU", "Connaught Place", etc.';
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
                          Text('• Institutions: "IIT Delhi", "DTU", "AIIMS"', style: TextStyle(fontSize: 12)),
                          Text('• Landmarks: "India Gate", "Red Fort"', style: TextStyle(fontSize: 12)),
                          Text('• Areas: "Connaught Place", "Karol Bagh"', style: TextStyle(fontSize: 12)),
                          Text('• Auto-adds "Delhi, India" if needed', style: TextStyle(fontSize: 12)),
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
