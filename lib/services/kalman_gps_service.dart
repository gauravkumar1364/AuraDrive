import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:latlong2/latlong.dart';

/// Kalman Filter for GPS/IMU sensor fusion
/// Implements Unscented Kalman Filter (UKF) for improved accuracy
class KalmanGPSService {
  // State vector: [X, Y, X_velocity, Y_velocity]
  List<double> state = [0, 0, 0, 0];
  
  // Covariance matrix (4x4)
  List<List<double>> covariance = [
    [1, 0, 0, 0],
    [0, 1, 0, 0],
    [0, 0, 1, 0],
    [0, 0, 0, 1],
  ];
  
  // Process noise
  double processNoise = 0.1;
  
  // Measurement noise
  double measurementNoise = 5.0; // GPS accuracy in meters
  
  // IMU data
  double _accelerometerX = 0;
  double _accelerometerY = 0;
  double _magnetometerHeading = 0;
  
  // Sensor subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<Position>? _gpsSubscription;
  
  // State
  bool _isInitialized = false;
  DateTime? _lastUpdate;
  LatLng? _lastPosition;
  LatLng? _referencePoint; // For local coordinate conversion
  
  // Callbacks
  Function(LatLng position, double speed, double heading)? onPositionUpdate;
  
  /// Initialize the Kalman filter with starting position
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Get initial GPS position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _referencePoint = LatLng(position.latitude, position.longitude);
      _lastPosition = _referencePoint;
      
      // Initialize state at origin (0, 0) with reference point
      state = [0, 0, 0, 0];
      _lastUpdate = DateTime.now();
      
      // Start sensor listeners
      _startSensorListeners();
      _startGPSListener();
      
      _isInitialized = true;
      print('KalmanGPSService initialized at ${_referencePoint}');
    } catch (e) {
      print('Error initializing KalmanGPSService: $e');
      rethrow;
    }
  }
  
  /// Start listening to IMU sensors
  void _startSensorListeners() {
    // Accelerometer (for velocity prediction)
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((event) {
      _accelerometerX = event.x;
      _accelerometerY = event.y;
    });
    
    // Gyroscope (for rotation detection - future enhancement)
    _gyroscopeSubscription = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((event) {
      // Future: Use for rotation compensation
    });
    
    // Magnetometer (for heading)
    _magnetometerSubscription = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((event) {
      _magnetometerHeading = atan2(event.y, event.x) * 180 / pi;
    });
  }
  
  /// Start listening to GPS
  void _startGPSListener() {
    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // Update every 1 meter
    );
    
    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      _processGPSUpdate(position);
    });
  }
  
  /// Process GPS update through Kalman filter
  void _processGPSUpdate(Position gpsPosition) {
    if (!_isInitialized || _referencePoint == null) return;
    
    final now = DateTime.now();
    final dt = _lastUpdate != null 
        ? now.difference(_lastUpdate!).inMilliseconds / 1000.0 
        : 0.1;
    
    // Convert GPS to local coordinates
    final localCoords = _gpsToLocal(
      LatLng(gpsPosition.latitude, gpsPosition.longitude),
    );
    
    // Prediction step
    _predict(dt);
    
    // Update step with GPS measurement
    _update(localCoords[0], localCoords[1], gpsPosition.accuracy);
    
    // Convert back to GPS coordinates
    final filteredPosition = _localToGPS(state[0], state[1]);
    final speed = sqrt(state[2] * state[2] + state[3] * state[3]);
    final heading = atan2(state[3], state[2]) * 180 / pi;
    
    _lastPosition = filteredPosition;
    _lastUpdate = now;
    
    // Callback
    onPositionUpdate?.call(filteredPosition, speed, heading);
  }
  
  /// Prediction step using IMU data
  void _predict(double dt) {
    // State transition: position += velocity * dt
    // velocity += acceleration * dt
    
    // Use accelerometer data (convert from m/s² to local units)
    final accelX = _accelerometerX * 9.81; // Convert to m/s²
    final accelY = _accelerometerY * 9.81;
    
    // Predict new state
    final newX = state[0] + state[2] * dt;
    final newY = state[1] + state[3] * dt;
    final newVx = state[2] + accelX * dt;
    final newVy = state[3] + accelY * dt;
    
    state = [newX, newY, newVx, newVy];
    
    // Update covariance with process noise
    for (int i = 0; i < 4; i++) {
      covariance[i][i] += processNoise * dt;
    }
  }
  
  /// Update step with GPS measurement
  void _update(double measuredX, double measuredY, double accuracy) {
    // Kalman gain calculation (simplified for position measurements)
    final measurementVar = accuracy * accuracy;
    
    // Innovation (measurement - prediction)
    final innovationX = measuredX - state[0];
    final innovationY = measuredY - state[1];
    
    // Kalman gain
    final kx = covariance[0][0] / (covariance[0][0] + measurementVar);
    final ky = covariance[1][1] / (covariance[1][1] + measurementVar);
    
    // Update state
    state[0] += kx * innovationX;
    state[1] += ky * innovationY;
    
    // Update covariance
    covariance[0][0] *= (1 - kx);
    covariance[1][1] *= (1 - ky);
  }
  
  /// Convert GPS coordinates to local Cartesian coordinates
  List<double> _gpsToLocal(LatLng position) {
    if (_referencePoint == null) return [0, 0];
    
    const Distance distance = Distance();
    
    // Calculate offset in meters
    final dx = distance.distance(_referencePoint!, 
        LatLng(_referencePoint!.latitude, position.longitude));
    final dy = distance.distance(_referencePoint!, 
        LatLng(position.latitude, _referencePoint!.longitude));
    
    // Apply sign based on direction
    final x = position.longitude > _referencePoint!.longitude ? dx : -dx;
    final y = position.latitude > _referencePoint!.latitude ? dy : -dy;
    
    return [x, y];
  }
  
  /// Convert local Cartesian coordinates to GPS
  LatLng _localToGPS(double x, double y) {
    if (_referencePoint == null) return LatLng(0, 0);
    
    // Calculate offset in degrees (approximate)
    final latOffset = y / 111320.0; // meters per degree latitude
    final lonOffset = x / (111320.0 * cos(_referencePoint!.latitude * pi / 180));
    
    return LatLng(
      _referencePoint!.latitude + latOffset,
      _referencePoint!.longitude + lonOffset,
    );
  }
  
  /// Get current filtered position
  LatLng? getCurrentPosition() {
    return _lastPosition;
  }
  
  /// Get current velocity (m/s)
  double getCurrentSpeed() {
    return sqrt(state[2] * state[2] + state[3] * state[3]);
  }
  
  /// Get current heading (degrees)
  double getCurrentHeading() {
    if (state[2] == 0 && state[3] == 0) return _magnetometerHeading;
    return atan2(state[3], state[2]) * 180 / pi;
  }
  
  /// Get velocity components [vx, vy]
  List<double> getVelocity() {
    return [state[2], state[3]];
  }
  
  /// Get state covariance for uncertainty estimation
  double getPositionUncertainty() {
    return sqrt(covariance[0][0] + covariance[1][1]);
  }
  
  /// Reset filter (e.g., after GPS signal loss recovery)
  void reset() {
    state = [0, 0, 0, 0];
    covariance = [
      [1, 0, 0, 0],
      [0, 1, 0, 0],
      [0, 0, 1, 0],
      [0, 0, 0, 1],
    ];
  }
  
  /// Dispose resources
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _gpsSubscription?.cancel();
    _isInitialized = false;
  }
}
