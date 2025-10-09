import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../services/gnss_service.dart';
import '../services/mesh_network_service.dart';
import '../services/accelerometer_collision_service.dart';
import '../services/routing_service.dart';
import '../models/models.dart';
import '../widgets/mesh_network_widget.dart';
import '../widgets/route_search_dialog.dart';
import '../widgets/collision_alert_widget.dart';
import '../config/app_config.dart';

import 'settings_screen.dart';

/// Main navigation screen with regit commit -m "fixed pixel overflow and ui"al-time OpenStreetMap and safety features
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
  double _currentHeading = 0.0; // Track heading for smooth rotation

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
      final collisionService = Provider.of<AccelerometerCollisionService>(
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
        // AccelerometerCollisionService doesn't need initialize() - it's ready to use
        debugPrint('✅ Accelerometer collision detection ready');
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
        await Future.wait(
          [
            gnssService.startPositioning(),
            meshService.startScanning(),
            collisionService.startMonitoring(),
          ].cast<Future>(),
        );

        // Set up listeners
        gnssService.positionStream.listen(_onPositionUpdate);
        meshService.positionReceivedStream.listen(_onPeerPositionUpdate);

        // Start automatic position broadcasting to connected devices
        meshService.startPositionBroadcasting(gnssService.positionStream);
        debugPrint('✅ Automatic position broadcasting started');

        // AccelerometerCollisionService doesn't have alertStream - it uses debug prints instead
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

    // Current position marker with dynamic heading
    if (_currentPosition != null) {
      final heading = gnssService.currentPosition?.heading ?? 0.0;

      markers.add(
        Marker(
          point: _currentPosition!,
          width: AppConfig.vehicleIconSize,
          height: AppConfig.vehicleIconSize,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: _currentHeading, end: heading),
            duration: const Duration(
              milliseconds: 300,
            ), // Smooth 300ms animation
            curve: Curves.easeInOut,
            onEnd: () {
              if (mounted) {
                setState(() {
                  _currentHeading = heading;
                });
              }
            },
            builder: (context, angle, child) {
              return Transform.rotate(
                angle: angle * (3.14159 / 180), // Convert degrees to radians
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // Peer vehicle markers - Show connected AuraDrive apps in real-time
    for (final entry in meshService.sharedPositions.entries) {
      final peerPosition = entry.value;

      final distance = _currentPosition != null
          ? gnssService.currentPosition?.distanceTo(peerPosition)
          : null;

      // Show peer heading if available
      final peerHeading = peerPosition.heading ?? 0.0;

      markers.add(
        Marker(
          point: LatLng(peerPosition.latitude, peerPosition.longitude),
          width: AppConfig.vehicleIconSize + 4,
          height: AppConfig.vehicleIconSize + 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow for visibility
              Container(
                width: AppConfig.vehicleIconSize + 4,
                height: AppConfig.vehicleIconSize + 4,
                decoration: BoxDecoration(
                  color: distance != null && distance < 25.0
                      ? Colors.red.withOpacity(0.3)
                      : Colors.green.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              // Main marker with heading
              Transform.rotate(
                angle: peerHeading * (3.14159 / 180), // Convert to radians
                child: Container(
                  width: AppConfig.vehicleIconSize,
                  height: AppConfig.vehicleIconSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: distance != null && distance < 25.0
                          ? [Colors.red[400]!, Colors.red[700]!]
                          : [Colors.green[400]!, Colors.green[700]!],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Collision alerts are now handled via debug prints - no active alerts list available
    // You can add visual feedback here if needed by listening to the service's notifier

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

  /// Build enhanced status bar widget
  Widget _buildStatusBar() {
    return Container(
      height: 63, // Reduced by 2px to fix overflow
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[850]!.withOpacity(0.95),
            Colors.grey[900]!.withOpacity(0.98),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _buildStatusItem(
              'GNSS',
              Icons.satellite_alt,
              Consumer<GnssService>(
                builder: (context, service, child) {
                  if (!service.isInitialized)
                    return const Text(
                      'Init',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, color: Colors.white),
                    );
                  if (service.currentQuality == null)
                    return const Text(
                      'No signal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, color: Colors.white),
                    );

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${service.satelliteCount} sats',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        service.currentQuality!.qualityDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 8, color: Colors.grey[400]),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        service.isScanning ? 'Scan' : 'Idle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 8, color: Colors.grey[400]),
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
              Consumer<AccelerometerCollisionService>(
                builder: (context, service, child) {
                  final recentAlertsCount = service.recentAlerts.length;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        service.isMonitoring ? 'Active' : 'Off',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: service.isMonitoring
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      Text(
                        recentAlertsCount > 0
                            ? '$recentAlertsCount alert${recentAlertsCount > 1 ? 's' : ''}'
                            : 'None',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          color: recentAlertsCount > 0
                              ? Colors.orange[300]
                              : Colors.grey[400],
                        ),
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

  /// Build enhanced individual status item
  Widget _buildStatusItem(String title, IconData icon, Widget content) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.grey[800]!.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue[300], size: 18),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 1),
            DefaultTextStyle(
              style: const TextStyle(fontSize: 9),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  /// Build speed display widget - Google Maps style
  Widget _buildSpeedDisplay() {
    return Consumer<GnssService>(
      builder: (context, gnssService, child) {
        // Get current position data
        final positionData = gnssService.currentPosition;

        // GPS speed is in meters per second, convert to km/h
        // Google Maps uses actual GPS speed, not calculated from position changes
        final speedMs = positionData?.speed ?? 0.0;

        // Filter invalid speeds (negative values mean GPS doesn't have speed data)
        // Also filter very small values as they're likely GPS noise when stationary
        final validSpeed =
            speedMs >= 0 &&
            speedMs < 200; // Max 200 m/s = 720 km/h (sanity check)
        final cleanSpeed = validSpeed ? speedMs : 0.0;

        // Convert m/s to km/h (1 m/s = 3.6 km/h)
        final speedKmh = cleanSpeed * 3.6;

        // Round to nearest integer for display (Google Maps style)
        final displaySpeed = speedKmh.round();

        // Consider "moving" if speed > 1 km/h (to avoid GPS drift showing movement)
        final isMoving = speedKmh >= 1.0;

        // Debug output
        if (positionData != null) {
          debugPrint(
            '🚗 Speed: ${speedMs.toStringAsFixed(2)} m/s = ${speedKmh.toStringAsFixed(1)} km/h → Display: $displaySpeed km/h',
          );
        } else {
          debugPrint('⚠️ No GPS position data available');
        }

        return Container(
          constraints: const BoxConstraints(minWidth: 130, minHeight: 110),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.85),
                Colors.grey[900]!.withOpacity(0.90),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: speedKmh > 80
                  ? Colors.red[400]!
                  : isMoving
                  ? Colors.green[400]!
                  : Colors.grey[600]!,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    displaySpeed.toString(),
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: speedKmh > 80
                          ? Colors.red[300]
                          : isMoving
                          ? Colors.green[300]
                          : Colors.white,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'km/h',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isMoving
                      ? Colors.green[600]!.withOpacity(0.3)
                      : Colors.grey[700]!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMoving ? Icons.speed : Icons.gps_fixed,
                      size: 16,
                      color: isMoving ? Colors.green[300] : Colors.grey[400],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      positionData != null
                          ? (positionData.accuracy < 10
                                ? 'GPS High'
                                : positionData.accuracy < 20
                                ? 'GPS Good'
                                : 'GPS Low')
                          : 'No GPS',
                      style: TextStyle(
                        fontSize: 11,
                        color: positionData != null
                            ? (positionData.accuracy < 10
                                  ? Colors.green[200]
                                  : positionData.accuracy < 20
                                  ? Colors.yellow[200]
                                  : Colors.orange[200])
                            : Colors.grey[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build floating controls
  Widget _buildFloatingControls() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 70,
      ), // Add padding to stay above footer
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enhanced Location button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FloatingActionButton(
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
              backgroundColor: _isFollowingLocation
                  ? Colors.blue[600]
                  : Colors.grey[700],
              elevation: 0,
              child: Icon(
                _isFollowingLocation
                    ? Icons.my_location
                    : Icons.location_disabled,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Enhanced Zoom In button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FloatingActionButton(
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
              backgroundColor: Colors.grey[700],
              elevation: 0,
              child: const Icon(Icons.zoom_in, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          // Enhanced Zoom Out button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FloatingActionButton(
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
              backgroundColor: Colors.grey[700],
              elevation: 0,
              child: const Icon(Icons.zoom_out, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          // Enhanced Network button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FloatingActionButton(
              mini: true,
              heroTag: 'network',
              onPressed: () {
                setState(() {
                  _showNetworkPanel = !_showNetworkPanel;
                  if (_showNetworkPanel) _showSafetyPanel = false;
                });
              },
              backgroundColor: _showNetworkPanel
                  ? Colors.blue[600]
                  : Colors.grey[700],
              elevation: 0,
              child: const Icon(Icons.device_hub, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          // Enhanced Safety button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FloatingActionButton(
              mini: true,
              heroTag: 'safety',
              onPressed: () {
                setState(() {
                  _showSafetyPanel = !_showSafetyPanel;
                  if (_showSafetyPanel) _showNetworkPanel = false;
                });
              },
              backgroundColor: _showSafetyPanel
                  ? Colors.green[600]
                  : Colors.grey[700],
              elevation: 0,
              child: const Icon(Icons.security, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark background
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back button
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'AuraDrive',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[850],
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          // Enhanced Search button
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _showRouteSearchDialog,
              tooltip: 'Search Route',
            ),
          ),
          // Enhanced Settings button
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
          // Enhanced Safety status indicator
          Consumer<AccelerometerCollisionService>(
            builder: (context, collisionService, child) {
              final isMonitoring = collisionService.isMonitoring;
              final alertCount = collisionService.recentAlerts.length;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMonitoring
                        ? [Colors.green[600]!, Colors.green[800]!]
                        : [Colors.red[600]!, Colors.red[800]!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isMonitoring
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMonitoring ? Icons.shield : Icons.shield_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isMonitoring ? 'ACTIVE' : 'OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    if (alertCount > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[600],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$alertCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
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
              // Safety alerts temporarily removed due to service changes
              Container(),

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

            // Speed display overlay
            Positioned(
              left: 16,
              bottom: 80,
              child: SafeArea(child: _buildSpeedDisplay()),
            ),

            // Bottom status bar with SafeArea protection
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(bottom: true, child: _buildStatusBar()),
            ),

            // Collision Alert Widget (overlay alerts)
            const CollisionAlertWidget(),
          ],
        ),
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
