import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocationService {
  // Streams for GPS data
  StreamController<Position>? _locationController;
  StreamSubscription<Position>? _locationSubscription;

  // Streams for IMU data
  StreamController<AccelerometerEvent>? _accelerometerController;
  StreamController<GyroscopeEvent>? _gyroscopeController;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // Recording related variables
  bool _isRecording = false;
  Position? _lastPosition;
  AccelerometerEvent? _lastAccelEvent;
  GyroscopeEvent? _lastGyroEvent;
  File? _logFile;
  IOSink? _logSink;

  // Singleton instance
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  // Initialize the service
  Future<void> initialize() async {
    // Request location permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    // Initialize controllers
    _locationController = StreamController<Position>.broadcast();
    _accelerometerController = StreamController<AccelerometerEvent>.broadcast();
    _gyroscopeController = StreamController<GyroscopeEvent>.broadcast();
  }

  // Start location updates
  void startLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5, // Update every 5 meters
          ),
        ).listen(
          (Position position) {
            _lastPosition = position;
            _locationController?.add(position);
            _recordDataPoint();
          },
          onError: (error) {
            print('Error getting location: $error');
          },
        );
  }

  // Start IMU updates
  void startIMUUpdates() {
    // Start accelerometer updates
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        _lastAccelEvent = event;
        _accelerometerController?.add(event);
        _recordDataPoint();
      },
      onError: (error) {
        print('Error getting accelerometer data: $error');
      },
    );

    // Start gyroscope updates
    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = gyroscopeEvents.listen(
      (GyroscopeEvent event) {
        _lastGyroEvent = event;
        _gyroscopeController?.add(event);
        _recordDataPoint();
      },
      onError: (error) {
        print('Error getting gyroscope data: $error');
      },
    );
  }

  // Get GPS location stream
  Stream<Position>? getLocationStream() {
    return _locationController?.stream;
  }

  // Get accelerometer stream
  Stream<AccelerometerEvent>? getAccelerometerStream() {
    return _accelerometerController?.stream;
  }

  // Get gyroscope stream
  Stream<GyroscopeEvent>? getGyroscopeStream() {
    return _gyroscopeController?.stream;
  }

  // Recording functions
  Future<void> startRecording() async {
    if (_isRecording) return;

    final directory = await getApplicationDocumentsDirectory();
    final String timestamp = DateTime.now().toIso8601String().replaceAll(
      ':',
      '-',
    );
    final String filepath = '${directory.path}/sensor_data_$timestamp.csv';

    _logFile = File(filepath);
    _logSink = _logFile?.openWrite();

    // Write CSV header
    _logSink?.writeln(
      'timestamp,latitude,longitude,speed,heading,' +
          'accelerometer_x,accelerometer_y,accelerometer_z,' +
          'gyroscope_x,gyroscope_y,gyroscope_z',
    );

    _isRecording = true;
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    _isRecording = false;
    await _logSink?.flush();
    await _logSink?.close();
    _logSink = null;
    _logFile = null;
  }

  String? getCurrentLogPath() {
    return _logFile?.path;
  }

  void _recordDataPoint() {
    if (!_isRecording || _logSink == null) return;

    final now = DateTime.now();
    final values = [
      now.toIso8601String(),
      _lastPosition?.latitude ?? '',
      _lastPosition?.longitude ?? '',
      _lastPosition?.speed ?? '',
      _lastPosition?.heading ?? '',
      _lastAccelEvent?.x ?? '',
      _lastAccelEvent?.y ?? '',
      _lastAccelEvent?.z ?? '',
      _lastGyroEvent?.x ?? '',
      _lastGyroEvent?.y ?? '',
      _lastGyroEvent?.z ?? '',
    ];

    _logSink?.writeln(values.join(','));
  }

  bool get isRecording => _isRecording;

  // Dispose all streams and subscriptions
  void dispose() {
    stopRecording();
    _locationSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();

    _locationController?.close();
    _accelerometerController?.close();
    _gyroscopeController?.close();
  }
}
