import 'dart:async';import 'dart:async';import 'dart:async';import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/foundation.dart';import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import '../models/collision_alert.dart';import 'package:flutter/foundation.dart';import 'dart:math' as math;import 'dart:math' as math;



class CollisionDetectionService extends ChangeNotifier {import 'package:sensors_plus/sensors_plus.dart';

  // Streams and subscriptions  

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;import '../models/collision_alert.dart';import 'package:flutter/foundation.dart';import 'package:flutter/foundation.dart';

  final StreamController<CollisionAlert> _alertController = 

      StreamController<CollisionAlert>.broadcast();

  

  // State managementclass CollisionDetectionService extends ChangeNotifier {import 'package:sensors_plus/sensors_plus.dart';import 'package:sensors_plus/sens  /// Advanced physics-based analysis for PRECISE collision & braking detection

  bool _isMonitoring = false;

  int _safetyScore = 100;  // Streams and subscriptions  

  final List<CollisionAlert> _activeAlerts = [];

    StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;import '../models/collision_alert.dart';  void _performAdvancedAnalysis(AccelerometerEvent event, double gForce, double smoothedMagnitude) {

  // Enhanced filtering system

  final List<double> _accelerationHistory = [];  final StreamController<CollisionAlert> _alertController = 

  DateTime? _lastEventTime;

  static const int _historySize = 8;      StreamController<CollisionAlert>.broadcast();    try {

  

  // REALISTIC Thresholds (less sensitive)  

  static const double _minorCrashThreshold = 8.0;     // Increased from 6.0

  static const double _moderateCrashThreshold = 12.0; // Increased from 8.0  // State managementclass CollisionDetectionService extends ChangeNotifier {      // Separate longitudinal (forward/backward) and lateral (left/right) forces

  static const double _severeCrashThreshold = 18.0;   // Increased from 12.0

  static const double _criticalCrashThreshold = 25.0; // Increased from 20.0  bool _isMonitoring = false;

  

  static const double _emergencyBrakingThreshold = 1.5;  // Increased from 1.2  int _safetyScore = 100;  // Streams and subscriptions        final longitudinalG = (event.y.abs() - 9.8).abs() / 9.8; // Y-axis = forward/backward (gravity compensated)

  static const double _hardBrakingThreshold = 1.0;       // Increased from 0.8

  static const double _moderateBrakingThreshold = 0.7;   // Increased from 0.5  final List<CollisionAlert> _activeAlerts = [];

  static const double _sharpTurnThreshold = 1.0;         // Increased from 0.8

        StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;      final lateralG = event.x.abs() / 9.8;       // X-axis = left/right

  bool get isMonitoring => _isMonitoring;

  List<CollisionAlert> get activeAlerts => List.unmodifiable(_activeAlerts);  // Enhanced filtering system for accuracy

  Stream<CollisionAlert> get alertStream => _alertController.stream;

  int get safetyScore => _safetyScore;  final List<double> _accelerationHistory = [];  final StreamController<CollisionAlert> _alertController =       final verticalG = (event.z.abs() - 9.8).abs() / 9.8;      // Z-axis = up/down (gravity compensated)

  

  Future<void> initialize() async {  final List<AccelerometerEvent> _rawEventHistory = [];

    debugPrint('🛡️ Initializing Collision Detection Service with ROBUST thresholds');

    debugPrint('🎯 Less sensitive: Crash 8G-25G | Braking 0.7G-1.5G | Turns 1.0G');  static const int _historySize = 10; // 10 samples for smoothing      StreamController<CollisionAlert>.broadcast();      

  }

    DateTime? _lastEventTime; // For duplicate event prevention

  Future<void> startMonitoring() async {

    if (_isMonitoring) return;          // Only log significant movements to reduce noise

    

    try {  // LESS SENSITIVE Thresholds for real-world use (reduced false positives)

      _isMonitoring = true;

        static const double _minorCrashThreshold = 6.0;     // 58.8 m/s² - Light collision  // State management      if (gForce > 0.3) {

      _accelerometerSubscription = accelerometerEventStream(

        samplingPeriod: SensorInterval.normalInterval,  static const double _moderateCrashThreshold = 8.0;  // 78.4 m/s² - Standard collision

      ).listen(

        _onAccelerometerEvent,  static const double _severeCrashThreshold = 12.0;   // 117.6 m/s² - Major accident  bool _isMonitoring = false;        debugPrint('🔍 Motion Analysis: Total=${gForce.toStringAsFixed(2)}G, '

        onError: (error) {

          debugPrint('❌ Accelerometer error: $error');  static const double _criticalCrashThreshold = 20.0; // 196 m/s² - Life-threatening

          stopMonitoring();

        },    int _safetyScore = 100;                   'Long=${longitudinalG.toStringAsFixed(2)}G, '

      );

        // REALISTIC Braking & Turning Thresholds

      debugPrint('🛡️ Collision detection started - Robust monitoring active');

      notifyListeners();  static const double _emergencyBrakingThreshold = 1.2;  // Emergency braking  final List<CollisionAlert> _activeAlerts = [];                   'Lat=${lateralG.toStringAsFixed(2)}G, '

    } catch (e) {

      debugPrint('❌ Failed to start collision monitoring: $e');  static const double _hardBrakingThreshold = 0.8;       // Hard braking

      _isMonitoring = false;

      rethrow;  static const double _moderateBrakingThreshold = 0.5;   // Moderate braking                     'Vert=${verticalG.toStringAsFixed(2)}G');

    }

  }  

  

  void stopMonitoring() {  static const double _sharpTurnThreshold = 0.8;         // Sharp turn  // Enhanced filtering system for accuracy      }

    _isMonitoring = false;

    _accelerometerSubscription?.cancel();    

    debugPrint('🛡️ Collision detection stopped');

    notifyListeners();  bool get isMonitoring => _isMonitoring;  final List<double> _accelerationHistory = [];      

  }

    List<CollisionAlert> get activeAlerts => List.unmodifiable(_activeAlerts);

  void clearAlerts() {

    _activeAlerts.clear();  Stream<CollisionAlert> get alertStream => _alertController.stream;  final List<AccelerometerEvent> _rawEventHistory = [];      _processAccurateAccelerationEvent(event, gForce, longitudinalG, lateralG, verticalG);

    notifyListeners();

  }  int get safetyScore => _safetyScore;



  void _onAccelerometerEvent(AccelerometerEvent event) {    static const int _historySize = 10; // 10 samples for smoothing    } catch (e) {

    try {

      final magnitude = math.sqrt(  Future<void> initialize() async {

        event.x * event.x + event.y * event.y + event.z * event.z

      );    debugPrint('🛡️ Initializing Collision Detection Service with REALISTIC thresholds');  DateTime? _lastEventTime; // For duplicate event prevention      debugPrint('❌ Error in advanced analysis: $e');

      

      _accelerationHistory.add(magnitude);    debugPrint('🎯 Crash detection: 6G-20G | Braking: 0.5G-1.2G | Turns: 0.8G');

      if (_accelerationHistory.length > _historySize) {

        _accelerationHistory.removeAt(0);  }      }

      }

        

      if (_accelerationHistory.length >= 5) {

        final smoothedMagnitude = _accelerationHistory  Future<void> startMonitoring() async {  // LESS SENSITIVE Thresholds for real-world use (reduced false positives)  };

            .reduce((a, b) => a + b) / _accelerationHistory.length;

            if (_isMonitoring) return;

        final gForce = (smoothedMagnitude - 9.8).abs() / 9.8;

              static const double _minorCrashThreshold = 6.0;     // 58.8 m/s² - Light collisionimport '../models/collision_alert.dart';

        // Higher threshold to reduce false positives

        if (gForce > 0.3) {    try {

          _processAccelerationEvent(event, gForce);

        }      _isMonitoring = true;  static const double _moderateCrashThreshold = 8.0;  // 78.4 m/s² - Standard collision

      }

    } catch (e) {      

      debugPrint('❌ Error processing accelerometer event: $e');

    }      // Subscribe to accelerometer with reasonable frequency (not fastest to avoid crashes)  static const double _severeCrashThreshold = 12.0;   // 117.6 m/s² - Major accidentclass CollisionDetectionService extends ChangeNotifier {

  }

      _accelerometerSubscription = accelerometerEventStream(

  void _processAccelerationEvent(AccelerometerEvent event, double gForce) {

    final now = DateTime.now();        samplingPeriod: SensorInterval.normalInterval, // Changed from fastest to normal  static const double _criticalCrashThreshold = 20.0; // 196 m/s² - Life-threatening  // Streams and subscriptions  

    

    if (_lastEventTime != null &&       ).listen(

        now.difference(_lastEventTime!).inMilliseconds < 200) {

      return;        _onAccelerometerEvent,    StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

    }

    _lastEventTime = now;        onError: (error) {



    // Separate directional forces          debugPrint('❌ Accelerometer error: $error');  // REALISTIC Braking & Turning Thresholds  final StreamController<CollisionAlert> _alertController = 

    final longitudinalG = event.y.abs() / 9.8;

    final lateralG = event.x.abs() / 9.8;          stopMonitoring(); // Stop if sensor fails



    AlertType? alertType;        },  static const double _emergencyBrakingThreshold = 1.2;  // Emergency braking      StreamController<CollisionAlert>.broadcast();

    CollisionRiskLevel? riskLevel;

    String? alertMessage;      );



    // Collision detection        static const double _hardBrakingThreshold = 0.8;       // Hard braking

    if (gForce >= _criticalCrashThreshold) {

      alertType = AlertType.crash;      debugPrint('🛡️ Collision detection started - Monitoring active');

      riskLevel = CollisionRiskLevel.critical;

      alertMessage = 'CRITICAL COLLISION! ${gForce.toStringAsFixed(1)}G impact';      notifyListeners();  static const double _moderateBrakingThreshold = 0.5;   // Moderate braking  // State management

      _safetyScore = math.max(0, _safetyScore - 50);

    } else if (gForce >= _severeCrashThreshold) {    } catch (e) {

      alertType = AlertType.crash;

      riskLevel = CollisionRiskLevel.high;      debugPrint('❌ Failed to start collision monitoring: $e');    bool _isMonitoring = false;

      alertMessage = 'SEVERE COLLISION! ${gForce.toStringAsFixed(1)}G impact';

      _safetyScore = math.max(0, _safetyScore - 30);      _isMonitoring = false;

    } else if (gForce >= _moderateCrashThreshold) {

      alertType = AlertType.crash;      rethrow;  static const double _sharpTurnThreshold = 0.8;         // Sharp turn  final List<CollisionAlert> _activeAlerts = [];

      riskLevel = CollisionRiskLevel.medium;

      alertMessage = 'MODERATE COLLISION! ${gForce.toStringAsFixed(1)}G impact';    }

      _safetyScore = math.max(0, _safetyScore - 20);

    } else if (gForce >= _minorCrashThreshold) {  }      int _safetyScore = 100;

      alertType = AlertType.crash;

      riskLevel = CollisionRiskLevel.low;  

      alertMessage = 'MINOR COLLISION! ${gForce.toStringAsFixed(1)}G impact';

      _safetyScore = math.max(0, _safetyScore - 10);  void stopMonitoring() {  bool get isMonitoring => _isMonitoring;  DateTime? _lastAlertTime;

    }

    // Braking detection     _isMonitoring = false;

    else if (longitudinalG >= _emergencyBrakingThreshold) {

      alertType = AlertType.hardBraking;    _accelerometerSubscription?.cancel();  List<CollisionAlert> get activeAlerts => List.unmodifiable(_activeAlerts);  

      riskLevel = CollisionRiskLevel.high;

      alertMessage = 'EMERGENCY BRAKING! ${longitudinalG.toStringAsFixed(1)}G deceleration';    

      _safetyScore = math.max(0, _safetyScore - 15);

    } else if (longitudinalG >= _hardBrakingThreshold) {    debugPrint('🛡️ Collision detection stopped');  Stream<CollisionAlert> get alertStream => _alertController.stream;  // Advanced filtering for accuracy

      alertType = AlertType.hardBraking;

      riskLevel = CollisionRiskLevel.medium;    notifyListeners();

      alertMessage = 'HARD BRAKING! ${longitudinalG.toStringAsFixed(1)}G deceleration';

      _safetyScore = math.max(0, _safetyScore - 10);  }  int get safetyScore => _safetyScore;  final List<double> _accelerationHistory = [];

    } else if (longitudinalG >= _moderateBrakingThreshold) {

      alertType = AlertType.hardBraking;  

      riskLevel = CollisionRiskLevel.low;

      alertMessage = 'MODERATE BRAKING! ${longitudinalG.toStringAsFixed(1)}G deceleration';  void clearAlerts() {    final List<AccelerometerEvent> _rawEventHistory = [];

      _safetyScore = math.max(0, _safetyScore - 5);

    }    _activeAlerts.clear();

    // Sharp turn detection

    else if (lateralG >= _sharpTurnThreshold) {    notifyListeners();  Future<void> initialize() async {  static const int _historySize = 10; // 10 samples for smoothing

      alertType = AlertType.sharpTurn;

      riskLevel = CollisionRiskLevel.medium;  }

      final direction = event.x > 0 ? 'RIGHT' : 'LEFT';

      alertMessage = 'SHARP $direction TURN! ${lateralG.toStringAsFixed(1)}G lateral force';    debugPrint('🛡️ Initializing Collision Detection Service with REALISTIC thresholds');  DateTime? _lastEventTime; // For duplicate event prevention

      _safetyScore = math.max(0, _safetyScore - 5);

    }  /// Process accelerometer data with ADVANCED FILTERING and REDUCED SENSITIVITY



    if (alertType != null && riskLevel != null && alertMessage != null) {  void _onAccelerometerEvent(AccelerometerEvent event) {    debugPrint('🎯 Crash detection: 6G-20G | Braking: 0.5G-1.2G | Turns: 0.8G');  

      final alert = CollisionAlert(

        alertId: now.millisecondsSinceEpoch.toString(),    try {

        sourceDeviceId: 'local_device_robust',

        riskLevel: riskLevel,      // Add to raw event history for advanced analysis  }  // Realistic Automotive Thresholds (G-forces) - LESS SENSITIVE for real-world use

        relativePosition: RelativePosition(

          distance: 0.0,      _rawEventHistory.add(event);

          bearing: 0.0,

          quadrant: DirectionQuadrant.front,      if (_rawEventHistory.length > _historySize) {    static const double _minorCrashThreshold = 6.0;     // 58.8 m/s² - Light collision (increased)

          timestamp: now,

        ),        _rawEventHistory.removeAt(0);

        alertType: alertType,

        timestamp: now,      }  Future<void> startMonitoring() async {  static const double _moderateCrashThreshold = 8.0;  // 78.4 m/s² - Standard collision (increased)

        message: alertMessage,

        additionalData: {      

          'total_g_force': gForce,

          'longitudinal_g': longitudinalG,      // Calculate magnitude (total acceleration)    if (_isMonitoring) return;  static const double _severeCrashThreshold = 12.0;   // 117.6 m/s² - Major accident (increased)

          'lateral_g': lateralG,

        },      final magnitude = math.sqrt(

      );

        event.x * event.x + event.y * event.y + event.z * event.z      static const double _criticalCrashThreshold = 20.0; // 196 m/s² - Life-threatening (increased)

      _emitAlert(alert);

      debugPrint('🚨 ${alertType.name.toUpperCase()}: ${alertMessage}');      );

    }

  }          try {  



  void _emitAlert(CollisionAlert alert) {      // Add to acceleration history for smoothing

    try {

      _activeAlerts.add(alert);      _accelerationHistory.add(magnitude);      _isMonitoring = true;  // LESS SENSITIVE Braking & Turning Thresholds for real driving

      

      if (_activeAlerts.length > 10) {      if (_accelerationHistory.length > _historySize) {

        _activeAlerts.removeAt(0);

      }        _accelerationHistory.removeAt(0);        static const double _emergencyBrakingThreshold = 1.2;  // Emergency braking (increased)

      

      _alertController.add(alert);      }

      notifyListeners();

    } catch (e) {            // Subscribe to accelerometer with reasonable frequency (not fastest to avoid crashes)  static const double _hardBrakingThreshold = 0.8;       // Hard braking (increased)

      debugPrint('❌ Error emitting alert: $e');

    }      // Apply advanced filtering: Moving average for noise reduction

  }

      if (_accelerationHistory.length >= 5) { // Wait for more samples      _accelerometerSubscription = accelerometerEventStream(  static const double _moderateBrakingThreshold = 0.5;   // Moderate braking (increased)

  @override

  void dispose() {        final smoothedMagnitude = _accelerationHistory

    stopMonitoring();

    _alertController.close();            .reduce((a, b) => a + b) / _accelerationHistory.length;        samplingPeriod: SensorInterval.normalInterval, // Changed from fastest to normal  

    super.dispose();

  }        

}
        // Convert to G-forces and SUBTRACT GRAVITY with smoothing      ).listen(  static const double _sharpTurnThreshold = 0.8;         // Sharp turn (increased)

        final gForce = (smoothedMagnitude - 9.8).abs() / 9.8;

                _onAccelerometerEvent,  

        // Enhanced motion detection with LESS sensitivity to avoid false positives

        if (gForce > 0.2) { // Increased threshold for less sensitivity        onError: (error) {  bool get isMonitoring => _isMonitoring;

          _performAdvancedAnalysis(event, gForce, smoothedMagnitude);

        }          debugPrint('❌ Accelerometer error: $error');  List<CollisionAlert> get activeAlerts => List.unmodifiable(_activeAlerts);

      }

    } catch (e) {          stopMonitoring(); // Stop if sensor fails  Stream<CollisionAlert> get alertStream => _alertController.stream;

      debugPrint('❌ Error processing accelerometer event: $e');

    }        },  int get safetyScore => _safetyScore;

  }

      );  

  /// Advanced physics-based analysis with REALISTIC detection

  void _performAdvancedAnalysis(AccelerometerEvent event, double gForce, double smoothedMagnitude) {        Future<void> initialize() async {

    try {

      // Separate directional forces with gravity compensation      debugPrint('🛡️ Collision detection started - Monitoring active');    debugPrint('🛡️ Initializing Advanced Collision Detection Service');

      final longitudinalG = math.max(0, (event.y.abs() - 9.8).abs() / 9.8); // Forward/backward

      final lateralG = event.x.abs() / 9.8;       // Left/right      notifyListeners();    debugPrint('🎯 Using realistic automotive thresholds (8G-16G crash detection)');

      final verticalG = math.max(0, (event.z.abs() - 9.8).abs() / 9.8);    // Up/down

          } catch (e) {  }

      // Only log significant movements to reduce noise

      if (gForce > 0.4) {      debugPrint('❌ Failed to start collision monitoring: $e');  

        debugPrint('🔍 Significant Motion: Total=${gForce.toStringAsFixed(2)}G, '

                   'Long=${longitudinalG.toStringAsFixed(2)}G, '      _isMonitoring = false;  Future<void> startMonitoring() async {

                   'Lat=${lateralG.toStringAsFixed(2)}G');

      }      rethrow;    if (_isMonitoring) return;

      

      _processAccurateAccelerationEvent(event, gForce, longitudinalG, lateralG, verticalG);    }    

    } catch (e) {

      debugPrint('❌ Error in advanced analysis: $e');  }    try {

    }

  }        _isMonitoring = true;



  /// REALISTIC collision & braking detection with proper thresholds  void stopMonitoring() {      

  void _processAccurateAccelerationEvent(AccelerometerEvent event, double totalG, 

                                          double longitudinalG, double lateralG, double verticalG) {    _isMonitoring = false;      // Subscribe to accelerometer with reasonable frequency (not fastest to avoid crashes)

    final now = DateTime.now();

        _accelerometerSubscription?.cancel();      _accelerometerSubscription = accelerometerEventStream(

    // Skip duplicate events (within 100ms for stability)

    if (_lastEventTime != null &&             samplingPeriod: SensorInterval.normalInterval, // Changed from fastest to normal

        now.difference(_lastEventTime!).inMilliseconds < 100) {

      return;    debugPrint('🛡️ Collision detection stopped');      ).listen(

    }

    _lastEventTime = now;    notifyListeners();        _onAccelerometerEvent,



    AlertType? alertType;  }        onError: (error) {

    CollisionRiskLevel? riskLevel;

    Map<String, dynamic> additionalData = {            debugPrint('❌ Accelerometer error: $error');

      'total_g_force': totalG,

      'longitudinal_g': longitudinalG,  void clearAlerts() {          stopMonitoring(); // Stop if sensor fails

      'lateral_g': lateralG,

      'vertical_g': verticalG,    _activeAlerts.clear();        },

      'raw_x': event.x,

      'raw_y': event.y,    notifyListeners();      );

      'raw_z': event.z,

    };  }      



    // === COLLISION DETECTION (Higher thresholds for realism) ===      debugPrint('🛡️ Collision detection started - Monitoring active');

    if (totalG >= _criticalCrashThreshold) {

      alertType = AlertType.crash;  /// Process accelerometer data with ADVANCED FILTERING and REDUCED SENSITIVITY      notifyListeners();

      riskLevel = CollisionRiskLevel.critical;

      _safetyScore = math.max(0, _safetyScore - 50);  void _onAccelerometerEvent(AccelerometerEvent event) {    } catch (e) {

      additionalData['crash_type'] = 'CRITICAL';

    } else if (totalG >= _severeCrashThreshold) {    try {      debugPrint('❌ Failed to start collision monitoring: $e');

      alertType = AlertType.crash;

      riskLevel = CollisionRiskLevel.high;      // Add to raw event history for advanced analysis      _isMonitoring = false;

      _safetyScore = math.max(0, _safetyScore - 30);

      additionalData['crash_type'] = 'SEVERE';      _rawEventHistory.add(event);      rethrow;

    } else if (totalG >= _moderateCrashThreshold) {

      alertType = AlertType.crash;      if (_rawEventHistory.length > _historySize) {    }

      riskLevel = CollisionRiskLevel.medium;

      _safetyScore = math.max(0, _safetyScore - 20);        _rawEventHistory.removeAt(0);  }

      additionalData['crash_type'] = 'MODERATE';

    } else if (totalG >= _minorCrashThreshold) {      }  

      alertType = AlertType.crash;

      riskLevel = CollisionRiskLevel.low;        void stopMonitoring() {

      _safetyScore = math.max(0, _safetyScore - 10);

      additionalData['crash_type'] = 'MINOR';      // Calculate magnitude (total acceleration)    _isMonitoring = false;

    }

          final magnitude = math.sqrt(    _accelerometerSubscription?.cancel();

    // === BRAKING DETECTION (Longitudinal forces only) ===

    else if (longitudinalG >= _emergencyBrakingThreshold) {        event.x * event.x + event.y * event.y + event.z * event.z    

      alertType = AlertType.hardBraking;

      riskLevel = CollisionRiskLevel.high;      );    debugPrint('🛡️ Collision detection stopped');

      additionalData['braking_type'] = 'EMERGENCY';

      _safetyScore = math.max(0, _safetyScore - 15);          notifyListeners();

    } else if (longitudinalG >= _hardBrakingThreshold) {

      alertType = AlertType.hardBraking;      // Add to acceleration history for smoothing  }

      riskLevel = CollisionRiskLevel.medium;

      additionalData['braking_type'] = 'HARD';      _accelerationHistory.add(magnitude);  

      _safetyScore = math.max(0, _safetyScore - 10);

    } else if (longitudinalG >= _moderateBrakingThreshold) {      if (_accelerationHistory.length > _historySize) {  void clearAlerts() {

      alertType = AlertType.hardBraking;

      riskLevel = CollisionRiskLevel.low;        _accelerationHistory.removeAt(0);    _activeAlerts.clear();

      additionalData['braking_type'] = 'MODERATE';

      _safetyScore = math.max(0, _safetyScore - 5);      }    notifyListeners();

    }

        }

    // === SHARP TURN DETECTION (Lateral forces only) ===

    else if (lateralG >= _sharpTurnThreshold) {      // Apply advanced filtering: Moving average for noise reduction  

      alertType = AlertType.sharpTurn;

      riskLevel = CollisionRiskLevel.medium;      if (_accelerationHistory.length >= 5) { // Wait for more samples  /// Process accelerometer data with ADVANCED FILTERING for maximum accuracy

      additionalData['turn_type'] = 'SHARP';

      additionalData['direction'] = event.x > 0 ? 'RIGHT' : 'LEFT';        final smoothedMagnitude = _accelerationHistory  void _onAccelerometerEvent(AccelerometerEvent event) {

      _safetyScore = math.max(0, _safetyScore - 5);

    }            .reduce((a, b) => a + b) / _accelerationHistory.length;    try {



    // Create and emit alert only for significant events              // Add to raw event history for advanced analysis

    if (alertType != null && riskLevel != null) {

      final alert = CollisionAlert(        // Convert to G-forces and SUBTRACT GRAVITY with smoothing      _rawEventHistory.add(event);

        alertId: now.millisecondsSinceEpoch.toString(),

        sourceDeviceId: 'local_device_v2',        final gForce = (smoothedMagnitude - 9.8).abs() / 9.8;      if (_rawEventHistory.length > _historySize) {

        riskLevel: riskLevel,

        relativePosition: RelativePosition(                _rawEventHistory.removeAt(0);

          distance: 0.0, // Self-detection

          bearing: 0.0,        // Enhanced motion detection with LESS sensitivity to avoid false positives      }

          quadrant: DirectionQuadrant.front,

          timestamp: now,        if (gForce > 0.2) { // Increased threshold for less sensitivity      

        ),

        alertType: alertType,          _performAdvancedAnalysis(event, gForce, smoothedMagnitude);      // Calculate magnitude (total acceleration)

        timestamp: now,

        message: _getRealisticAlertMessage(alertType, totalG, longitudinalG, lateralG, additionalData),        }      final magnitude = math.sqrt(

        additionalData: additionalData,

      );      }        event.x * event.x + event.y * event.y + event.z * event.z



      _emitAlert(alert);    } catch (e) {      );

      

      // Reduced logging for less noise      debugPrint('❌ Error processing accelerometer event: $e');      

      debugPrint('🚨 ${alertType.name.toUpperCase()}: ${additionalData['crash_type'] ?? additionalData['braking_type'] ?? additionalData['turn_type']} - ${totalG.toStringAsFixed(1)}G');

    }    }      // Add to acceleration history for smoothing

  }

  }      _accelerationHistory.add(magnitude);

  /// Generate REALISTIC alert messages

  String _getRealisticAlertMessage(AlertType alertType, double totalG, double longitudinalG,       if (_accelerationHistory.length > _historySize) {

                                  double lateralG, Map<String, dynamic> data) {

    switch (alertType) {  /// Advanced physics-based analysis with REALISTIC detection        _accelerationHistory.removeAt(0);

      case AlertType.crash:

        final crashType = data['crash_type'] ?? 'UNKNOWN';  void _performAdvancedAnalysis(AccelerometerEvent event, double gForce, double smoothedMagnitude) {      }

        return '$crashType COLLISION DETECTED! ${totalG.toStringAsFixed(1)}G impact force';

            try {      

      case AlertType.hardBraking:

        final brakingType = data['braking_type'] ?? 'UNKNOWN';      // Separate directional forces with gravity compensation      // Apply advanced filtering: Moving average for noise reduction

        return '$brakingType BRAKING! ${longitudinalG.toStringAsFixed(1)}G deceleration';

              final longitudinalG = math.max(0, (event.y.abs() - 9.8).abs() / 9.8); // Forward/backward      if (_accelerationHistory.length >= 3) {

      case AlertType.sharpTurn:

        final direction = data['direction'] ?? 'UNKNOWN';      final lateralG = event.x.abs() / 9.8;       // Left/right        final smoothedMagnitude = _accelerationHistory

        return 'SHARP $direction TURN! ${lateralG.toStringAsFixed(1)}G lateral force';

              final verticalG = math.max(0, (event.z.abs() - 9.8).abs() / 9.8);    // Up/down            .reduce((a, b) => a + b) / _accelerationHistory.length;

      default:

        return 'Safety event: ${totalG.toStringAsFixed(1)}G force detected';              

    }

  }      // Only log significant movements to reduce noise        // Convert to G-forces and SUBTRACT GRAVITY with smoothing



  /// Emit alert with proper error handling      if (gForce > 0.4) {        final gForce = (smoothedMagnitude - 9.8).abs() / 9.8;

  void _emitAlert(CollisionAlert alert) {

    try {        debugPrint('🔍 Significant Motion: Total=${gForce.toStringAsFixed(2)}G, '        

      _activeAlerts.add(alert);

                         'Long=${longitudinalG.toStringAsFixed(2)}G, '        // Enhanced motion detection with LESS sensitivity to avoid false positives

      // Keep only recent alerts (last 10)

      if (_activeAlerts.length > 10) {                   'Lat=${lateralG.toStringAsFixed(2)}G');        if (gForce > 0.15) { // Increased threshold from 0.05 to 0.15 for less sensitivity

        _activeAlerts.removeAt(0);

      }      }          _performAdvancedAnalysis(event, gForce, smoothedMagnitude);

      

      _alertController.add(alert);              }

      notifyListeners();

    } catch (e) {      _processAccurateAccelerationEvent(event, gForce, longitudinalG, lateralG, verticalG);      }

      debugPrint('❌ Error emitting alert: $e');

    }    } catch (e) {    } catch (e) {

  }

      debugPrint('❌ Error in advanced analysis: $e');      debugPrint('❌ Error processing accelerometer event: $e');

  @override

  void dispose() {    }    }

    stopMonitoring();

    _alertController.close();  }  }

    super.dispose();

  }  

}
  /// REALISTIC collision & braking detection with proper thresholds  /// Advanced physics-based analysis for PRECISE collision & braking detection

  void _processAccurateAccelerationEvent(AccelerometerEvent event, double totalG,   void _performAdvancedAnalysis(AccelerometerEvent event, double gForce, double smoothedMagnitude) {

                                          double longitudinalG, double lateralG, double verticalG) {    // Separate longitudinal (forward/backward) and lateral (left/right) forces

    final now = DateTime.now();    final longitudinalG = event.y.abs() / 9.8; // Y-axis = forward/backward

        final lateralG = event.x.abs() / 9.8;       // X-axis = left/right

    // Skip duplicate events (within 100ms for stability)    final verticalG = event.z.abs() / 9.8;      // Z-axis = up/down

    if (_lastEventTime != null &&     

        now.difference(_lastEventTime!).inMilliseconds < 100) {    debugPrint('� Motion Analysis: Total=${gForce.toStringAsFixed(2)}G, '

      return;               'Long=${longitudinalG.toStringAsFixed(2)}G, '

    }               'Lat=${lateralG.toStringAsFixed(2)}G, '

    _lastEventTime = now;               'Vert=${verticalG.toStringAsFixed(2)}G');

    

    AlertType? alertType;    _processAccurateAccelerationEvent(event, gForce, longitudinalG, lateralG, verticalG);

    CollisionRiskLevel? riskLevel;  }

    Map<String, dynamic> additionalData = {

      'total_g_force': totalG,  /// ADVANCED ACCURACY: Multi-level collision & braking detection with physics

      'longitudinal_g': longitudinalG,  void _processAccurateAccelerationEvent(AccelerometerEvent event, double totalG, 

      'lateral_g': lateralG,                                          double longitudinalG, double lateralG, double verticalG) {

      'vertical_g': verticalG,    final now = DateTime.now();

      'raw_x': event.x,    

      'raw_y': event.y,    // Skip duplicate events (within 50ms)

      'raw_z': event.z,    if (_lastEventTime != null && 

    };        now.difference(_lastEventTime!).inMilliseconds < 50) {

      return;

    // === COLLISION DETECTION (Higher thresholds for realism) ===    }

    if (totalG >= _criticalCrashThreshold) {    _lastEventTime = now;

      alertType = AlertType.crash;

      riskLevel = CollisionRiskLevel.critical;    AlertType? alertType;

      _safetyScore = math.max(0, _safetyScore - 50);    CollisionRiskLevel? riskLevel;

      additionalData['crash_type'] = 'CRITICAL';    Map<String, dynamic> additionalData = {

    } else if (totalG >= _severeCrashThreshold) {      'total_g_force': totalG,

      alertType = AlertType.crash;      'longitudinal_g': longitudinalG,

      riskLevel = CollisionRiskLevel.high;      'lateral_g': lateralG,

      _safetyScore = math.max(0, _safetyScore - 30);      'vertical_g': verticalG,

      additionalData['crash_type'] = 'SEVERE';      'raw_x': event.x,

    } else if (totalG >= _moderateCrashThreshold) {      'raw_y': event.y,

      alertType = AlertType.crash;      'raw_z': event.z,

      riskLevel = CollisionRiskLevel.medium;    };

      _safetyScore = math.max(0, _safetyScore - 20);

      additionalData['crash_type'] = 'MODERATE';    // === EMERGENCY COLLISION DETECTION (4G+ total force) ===

    } else if (totalG >= _minorCrashThreshold) {    if (totalG >= _criticalCrashThreshold) {

      alertType = AlertType.crash;      alertType = AlertType.crash;

      riskLevel = CollisionRiskLevel.low;      riskLevel = CollisionRiskLevel.critical;

      _safetyScore = math.max(0, _safetyScore - 10);      _safetyScore = math.max(0, _safetyScore - 50);

      additionalData['crash_type'] = 'MINOR';      additionalData['crash_type'] = 'CRITICAL';

    }    } else if (totalG >= _severeCrashThreshold) {

          alertType = AlertType.crash;

    // === BRAKING DETECTION (Longitudinal forces only) ===      riskLevel = CollisionRiskLevel.high;

    else if (longitudinalG >= _emergencyBrakingThreshold) {      _safetyScore = math.max(0, _safetyScore - 30);

      alertType = AlertType.hardBraking;      additionalData['crash_type'] = 'SEVERE';

      riskLevel = CollisionRiskLevel.high;    } else if (totalG >= _moderateCrashThreshold) {

      additionalData['braking_type'] = 'EMERGENCY';      alertType = AlertType.crash;

      _safetyScore = math.max(0, _safetyScore - 15);      riskLevel = CollisionRiskLevel.medium;

    } else if (longitudinalG >= _hardBrakingThreshold) {      _safetyScore = math.max(0, _safetyScore - 20);

      alertType = AlertType.hardBraking;      additionalData['crash_type'] = 'MODERATE';

      riskLevel = CollisionRiskLevel.medium;    } else if (totalG >= _minorCrashThreshold) {

      additionalData['braking_type'] = 'HARD';      alertType = AlertType.crash;

      _safetyScore = math.max(0, _safetyScore - 10);      riskLevel = CollisionRiskLevel.low;

    } else if (longitudinalG >= _moderateBrakingThreshold) {      _safetyScore = math.max(0, _safetyScore - 10);

      alertType = AlertType.hardBraking;      additionalData['crash_type'] = 'MINOR';

      riskLevel = CollisionRiskLevel.low;    }

      additionalData['braking_type'] = 'MODERATE';    

      _safetyScore = math.max(0, _safetyScore - 5);    // === ENHANCED BRAKING DETECTION (Longitudinal forces) ===

    }    else if (longitudinalG >= _emergencyBrakingThreshold) {

      alertType = AlertType.hardBraking;

    // === SHARP TURN DETECTION (Lateral forces only) ===      riskLevel = CollisionRiskLevel.high;

    else if (lateralG >= _sharpTurnThreshold) {      additionalData['braking_type'] = 'EMERGENCY';

      alertType = AlertType.sharpTurn;      _safetyScore = math.max(0, _safetyScore - 15);

      riskLevel = CollisionRiskLevel.medium;    } else if (longitudinalG >= _hardBrakingThreshold) {

      additionalData['turn_type'] = 'SHARP';      alertType = AlertType.hardBraking;

      additionalData['direction'] = event.x > 0 ? 'RIGHT' : 'LEFT';      riskLevel = CollisionRiskLevel.medium;

      _safetyScore = math.max(0, _safetyScore - 5);      additionalData['braking_type'] = 'HARD';

    }      _safetyScore = math.max(0, _safetyScore - 10);

    } else if (longitudinalG >= _moderateBrakingThreshold) {

    // Create and emit alert only for significant events      alertType = AlertType.hardBraking;

    if (alertType != null && riskLevel != null) {      riskLevel = CollisionRiskLevel.low;

      final alert = CollisionAlert(      additionalData['braking_type'] = 'MODERATE';

        alertId: now.millisecondsSinceEpoch.toString(),      _safetyScore = math.max(0, _safetyScore - 5);

        sourceDeviceId: 'local_device_v2',    }

        riskLevel: riskLevel,

        relativePosition: RelativePosition(    // === LATERAL FORCE DETECTION (Sharp turns/swerving) ===

          distance: 0.0, // Self-detection    else if (lateralG >= _sharpTurnThreshold) {

          bearing: 0.0,      alertType = AlertType.sharpTurn;

          quadrant: DirectionQuadrant.front,      riskLevel = CollisionRiskLevel.medium;

          timestamp: now,      additionalData['turn_type'] = 'SHARP';

        ),      additionalData['direction'] = event.x > 0 ? 'RIGHT' : 'LEFT';

        alertType: alertType,      _safetyScore = math.max(0, _safetyScore - 5);

        timestamp: now,    }

        message: _getRealisticAlertMessage(alertType, totalG, longitudinalG, lateralG, additionalData),

        additionalData: additionalData,    // Create and emit alert with enhanced accuracy data

      );    if (alertType != null && riskLevel != null) {

      final alert = CollisionAlert(

      _emitAlert(alert);        alertId: now.millisecondsSinceEpoch.toString(),

              sourceDeviceId: 'local_device_enhanced',

      // Reduced logging for less noise        riskLevel: riskLevel,

      debugPrint('🚨 ${alertType.name.toUpperCase()}: ${additionalData['crash_type'] ?? additionalData['braking_type'] ?? additionalData['turn_type']} - ${totalG.toStringAsFixed(1)}G');        relativePosition: RelativePosition(

    }          distance: 0.0, // Self-detection

  }          bearing: 0.0,

          quadrant: DirectionQuadrant.front,

  /// Generate REALISTIC alert messages          timestamp: now,

  String _getRealisticAlertMessage(AlertType alertType, double totalG, double longitudinalG,         ),

                                  double lateralG, Map<String, dynamic> data) {        alertType: alertType,

    switch (alertType) {        timestamp: now,

      case AlertType.crash:        message: _getEnhancedAlertMessage(alertType, totalG, longitudinalG, lateralG, additionalData),

        final crashType = data['crash_type'] ?? 'UNKNOWN';        additionalData: additionalData,

        return '$crashType COLLISION DETECTED! ${totalG.toStringAsFixed(1)}G impact force';      );

        

      case AlertType.hardBraking:      _emitAlert(alert);

        final brakingType = data['braking_type'] ?? 'UNKNOWN';      

        return '$brakingType BRAKING! ${longitudinalG.toStringAsFixed(1)}G deceleration';      // Enhanced logging for accuracy verification

              debugPrint('🎯 ACCURATE DETECTION: ${alertType.name.toUpperCase()} - '

      case AlertType.sharpTurn:                'Total: ${totalG.toStringAsFixed(2)}G, '

        final direction = data['direction'] ?? 'UNKNOWN';                'Long: ${longitudinalG.toStringAsFixed(2)}G, '

        return 'SHARP $direction TURN! ${lateralG.toStringAsFixed(1)}G lateral force';                'Lat: ${lateralG.toStringAsFixed(2)}G');

            }

      default:  }

        return 'Safety event: ${totalG.toStringAsFixed(1)}G force detected';  

    }  /// Generate ENHANCED alert message with physics details

  }  String _getEnhancedAlertMessage(AlertType alertType, double totalG, double longitudinalG, 

                                  double lateralG, Map<String, dynamic> data) {

  /// Emit alert with proper error handling    switch (alertType) {

  void _emitAlert(CollisionAlert alert) {      case AlertType.crash:

    try {        final crashType = data['crash_type'] ?? 'UNKNOWN';

      _activeAlerts.add(alert);        return '$crashType COLLISION! Total: ${totalG.toStringAsFixed(1)}G impact detected!';

              

      // Keep only recent alerts (last 10)      case AlertType.hardBraking:

      if (_activeAlerts.length > 10) {        final brakingType = data['braking_type'] ?? 'UNKNOWN';

        _activeAlerts.removeAt(0);        return '$brakingType BRAKING! Longitudinal: ${longitudinalG.toStringAsFixed(1)}G deceleration';

      }        

            case AlertType.sharpTurn:

      _alertController.add(alert);        final direction = data['direction'] ?? 'UNKNOWN';

      notifyListeners();        return 'SHARP $direction TURN! Lateral: ${lateralG.toStringAsFixed(1)}G force';

    } catch (e) {        

      debugPrint('❌ Error emitting alert: $e');      default:

    }        return 'Safety alert: Total ${totalG.toStringAsFixed(1)}G force detected';

  }    }

  }

  @override

  void dispose() {  /// Emit collision alert with duplicate prevention

    stopMonitoring();  void _emitAlert(CollisionAlert alert) {

    _alertController.close();    final now = DateTime.now();

    super.dispose();    

  }    // Prevent duplicate alerts within 2 seconds

}    if (_lastAlertTime != null && 
        now.difference(_lastAlertTime!).inSeconds < 2) {
      return;
    }
    
    _lastAlertTime = now;
    _activeAlerts.add(alert);
    _alertController.add(alert);
    
    // Remove old alerts (keep only last 10)
    if (_activeAlerts.length > 10) {
      _activeAlerts.removeAt(0);
    }
    
    debugPrint('🚨 ${alert.alertType.name.toUpperCase()} Alert: ${alert.riskLevel.name} '
               '(${alert.additionalData?['g_force']?.toStringAsFixed(1) ?? '0.0'}G)');
    debugPrint('📨 ${alert.message}');
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    _alertController.close();
    super.dispose();
  }
}
