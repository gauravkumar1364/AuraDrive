import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/models.dart';
import '../widgets/collision_acknowledgment_dialog.dart';

/// Service for collision detection and safety monitoring
class CollisionDetectionService extends ChangeNotifier {
  // Global navigator key for dialog display
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // State
  bool _isInitialized = false;
  bool _isMonitoring = false;

  // Sensor data
  AccelerationData? _currentAcceleration;
  List<AccelerationData> _accelerationHistory = [];

  // Collision detection
  final List<CollisionAlert> _activeAlerts = [];
  final Map<String, VehicleData> _trackedVehicles = {};

  // Enhanced Thresholds with reduced sensitivity
  // Crash detection
  static const double crashThreshold = 39.2; // 4G in m/s² (less sensitive)
  static const double severeCrashThreshold = 58.8; // 6G in m/s² (severe impact)

  // Hard braking detection
  static const double hardBrakingThreshold = -6.5; // m/s² (less sensitive)
  static const double emergencyBrakingThreshold = -8.0; // m/s² (emergency)

  // Sharp turn detection - reduced sensitivity
  static const double sharpTurnThreshold = 4.5; // m/s² (less sensitive)
  static const double aggressiveTurnThreshold = 6.5; // m/s² (aggressive)

  // Distance thresholds - increased for less sensitivity
  static const double proximityWarningDistance = 60.0; // meters
  static const double collisionWarningDistance = 35.0; // meters
  static const double criticalDistance = 15.0; // meters
  static const double urgentDistance = 8.0; // meters (immediate action)

  // Stream controllers
  final StreamController<CollisionAlert> _alertController =
      StreamController<CollisionAlert>.broadcast();
  final StreamController<AccelerationData> _accelerationController =
      StreamController<AccelerationData>.broadcast();

  // Stream subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Streams
  Stream<CollisionAlert> get alertStream => _alertController.stream;
  Stream<AccelerationData> get accelerationStream =>
      _accelerationController.stream;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isMonitoring => _isMonitoring;
  AccelerationData? get currentAcceleration => _currentAcceleration;
  List<CollisionAlert> get activeAlerts => List.unmodifiable(_activeAlerts);
  int get trackedVehicleCount => _trackedVehicles.length;

  /// Initialize collision detection service
  Future<bool> initialize() async {
    try {
      _isInitialized = true;
      notifyListeners();

      debugPrint('CollisionDetectionService: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('CollisionDetectionService: Initialization error: $e');
      return false;
    }
  }

  /// Start collision monitoring
  Future<bool> startMonitoring() async {
    if (!_isInitialized) {
      debugPrint('CollisionDetectionService: Not initialized');
      return false;
    }

    if (_isMonitoring) {
      debugPrint('CollisionDetectionService: Already monitoring');
      return true;
    }

    try {
      // Start accelerometer monitoring
      _accelerometerSubscription = accelerometerEventStream().listen(
        _onAccelerometerEvent,
        onError: (error) {
          debugPrint('CollisionDetectionService: Accelerometer error: $error');
        },
      );

      // Start periodic vehicle monitoring
      Timer.periodic(const Duration(milliseconds: 500), _monitorVehicles);

      // Start alert cleanup timer
      Timer.periodic(const Duration(seconds: 10), _cleanupExpiredAlerts);

      _isMonitoring = true;
      notifyListeners();

      debugPrint('CollisionDetectionService: Started monitoring');
      return true;
    } catch (e) {
      debugPrint('CollisionDetectionService: Error starting monitoring: $e');
      return false;
    }
  }

  /// Stop collision monitoring
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    try {
      await _accelerometerSubscription?.cancel();
      _accelerometerSubscription = null;

      _isMonitoring = false;
      notifyListeners();

      debugPrint('CollisionDetectionService: Stopped monitoring');
    } catch (e) {
      debugPrint('CollisionDetectionService: Error stopping monitoring: $e');
    }
  }

  /// Handle accelerometer events
  void _onAccelerometerEvent(AccelerometerEvent event) {
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    final accelerationData = AccelerationData(
      x: event.x,
      y: event.y,
      z: event.z,
      magnitude: magnitude,
      timestamp: DateTime.now(),
    );

    _currentAcceleration = accelerationData;
    _accelerationHistory.add(accelerationData);

    // Keep only recent history (last 10 seconds)
    final cutoffTime = DateTime.now().subtract(const Duration(seconds: 10));
    _accelerationHistory = _accelerationHistory
        .where((data) => data.timestamp.isAfter(cutoffTime))
        .toList();

    // Check for crash detection
    _checkForCrash(accelerationData);

    // Check for sudden movements
    _checkForSuddenMovements(accelerationData);

    _accelerationController.add(accelerationData);
    notifyListeners();
  }

  /// Check for crash detection based on acceleration with severity levels
  void _checkForCrash(AccelerationData acceleration) {
    // Check for severe crash
    if (acceleration.magnitude > severeCrashThreshold) {
      final alert = CollisionAlert(
        alertId: _generateAlertId(),
        sourceDeviceId: 'current_device',
        riskLevel: CollisionRiskLevel.critical,
        relativePosition: RelativePosition(
          distance: 0.0,
          bearing: 0.0,
          quadrant: DirectionQuadrant.front,
          timestamp: DateTime.now(),
        ),
        alertType: AlertType.crash,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        message:
            'SEVERE CRASH DETECTED! Impact force: ${acceleration.magnitude.toStringAsFixed(1)} m/s² (${(acceleration.magnitude / 9.8).toStringAsFixed(1)}G)',
        additionalData: {
          'severity': 'severe',
          'g_force': acceleration.magnitude / 9.8,
          'x': acceleration.x,
          'y': acceleration.y,
          'z': acceleration.z,
        },
      );
      _addAlert(alert);
      debugPrint(
        'CollisionDetectionService: SEVERE crash detected! Magnitude: ${acceleration.magnitude}',
      );
    }
    // Check for moderate crash
    else if (acceleration.magnitude > crashThreshold) {
      final alert = CollisionAlert(
        alertId: _generateAlertId(),
        sourceDeviceId: 'current_device',
        riskLevel: CollisionRiskLevel.high,
        relativePosition: RelativePosition(
          distance: 0.0,
          bearing: 0.0,
          quadrant: DirectionQuadrant.front,
          timestamp: DateTime.now(),
        ),
        alertType: AlertType.crash,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        message:
            'CRASH DETECTED! Impact force: ${acceleration.magnitude.toStringAsFixed(1)} m/s² (${(acceleration.magnitude / 9.8).toStringAsFixed(1)}G)',
        additionalData: {
          'severity': 'moderate',
          'g_force': acceleration.magnitude / 9.8,
          'x': acceleration.x,
          'y': acceleration.y,
          'z': acceleration.z,
        },
      );
      _addAlert(alert);
      debugPrint(
        'CollisionDetectionService: Crash detected! Magnitude: ${acceleration.magnitude}',
      );
    }
  }

  /// Check for sudden movements (hard braking, sharp turns) with enhanced detection
  void _checkForSuddenMovements(AccelerationData acceleration) {
    // Enhanced hard braking detection with severity
    if (acceleration.y < emergencyBrakingThreshold) {
      final alert = CollisionAlert(
        alertId: _generateAlertId(),
        sourceDeviceId: 'current_device',
        riskLevel: CollisionRiskLevel.high,
        relativePosition: RelativePosition(
          distance: 0.0,
          bearing: 0.0,
          quadrant: DirectionQuadrant.front,
          timestamp: DateTime.now(),
        ),
        alertType: AlertType.hardBraking,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
        message:
            'EMERGENCY BRAKING: ${acceleration.y.toStringAsFixed(1)} m/s² (${(acceleration.y.abs() / 9.8).toStringAsFixed(1)}G)',
        additionalData: {
          'severity': 'emergency',
          'deceleration_g': acceleration.y.abs() / 9.8,
        },
      );
      _addAlert(alert);
    } else if (acceleration.y < hardBrakingThreshold) {
      final alert = CollisionAlert(
        alertId: _generateAlertId(),
        sourceDeviceId: 'current_device',
        riskLevel: CollisionRiskLevel.medium,
        relativePosition: RelativePosition(
          distance: 0.0,
          bearing: 0.0,
          quadrant: DirectionQuadrant.front,
          timestamp: DateTime.now(),
        ),
        alertType: AlertType.hardBraking,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
        message:
            'Hard braking: ${acceleration.y.toStringAsFixed(1)} m/s² (${(acceleration.y.abs() / 9.8).toStringAsFixed(1)}G)',
        additionalData: {
          'severity': 'moderate',
          'deceleration_g': acceleration.y.abs() / 9.8,
        },
      );
      _addAlert(alert);
    }

    // Enhanced sharp turn detection with accurate direction
    final lateralAccel = acceleration.x.abs();
    if (lateralAccel > aggressiveTurnThreshold) {
      // Determine turn direction
      final turnDirection = acceleration.x > 0 ? 'RIGHT' : 'LEFT';
      final quadrant = acceleration.x > 0
          ? DirectionQuadrant.right
          : DirectionQuadrant.left;

      final alert = CollisionAlert(
        alertId: _generateAlertId(),
        sourceDeviceId: 'current_device',
        riskLevel: CollisionRiskLevel.high,
        relativePosition: RelativePosition(
          distance: 0.0,
          bearing: acceleration.x > 0 ? 90.0 : 270.0, // Right or Left
          quadrant: quadrant,
          timestamp: DateTime.now(),
        ),
        alertType: AlertType.sharpTurn,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
        message:
            'AGGRESSIVE $turnDirection TURN: ${lateralAccel.toStringAsFixed(1)} m/s² (${(lateralAccel / 9.8).toStringAsFixed(1)}G)',
        additionalData: {
          'direction': turnDirection,
          'severity': 'aggressive',
          'lateral_g': lateralAccel / 9.8,
          'lateral_accel': acceleration.x,
        },
      );
      _addAlert(alert);
    } else if (lateralAccel > sharpTurnThreshold) {
      // Determine turn direction
      final turnDirection = acceleration.x > 0 ? 'RIGHT' : 'LEFT';
      final quadrant = acceleration.x > 0
          ? DirectionQuadrant.right
          : DirectionQuadrant.left;

      final alert = CollisionAlert(
        alertId: _generateAlertId(),
        sourceDeviceId: 'current_device',
        riskLevel: CollisionRiskLevel.medium,
        relativePosition: RelativePosition(
          distance: 0.0,
          bearing: acceleration.x > 0 ? 90.0 : 270.0, // Right or Left
          quadrant: quadrant,
          timestamp: DateTime.now(),
        ),
        alertType: AlertType.sharpTurn,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
        message:
            'Sharp $turnDirection turn: ${lateralAccel.toStringAsFixed(1)} m/s² (${(lateralAccel / 9.8).toStringAsFixed(1)}G)',
        additionalData: {
          'direction': turnDirection,
          'severity': 'moderate',
          'lateral_g': lateralAccel / 9.8,
          'lateral_accel': acceleration.x,
        },
      );
      _addAlert(alert);
    }
  }

  /// Monitor vehicles for collision risks
  void _monitorVehicles(Timer timer) {
    if (!_isMonitoring) {
      timer.cancel();
      return;
    }

    // Check each tracked vehicle for collision risk
    for (final vehicle in _trackedVehicles.values) {
      if (!vehicle.isRecent(seconds: 10)) continue; // Skip stale data

      final alert = _assessCollisionRisk(vehicle);
      if (alert != null) {
        _addAlert(alert);
      }
    }
  }

  /// Assess collision risk with a specific vehicle
  CollisionAlert? _assessCollisionRisk(VehicleData vehicle) {
    // For demonstration, we'll create a mock current vehicle position
    // In reality, this would come from the GNSS service
    final currentPosition = PositionData(
      deviceId: 'current_device',
      latitude: 28.6139, // Delhi coordinates
      longitude: 77.2090,
      accuracy: 5.0,
      timestamp: DateTime.now(),
    );

    final distance = currentPosition.distanceTo(vehicle.position);
    final timeToCollision = vehicle.timeToCollision(
      _createMockCurrentVehicle(currentPosition),
    );

    // Determine risk level based on distance and time to collision
    CollisionRiskLevel riskLevel;
    AlertType alertType;
    String message;

    // Enhanced distance-based risk assessment
    if (distance <= urgentDistance) {
      riskLevel = CollisionRiskLevel.critical;
      alertType = AlertType.collision;
      message =
          'URGENT! Vehicle extremely close (${distance.toStringAsFixed(1)}m) - IMMEDIATE ACTION REQUIRED';
    } else if (distance <= criticalDistance) {
      riskLevel = CollisionRiskLevel.critical;
      alertType = AlertType.collision;
      message =
          'CRITICAL: Vehicle very close (${distance.toStringAsFixed(1)}m)';
    } else if (distance <= collisionWarningDistance) {
      riskLevel = CollisionRiskLevel.high;
      alertType = AlertType.collision;
      message =
          'COLLISION WARNING: Vehicle approaching (${distance.toStringAsFixed(1)}m)';
    } else if (distance <= proximityWarningDistance) {
      riskLevel = CollisionRiskLevel.medium;
      alertType = AlertType.proximity;
      message =
          'Proximity warning: Vehicle nearby (${distance.toStringAsFixed(1)}m)';
    } else {
      return null; // No risk
    }

    // Enhance message with time to collision if available
    if (timeToCollision != null && timeToCollision < 10.0) {
      message += ' - Time to collision: ${timeToCollision.toStringAsFixed(1)}s';
      if (timeToCollision < 3.0) {
        riskLevel = CollisionRiskLevel.critical;
      }
    }

    return CollisionAlert(
      alertId: _generateAlertId(),
      sourceDeviceId: 'current_device',
      targetDeviceId: vehicle.deviceId,
      riskLevel: riskLevel,
      timeToCollision: timeToCollision,
      relativePosition: RelativePosition.fromPositions(
        currentPosition,
        vehicle.position,
        relativeSpeed: _calculateRelativeSpeed(vehicle),
      ),
      alertType: alertType,
      timestamp: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(seconds: 30)),
      message: message,
    );
  }

  /// Create mock current vehicle data
  VehicleData _createMockCurrentVehicle(PositionData position) {
    return VehicleData(
      deviceId: 'current_device',
      position: position,
      velocity: const VelocityData(
        speed: 10.0, // 10 m/s = 36 km/h
        bearing: 0.0,
        accuracy: 1.0,
      ),
      acceleration:
          _currentAcceleration ??
          AccelerationData(
            x: 0.0,
            y: 0.0,
            z: 9.8,
            magnitude: 9.8,
            timestamp: DateTime.now(),
          ),
      heading: 0.0,
      deviceInfo: const DeviceInfo(
        deviceModel: 'Mock Device',
        osVersion: 'Android 13',
        appVersion: '1.0.0',
        bluetoothCapability: 'BLE',
        gnssCapability: 'GPS+NavIC',
      ),
      timestamp: DateTime.now(),
    );
  }

  /// Calculate relative speed between vehicles
  double _calculateRelativeSpeed(VehicleData otherVehicle) {
    // Simplified calculation - in reality would use vector math
    return otherVehicle
        .velocity
        .speed; // Assume head-on approach for worst case
  }

  /// Add vehicle to tracking
  void addVehicleToTracking(VehicleData vehicle) {
    _trackedVehicles[vehicle.deviceId] = vehicle;

    // Remove old vehicles (older than 1 minute)
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 1));
    _trackedVehicles.removeWhere(
      (key, value) => value.timestamp.isBefore(cutoffTime),
    );

    notifyListeners();
  }

  /// Remove vehicle from tracking
  void removeVehicleFromTracking(String deviceId) {
    _trackedVehicles.remove(deviceId);
    notifyListeners();
  }

  /// Add alert to active alerts
  void _addAlert(CollisionAlert alert) {
    // Check if similar alert already exists
    final existingSimilar = _activeAlerts.any(
      (existing) =>
          existing.sourceDeviceId == alert.sourceDeviceId &&
          existing.targetDeviceId == alert.targetDeviceId &&
          existing.alertType == alert.alertType &&
          existing.isRecent,
    );

    if (!existingSimilar) {
      _activeAlerts.add(alert);
      _alertController.add(alert);
      notifyListeners();

      debugPrint('CollisionDetectionService: Alert added: ${alert.message}');
    }
  }

  /// Clean up expired alerts
  void _cleanupExpiredAlerts(Timer timer) {
    if (!_isMonitoring) {
      timer.cancel();
      return;
    }

    final initialCount = _activeAlerts.length;
    _activeAlerts.removeWhere((alert) => !alert.isValid);

    if (_activeAlerts.length != initialCount) {
      notifyListeners();
      debugPrint(
        'CollisionDetectionService: Cleaned up ${initialCount - _activeAlerts.length} expired alerts',
      );
    }
  }

  /// Generate unique alert ID
  String _generateAlertId() {
    return 'alert_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  /// Get active alerts by risk level
  List<CollisionAlert> getAlertsByRiskLevel(CollisionRiskLevel riskLevel) {
    return _activeAlerts
        .where((alert) => alert.riskLevel == riskLevel && alert.isValid)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get highest priority alert
  CollisionAlert? get highestPriorityAlert {
    if (_activeAlerts.isEmpty) return null;

    final validAlerts = _activeAlerts.where((alert) => alert.isValid).toList();
    if (validAlerts.isEmpty) return null;

    validAlerts.sort((a, b) => b.priority.compareTo(a.priority));
    return validAlerts.first;
  }

  /// Check if driving behavior is aggressive
  bool get isAggressiveDriving {
    if (_accelerationHistory.length < 10) return false;

    final recentAccelerations = _accelerationHistory
        .where(
          (data) => DateTime.now().difference(data.timestamp).inSeconds < 30,
        )
        .toList();

    final hardEvents = recentAccelerations
        .where((data) => data.indicatesHardBraking || data.indicatesSharpTurn)
        .length;

    return hardEvents > 3; // More than 3 hard events in 30 seconds
  }

  /// Get safety score (0-100, higher is safer)
  int get safetyScore {
    int score = 100;

    // Deduct for active alerts
    for (final alert in _activeAlerts.where((a) => a.isValid)) {
      switch (alert.riskLevel) {
        case CollisionRiskLevel.critical:
          score -= 30;
          break;
        case CollisionRiskLevel.high:
          score -= 20;
          break;
        case CollisionRiskLevel.medium:
          score -= 10;
          break;
        case CollisionRiskLevel.low:
          score -= 5;
          break;
        case CollisionRiskLevel.none:
          break;
      }
    }

    // Deduct for aggressive driving
    if (isAggressiveDriving) {
      score -= 25;
    }

    return score.clamp(0, 100);
  }

  /// Dispose of resources
  @override
  void dispose() {
    stopMonitoring();
    _alertController.close();
    _accelerationController.close();
    super.dispose();
  }
}
