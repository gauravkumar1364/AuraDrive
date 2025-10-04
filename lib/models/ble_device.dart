import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Represents a BLE device in the mesh network
class BLEDevice {
  final String id;
  final String name;
  final BluetoothDevice device;
  int rssi;
  DateTime lastSeen;
  
  // Mesh properties
  bool isConnected;
  bool isProxyNode;
  String? clusterId;
  
  // Doppler data
  List<int> rssiHistory; // For frequency shift analysis
  double? estimatedSpeed; // m/s
  
  // Performance metrics
  int messagesReceived;
  int messagesSent;
  double messageSuccessRate;

  BLEDevice({
    required this.id,
    required this.name,
    required this.device,
    this.rssi = 0,
    required this.lastSeen,
    this.isConnected = false,
    this.isProxyNode = false,
    this.clusterId,
    List<int>? rssiHistory,
    this.estimatedSpeed,
    this.messagesReceived = 0,
    this.messagesSent = 0,
    this.messageSuccessRate = 1.0,
  }) : rssiHistory = rssiHistory ?? [];

  /// Update RSSI and track history for Doppler analysis
  void updateRSSI(int newRssi) {
    rssi = newRssi;
    rssiHistory.add(newRssi);
    lastSeen = DateTime.now();
    
    // Keep only last 20 readings (about 2 seconds at 100ms intervals)
    if (rssiHistory.length > 20) {
      rssiHistory.removeAt(0);
    }
  }

  /// Calculate RSSI trend for Doppler effect estimation
  double get rssiTrend {
    if (rssiHistory.length < 3) return 0.0;
    
    // Simple linear regression slope
    final n = rssiHistory.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += rssiHistory[i];
      sumXY += i * rssiHistory[i];
      sumX2 += i * i;
    }
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope;
  }

  /// Check if device is still active (seen within last 5 seconds)
  bool get isActive {
    return DateTime.now().difference(lastSeen).inSeconds < 5;
  }

  /// Create from scan result
  factory BLEDevice.fromScanResult(ScanResult result) {
    return BLEDevice(
      id: result.device.remoteId.toString(),
      name: result.device.platformName.isNotEmpty 
          ? result.device.platformName 
          : 'Unknown',
      device: result.device,
      rssi: result.rssi,
      lastSeen: DateTime.now(),
    );
  }

  /// Create from JSON
  factory BLEDevice.fromJson(Map<String, dynamic> json) {
    // Note: BluetoothDevice cannot be serialized, so this is limited
    throw UnimplementedError('BLEDevice cannot be created from JSON');
  }

  /// Convert to JSON (limited - excludes BluetoothDevice)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rssi': rssi,
      'lastSeen': lastSeen.toIso8601String(),
      'isConnected': isConnected,
      'isProxyNode': isProxyNode,
      'clusterId': clusterId,
      'rssiHistory': rssiHistory,
      'estimatedSpeed': estimatedSpeed,
      'messagesReceived': messagesReceived,
      'messagesSent': messagesSent,
      'messageSuccessRate': messageSuccessRate,
    };
  }

  @override
  String toString() {
    return 'BLEDevice(id: $id, name: $name, rssi: $rssi, connected: $isConnected)';
  }
}
