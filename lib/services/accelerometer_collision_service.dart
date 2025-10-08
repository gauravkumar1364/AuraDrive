import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Simple collision alert for accelerometer detection
class SimpleCollisionAlert {
  final String id;
  final DateTime timestamp;
  final String type; // 'crash', 'braking', 'turn'
  final String message;
  final double gForce;
  final String severity; // 'low', 'medium', 'high', 'critical'

  SimpleCollisionAlert({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.message,
    required this.gForce,
    required this.severity,
  });
}

/// Simple Accelerometer Collision Detection with Visual Alerts
/// Detects crashes, hard braking, and sharp turns using phone sensors
class AccelerometerCollisionService extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _subscription;
  bool _isMonitoring = false;
  DateTime? _lastAlert;

  // Alert stream for UI notifications
  final StreamController<SimpleCollisionAlert> _alertController =
      StreamController<SimpleCollisionAlert>.broadcast();
  Stream<SimpleCollisionAlert> get alertStream => _alertController.stream;

  // Recent alerts list
  final List<SimpleCollisionAlert> _recentAlerts = [];
  List<SimpleCollisionAlert> get recentAlerts =>
      List.unmodifiable(_recentAlerts);

  // REALISTIC thresholds to reduce false positives
  static const double crashThreshold =
      12.0; // 12G for crashes (reduced from 15G)
  static const double brakingThreshold =
      1.0; // 1.0G for hard braking (reduced from 1.5G)
  static const double turnThreshold =
      0.8; // 0.8G for sharp turns (reduced from 1.2G)
  static const double motionThreshold =
      0.3; // 0.3G minimum motion (reduced from 0.4G)

  final List<double> _history = [];
  static const int historySize = 10;

  bool get isMonitoring => _isMonitoring;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    try {
      _isMonitoring = true;

      _subscription =
          accelerometerEventStream(
            samplingPeriod: SensorInterval.normalInterval,
          ).listen(
            _onAccelerometerEvent,
            onError: (error) {
              debugPrint('❌ Accelerometer error: $error');
              stopMonitoring();
            },
          );

      debugPrint('🚗 Accelerometer collision detection started');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to start accelerometer monitoring: $e');
      _isMonitoring = false;
    }
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _subscription?.cancel();
    debugPrint('🚗 Accelerometer collision detection stopped');
    notifyListeners();
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    try {
      // Calculate total acceleration magnitude
      final magnitude = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Add to history for smoothing
      _history.add(magnitude);
      if (_history.length > historySize) {
        _history.removeAt(0);
      }

      if (_history.length >= 5) {
        // Calculate smoothed magnitude
        final smoothed = _history.reduce((a, b) => a + b) / _history.length;

        // Convert to G-forces (subtract gravity)
        final gForce = (smoothed - 9.8).abs() / 9.8;

        // Only process significant motion
        if (gForce > motionThreshold) {
          _analyzeMotion(event, gForce);
        }
      }
    } catch (e) {
      debugPrint('❌ Error analyzing motion: $e');
    }
  }

  void _analyzeMotion(AccelerometerEvent event, double gForce) {
    final now = DateTime.now();

    // Prevent spam alerts (minimum 2 seconds between alerts for better user experience)
    if (_lastAlert != null && now.difference(_lastAlert!).inSeconds < 2) {
      return;
    }

    // Calculate directional forces
    final longitudinalG = event.y.abs() / 9.8; // Forward/backward
    final lateralG = event.x.abs() / 9.8; // Left/right

    SimpleCollisionAlert? alert;

    // Check for collision (very high threshold)
    if (gForce >= crashThreshold) {
      alert = SimpleCollisionAlert(
        id: now.millisecondsSinceEpoch.toString(),
        timestamp: now,
        type: 'crash',
        message: 'COLLISION DETECTED! ${gForce.toStringAsFixed(1)}G impact',
        gForce: gForce,
        severity: gForce >= 20.0
            ? 'critical'
            : gForce >= 15.0
            ? 'high'
            : 'medium',
      );
      _lastAlert = now;
    }
    // Check for hard braking
    else if (longitudinalG >= brakingThreshold) {
      alert = SimpleCollisionAlert(
        id: now.millisecondsSinceEpoch.toString(),
        timestamp: now,
        type: 'braking',
        message:
            'HARD BRAKING! ${longitudinalG.toStringAsFixed(1)}G deceleration',
        gForce: longitudinalG,
        severity: longitudinalG >= 1.5 ? 'high' : 'medium',
      );
      _lastAlert = now;
    }
    // Check for sharp turn
    else if (lateralG >= turnThreshold) {
      final direction = event.x > 0 ? 'RIGHT' : 'LEFT';
      alert = SimpleCollisionAlert(
        id: now.millisecondsSinceEpoch.toString(),
        timestamp: now,
        type: 'turn',
        message:
            'SHARP $direction TURN! ${lateralG.toStringAsFixed(1)}G lateral',
        gForce: lateralG,
        severity: lateralG >= 1.2 ? 'high' : 'medium',
      );
      _lastAlert = now;
    }

    if (alert != null) {
      // Add to recent alerts list
      _recentAlerts.add(alert);
      if (_recentAlerts.length > 10) {
        _recentAlerts.removeAt(0);
      }

      // Emit alert to stream for UI
      _alertController.add(alert);

      // Debug print
      debugPrint('🚨 ${alert.message}');

      // Notify listeners
      notifyListeners();
    }
  }

  /// Test method to manually trigger an alert (for testing UI)
  void testAlert({
    String type = 'crash',
    String message = 'TEST ALERT!',
    double gForce = 15.0,
    String severity = 'high',
  }) {
    final alert = SimpleCollisionAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: type,
      message: message,
      gForce: gForce,
      severity: severity,
    );

    // Add to recent alerts list
    _recentAlerts.add(alert);
    if (_recentAlerts.length > 10) {
      _recentAlerts.removeAt(0);
    }

    // Emit alert to stream for UI
    _alertController.add(alert);

    // Debug print
    debugPrint('🧪 Test Alert: ${alert.message}');

    // Notify listeners
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
