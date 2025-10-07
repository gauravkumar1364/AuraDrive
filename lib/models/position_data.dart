import 'dart:convert';
import 'dart:math' as math;

/// Model representing position data for cooperative positioning
class PositionData {
  final String deviceId;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double accuracy;
  final DateTime timestamp;
  final double? speed;
  final double? heading;
  final String positioningMode; // GPS, NavIC, Cooperative, Fused
  final Map<String, dynamic>? metadata;

  const PositionData({
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.accuracy,
    required this.timestamp,
    this.speed,
    this.heading,
    this.positioningMode = 'GPS',
    this.metadata,
  });

  /// Create PositionData from JSON
  factory PositionData.fromJson(Map<String, dynamic> json) {
    return PositionData(
      deviceId: json['deviceId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: json['altitude'] != null
          ? (json['altitude'] as num).toDouble()
          : null,
      accuracy: (json['accuracy'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      heading: json['heading'] != null
          ? (json['heading'] as num).toDouble()
          : null,
      positioningMode: json['positioningMode'] as String? ?? 'GPS',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert PositionData to JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'heading': heading,
      'positioningMode': positioningMode,
      'metadata': metadata,
    };
  }

  /// Convert to bytes for BLE transmission
  List<int> toBytes() {
    final json = jsonEncode(toJson());
    return utf8.encode(json);
  }

  /// Convert to JSON string for BLE transmission
  String toJsonString() => json.encode(toJson());

  /// Create PositionData from JSON string
  factory PositionData.fromJsonString(String jsonString) {
    return PositionData.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  /// Calculate distance to another position in meters
  double distanceTo(PositionData other) {
    return _calculateDistance(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }

  /// Calculate bearing to another position in degrees
  double bearingTo(PositionData other) {
    return _calculateBearing(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }

  /// Check if position is recent (within specified seconds)
  bool isRecent({int seconds = 10}) {
    return DateTime.now().difference(timestamp).inSeconds <= seconds;
  }

  /// Copy with new values
  PositionData copyWith({
    String? deviceId,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    DateTime? timestamp,
    double? speed,
    double? heading,
    String? positioningMode,
    Map<String, dynamic>? metadata,
  }) {
    return PositionData(
      deviceId: deviceId ?? this.deviceId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      positioningMode: positioningMode ?? this.positioningMode,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'PositionData(deviceId: $deviceId, lat: $latitude, lng: $longitude, '
        'accuracy: ${accuracy}m, mode: $positioningMode, time: $timestamp)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositionData &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      deviceId.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      timestamp.hashCode;
}

/// Calculate distance between two points using Haversine formula
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // Earth radius in meters

  final double dLat = _toRadians(lat2 - lat1);
  final double dLon = _toRadians(lon2 - lon1);

  final double a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadius * c;
}

/// Calculate bearing between two points
double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
  final double dLon = _toRadians(lon2 - lon1);
  final double lat1Rad = _toRadians(lat1);
  final double lat2Rad = _toRadians(lat2);

  final double y = math.sin(dLon) * math.cos(lat2Rad);
  final double x =
      math.cos(lat1Rad) * math.sin(lat2Rad) -
      math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

  final double bearing = math.atan2(y, x);

  return (_toDegrees(bearing) + 360) % 360;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
double _toDegrees(double radians) => radians * 180 / math.pi;
