import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:latlong2/latlong.dart';
import '../models/ble_device.dart';
import '../models/cluster.dart';
import '../models/vehicle.dart';

/// BLE Mesh Manager for smartphone-based mesh networking
/// Implements proxy node functionality using GATT operations
class BLEMeshService {
  // Device discovery
  final Map<String, BLEDevice> _discoveredDevices = {};
  final Map<String, BluetoothCharacteristic> _characteristics = {};
  
  // Mesh network state
  String? _myDeviceId;
  Cluster? _myCluster;
  bool _isScanning = false;
  bool _isInitialized = false;
  
  // Clustering parameters
  static const int rssiThreshold = -70; // dBm - devices closer than this can cluster
  static const int maxClusterSize = 10;
  static const int minClusterSize = 2;
  
  // Service and Characteristic UUIDs for mesh communication
  static final Guid meshServiceUuid = Guid('0000180a-0000-1000-8000-00805f9b34fb');
  static final Guid meshCharacteristicUuid = Guid('00002a29-0000-1000-8000-00805f9b34fb');
  
  // Streams
  final StreamController<List<BLEDevice>> _devicesController = 
      StreamController<List<BLEDevice>>.broadcast();
  final StreamController<Cluster?> _clusterController = 
      StreamController<Cluster?>.broadcast();
  
  Stream<List<BLEDevice>> get devicesStream => _devicesController.stream;
  Stream<Cluster?> get clusterStream => _clusterController.stream;
  
  /// Initialize BLE mesh service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Check BLE availability
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('BLE not supported on this device');
      }
      
      // Generate device ID
      _myDeviceId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Start advertising and scanning
      await startMesh();
      
      _isInitialized = true;
      print('BLE Mesh Service initialized with ID: $_myDeviceId');
    } catch (e) {
      print('Error initializing BLE Mesh Service: $e');
      rethrow;
    }
  }
  
  /// Start mesh networking (advertising + scanning)
  Future<void> startMesh() async {
    await startScanning();
    // Note: BLE advertising on mobile is limited
    // We rely on scanning and GATT connections for mesh communication
  }
  
  /// Start scanning for nearby BLE devices
  Future<void> startScanning() async {
    if (_isScanning) return;
    
    try {
      _isScanning = true;
      
      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          _processScannedDevice(result);
        }
      });
      
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: true,
      );
      
      // Auto restart scanning
      Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (!_isScanning) {
          timer.cancel();
          return;
        }
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 4),
          androidUsesFineLocation: true,
        );
      });
      
    } catch (e) {
      print('Error starting BLE scan: $e');
      _isScanning = false;
    }
  }
  
  /// Process scanned BLE device
  void _processScannedDevice(ScanResult result) {
    final deviceId = result.device.remoteId.toString();
    
    // Update or add device
    if (_discoveredDevices.containsKey(deviceId)) {
      _discoveredDevices[deviceId]!.updateRSSI(result.rssi);
    } else {
      final bleDevice = BLEDevice.fromScanResult(result);
      _discoveredDevices[deviceId] = bleDevice;
    }
    
    // Update cluster formation
    _updateClusterFormation();
    
    // Emit updated devices
    _devicesController.add(_discoveredDevices.values.toList());
  }
  
  /// Update cluster formation based on RSSI
  void _updateClusterFormation() {
    // Get devices with strong signal (RSSI > threshold)
    final nearbyDevices = _discoveredDevices.values
        .where((d) => d.rssi > rssiThreshold && d.isActive)
        .toList();
    
    if (nearbyDevices.isEmpty) {
      // No cluster
      if (_myCluster != null) {
        _myCluster = null;
        _clusterController.add(null);
      }
      return;
    }
    
    // Check if we should create or join a cluster
    if (_myCluster == null) {
      _createOrJoinCluster(nearbyDevices);
    } else {
      _maintainCluster(nearbyDevices);
    }
  }
  
  /// Create new cluster or join existing one
  void _createOrJoinCluster(List<BLEDevice> nearbyDevices) {
    // For simplification, create new cluster with strongest nearby devices
    if (nearbyDevices.length >= minClusterSize - 1) {
      // Sort by RSSI (strongest first)
      nearbyDevices.sort((a, b) => b.rssi.compareTo(a.rssi));
      
      // Take top devices
      final clusterMembers = nearbyDevices
          .take(maxClusterSize - 1)
          .map((d) => Vehicle(
                id: d.id,
                deviceId: d.id,
                position: const LatLng(0, 0), // Will be updated
                lastUpdate: d.lastSeen,
                rssi: d.rssi,
              ))
          .toList();
      
      // Add self
      clusterMembers.add(Vehicle(
        id: _myDeviceId!,
        deviceId: _myDeviceId!,
        position: const LatLng(0, 0),
        lastUpdate: DateTime.now(),
        isCoordinator: true, // Initially we are coordinator
      ));
      
      _myCluster = Cluster(
        id: _myDeviceId!,
        coordinatorId: _myDeviceId!,
        members: clusterMembers,
        createdAt: DateTime.now(),
        lastUpdate: DateTime.now(),
      );
      
      _clusterController.add(_myCluster);
      print('Created cluster ${_myCluster!.id} with ${clusterMembers.length} members');
    }
  }
  
  /// Maintain existing cluster
  void _maintainCluster(List<BLEDevice> nearbyDevices) {
    if (_myCluster == null) return;
    
    // Remove devices that are no longer nearby
    _myCluster!.members.removeWhere((member) {
      if (member.id == _myDeviceId) return false; // Keep self
      final device = _discoveredDevices[member.id];
      return device == null || !device.isActive || device.rssi < rssiThreshold;
    });
    
    // Add new nearby devices
    for (final device in nearbyDevices) {
      if (_myCluster!.members.length >= maxClusterSize) break;
      
      if (!_myCluster!.members.any((m) => m.id == device.id)) {
        _myCluster!.addMember(Vehicle(
          id: device.id,
          deviceId: device.id,
          position: const LatLng(0, 0),
          lastUpdate: device.lastSeen,
          rssi: device.rssi,
          clusterId: _myCluster!.id,
        ));
      }
    }
    
    // Dissolve cluster if too small
    if (_myCluster!.members.length < minClusterSize) {
      _myCluster = null;
      _clusterController.add(null);
      print('Cluster dissolved - too few members');
    } else {
      _clusterController.add(_myCluster);
    }
  }
  
  /// Connect to a BLE device and establish GATT connection
  Future<void> connectToDevice(String deviceId) async {
    final bleDevice = _discoveredDevices[deviceId];
    if (bleDevice == null) return;
    
    try {
      await bleDevice.device.connect(
        timeout: const Duration(seconds: 5),
      );
      
      bleDevice.isConnected = true;
      
      // Discover services
      final services = await bleDevice.device.discoverServices();
      
      // Find mesh characteristic for data exchange
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _characteristics[deviceId] = characteristic;
          }
        }
      }
      
      print('Connected to device $deviceId');
    } catch (e) {
      print('Error connecting to device $deviceId: $e');
    }
  }
  
  /// Send data to a device via GATT
  Future<void> sendData(String deviceId, Map<String, dynamic> data) async {
    final characteristic = _characteristics[deviceId];
    if (characteristic == null) {
      // Try to connect first
      await connectToDevice(deviceId);
      return sendData(deviceId, data); // Retry
    }
    
    try {
      final jsonData = jsonEncode(data);
      final bytes = utf8.encode(jsonData);
      
      await characteristic.write(bytes, withoutResponse: true);
      
      // Update statistics
      final device = _discoveredDevices[deviceId];
      if (device != null) {
        device.messagesSent++;
      }
    } catch (e) {
      print('Error sending data to $deviceId: $e');
    }
  }
  
  /// Broadcast data to all cluster members
  Future<void> broadcastToCluster(Map<String, dynamic> data) async {
    if (_myCluster == null) return;
    
    for (final member in _myCluster!.members) {
      if (member.id != _myDeviceId) {
        await sendData(member.id, data);
      }
    }
  }
  
  /// Get discovered devices
  List<BLEDevice> getDiscoveredDevices() {
    return _discoveredDevices.values
        .where((d) => d.isActive)
        .toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
  }
  
  /// Get current cluster
  Cluster? getCurrentCluster() {
    return _myCluster;
  }
  
  /// Check if device is cluster coordinator
  bool isCoordinator() {
    return _myCluster?.coordinatorId == _myDeviceId;
  }
  
  /// Stop scanning
  Future<void> stopScanning() async {
    _isScanning = false;
    await FlutterBluePlus.stopScan();
  }
  
  /// Disconnect all devices
  Future<void> disconnectAll() async {
    for (final device in _discoveredDevices.values) {
      if (device.isConnected) {
        await device.device.disconnect();
      }
    }
  }
  
  /// Dispose resources
  void dispose() {
    stopScanning();
    disconnectAll();
    _devicesController.close();
    _clusterController.close();
    _isInitialized = false;
  }
}
