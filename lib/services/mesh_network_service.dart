import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../models/position_data.dart';
import '../models/network_device.dart';
import '../models/vehicle_data.dart';

/// Service for managing BLE mesh network communication.
class MeshNetworkService extends ChangeNotifier {
  static final MeshNetworkService _instance = MeshNetworkService._internal();

  MeshNetworkService._internal();

  factory MeshNetworkService() => _instance;

  /// Request and check required BLE and location permissions
  Future<bool> _checkPermissions() async {
    try {
      final locationStatus = await Permission.location.request();
      if (!locationStatus.isGranted) {
        debugPrint('MeshNetworkService: Location permission denied');
        return false;
      }

      if (Platform.isAndroid) {
        final bluetoothScan = await Permission.bluetoothScan.request();
        final bluetoothConnect = await Permission.bluetoothConnect.request();
        final bluetoothAdvertise = await Permission.bluetoothAdvertise
            .request();

        if (!bluetoothScan.isGranted ||
            !bluetoothConnect.isGranted ||
            !bluetoothAdvertise.isGranted) {
          debugPrint('MeshNetworkService: Bluetooth permissions denied');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('MeshNetworkService: Permission error: $e');
      return false;
    }
  }

  /// Attempt to start advertising
  Future<void> _attemptAdvertising() async {
    try {
      if (!await _blePeripheral.isAdvertising) {
        final packageInfo = await PackageInfo.fromPlatform();
        final deviceId = const Uuid().v4().substring(0, 8);
        await _blePeripheral.start(
          advertiseData: AdvertiseData(
            serviceUuid: naviSafeServiceUuid,
            localName: 'NaviSafe-${deviceId}',
            manufacturerId: 0x0000,
            manufacturerData: Uint8List.fromList(
              utf8.encode(packageInfo.version),
            ),
          ),
        );
        _isAdvertising = true;
        debugPrint(
          'MeshNetworkService: Started advertising as NaviSafe-${deviceId}',
        );
      }
    } catch (e) {
      debugPrint('MeshNetworkService: Advertising error: $e');
    }
  }

  /// Initialize the mesh network service
  Future<bool> initialize() async {
    try {
      if (!await _checkPermissions()) {
        debugPrint('MeshNetworkService: Permissions denied');
        return false;
      }

      if (!await FlutterBluePlus.isSupported) {
        debugPrint('MeshNetworkService: Bluetooth not supported');
        return false;
      }

      await _generateServiceUuid();
      _isInitialized = true;
      notifyListeners();

      await _attemptAdvertising();
      _startContinuousScanning();

      debugPrint('MeshNetworkService: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('MeshNetworkService: Initialization error: $e');
      return false;
    }
  }

  // BLE state
  bool _isInitialized = false;
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  bool _isAdvertising = false;
  Timer? _scanTimer;
  Timer? _reconnectTimer;
  static const Duration _scanInterval = Duration(seconds: 30);
  static const Duration _reconnectInterval = Duration(seconds: 15);

  // BLE peripheral instance for advertising
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();

  // Network devices
  final Map<String, NetworkDevice> _discoveredDevices = {};
  final Map<String, BluetoothDevice> _connectedDevices = {};

  // Cluster configuration

  int _maxClusterSize = 8;
  static const int minRssiThreshold = -80;
  final Map<String, int> _connectionAttempts = {};
  static const int maxConnectionAttempts = 3;

  // Cached characteristics for efficient broadcasting
  final Map<String, BluetoothCharacteristic> _positionCharacteristics = {};
  final Map<String, BluetoothCharacteristic> _vehicleDataCharacteristics = {};

  // Connection subscriptions for robust state management
  final Map<String, StreamSubscription<BluetoothConnectionState>>
  _connectionSubscriptions = {};

  // Data sharing
  final Map<String, PositionData> _sharedPositions = <String, PositionData>{};

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
  Stream<NetworkDevice> get deviceDiscoveredStream =>
      _deviceDiscoveredController.stream;
  Stream<PositionData> get positionReceivedStream =>
      _positionReceivedController.stream;
  Stream<VehicleData> get vehicleDataReceivedStream =>
      _vehicleDataReceivedController.stream;
  Stream<String> get networkStatusStream => _networkStatusController.stream;

  // Service UUIDs
  String naviSafeServiceUuid = '12345678-1234-1234-1234-123456789abc';
  late final Guid naviSafeServiceGuid;

  // Characteristic UUIDs
  static const String positionCharacteristicUuid =
      '12345678-1234-1234-1234-123456789abd';
  static const String vehicleDataCharacteristicUuid =
      '12345678-1234-1234-1234-123456789abe';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isAdvertising;
  int get connectedDeviceCount => _connectedDevices.length;
  Map<String, NetworkDevice> get discoveredDevices =>
      Map.unmodifiable(_discoveredDevices);
  Map<String, PositionData> get sharedPositions =>
      Map.unmodifiable(_sharedPositions);

  /// Start continuous scanning for devices
  void _startContinuousScanning() async {
    if (!_isScanning) {
      await startScanning();
    }

    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(_scanInterval, (timer) async {
      if (!_isScanning) {
        await startScanning();
      }
    });

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(_reconnectInterval, (timer) {
      _attemptReconnections();
    });
  }

  /// Attempt to reconnect to previously discovered devices
  void _attemptReconnections() {
    if (_connectedDevices.length >= _maxClusterSize) return;

    for (var device in _discoveredDevices.values) {
      if (!_connectedDevices.containsKey(device.deviceId) &&
          (_connectionAttempts[device.deviceId] ?? 0) < maxConnectionAttempts) {
        _connectionAttempts[device.deviceId] =
            (_connectionAttempts[device.deviceId] ?? 0) + 1;
        connectToDevice(device.deviceId).then((success) {
          if (success) {
            _connectionAttempts.remove(device.deviceId);
            debugPrint(
              'MeshNetworkService: Reconnected to ${device.deviceId} successfully',
            );
          }
        });
      }
    }
  }

  /// Stop continuous scanning
  void _stopContinuousScanning() {
    _scanTimer?.cancel();
    _reconnectTimer?.cancel();
    _scanTimer = null;
    _reconnectTimer = null;
    if (_isScanning) {
      stopScanning();
    }
  }

  /// Start scanning for BLE devices
  Future<void> startScanning() async {
    if (_isScanning) return;

    try {
      debugPrint('MeshNetworkService: Starting BLE scan for all devices...');
      
      // Subscribe to scan results
      _scanResultsSubscription?.cancel();
      _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        debugPrint('MeshNetworkService: Scan found ${results.length} devices');
        
        for (final result in results) {
          final deviceId = result.device.remoteId.toString();
          final deviceName = result.advertisementData.localName.isNotEmpty
              ? result.advertisementData.localName
              : result.device.platformName.isNotEmpty
                  ? result.device.platformName
                  : 'Unknown Device ${deviceId.substring(0, 4)}';

          debugPrint('MeshNetworkService: Found device $deviceName (RSSI: ${result.rssi})');

          // Check if it's a NaviSafe device
          final isNaviSafe = result.advertisementData.serviceUuids.any(
                (uuid) =>
                    uuid.toString().toLowerCase() ==
                    naviSafeServiceUuid.toLowerCase(),
              ) ||
              result.advertisementData.localName.startsWith('NaviSafe');

          final device = NetworkDevice(
            deviceId: deviceId,
            deviceName: deviceName,
            lastSeen: DateTime.now(),
            connectionStrength: result.rssi,
            status: result.device.isConnected
                ? NetworkDeviceStatus.connected
                : NetworkDeviceStatus.offline,
            capabilities: DeviceCapabilities(
              supportsRawGnss: isNaviSafe,
              supportsNavIC: false,
              supportsBluetooth: true,
              supportsWifi: false,
              supportsAccelerometer: isNaviSafe,
              supportsGyroscope: isNaviSafe,
              supportsMagnetometer: isNaviSafe,
            ),
          );
          
          // Only add devices with acceptable signal strength
          if (result.rssi > minRssiThreshold) {
            _discoveredDevices[device.deviceId] = device;
            _deviceDiscoveredController.add(device);
            notifyListeners();
            debugPrint(
              'MeshNetworkService: Added ${isNaviSafe ? 'NaviSafe' : 'BLE'} device ${device.deviceName} with RSSI ${result.rssi}',
            );
          } else {
            debugPrint(
              'MeshNetworkService: Rejected device ${device.deviceName} - RSSI ${result.rssi} below threshold $minRssiThreshold',
            );
          }
        }
      });

      // Start scanning with optimized settings for all BLE devices
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30),
        androidUsesFineLocation: true,
        // Remove service filter to discover all BLE devices
      );
      _isScanning = true;
      notifyListeners();

      // Set up timer to restart scan after timeout
      Future.delayed(const Duration(seconds: 31), () async {
        if (_isInitialized) {
          _isScanning = false;
          await startScanning(); // Restart scan
        }
      });
    } catch (e) {
      debugPrint('MeshNetworkService: Error starting scan: $e');
    }
  }

  /// Stop scanning for BLE devices
  Future<void> stopScanning() async {
    if (!_isScanning) return;
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  /// Connect to a specific device by ID
  Future<bool> connectToDevice(String deviceId) async {
    try {
      final scanResults = await FlutterBluePlus.scanResults.first;
      final scanResult = scanResults.firstWhere(
        (r) => r.device.remoteId.toString() == deviceId,
        orElse: () => throw Exception('Device not found in scan results'),
      );
      final device = scanResult.device;

      await device.connect(timeout: const Duration(seconds: 20));

      final services = await device.discoverServices();
      final naviSafeService = services.firstWhere(
        (s) =>
            s.uuid.toString().toLowerCase() ==
            naviSafeServiceUuid.toLowerCase(),
        orElse: () => throw Exception('NaviSafe service not found'),
      );

      _connectedDevices[deviceId] = device;
      _connectionSubscriptions[deviceId] = device.connectionState.listen(
        (state) {
          if (state == BluetoothConnectionState.disconnected) {
            _handleDeviceDisconnected(deviceId);
          }
        },
        onError: (e) {
          debugPrint(
            'MeshNetworkService: Connection state error for $deviceId: $e',
          );
          _handleDeviceDisconnected(deviceId);
        },
      );

      _networkStatusController.add('Connected to ${device.platformName}');

      // Set up characteristic monitoring
      final positionChar = naviSafeService.characteristics.firstWhere(
        (c) => c.uuid.toString() == positionCharacteristicUuid,
      );
      _positionCharacteristics[deviceId] = positionChar;

      final vehicleDataChar = naviSafeService.characteristics.firstWhere(
        (c) => c.uuid.toString() == vehicleDataCharacteristicUuid,
      );
      _vehicleDataCharacteristics[deviceId] = vehicleDataChar;

      return true;
    } catch (e) {
      debugPrint('MeshNetworkService: Connect error: $e');
      return false;
    }
  }

  /// Broadcast position data to all connected devices
  Future<bool> broadcastPositionData(PositionData data) async {
    if (_connectedDevices.isEmpty) return false;
    try {
      for (final entry in _positionCharacteristics.entries) {
        if (_connectedDevices.containsKey(entry.key)) {
          await entry.value.write(data.toBytes());
        }
      }
      return true;
    } catch (e) {
      debugPrint('MeshNetworkService: Error broadcasting position data: $e');
      return false;
    }
  }

  /// Handle device disconnection
  void _handleDeviceDisconnected(String deviceId) {
    final device = _connectedDevices[deviceId];
    if (device == null) return;

    // Clean up all resources associated with this device
    _connectedDevices.remove(deviceId);
    _positionCharacteristics.remove(deviceId);
    _vehicleDataCharacteristics.remove(deviceId);
    _connectionSubscriptions[deviceId]?.cancel();
    _connectionSubscriptions.remove(deviceId);

    _networkStatusController.add('Device disconnected');
  }

  @override
  void dispose() {
    _stopContinuousScanning();
    _blePeripheral.stop();

    // Cancel all connection subscriptions
    _connectionSubscriptions.values.forEach((sub) => sub.cancel());
    _connectionSubscriptions.clear();

    // Close all stream controllers
    _deviceDiscoveredController.close();
    _positionReceivedController.close();
    _vehicleDataReceivedController.close();
    _networkStatusController.close();

    super.dispose();
  }

  Future<void> _generateServiceUuid() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      final packageName = (pkg.packageName.isNotEmpty)
          ? pkg.packageName
          : pkg.appName;
      final uid = Uuid();
      naviSafeServiceUuid = uid.v5(Uuid.NAMESPACE_URL, packageName);
      naviSafeServiceGuid = Guid(naviSafeServiceUuid);
      debugPrint(
        'MeshNetworkService: Generated NaviSafe service UUID: $naviSafeServiceUuid from package: $packageName',
      );
    } catch (e) {
      naviSafeServiceUuid = '12345678-1234-1234-1234-123456789abc';
      naviSafeServiceGuid = Guid(naviSafeServiceUuid);
      debugPrint(
        'MeshNetworkService: Failed to derive package name, using fallback UUID $naviSafeServiceUuid - error: $e',
      );
    }
  }
}
