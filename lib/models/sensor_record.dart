class SensorRecord {
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final double? speed;
  final double? heading;
  final double? accelerometerX;
  final double? accelerometerY;
  final double? accelerometerZ;
  final double? gyroscopeX;
  final double? gyroscopeY;
  final double? gyroscopeZ;

  SensorRecord({
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.speed,
    this.heading,
    this.accelerometerX,
    this.accelerometerY,
    this.accelerometerZ,
    this.gyroscopeX,
    this.gyroscopeY,
    this.gyroscopeZ,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'speed': speed,
    'heading': heading,
    'accelerometerX': accelerometerX,
    'accelerometerY': accelerometerY,
    'accelerometerZ': accelerometerZ,
    'gyroscopeX': gyroscopeX,
    'gyroscopeY': gyroscopeY,
    'gyroscopeZ': gyroscopeZ,
  };
}
