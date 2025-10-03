import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

/// Simulated location service for testing on desktop/emulator
class SimulatedLocationService {
  Timer? _timer;
  StreamController<Position>? _positionController;
  
  // Starting position (Delhi, India)
  double _latitude = 28.6139;
  double _longitude = 77.2090;
  double _speed = 10.0; // m/s (36 km/h)
  double _heading = 45.0; // degrees
  
  // Simulation parameters
  final double _speedVariation = 5.0; // ±5 m/s
  final double _headingVariation = 30.0; // ±30 degrees
  final math.Random _random = math.Random();

  /// Initialize the simulated service
  Future<void> initialize() async {
    _positionController = StreamController<Position>.broadcast();
    print('🚗 Simulated Location Service initialized');
    print('📍 Starting at: $_latitude, $_longitude');
  }

  /// Start generating simulated location updates
  void startLocationUpdates() {
    _timer?.cancel();
    
    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updatePosition();
    });
    
    print('🎬 Started simulated location updates');
  }

  /// Update the simulated position
  void _updatePosition() {
    // Add some randomness to speed and heading
    final speedChange = (_random.nextDouble() - 0.5) * 2 * _speedVariation;
    _speed = (_speed + speedChange).clamp(0.0, 30.0); // 0-30 m/s (0-108 km/h)
    
    final headingChange = (_random.nextDouble() - 0.5) * 2 * _headingVariation;
    _heading = (_heading + headingChange) % 360.0;
    
    // Calculate new position based on speed and heading
    // Convert speed from m/s to degrees per second (approximate)
    final metersPerDegree = 111320.0; // at equator
    final latChange = (_speed * math.cos(_heading * math.pi / 180)) / metersPerDegree;
    final lngChange = (_speed * math.sin(_heading * math.pi / 180)) / 
                      (metersPerDegree * math.cos(_latitude * math.pi / 180));
    
    _latitude += latChange;
    _longitude += lngChange;
    
    // Create position object
    final position = Position(
      latitude: _latitude,
      longitude: _longitude,
      timestamp: DateTime.now(),
      accuracy: 5.0 + _random.nextDouble() * 10.0, // 5-15m accuracy
      altitude: 50.0 + _random.nextDouble() * 20.0, // 50-70m altitude
      heading: _heading,
      speed: _speed,
      speedAccuracy: 1.0,
      altitudeAccuracy: 5.0,
      headingAccuracy: 5.0,
    );
    
    _positionController?.add(position);
  }

  /// Get the location stream
  Stream<Position>? getLocationStream() {
    return _positionController?.stream;
  }

  /// Get current position immediately
  Future<Position> getCurrentPosition() async {
    return Position(
      latitude: _latitude,
      longitude: _longitude,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 50.0,
      heading: _heading,
      speed: _speed,
      speedAccuracy: 1.0,
      altitudeAccuracy: 5.0,
      headingAccuracy: 5.0,
    );
  }

  /// Set custom starting position
  void setStartPosition(double latitude, double longitude) {
    _latitude = latitude;
    _longitude = longitude;
    print('📍 Position set to: $_latitude, $_longitude');
  }

  /// Set movement parameters
  void setMovementParams({double? speed, double? heading}) {
    if (speed != null) _speed = speed;
    if (heading != null) _heading = heading;
    print('🚗 Speed: $_speed m/s, Heading: $_heading°');
  }

  /// Stop updates
  void stopLocationUpdates() {
    _timer?.cancel();
    print('⏹️ Stopped simulated location updates');
  }

  /// Dispose
  void dispose() {
    _timer?.cancel();
    _positionController?.close();
  }
}
