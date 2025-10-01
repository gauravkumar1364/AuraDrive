import 'dart:convert';
import 'dart:math' as math;
import 'position_data.dart';

/// Model representing comprehensive vehicle data for autonomous navigation
class VehicleData {
  final String deviceId;
  final PositionData position;
  final VelocityData velocity;
  final AccelerationData acceleration;
  final double heading; // degrees from north
  final DeviceInfo deviceInfo;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;

  const VehicleData({
    required this.deviceId,
    required this.position,
    required this.velocity,
    required this.acceleration,
    required this.heading,
    required this.deviceInfo,
    required this.timestamp,
    this.additionalData,
  });

  /// Create VehicleData from JSON
  factory VehicleData.fromJson(Map<String, dynamic> json) {
    return VehicleData(
      deviceId: json['deviceId'] as String,
      position: PositionData.fromJson(json['position'] as Map<String, dynamic>),
      velocity: VelocityData.fromJson(json['velocity'] as Map<String, dynamic>),
      acceleration: AccelerationData.fromJson(json['acceleration'] as Map<String, dynamic>),
      heading: (json['heading'] as num).toDouble(),
      deviceInfo: DeviceInfo.fromJson(json['deviceInfo'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'position': position.toJson(),
      'velocity': velocity.toJson(),
      'acceleration': acceleration.toJson(),
      'heading': heading,
      'deviceInfo': deviceInfo.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
    };
  }

  /// Convert to JSON string for transmission
  String toJsonString() => json.encode(toJson());

  /// Create from JSON string
  factory VehicleData.fromJsonString(String jsonString) {
    return VehicleData.fromJson(json.decode(jsonString) as Map<String, dynamic>);
  }

  /// Calculate time to collision with another vehicle
  double? timeToCollision(VehicleData other) {
    final double distance = position.distanceTo(other.position);
    final double relativeSpeed = _calculateRelativeSpeed(other);
    
    if (relativeSpeed <= 0) return null; // Not approaching
    
    return distance / relativeSpeed;
  }

  /// Calculate relative speed between vehicles
  double _calculateRelativeSpeed(VehicleData other) {
    final double bearing = position.bearingTo(other.position);
    final double reverseBearing = (bearing + 180) % 360;
    
    // Project velocities onto the line connecting the vehicles
    final double thisProjected = velocity.speed * _cosDegrees(velocity.bearing - bearing);
    final double otherProjected = other.velocity.speed * _cosDegrees(other.velocity.bearing - reverseBearing);
    
    return thisProjected + otherProjected;
  }

  /// Check if vehicle is stationary
  bool get isStationary => velocity.speed < 0.5; // Less than 0.5 m/s

  /// Check if data is recent
  bool isRecent({int seconds = 5}) {
    return DateTime.now().difference(timestamp).inSeconds <= seconds;
  }

  /// Copy with new values
  VehicleData copyWith({
    String? deviceId,
    PositionData? position,
    VelocityData? velocity,
    AccelerationData? acceleration,
    double? heading,
    DeviceInfo? deviceInfo,
    DateTime? timestamp,
    Map<String, dynamic>? additionalData,
  }) {
    return VehicleData(
      deviceId: deviceId ?? this.deviceId,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      acceleration: acceleration ?? this.acceleration,
      heading: heading ?? this.heading,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      timestamp: timestamp ?? this.timestamp,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'VehicleData(deviceId: $deviceId, speed: ${velocity.speed}m/s, '
           'heading: $heading°, position: (${position.latitude}, ${position.longitude}))';
  }

  double _cosDegrees(double degrees) => math.cos(degrees * math.pi / 180);
}

/// Model for velocity data
class VelocityData {
  final double speed; // m/s
  final double bearing; // degrees from north
  final double? verticalSpeed; // m/s (positive = upward)
  final double accuracy; // m/s

  const VelocityData({
    required this.speed,
    required this.bearing,
    this.verticalSpeed,
    required this.accuracy,
  });

  factory VelocityData.fromJson(Map<String, dynamic> json) {
    return VelocityData(
      speed: (json['speed'] as num).toDouble(),
      bearing: (json['bearing'] as num).toDouble(),
      verticalSpeed: json['verticalSpeed'] != null ? (json['verticalSpeed'] as num).toDouble() : null,
      accuracy: (json['accuracy'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speed': speed,
      'bearing': bearing,
      'verticalSpeed': verticalSpeed,
      'accuracy': accuracy,
    };
  }

  /// Get velocity components (vx, vy) in m/s
  ({double vx, double vy}) get components {
    final double bearingRad = bearing * math.pi / 180;
    return (
      vx: speed * math.sin(bearingRad),
      vy: speed * math.cos(bearingRad),
    );
  }
}

/// Model for acceleration data from IMU
class AccelerationData {
  final double x; // m/s² (lateral)
  final double y; // m/s² (longitudinal)
  final double z; // m/s² (vertical)
  final double magnitude; // total acceleration magnitude
  final DateTime timestamp;

  const AccelerationData({
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
    required this.timestamp,
  });

  factory AccelerationData.fromJson(Map<String, dynamic> json) {
    return AccelerationData(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      magnitude: (json['magnitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'magnitude': magnitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Check if indicates potential crash (>4G threshold)
  bool get indicatesCrash => magnitude > 39.2; // 4G = 4 * 9.8 m/s²

  /// Check if indicates hard braking
  bool get indicatesHardBraking => y < -6.0; // Strong deceleration

  /// Check if indicates sharp turn
  bool get indicatesSharpTurn => x.abs() > 4.0; // High lateral acceleration
}

/// Model for device information
class DeviceInfo {
  final String deviceModel;
  final String osVersion;
  final String appVersion;
  final String bluetoothCapability;
  final String gnssCapability;
  final Map<String, dynamic>? capabilities;

  const DeviceInfo({
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
    required this.bluetoothCapability,
    required this.gnssCapability,
    this.capabilities,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceModel: json['deviceModel'] as String,
      osVersion: json['osVersion'] as String,
      appVersion: json['appVersion'] as String,
      bluetoothCapability: json['bluetoothCapability'] as String,
      gnssCapability: json['gnssCapability'] as String,
      capabilities: json['capabilities'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'bluetoothCapability': bluetoothCapability,
      'gnssCapability': gnssCapability,
      'capabilities': capabilities,
    };
  }

  /// Check if device supports raw GNSS measurements
  bool get supportsRawGnss => capabilities?['rawGnss'] == true;

  /// Check if device supports NavIC
  bool get supportsNavIC => capabilities?['navic'] == true;

  /// Check if device supports BLE mesh
  bool get supportsBLEMesh => bluetoothCapability.contains('BLE');
}