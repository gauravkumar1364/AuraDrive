import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/ble_device.dart';
import '../models/vehicle_data.dart';

/// Automatic BLE Connection Service
/// Handles automatic discovery, connection, and reconnection of BLE peripheral devices
class BLEAutoConnectService extends ChangeNotifier {
  // Connection management
  final Map<String, BluetoothDevice> _connectedDevices = {};
  final Map<String, BLEDevice> _discoveredDevices = {};
  final Map<String, StreamSubscription> _deviceSubscriptions = {};
  final Set<String> _reconnectQueue = {};
  final Set<String> _connectionAttempts = {};
  
  // Configuration
  static const int maxAutoConnectDevices = 10;
  static const int reconnectDelay = 5; // seconds
  static const int connectionTimeout = 15; // seconds
  static const int rssiThreshold = -85; // dBm - minimum signal strength
  static const int strongRssiThreshold = -70; // dBm - strong signal
  
  // AuraDrive Service UUID (custom UUID for your app)
  static const String auraDriveServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String dataCharacteristicUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const String notifyCharacteristicUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';
  
  // State
  bool _isScanning = false;
  bool _isInitialized = false;
  bool _autoConnectEnabled = true;
  Timer? _scanTimer;
  Timer? _reconnectTimer;
  
  // Streams
  final StreamController<Map<String, BLEDevice>> _devicesController = 
      StreamController<Map<String, BLEDevice>>.broadcast();
  final StreamController<String> _connectionEventController = 
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _dataController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, BLEDevice>> get devicesStream => _devicesController.stream;
  Stream<String> get connectionEventStream => _connectionEventController.stream;
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  
  // Getters
  bool get isScanning => _isScanning;
  bool get isInitialized => _isInitialized;
  bool get autoConnectEnabled => _autoConnectEnabled;
  int get connectedDeviceCount => _connectedDevices.length;
  int get discoveredDeviceCount => _discoveredDevices.length;
  List<BLEDevice> get connectedDevicesList => 
      _discoveredDevices.values.where((d) => d.isConnected).toList();
  List<BLEDevice> get allDevices => _discoveredDevices.values.toList();
  
  /// Initialize the BLE service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Check BLE support
      if (await FlutterBluePlus.isSupported == false) {
        debugPrint('BLE Auto Connect: BLE not supported on this device');
        return false;
      }
      
      // Check if Bluetooth is on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        debugPrint('BLE Auto Connect: Bluetooth is not enabled');
        
        // Try to turn on Bluetooth (Android only)
        if (Platform.isAndroid) {
          try {
            await FlutterBluePlus.turnOn();
            await Future.delayed(const Duration(seconds: 2));
          } catch (e) {
            debugPrint('BLE Auto Connect: Cannot turn on Bluetooth automatically: $e');
            return false;
          }
        }
      }
      
      // Listen to adapter state changes
      FlutterBluePlus.adapterState.listen((state) {
        debugPrint('BLE Auto Connect: Adapter state changed to $state');
        if (state == BluetoothAdapterState.on && _autoConnectEnabled) {
          startAutoConnect();
        } else if (state == BluetoothAdapterState.off) {
          stopAutoConnect();
        }
      });
      
      _isInitialized = true;
      debugPrint('BLE Auto Connect: Service initialized successfully');
      
      return true;
    } catch (e) {
      debugPrint('BLE Auto Connect: Initialization error: $e');
      return false;
    }
  }
  
  /// Start automatic connection process
  Future<void> startAutoConnect() async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }
    
    if (_isScanning) {
      debugPrint('BLE Auto Connect: Already scanning');
      return;
    }
    
    _autoConnectEnabled = true;
    await _startContinuousScanning();
    _startReconnectTimer();
    
    debugPrint('BLE Auto Connect: Auto-connect started');
    notifyListeners();
  }
  
  /// Stop automatic connection
  Future<void> stopAutoConnect() async {
    _autoConnectEnabled = false;
    _scanTimer?.cancel();
    _reconnectTimer?.cancel();
    await stopScanning();
    
    debugPrint('BLE Auto Connect: Auto-connect stopped');
    notifyListeners();
  }
  
  /// Start continuous scanning with periodic restarts
  Future<void> _startContinuousScanning() async {
    await _performScan();
    
    // Restart scan every 10 seconds to keep discovering
    _scanTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!_autoConnectEnabled) {
        timer.cancel();
        return;
      }
      await _performScan();
    });
  }
  
  /// Perform a single scan cycle
  Future<void> _performScan() async {
    if (!_autoConnectEnabled) return;
    
    try {
      _isScanning = true;
      notifyListeners();
      
      // Listen to scan results
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          _processScanResult(result);
        }
      });
      
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 8),
        androidUsesFineLocation: true,
      );
      
      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 8));
      
      await subscription.cancel();
      
      _isScanning = false;
      notifyListeners();
      
      debugPrint('BLE Auto Connect: Scan cycle completed. Found ${_discoveredDevices.length} devices');
      
    } catch (e) {
      debugPrint('BLE Auto Connect: Scan error: $e');
      _isScanning = false;
      notifyListeners();
    }
  }
  
  /// Process scan result
  void _processScanResult(ScanResult result) {
    final deviceId = result.device.remoteId.toString();
    final rssi = result.rssi;
    final name = result.advertisementData.localName;
    
    // Filter out very weak signals
    if (rssi < rssiThreshold) return;
    
    // Check if it's an AuraDrive device
    final isAuraDriveDevice = _isAuraDriveDevice(result);
    
    // Update or add device
    if (_discoveredDevices.containsKey(deviceId)) {
      _discoveredDevices[deviceId]!.updateRSSI(rssi);
    } else {
      final bleDevice = BLEDevice.fromScanResult(result);
      _discoveredDevices[deviceId] = bleDevice;
      
      debugPrint('BLE Auto Connect: Discovered device: ${name ?? deviceId} (RSSI: $rssi dBm)');
      
      // Auto-connect to AuraDrive devices with strong signal
      if (isAuraDriveDevice && rssi > strongRssiThreshold && _autoConnectEnabled) {
        _tryAutoConnect(deviceId, result.device);
      }
    }
    
    _devicesController.add(_discoveredDevices);
    notifyListeners();
  }
  
  /// Check if device is running AuraDrive app
  bool _isAuraDriveDevice(ScanResult result) {
    final serviceUuids = result.advertisementData.serviceUuids
        .map((guid) => guid.toString().toLowerCase())
        .toList();
    
    // Check for AuraDrive service UUID
    return serviceUuids.contains(auraDriveServiceUuid.toLowerCase());
  }
  
  /// Try to auto-connect to a device
  Future<void> _tryAutoConnect(String deviceId, BluetoothDevice device) async {
    // Prevent duplicate connection attempts
    if (_connectionAttempts.contains(deviceId)) return;
    if (_connectedDevices.containsKey(deviceId)) return;
    if (_connectedDevices.length >= maxAutoConnectDevices) return;
    
    _connectionAttempts.add(deviceId);
    
    debugPrint('BLE Auto Connect: Attempting auto-connect to $deviceId');
    
    try {
      await connectToDevice(deviceId, device);
    } catch (e) {
      debugPrint('BLE Auto Connect: Auto-connect failed for $deviceId: $e');
    } finally {
      _connectionAttempts.remove(deviceId);
    }
  }
  
  /// Connect to a specific device
  Future<bool> connectToDevice(String deviceId, BluetoothDevice? device) async {
    device ??= _discoveredDevices[deviceId]?.device;
    if (device == null) {
      debugPrint('BLE Auto Connect: Device $deviceId not found');
      return false;
    }
    
    try {
      debugPrint('BLE Auto Connect: Connecting to $deviceId...');
      
      // Connect with timeout
      await device.connect(
        timeout: Duration(seconds: connectionTimeout),
        autoConnect: true, // Enable auto-reconnect
      );
      
      // Wait a bit for connection to stabilize
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Discover services
      final services = await device.discoverServices();
      
      // Find AuraDrive service and characteristics
      BluetoothCharacteristic? notifyChar;
      BluetoothCharacteristic? writeChar;
      
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == auraDriveServiceUuid.toLowerCase()) {
          for (final char in service.characteristics) {
            final charUuid = char.uuid.toString().toLowerCase();
            if (charUuid == notifyCharacteristicUuid.toLowerCase()) {
              notifyChar = char;
            } else if (charUuid == dataCharacteristicUuid.toLowerCase()) {
              writeChar = char;
            }
          }
        }
      }
      
      // Subscribe to notifications
      if (notifyChar != null) {
        await notifyChar.setNotifyValue(true);
        final subscription = notifyChar.lastValueStream.listen((value) {
          _handleReceivedData(deviceId, value);
        });
        _deviceSubscriptions[deviceId] = subscription;
      }
      
      // Update state
      _connectedDevices[deviceId] = device;
      if (_discoveredDevices.containsKey(deviceId)) {
        _discoveredDevices[deviceId]!.isConnected = true;
      }
      
      // Listen to connection state
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection(deviceId);
        }
      });
      
      _connectionEventController.add('connected:$deviceId');
      notifyListeners();
      
      debugPrint('BLE Auto Connect: Successfully connected to $deviceId');
      return true;
      
    } catch (e) {
      debugPrint('BLE Auto Connect: Connection failed for $deviceId: $e');
      _handleDisconnection(deviceId);
      return false;
    }
  }
  
  /// Handle device disconnection
  void _handleDisconnection(String deviceId) {
    debugPrint('BLE Auto Connect: Device $deviceId disconnected');
    
    // Clean up
    _connectedDevices.remove(deviceId);
    _deviceSubscriptions[deviceId]?.cancel();
    _deviceSubscriptions.remove(deviceId);
    
    if (_discoveredDevices.containsKey(deviceId)) {
      _discoveredDevices[deviceId]!.isConnected = false;
    }
    
    // Add to reconnect queue if auto-connect is enabled
    if (_autoConnectEnabled) {
      _reconnectQueue.add(deviceId);
    }
    
    _connectionEventController.add('disconnected:$deviceId');
    notifyListeners();
  }
  
  /// Start reconnection timer
  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(Duration(seconds: reconnectDelay), (timer) {
      if (!_autoConnectEnabled) {
        timer.cancel();
        return;
      }
      _processReconnectQueue();
    });
  }
  
  /// Process reconnection queue
  Future<void> _processReconnectQueue() async {
    if (_reconnectQueue.isEmpty) return;
    
    final devicesToReconnect = List<String>.from(_reconnectQueue);
    _reconnectQueue.clear();
    
    for (final deviceId in devicesToReconnect) {
      if (_connectedDevices.length >= maxAutoConnectDevices) break;
      
      final bleDevice = _discoveredDevices[deviceId];
      if (bleDevice != null && bleDevice.isActive) {
        debugPrint('BLE Auto Connect: Attempting reconnection to $deviceId');
        await connectToDevice(deviceId, bleDevice.device);
      }
    }
  }
  
  /// Handle received data from peripheral
  void _handleReceivedData(String deviceId, List<int> value) {
    try {
      final jsonString = utf8.decode(value);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      
      data['deviceId'] = deviceId;
      data['timestamp'] = DateTime.now().toIso8601String();
      
      _dataController.add(data);
      
      // Update device stats
      if (_discoveredDevices.containsKey(deviceId)) {
        _discoveredDevices[deviceId]!.messagesReceived++;
      }
      
      debugPrint('BLE Auto Connect: Received data from $deviceId: ${data.keys.join(", ")}');
      
    } catch (e) {
      debugPrint('BLE Auto Connect: Error parsing received data from $deviceId: $e');
    }
  }
  
  /// Send data to a connected device
  Future<bool> sendData(String deviceId, Map<String, dynamic> data) async {
    final device = _connectedDevices[deviceId];
    if (device == null) {
      debugPrint('BLE Auto Connect: Device $deviceId not connected');
      return false;
    }
    
    try {
      final services = await device.discoverServices();
      
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == auraDriveServiceUuid.toLowerCase()) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == dataCharacteristicUuid.toLowerCase()) {
              final jsonString = json.encode(data);
              final bytes = utf8.encode(jsonString);
              
              await char.write(bytes, withoutResponse: true);
              
              // Update stats
              if (_discoveredDevices.containsKey(deviceId)) {
                _discoveredDevices[deviceId]!.messagesSent++;
              }
              
              debugPrint('BLE Auto Connect: Data sent to $deviceId');
              return true;
            }
          }
        }
      }
      
      debugPrint('BLE Auto Connect: Write characteristic not found for $deviceId');
      return false;
      
    } catch (e) {
      debugPrint('BLE Auto Connect: Error sending data to $deviceId: $e');
      return false;
    }
  }
  
  /// Broadcast data to all connected devices
  Future<int> broadcastData(Map<String, dynamic> data) async {
    int successCount = 0;
    
    for (final deviceId in _connectedDevices.keys) {
      if (await sendData(deviceId, data)) {
        successCount++;
      }
    }
    
    debugPrint('BLE Auto Connect: Broadcast sent to $successCount/${_connectedDevices.length} devices');
    return successCount;
  }
  
  /// Disconnect from a device
  Future<void> disconnectDevice(String deviceId) async {
    final device = _connectedDevices[deviceId];
    if (device != null) {
      try {
        await device.disconnect();
      } catch (e) {
        debugPrint('BLE Auto Connect: Error disconnecting from $deviceId: $e');
      }
    }
    _handleDisconnection(deviceId);
  }
  
  /// Stop scanning
  Future<void> stopScanning() async {
    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      debugPrint('BLE Auto Connect: Error stopping scan: $e');
    }
  }
  
  /// Get connection statistics
  Map<String, dynamic> getStatistics() {
    return {
      'discoveredDevices': _discoveredDevices.length,
      'connectedDevices': _connectedDevices.length,
      'isScanning': _isScanning,
      'autoConnectEnabled': _autoConnectEnabled,
      'reconnectQueueSize': _reconnectQueue.length,
      'devices': _discoveredDevices.values.map((d) => {
        'id': d.id,
        'name': d.name,
        'rssi': d.rssi,
        'isConnected': d.isConnected,
        'messagesSent': d.messagesSent,
        'messagesReceived': d.messagesReceived,
      }).toList(),
    };
  }
  
  /// Dispose of resources
  @override
  void dispose() {
    _scanTimer?.cancel();
    _reconnectTimer?.cancel();
    stopScanning();
    
    // Disconnect all devices
    for (final deviceId in _connectedDevices.keys.toList()) {
      disconnectDevice(deviceId);
    }
    
    _devicesController.close();
    _connectionEventController.close();
    _dataController.close();
    
    super.dispose();
  }
}
