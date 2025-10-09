import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
  String? _advertisingDeviceId;
  Timer? _advertisingUpdateTimer;

  Future<void> _attemptAdvertising() async {
    try {
      debugPrint(
        '🔔 MeshNetworkService: Attempting to start BLE advertising...',
      );
      final isCurrentlyAdvertising = await _blePeripheral.isAdvertising;
      debugPrint(
        '🔔 MeshNetworkService: Currently advertising: $isCurrentlyAdvertising',
      );

      if (!isCurrentlyAdvertising) {
        _advertisingDeviceId = const Uuid().v4().substring(0, 6);
        debugPrint(
          '🔔 MeshNetworkService: Generated device ID: Nav-$_advertisingDeviceId',
        );
        debugPrint('🔔 MeshNetworkService: Service UUID: $naviSafeServiceUuid');

        // Start with initial position
        await _updateAdvertisingWithPosition();

        _isAdvertising = true;
        debugPrint(
          '✅ MeshNetworkService: Started advertising as Nav-$_advertisingDeviceId',
        );

        // Update advertising position every 2 seconds
        _advertisingUpdateTimer?.cancel();
        _advertisingUpdateTimer = Timer.periodic(const Duration(seconds: 2), (
          timer,
        ) {
          _updateAdvertisingWithPosition();
        });
      } else {
        debugPrint('✅ MeshNetworkService: Already advertising');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ MeshNetworkService: Advertising error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _updateAdvertisingWithPosition() async {
    try {
      // Get current position
      final position = _currentPosition;

      // Encode position in manufacturer data (12 bytes total)
      ByteData buffer = ByteData(12);

      if (position != null) {
        // Latitude as float32 (4 bytes) - precision ~1cm
        buffer.setFloat32(0, position.latitude, Endian.little);
        // Longitude as float32 (4 bytes)
        buffer.setFloat32(4, position.longitude, Endian.little);
        // Speed as uint16 (2 bytes) - 0-655.35 km/h with 0.01 precision
        final speed = position.speed ?? 0.0;
        buffer.setUint16(
          8,
          (speed * 100).round().clamp(0, 65535),
          Endian.little,
        );
        // Heading as uint16 (2 bytes) - 0-359.99 degrees with 0.01 precision
        final heading = position.heading ?? 0.0;
        buffer.setUint16(
          10,
          (heading * 100).round().clamp(0, 35999),
          Endian.little,
        );

        debugPrint(
          '📡 Advertising position: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
        );
      } else {
        // No position - send zeros
        debugPrint('📡 Advertising without position (GPS not ready)');
      }

      await _blePeripheral.stop();
      await _blePeripheral.start(
        advertiseData: AdvertiseData(
          serviceUuid: naviSafeServiceUuid,
          localName: 'Nav-$_advertisingDeviceId',
          manufacturerId: 0xFFFF, // Custom manufacturer ID
          manufacturerData: buffer.buffer.asUint8List(),
        ),
      );
    } catch (e) {
      debugPrint('❌ Failed to update advertising: $e');
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

      debugPrint('🔔 MeshNetworkService: Starting advertising...');
      await _attemptAdvertising();
      debugPrint('🔔 MeshNetworkService: Starting continuous scanning...');
      _startContinuousScanning();

      debugPrint('✅ MeshNetworkService: Initialized successfully');
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
  PositionData? _currentPosition; // Store current position for advertising
  static const Duration _scanInterval = Duration(
    milliseconds: 1500,
  ); // EXTREME FAST - scan every 1.5 seconds
  static const Duration _reconnectInterval = Duration(
    milliseconds: 500,
  ); // INSANE - retry every 0.5 seconds

  // BLE peripheral instance for advertising
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();

  // Network devices
  final Map<String, NetworkDevice> _discoveredDevices = {};
  final Map<String, BluetoothDevice> _connectedDevices = {};
  final Map<String, BluetoothDevice> _scannedDevices =
      {}; // Cache scanned devices for connection

  // Cluster configuration
  int _maxClusterSize = 20; // Support more devices
  static const int minRssiThreshold =
      -90; // MAXIMUM RANGE - 60-70m for ultra-long detection
  final Map<String, int> _connectionAttempts = {};
  static const int maxConnectionAttempts =
      15; // MASSIVE attempts - never give up
  PositionData? _lastBroadcastedPosition;

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

  // Service UUIDs - FIXED for all AuraDrive devices
  static const String naviSafeServiceUuid =
      '12345678-1234-1234-1234-123456789abc';
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

    // Sort devices by RSSI (strongest signal first) for faster connections
    final sortedDevices = _discoveredDevices.values.toList()
      ..sort((a, b) => b.connectionStrength.compareTo(a.connectionStrength));

    int connectionsStarted = 0;
    for (var device in sortedDevices) {
      if (_connectedDevices.length >= _maxClusterSize) break;
      if (connectionsStarted >= 8)
        break; // MAXIMUM parallel connections - 8 at once for extreme speed

      if (!_connectedDevices.containsKey(device.deviceId) &&
          (_connectionAttempts[device.deviceId] ?? 0) < maxConnectionAttempts) {
        // Prioritize NaviSafe devices
        final isNaviSafe = device.capabilities.supportsRawGnss;

        _connectionAttempts[device.deviceId] =
            (_connectionAttempts[device.deviceId] ?? 0) + 1;

        if (isNaviSafe) {
          debugPrint(
            '🚀 AUTO-CONNECTING to NaviSafe device ${device.deviceName} (Attempt ${_connectionAttempts[device.deviceId]})...',
          );
        }

        connectionsStarted++;
        connectToDevice(device.deviceId).then((success) {
          if (success) {
            _connectionAttempts.remove(device.deviceId);
            debugPrint('✅ Connected to ${device.deviceName} successfully');
          } else {
            debugPrint(
              '❌ Failed to connect to ${device.deviceName} (Attempt ${_connectionAttempts[device.deviceId]}/$maxConnectionAttempts)',
            );
          }
        });
      }
    }

    if (connectionsStarted > 0) {
      debugPrint('📡 Started $connectionsStarted auto-connection attempts');
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

          debugPrint(
            'MeshNetworkService: Found device $deviceName (RSSI: ${result.rssi})',
          );

          // Check if it's a NaviSafe device
          final isNaviSafe =
              result.advertisementData.serviceUuids.any(
                (uuid) =>
                    uuid.toString().toLowerCase() ==
                    naviSafeServiceUuid.toLowerCase(),
              ) ||
              result.advertisementData.localName.startsWith('Nav-') ||
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
          if (result.rssi >= minRssiThreshold) {
            _discoveredDevices[device.deviceId] = device;
            _scannedDevices[device.deviceId] =
                result.device; // Cache the actual BLE device
            _deviceDiscoveredController.add(device);
            notifyListeners();
            debugPrint(
              'MeshNetworkService: Added ${isNaviSafe ? 'NaviSafe' : 'BLE'} device ${device.deviceName} with RSSI ${result.rssi}',
            );

            // Extract position from manufacturer data for NaviSafe devices
            if (isNaviSafe &&
                result.advertisementData.manufacturerData.containsKey(0xFFFF)) {
              final manuData =
                  result.advertisementData.manufacturerData[0xFFFF]!;
              if (manuData.length >= 12) {
                try {
                  ByteData buffer = ByteData.sublistView(
                    Uint8List.fromList(manuData),
                  );
                  double lat = buffer.getFloat32(0, Endian.little);
                  double lon = buffer.getFloat32(4, Endian.little);
                  double speed =
                      buffer.getUint16(8, Endian.little) /
                      100.0; // Convert back from 0.01 precision
                  double heading = buffer.getUint16(10, Endian.little) / 100.0;

                  // Only add if position is valid (not all zeros)
                  if (lat != 0.0 || lon != 0.0) {
                    final positionData = PositionData(
                      deviceId: device.deviceId,
                      latitude: lat,
                      longitude: lon,
                      altitude: 0.0,
                      accuracy: 5.0, // Assume good accuracy
                      speed: speed,
                      heading: heading,
                      timestamp: DateTime.now(),
                    );

                    _sharedPositions[device.deviceId] = positionData;
                    _positionReceivedController.add(positionData);
                    notifyListeners();

                    debugPrint(
                      '� Received position from ${device.deviceName}: ${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)} (${speed.toStringAsFixed(1)} km/h)',
                    );
                  }
                } catch (e) {
                  debugPrint(
                    '❌ Failed to decode position from ${device.deviceName}: $e',
                  );
                }
              }
            }

            // REMOVE AUTO-CONNECT LOGIC - No longer needed!
            // Position sharing now works via advertising data only
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

  /// Connect to a specific device by ID with enhanced error handling
  Future<bool> connectToDevice(String deviceId) async {
    try {
      // Try to get device from cache first
      BluetoothDevice? device = _scannedDevices[deviceId];

      // If not in cache, try to find in scan results
      if (device == null) {
        final scanResults = await FlutterBluePlus.scanResults.first.timeout(
          const Duration(seconds: 2),
          onTimeout: () => [],
        );

        if (scanResults.isEmpty) {
          throw Exception('No scan results available');
        }

        final scanResult = scanResults.firstWhere(
          (r) => r.device.remoteId.toString() == deviceId,
          orElse: () => throw Exception('Device not found in scan results'),
        );
        device = scanResult.device;
        _scannedDevices[deviceId] = device; // Cache for future use
      }

      debugPrint('🔗 Connecting to ${device.platformName} ($deviceId)...');
      await device.connect(
        timeout: const Duration(seconds: 10),
      ); // VERY FAST timeout - fail and retry quickly
      debugPrint('✅ Connected to ${device.platformName}');

      debugPrint('🔍 Discovering services...');
      final services = await device.discoverServices();
      debugPrint('📋 Found ${services.length} services');

      // Log all services for debugging
      for (final service in services) {
        debugPrint('   Service: ${service.uuid}');
      }

      final naviSafeService = services.firstWhere(
        (s) =>
            s.uuid.toString().toLowerCase() ==
            naviSafeServiceUuid.toLowerCase(),
        orElse: () => throw Exception(
          'NaviSafe service not found - available services: ${services.map((s) => s.uuid).join(", ")}',
        ),
      );
      debugPrint('✅ NaviSafe service found: ${naviSafeService.uuid}');

      _connectedDevices[deviceId] = device;
      _connectionSubscriptions[deviceId] = device.connectionState.listen(
        (state) {
          if (state == BluetoothConnectionState.disconnected) {
            debugPrint(
              '⚠️ Device $deviceId disconnected - will auto-reconnect',
            );
            _handleDeviceDisconnected(deviceId);

            // Reset connection attempts for auto-reconnect
            if (_connectionAttempts.containsKey(deviceId)) {
              _connectionAttempts[deviceId] = 0;
            }
          } else if (state == BluetoothConnectionState.connected) {
            debugPrint('✅ Device $deviceId connection state: connected');
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

      // Set up characteristic monitoring for position updates
      final positionChar = naviSafeService.characteristics.firstWhere(
        (c) => c.uuid.toString() == positionCharacteristicUuid,
      );
      _positionCharacteristics[deviceId] = positionChar;

      // Subscribe to position updates for real-time location sharing
      await positionChar.setNotifyValue(true);
      positionChar.value.listen((value) {
        if (value.isNotEmpty) {
          try {
            final jsonString = utf8.decode(value);
            final position = PositionData.fromJsonString(jsonString);
            _sharedPositions[deviceId] = position;
            _positionReceivedController.add(position);
            debugPrint(
              '📍 Received position from $deviceId: ${position.latitude}, ${position.longitude}',
            );
            notifyListeners(); // Update UI immediately
          } catch (e) {
            debugPrint('⚠️ Error parsing position data: $e');
          }
        }
      });

      final vehicleDataChar = naviSafeService.characteristics.firstWhere(
        (c) => c.uuid.toString() == vehicleDataCharacteristicUuid,
      );
      _vehicleDataCharacteristics[deviceId] = vehicleDataChar;

      // Subscribe to vehicle data updates
      await vehicleDataChar.setNotifyValue(true);
      vehicleDataChar.value.listen((value) {
        if (value.isNotEmpty) {
          try {
            final jsonString = utf8.decode(value);
            final vehicleData = VehicleData.fromJsonString(jsonString);
            _vehicleDataReceivedController.add(vehicleData);
            debugPrint('🚗 Received vehicle data from $deviceId');
          } catch (e) {
            debugPrint('⚠️ Error parsing vehicle data: $e');
          }
        }
      });

      debugPrint('✅ Device $deviceId fully connected and monitoring');

      // Update the discovered device status to connected
      if (_discoveredDevices.containsKey(deviceId)) {
        final discoveredDevice = _discoveredDevices[deviceId]!;
        _discoveredDevices[deviceId] = NetworkDevice(
          deviceId: discoveredDevice.deviceId,
          deviceName: discoveredDevice.deviceName,
          lastSeen: DateTime.now(),
          connectionStrength: discoveredDevice.connectionStrength,
          status: NetworkDeviceStatus.connected, // Update status
          capabilities: discoveredDevice.capabilities,
        );
      }

      notifyListeners(); // Update UI with new connection count and status
      return true;
    } catch (e) {
      debugPrint('❌ Connect error for $deviceId: $e');

      // Increment connection attempts counter
      _connectionAttempts[deviceId] = (_connectionAttempts[deviceId] ?? 0) + 1;

      // Try to disconnect the device if it's stuck in a bad state
      try {
        final device = _scannedDevices[deviceId];
        if (device != null && device.isConnected) {
          await device.disconnect();
        }
      } catch (disconnectError) {
        debugPrint('⚠️ Error disconnecting device $deviceId: $disconnectError');
      }

      return false;
    }
  }

  /// Broadcast position data to all connected devices with real-time updates
  Future<bool> broadcastPositionData(PositionData data) async {
    if (_connectedDevices.isEmpty) {
      debugPrint('📡 No connected devices to broadcast position');
      return false;
    }

    // Check if position changed significantly (> 1 meter or > 5 degrees heading change)
    if (_lastBroadcastedPosition != null) {
      final distance = _lastBroadcastedPosition!.distanceTo(data);
      final lastHeading = _lastBroadcastedPosition!.heading ?? 0.0;
      final currentHeading = data.heading ?? 0.0;
      final headingDiff = (lastHeading - currentHeading).abs();

      if (distance < 1.0 && headingDiff < 5.0) {
        // Position hasn't changed significantly, skip broadcast to save battery
        return true;
      }
    }

    try {
      int successCount = 0;
      for (final entry in _positionCharacteristics.entries) {
        if (_connectedDevices.containsKey(entry.key)) {
          try {
            await entry.value.write(data.toBytes(), withoutResponse: true);
            successCount++;
          } catch (e) {
            debugPrint('⚠️ Failed to broadcast to device ${entry.key}: $e');
          }
        }
      }

      if (successCount > 0) {
        _lastBroadcastedPosition = data;
        debugPrint('📤 Broadcasted position to $successCount devices');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('MeshNetworkService: Error broadcasting position data: $e');
      return false;
    }
  }

  /// Update current position (for advertising)
  void updateCurrentPosition(PositionData position) {
    _currentPosition = position;
    // Position will be advertised in the next advertising update cycle
  }

  /// Start automatic position broadcasting
  void startPositionBroadcasting(Stream<PositionData> positionStream) {
    positionStream.listen((position) async {
      // Update advertising position
      updateCurrentPosition(position);

      // Legacy GATT broadcasting (kept for backward compatibility if connections exist)
      if (_connectedDevices.isNotEmpty) {
        await broadcastPositionData(position);
      }
    });
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
    _sharedPositions.remove(deviceId); // Remove shared position data

    // Update the discovered device status to offline
    if (_discoveredDevices.containsKey(deviceId)) {
      final discoveredDevice = _discoveredDevices[deviceId]!;
      _discoveredDevices[deviceId] = NetworkDevice(
        deviceId: discoveredDevice.deviceId,
        deviceName: discoveredDevice.deviceName,
        lastSeen: DateTime.now(),
        connectionStrength: discoveredDevice.connectionStrength,
        status: NetworkDeviceStatus.offline, // Update status
        capabilities: discoveredDevice.capabilities,
      );
    }

    _networkStatusController.add('Device disconnected');
    notifyListeners(); // Update UI with new connection count
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
      // Use fixed UUID for all AuraDrive devices to ensure interoperability
      naviSafeServiceGuid = Guid(naviSafeServiceUuid);
      debugPrint(
        'MeshNetworkService: Using fixed NaviSafe service UUID: $naviSafeServiceUuid for AuraDrive compatibility',
      );
    } catch (e) {
      debugPrint('MeshNetworkService: Error initializing service UUID: $e');
    }
  }
}
