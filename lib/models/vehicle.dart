import 'package:latlong2/latlong.dart';

/// Represents a vehicle in the autonomous system
class Vehicle {
  final String id;
  final String deviceId;
  LatLng position;
  double speed; // m/sfl
  double heading; // degrees
  double accuracy; // meters
  DateTime lastUpdate;
  
  // Kalman filter state
  List<double>? kalmanState; // [X, Y, X_velocity, Y_velocity]
  
  // BLE mesh properties
  int? rssi; // Signal strength
  String? clusterId;
  bool isCoordinator;
  
  // Relative motion data
  double? relativeSpeed; // m/s (from Doppler)
  double? relativeDistance; // meters
  double? collisionRisk; // 0.0 to 1.0
  
  // Battery optimization
  int batteryLevel; // percentage
  bool isBackgroundMode;

  Vehicle({
    required this.id,
    required this.deviceId,
    required this.position,
    this.speed = 0.0,
    this.heading = 0.0,
    this.accuracy = 0.0,
    required this.lastUpdate,
    this.kalmanState,
    this.rssi,
    this.clusterId,
    this.isCoordinator = false,
    this.relativeSpeed,
    this.relativeDistance,
    this.collisionRisk,
    this.batteryLevel = 100,
    this.isBackgroundMode = false,
  });

  /// Create from JSON
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      position: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
      kalmanState: (json['kalmanState'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      rssi: json['rssi'] as int?,
      clusterId: json['clusterId'] as String?,
      isCoordinator: json['isCoordinator'] as bool? ?? false,
      relativeSpeed: (json['relativeSpeed'] as num?)?.toDouble(),
      relativeDistance: (json['relativeDistance'] as num?)?.toDouble(),
      collisionRisk: (json['collisionRisk'] as num?)?.toDouble(),
      batteryLevel: json['batteryLevel'] as int? ?? 100,
      isBackgroundMode: json['isBackgroundMode'] as bool? ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'speed': speed,
      'heading': heading,
      'accuracy': accuracy,
      'lastUpdate': lastUpdate.toIso8601String(),
      'kalmanState': kalmanState,
      'rssi': rssi,
      'clusterId': clusterId,
      'isCoordinator': isCoordinator,
      'relativeSpeed': relativeSpeed,
      'relativeDistance': relativeDistance,
      'collisionRisk': collisionRisk,
      'batteryLevel': batteryLevel,
      'isBackgroundMode': isBackgroundMode,
    };
  }

  /// Create a copy with updated fields
  Vehicle copyWith({
    String? id,
    String? deviceId,
    LatLng? position,
    double? speed,
    double? heading,
    double? accuracy,
    DateTime? lastUpdate,
    List<double>? kalmanState,
    int? rssi,
    String? clusterId,
    bool? isCoordinator,
    double? relativeSpeed,
    double? relativeDistance,
    double? collisionRisk,
    int? batteryLevel,
    bool? isBackgroundMode,
  }) {
    return Vehicle(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      position: position ?? this.position,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      kalmanState: kalmanState ?? this.kalmanState,
      rssi: rssi ?? this.rssi,
      clusterId: clusterId ?? this.clusterId,
      isCoordinator: isCoordinator ?? this.isCoordinator,
      relativeSpeed: relativeSpeed ?? this.relativeSpeed,
      relativeDistance: relativeDistance ?? this.relativeDistance,
      collisionRisk: collisionRisk ?? this.collisionRisk,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isBackgroundMode: isBackgroundMode ?? this.isBackgroundMode,
    );
  }

  /// Check if vehicle data is stale (>5 seconds old)
  bool get isStale {
    return DateTime.now().difference(lastUpdate).inSeconds > 5;
  }

  /// Calculate time to collision (TTC) with another vehicle
  double? calculateTTC(Vehicle other) {
    if (relativeDistance == null || relativeSpeed == null) return null;
    if (relativeSpeed! <= 0) return null; // Moving apart
    
    return relativeDistance! / relativeSpeed!;
  }
}
