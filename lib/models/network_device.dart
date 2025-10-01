import 'dart:convert';
import 'dart:math' as dart_math;
import 'position_data.dart';

/// Model representing a network device in the BLE mesh
class NetworkDevice {
  final String deviceId;
  final String deviceName;
  final PositionData? lastKnownPosition;
  final DateTime lastSeen;
  final int connectionStrength; // RSSI value
  final NetworkDeviceStatus status;
  final DeviceCapabilities capabilities;
  final DateTime? lastDataUpdate;
  final Map<String, dynamic>? metadata;

  const NetworkDevice({
    required this.deviceId,
    required this.deviceName,
    this.lastKnownPosition,
    required this.lastSeen,
    required this.connectionStrength,
    required this.status,
    required this.capabilities,
    this.lastDataUpdate,
    this.metadata,
  });

  /// Create NetworkDevice from JSON
  factory NetworkDevice.fromJson(Map<String, dynamic> json) {
    return NetworkDevice(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      lastKnownPosition: json['lastKnownPosition'] != null
          ? PositionData.fromJson(json['lastKnownPosition'] as Map<String, dynamic>)
          : null,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      connectionStrength: json['connectionStrength'] as int,
      status: NetworkDeviceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NetworkDeviceStatus.offline,
      ),
      capabilities: DeviceCapabilities.fromJson(json['capabilities'] as Map<String, dynamic>),
      lastDataUpdate: json['lastDataUpdate'] != null
          ? DateTime.parse(json['lastDataUpdate'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'lastKnownPosition': lastKnownPosition?.toJson(),
      'lastSeen': lastSeen.toIso8601String(),
      'connectionStrength': connectionStrength,
      'status': status.name,
      'capabilities': capabilities.toJson(),
      'lastDataUpdate': lastDataUpdate?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Convert to JSON string
  String toJsonString() => json.encode(toJson());

  /// Create from JSON string
  factory NetworkDevice.fromJsonString(String jsonString) {
    return NetworkDevice.fromJson(json.decode(jsonString) as Map<String, dynamic>);
  }

  /// Check if device is currently connected
  bool get isConnected => status == NetworkDeviceStatus.connected;

  /// Check if device is online (connected or recently seen)
  bool get isOnline => 
      status == NetworkDeviceStatus.connected ||
      DateTime.now().difference(lastSeen).inMinutes < 2;

  /// Get signal quality (0-100)
  int get signalQuality {
    // Convert RSSI to quality percentage (typical RSSI range: -100 to -30 dBm)
    if (connectionStrength >= -30) return 100;
    if (connectionStrength <= -100) return 0;
    return ((connectionStrength + 100) * 100 / 70).round();
  }

  /// Get distance estimate from RSSI (rough approximation)
  double? get estimatedDistance {
    if (connectionStrength == 0) return null;
    
    // Simple path loss model: RSSI = TxPower - 20*log10(distance) - 20*log10(frequency) + C
    // Assuming TxPower = 0 dBm, frequency = 2.4 GHz, C = -40
    const double txPower = 0;
    const double frequency = 2400; // MHz
    const double constant = -40;
    
    final double pathLoss = txPower - connectionStrength;
    final double frequencyLoss = 20 * (frequency / 1000).log10();
    final double distanceComponent = pathLoss - frequencyLoss - constant;
    
    if (distanceComponent <= 0) return 1.0; // Very close
    
    return distanceComponent.pow(10) / 20;
  }

  /// Check if device data is fresh
  bool get hasRecentData {
    if (lastDataUpdate == null) return false;
    return DateTime.now().difference(lastDataUpdate!).inSeconds < 30;
  }

  /// Check if position data is available and recent
  bool get hasRecentPosition {
    if (lastKnownPosition == null) return false;
    return lastKnownPosition!.isRecent(seconds: 30);
  }

  /// Calculate priority for cooperative positioning (higher = more important)
  int get cooperativePositioningPriority {
    int priority = 0;
    
    // Higher signal quality = higher priority
    priority += signalQuality;
    
    // Recent data = higher priority
    if (hasRecentData) priority += 30;
    if (hasRecentPosition) priority += 20;
    
    // Better capabilities = higher priority
    if (capabilities.supportsRawGnss) priority += 25;
    if (capabilities.supportsNavIC) priority += 15;
    if (capabilities.isBaseStation) priority += 40;
    
    // Connection status
    if (isConnected) priority += 20;
    
    return priority;
  }

  /// Copy with new values
  NetworkDevice copyWith({
    String? deviceId,
    String? deviceName,
    PositionData? lastKnownPosition,
    DateTime? lastSeen,
    int? connectionStrength,
    NetworkDeviceStatus? status,
    DeviceCapabilities? capabilities,
    DateTime? lastDataUpdate,
    Map<String, dynamic>? metadata,
  }) {
    return NetworkDevice(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      lastKnownPosition: lastKnownPosition ?? this.lastKnownPosition,
      lastSeen: lastSeen ?? this.lastSeen,
      connectionStrength: connectionStrength ?? this.connectionStrength,
      status: status ?? this.status,
      capabilities: capabilities ?? this.capabilities,
      lastDataUpdate: lastDataUpdate ?? this.lastDataUpdate,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'NetworkDevice(id: $deviceId, name: $deviceName, '
           'status: $status, signal: $signalQuality%, '
           'distance: ${estimatedDistance?.toStringAsFixed(1)}m)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkDevice &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId;

  @override
  int get hashCode => deviceId.hashCode;
}

/// Enum for network device status
enum NetworkDeviceStatus {
  connecting,
  connected,
  disconnecting,
  offline,
  error,
}

/// Model for device capabilities
class DeviceCapabilities {
  final bool supportsRawGnss;
  final bool supportsNavIC;
  final bool supportsBluetooth;
  final bool supportsWifi;
  final bool supportsAccelerometer;
  final bool supportsGyroscope;
  final bool supportsMagnetometer;
  final bool isBaseStation;
  final List<String> supportedConstellations;
  final Map<String, dynamic>? additionalCapabilities;

  const DeviceCapabilities({
    required this.supportsRawGnss,
    required this.supportsNavIC,
    required this.supportsBluetooth,
    required this.supportsWifi,
    required this.supportsAccelerometer,
    required this.supportsGyroscope,
    required this.supportsMagnetometer,
    this.isBaseStation = false,
    this.supportedConstellations = const [],
    this.additionalCapabilities,
  });

  factory DeviceCapabilities.fromJson(Map<String, dynamic> json) {
    return DeviceCapabilities(
      supportsRawGnss: json['supportsRawGnss'] as bool? ?? false,
      supportsNavIC: json['supportsNavIC'] as bool? ?? false,
      supportsBluetooth: json['supportsBluetooth'] as bool? ?? false,
      supportsWifi: json['supportsWifi'] as bool? ?? false,
      supportsAccelerometer: json['supportsAccelerometer'] as bool? ?? false,
      supportsGyroscope: json['supportsGyroscope'] as bool? ?? false,
      supportsMagnetometer: json['supportsMagnetometer'] as bool? ?? false,
      isBaseStation: json['isBaseStation'] as bool? ?? false,
      supportedConstellations: (json['supportedConstellations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      additionalCapabilities: json['additionalCapabilities'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supportsRawGnss': supportsRawGnss,
      'supportsNavIC': supportsNavIC,
      'supportsBluetooth': supportsBluetooth,
      'supportsWifi': supportsWifi,
      'supportsAccelerometer': supportsAccelerometer,
      'supportsGyroscope': supportsGyroscope,
      'supportsMagnetometer': supportsMagnetometer,
      'isBaseStation': isBaseStation,
      'supportedConstellations': supportedConstellations,
      'additionalCapabilities': additionalCapabilities,
    };
  }

  /// Check if device has full sensor suite
  bool get hasFullSensorSuite =>
      supportsAccelerometer && supportsGyroscope && supportsMagnetometer;

  /// Check if device is suitable for cooperative positioning
  bool get isSuitableForCooperativePositioning =>
      supportsRawGnss && supportsBluetooth && hasFullSensorSuite;

  /// Get capability score (0-100)
  int get capabilityScore {
    int score = 0;
    if (supportsRawGnss) score += 25;
    if (supportsNavIC) score += 15;
    if (supportsBluetooth) score += 10;
    if (supportsWifi) score += 5;
    if (hasFullSensorSuite) score += 20;
    if (isBaseStation) score += 25;
    return score;
  }
}

// Extension for double operations
extension DoubleExtension on double {
  double log10() => log() / ln10;
  double pow(double exponent) => dart_math.pow(this, exponent).toDouble();
  double log() => dart_math.log(this);
}

// Math constants
const double ln10 = 2.302585092994046;