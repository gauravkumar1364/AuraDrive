import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/models.dart';

/// Service for managing BLE mesh network communication
class MeshNetworkService extends ChangeNotifier {
  // BLE state
  bool _isInitialized = false;
  bool _isScanning = false;
  final bool _isAdvertising = false;
  
  // Network devices
  final Map<String, NetworkDevice> _discoveredDevices = {};
  final Map<String, BluetoothDevice> _connectedDevices = {};
  
  // Data sharing
  final Map<String, PositionData> _sharedPositions = {};
  final Map<String, VehicleData> _sharedVehicleData = {};
  
  // Stream controllers
  final StreamController<NetworkDevice> _deviceDiscoveredController = 
      StreamController<NetworkDevice>.broadcast();
  final StreamController<PositionData> _positionReceivedController = 
      StreamController<PositionData>.broadcast();
  final StreamController<VehicleData> _vehicleDataReceivedController = 
      StreamController<VehicleData>.broadcast();
  final StreamController<String> _networkStatusController = 
      StreamController<String>.broadcast();
  
  // Streams
  Stream<NetworkDevice> get deviceDiscoveredStream => _deviceDiscoveredController.stream;
  Stream<PositionData> get positionReceivedStream => _positionReceivedController.stream;
  Stream<VehicleData> get vehicleDataReceivedStream => _vehicleDataReceivedController.stream;
  Stream<String> get networkStatusStream => _networkStatusController.stream;
  
  // Service UUIDs for NaviSafe
  static const String naviSafeServiceUuid = '12345678-1234-1234-1234-123456789abc';
  static const String positionCharacteristicUuid = '12345678-1234-1234-1234-123456789abd';
  static const String vehicleDataCharacteristicUuid = '12345678-1234-1234-1234-123456789abe';
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isAdvertising;
  int get connectedDeviceCount => _connectedDevices.length;
  Map<String, NetworkDevice> get discoveredDevices => Map.unmodifiable(_discoveredDevices);
  Map<String, PositionData> get sharedPositions => Map.unmodifiable(_sharedPositions);
  
  /// Initialize the mesh network service
  Future<bool> initialize() async {
    try {
      // Check Bluetooth permissions
      if (!await _checkPermissions()) {
        debugPrint('MeshNetworkService: Permissions denied');
        return false;
      }
      
      // Check if Bluetooth is supported
      if (!await FlutterBluePlus.isSupported) {
        debugPrint('MeshNetworkService: Bluetooth not supported');
        return false;
      }
      
      // Wait for Bluetooth to be turned on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        debugPrint('MeshNetworkService: Bluetooth adapter not on');
        return false;
      }
      
      _isInitialized = true;
      notifyListeners();
      
      debugPrint('MeshNetworkService: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('MeshNetworkService: Initialization error: $e');
      return false;
    }
  }
  
  /// Check required permissions
  Future<bool> _checkPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.location,
    ];
    
    for (final permission in permissions) {
      final status = await permission.request();
      if (!status.isGranted) {
        debugPrint('MeshNetworkService: Permission denied: $permission');
        return false;
      }
    }
    
    return true;
  }
  
  /// Start scanning for nearby NaviSafe devices
  Future<bool> startScanning() async {
    if (!_isInitialized) {
      debugPrint('MeshNetworkService: Not initialized');
      return false;
    }
    
    if (_isScanning) {
      debugPrint('MeshNetworkService: Already scanning');
      return true;
    }
    
    try {
      // Clear previous discoveries
      _discoveredDevices.clear();
      
      // Start scanning with specific service UUID
      await FlutterBluePlus.startScan(
        withServices: [Guid(naviSafeServiceUuid)],
        timeout: const Duration(seconds: 30),
      );
      
      // Listen for scan results
      FlutterBluePlus.scanResults.listen(_onDeviceDiscovered);
      
      _isScanning = true;
      notifyListeners();
      
      _networkStatusController.add('Scanning for devices...');
      debugPrint('MeshNetworkService: Started scanning');
      return true;
    } catch (e) {
      debugPrint('MeshNetworkService: Error starting scan: $e');
      return false;
    }
  }
  
  /// Stop scanning for devices
  Future<void> stopScanning() async {
    if (!_isScanning) return;
    
    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      notifyListeners();
      
      _networkStatusController.add('Scan stopped');
      debugPrint('MeshNetworkService: Stopped scanning');
    } catch (e) {
      debugPrint('MeshNetworkService: Error stopping scan: $e');
    }
  }
  
  /// Handle discovered devices
  void _onDeviceDiscovered(List<ScanResult> results) {
    for (final result in results) {
      final device = result.device;
      final deviceId = device.remoteId.toString();
      
      // Create network device info
      final networkDevice = NetworkDevice(
        deviceId: deviceId,
        deviceName: device.platformName.isNotEmpty ? device.platformName : 'NaviSafe Device',
        lastSeen: DateTime.now(),
        connectionStrength: result.rssi,
        status: NetworkDeviceStatus.offline,
        capabilities: const DeviceCapabilities(
          supportsRawGnss: true,
          supportsNavIC: true,
          supportsBluetooth: true,
          supportsWifi: false,
          supportsAccelerometer: true,
          supportsGyroscope: true,
          supportsMagnetometer: true,
        ),
      );
      
      _discoveredDevices[deviceId] = networkDevice;
      _deviceDiscoveredController.add(networkDevice);
      notifyListeners();
      
      debugPrint('MeshNetworkService: Discovered device: ${device.platformName} ($deviceId)');
    }
  }
  
  /// Connect to a specific device
  Future<bool> connectToDevice(String deviceId) async {
    final networkDevice = _discoveredDevices[deviceId];
    if (networkDevice == null) {
      debugPrint('MeshNetworkService: Device not found: $deviceId');
      return false;
    }
    
    try {
      // Find the Bluetooth device
      final scanResults = await FlutterBluePlus.scanResults.first;
      final scanResult = scanResults.firstWhere(
        (result) => result.device.remoteId.toString() == deviceId,
        orElse: () => throw Exception('Device not in scan results'),
      );
      
      final device = scanResult.device;
      
      // Connect to device
      await device.connect(timeout: const Duration(seconds: 15));
      
      // Discover services
      final services = await device.discoverServices();
      
      // Find NaviSafe service
      final naviSafeService = services.firstWhere(
        (service) => service.uuid.toString() == naviSafeServiceUuid,
        orElse: () => throw Exception('NaviSafe service not found'),
      );
      
      // Setup characteristics for data sharing
      await _setupCharacteristics(device, naviSafeService);
      
      // Update device status
      _connectedDevices[deviceId] = device;
      _discoveredDevices[deviceId] = networkDevice.copyWith(
        status: NetworkDeviceStatus.connected,
        lastSeen: DateTime.now(),
      );
      
      notifyListeners();
      _networkStatusController.add('Connected to ${device.platformName}');
      
      debugPrint('MeshNetworkService: Connected to device: $deviceId');
      return true;
    } catch (e) {
      debugPrint('MeshNetworkService: Error connecting to device: $e');
      return false;
    }
  }
  
  /// Setup characteristics for data communication
  Future<void> _setupCharacteristics(BluetoothDevice device, BluetoothService service) async {
    try {
      // Find position characteristic
      final positionChar = service.characteristics.firstWhere(
        (char) => char.uuid.toString() == positionCharacteristicUuid,
        orElse: () => throw Exception('Position characteristic not found'),
      );
      
      // Find vehicle data characteristic
      final vehicleDataChar = service.characteristics.firstWhere(
        (char) => char.uuid.toString() == vehicleDataCharacteristicUuid,
        orElse: () => throw Exception('Vehicle data characteristic not found'),
      );
      
      // Subscribe to notifications
      await positionChar.setNotifyValue(true);
      positionChar.lastValueStream.listen(_onPositionDataReceived);
      
      await vehicleDataChar.setNotifyValue(true);
      vehicleDataChar.lastValueStream.listen(_onVehicleDataReceived);
      
      debugPrint('MeshNetworkService: Characteristics setup complete');
    } catch (e) {
      debugPrint('MeshNetworkService: Error setting up characteristics: $e');
    }
  }
  
  /// Handle received position data
  void _onPositionDataReceived(List<int> data) {
    try {
      final jsonString = utf8.decode(data);
      final positionData = PositionData.fromJsonString(jsonString);
      
      _sharedPositions[positionData.deviceId] = positionData;
      _positionReceivedController.add(positionData);
      
      // Update device position
      if (_discoveredDevices.containsKey(positionData.deviceId)) {
        _discoveredDevices[positionData.deviceId] = _discoveredDevices[positionData.deviceId]!.copyWith(
          lastKnownPosition: positionData,
          lastDataUpdate: DateTime.now(),
        );
      }
      
      notifyListeners();
      debugPrint('MeshNetworkService: Received position data from ${positionData.deviceId}');
    } catch (e) {
      debugPrint('MeshNetworkService: Error processing position data: $e');
    }
  }
  
  /// Handle received vehicle data
  void _onVehicleDataReceived(List<int> data) {
    try {
      final jsonString = utf8.decode(data);
      final vehicleData = VehicleData.fromJsonString(jsonString);
      
      _sharedVehicleData[vehicleData.deviceId] = vehicleData;
      _vehicleDataReceivedController.add(vehicleData);
      
      notifyListeners();
      debugPrint('MeshNetworkService: Received vehicle data from ${vehicleData.deviceId}');
    } catch (e) {
      debugPrint('MeshNetworkService: Error processing vehicle data: $e');
    }
  }
  
  /// Broadcast position data to connected devices
  Future<bool> broadcastPositionData(PositionData positionData) async {
    if (_connectedDevices.isEmpty) {
      debugPrint('MeshNetworkService: No connected devices to broadcast to');
      return false;
    }
    
    try {
      final jsonData = utf8.encode(positionData.toJsonString());
      
      for (final device in _connectedDevices.values) {
        // Find the position characteristic and write data
        final services = await device.discoverServices();
        final naviSafeService = services.firstWhere(
          (service) => service.uuid.toString() == naviSafeServiceUuid,
        );
        
        final positionChar = naviSafeService.characteristics.firstWhere(
          (char) => char.uuid.toString() == positionCharacteristicUuid,
        );
        
        await positionChar.write(jsonData);
      }
      
      debugPrint('MeshNetworkService: Broadcasted position data to ${_connectedDevices.length} devices');
      return true;
    } catch (e) {
      debugPrint('MeshNetworkService: Error broadcasting position data: $e');
      return false;
    }
  }
  
  /// Broadcast vehicle data to connected devices
  Future<bool> broadcastVehicleData(VehicleData vehicleData) async {
    if (_connectedDevices.isEmpty) {
      debugPrint('MeshNetworkService: No connected devices to broadcast to');
      return false;
    }
    
    try {
      final jsonData = utf8.encode(vehicleData.toJsonString());
      
      for (final device in _connectedDevices.values) {
        // Find the vehicle data characteristic and write data
        final services = await device.discoverServices();
        final naviSafeService = services.firstWhere(
          (service) => service.uuid.toString() == naviSafeServiceUuid,
        );
        
        final vehicleDataChar = naviSafeService.characteristics.firstWhere(
          (char) => char.uuid.toString() == vehicleDataCharacteristicUuid,
        );
        
        await vehicleDataChar.write(jsonData);
      }
      
      debugPrint('MeshNetworkService: Broadcasted vehicle data to ${_connectedDevices.length} devices');
      return true;
    } catch (e) {
      debugPrint('MeshNetworkService: Error broadcasting vehicle data: $e');
      return false;
    }
  }
  
  /// Disconnect from a specific device
  Future<void> disconnectFromDevice(String deviceId) async {
    final device = _connectedDevices[deviceId];
    if (device == null) return;
    
    try {
      await device.disconnect();
      _connectedDevices.remove(deviceId);
      
      // Update device status
      if (_discoveredDevices.containsKey(deviceId)) {
        _discoveredDevices[deviceId] = _discoveredDevices[deviceId]!.copyWith(
          status: NetworkDeviceStatus.offline,
        );
      }
      
      notifyListeners();
      _networkStatusController.add('Disconnected from device');
      
      debugPrint('MeshNetworkService: Disconnected from device: $deviceId');
    } catch (e) {
      debugPrint('MeshNetworkService: Error disconnecting from device: $e');
    }
  }
  
  /// Disconnect from all devices
  Future<void> disconnectAll() async {
    final deviceIds = List<String>.from(_connectedDevices.keys);
    for (final deviceId in deviceIds) {
      await disconnectFromDevice(deviceId);
    }
  }
  
  /// Get network statistics
  Map<String, dynamic> getNetworkStatistics() {
    final connectedCount = _connectedDevices.length;
    final discoveredCount = _discoveredDevices.length;
    final avgSignalStrength = _discoveredDevices.values.isEmpty
        ? 0
        : _discoveredDevices.values
            .map((d) => d.signalQuality)
            .reduce((a, b) => a + b) / _discoveredDevices.values.length;
    
    return {
      'connectedDevices': connectedCount,
      'discoveredDevices': discoveredCount,
      'averageSignalStrength': avgSignalStrength.round(),
      'dataTransferActive': _sharedPositions.isNotEmpty,
      'networkHealth': connectedCount > 0 ? 'Good' : 'No connections',
    };
  }
  
  /// Check if device is suitable for cooperative positioning
  bool isDeviceSuitableForCooperativePositioning(String deviceId) {
    final device = _discoveredDevices[deviceId];
    if (device == null) return false;
    
    return device.capabilities.isSuitableForCooperativePositioning &&
           device.signalQuality > 30 &&
           device.hasRecentData;
  }
  
  /// Get devices suitable for cooperative positioning
  List<NetworkDevice> get cooperativePositioningDevices {
    return _discoveredDevices.values
        .where((device) => isDeviceSuitableForCooperativePositioning(device.deviceId))
        .toList()
      ..sort((a, b) => b.cooperativePositioningPriority.compareTo(a.cooperativePositioningPriority));
  }
  
  /// Dispose of resources
  @override
  void dispose() {
    disconnectAll();
    stopScanning();
    _deviceDiscoveredController.close();
    _positionReceivedController.close();
    _vehicleDataReceivedController.close();
    _networkStatusController.close();
    super.dispose();
  }
}