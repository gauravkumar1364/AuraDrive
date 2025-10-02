import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';
import '../services/gnss_service.dart';
import '../services/mesh_network_service.dart';
import '../services/collision_detection_service.dart';
import '../models/models.dart';
import '../widgets/safety_alerts_widget.dart';
import '../widgets/mesh_network_widget.dart';
import '../config/app_config.dart';

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
        title: const Text('NaviSafe'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
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

  @override
  void dispose() {
    _dataTimer?.cancel();
    super.dispose();
  }
}
