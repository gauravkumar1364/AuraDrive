import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'dart:async';
import '../services/gnss_service.dart';
import '../services/mesh_network_service.dart';
import '../services/collision_detection_service.dart';
import '../services/routing_service.dart';
import '../models/models.dart';
import '../widgets/safety_alerts_widget.dart';
import '../widgets/mesh_network_widget.dart';
import '../widgets/route_search_dialog.dart';
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

  // Peer devices positions
  final Map<String, LatLng> _peerPositions = <String, LatLng>{};

  Timer? _dataTimer;

  void _showServiceError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

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

  /// Handle position updates from GNSS
  void _onPositionUpdate(PositionData position) {
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    // Auto-follow location if enabled
    if (_isFollowingLocation && _currentPosition != null) {
      _mapController.move(_currentPosition!, _currentZoom);
    }
  }

  /// Handle position updates from peer devices
  void _onPeerPositionUpdate(PositionData peerPosition) {
    // Update shared positions map
    setState(() {
      _peerPositions[peerPosition.deviceId] = LatLng(
        peerPosition.latitude,
        peerPosition.longitude,
      );
    });
  }

  /// Handle collision alerts
  void _onCollisionAlert(CollisionAlert alert) {
    // Show alert UI
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Collision alert: ${alert.alertType}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    super.dispose();
  }

  /// Initialize all services
  Future<void> _initializeServices() async {
    if (!mounted) return;

    try {
      final gnssService = Provider.of<GnssService>(context, listen: false);
      final meshService = Provider.of<MeshNetworkService>(
        context,
        listen: false,
      );
      final collisionService = Provider.of<CollisionDetectionService>(
        context,
        listen: false,
      );

      // Initialize services with error handling
      bool initSuccess = true;

      try {
        if (!await gnssService.initialize()) {
          _showServiceError('Failed to initialize GNSS services');
          initSuccess = false;
        }
      } catch (e) {
        _showServiceError('Failed to initialize GNSS: $e');
        initSuccess = false;
      }

      try {
        if (!await meshService.initialize()) {
          _showServiceError('Failed to initialize BLE services');
          initSuccess = false;
        }
      } catch (e) {
        _showServiceError('Failed to initialize BLE: $e');
        initSuccess = false;
      }

      try {
        if (!await collisionService.initialize()) {
          _showServiceError('Failed to initialize collision detection');
          initSuccess = false;
        }
      } catch (e) {
        _showServiceError('Failed to initialize collision detection: $e');
        initSuccess = false;
      }

      if (!initSuccess || !mounted) {
        _showServiceError('One or more services failed to initialize');
        return;
      }

      // Start services with error handling
      try {
        await Future.wait([
          gnssService.startPositioning(),
          meshService.startScanning(),
          collisionService.startMonitoring(),
        ]);

        // Set up listeners
        gnssService.positionStream.listen(_onPositionUpdate);
        meshService.positionReceivedStream.listen(_onPeerPositionUpdate);
        collisionService.alertStream.listen(_onCollisionAlert);
      } catch (e) {
        if (mounted) {
          _showServiceError('Failed to start services: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        _showServiceError('Failed to access services: $e');
      }
    }
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 24),
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.flag, color: Colors.white, size: 24),
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
          color: Colors.orange.withOpacity(0.15),
          borderColor: Colors.orange.withOpacity(0.6),
          borderStrokeWidth: 2,
        ),
      );

      // Critical radius circle
      circles.add(
        CircleMarker(
          point: _currentPosition!,
          radius: AppConfig.criticalDistanceMeters,
          color: Colors.red.withOpacity(0.15),
          borderColor: Colors.red.withOpacity(0.6),
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
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
              maxZoom: 20.0,
              keepAlive: true,
              onTap: (tapPosition, point) {
                setState(() {
                  _isFollowingLocation = false;
                });
              },
            ),
            children: [
              // Google Maps-like colorful tiles
              TileLayer(
                urlTemplate:
                    'https://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.aura.drive',
                maxZoom: 20,
              ),

              // Proximity circles
              CircleLayer(circles: _buildProximityCircles()),

              // Route polyline (if both source and destination are set)
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6.0,
                      color: Colors.blue.shade600,
                      borderStrokeWidth: 3.0,
                      borderColor: Colors.white.withOpacity(0.5),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.directions_car,
                          color: Colors.blue,
                          size: 20,
                        ),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
            Positioned(
              top: 0,
              right: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 300,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: const MeshNetworkWidget(),
              ),
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
      builder: (context) => RouteSearchDialog(
        currentPosition: _currentPosition ?? const LatLng(28.6139, 77.2090),
        onRouteSelected: _startNavigation,
      ),
    );
  }

  /// Start navigation with selected route
  Future<void> _startNavigation(LatLng? source, LatLng? destination) async {
    if (source == null || destination == null) return;

    setState(() {
      _sourcePosition = source;
      _destinationPosition = destination;
      _isCalculatingRoute = true;
      _routePoints = [];
      _isFollowingLocation = false;
    });

    try {
      final routeInfo = await _routingService.getRouteInfo(
        start: source,
        end: destination,
        profile: 'driving',
      );

      if (!mounted) return;

      setState(() {
        _routeInfo = routeInfo;
        _routePoints = routeInfo?.points ?? [source, destination];
        _isCalculatingRoute = false;
      });

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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCalculatingRoute = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to calculate route: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
