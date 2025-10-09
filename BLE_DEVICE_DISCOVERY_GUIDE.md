# AuraDrive BLE Device Discovery & Location Sharing Guide

## 🎯 Overview

This document explains how AuraDrive devices discover each other via BLE and share real-time location data.

## ✅ What Was Fixed

### **Critical Issue: Dynamic Service UUID** 🔴 → 🟢

**PROBLEM**: Each device was generating a different service UUID based on package name, preventing devices from discovering each other.

```dart
// BEFORE (BROKEN):
String naviSafeServiceUuid = '12345678-1234-1234-1234-123456789abc';

Future<void> _generateServiceUuid() async {
  final pkg = await PackageInfo.fromPlatform();
  naviSafeServiceUuid = uid.v5(Uuid.NAMESPACE_URL, pkg.packageName);
  // Each device got different UUID! ❌
}
```

```dart
// AFTER (FIXED):
static const String naviSafeServiceUuid = '12345678-1234-1234-1234-123456789abc';

Future<void> _generateServiceUuid() async {
  naviSafeServiceGuid = Guid(naviSafeServiceUuid);
  // All devices use same UUID! ✅
}
```

**IMPACT**: 
- ✅ All AuraDrive devices now use the **same fixed UUID**
- ✅ Devices can discover each other via BLE scanning
- ✅ Auto-connect works for all AuraDrive apps

---

## 🔄 How It Works

### **Step 1: BLE Advertising** 📡

When the app starts, each device advertises itself:

```dart
// In mesh_network_service.dart - _attemptAdvertising()
await _blePeripheral.start(
  advertiseData: AdvertiseData(
    serviceUuid: '12345678-1234-1234-1234-123456789abc', // FIXED UUID
    localName: 'NaviSafe-A1B2C3D4',                      // Unique device name
    manufacturerId: 0x0000,
    manufacturerData: [app_version_bytes],
  ),
);
```

**What this does**:
- Broadcasts "I'm an AuraDrive device!" to nearby BLE scanners
- Uses service UUID `12345678-1234-1234-1234-123456789abc`
- Advertises with name starting with `NaviSafe-`

### **Step 2: BLE Scanning & Discovery** 🔍

Every 10 seconds, the app scans for nearby devices:

```dart
// Detection logic in startScanning()
final isNaviSafe =
    result.advertisementData.serviceUuids.any(
      (uuid) => uuid.toString().toLowerCase() == naviSafeServiceUuid.toLowerCase(),
    ) ||
    result.advertisementData.localName.startsWith('NaviSafe');
```

**Detection Criteria** (Either one triggers auto-connect):
1. ✅ **Service UUID matches**: `12345678-1234-1234-1234-123456789abc`
2. ✅ **Name starts with**: `NaviSafe-`
3. ✅ **Signal strength**: RSSI ≥ -79 dBm (30%+)

### **Step 3: Auto-Connect** 🔗

When a NaviSafe device is discovered:

```dart
if (isNaviSafe && 
    isNewDevice && 
    !_connectedDevices.containsKey(device.deviceId) &&
    _connectedDevices.length < _maxClusterSize &&
    (_connectionAttempts[device.deviceId] ?? 0) < maxConnectionAttempts) {
  
  debugPrint('🚀 AUTO-CONNECTING to NaviSafe device...');
  connectToDevice(device.deviceId);
}
```

**Connection Process**:
1. Connect to BLE device (30-second timeout)
2. Discover GATT services
3. Find NaviSafe service (`12345678-1234-1234-1234-123456789abc`)
4. Subscribe to position characteristic (`...789abd`)
5. Subscribe to vehicle data characteristic (`...789abe`)
6. Start monitoring for position updates

### **Step 4: Position Broadcasting** 📍

Your device continuously broadcasts its location:

```dart
// Triggered from navigation_screen.dart
meshService.startPositionBroadcasting(gnssService.positionStream);

// In mesh_network_service.dart
void startPositionBroadcasting(Stream<PositionData> positionStream) {
  positionStream.listen((position) async {
    if (_connectedDevices.isNotEmpty) {
      await broadcastPositionData(position);
    }
  });
}
```

**Position Data Format**:
```json
{
  "latitude": 28.1234567,
  "longitude": 77.9876543,
  "altitude": 245.5,
  "accuracy": 8.2,
  "heading": 135.0,
  "speed": 15.5,
  "timestamp": "2025-10-09T10:30:45.123Z"
}
```

**Smart Broadcasting**:
- Only broadcasts when **movement > 1 meter** OR **heading change > 5°**
- Saves battery by avoiding redundant transmissions
- Update frequency: ~500ms when moving

### **Step 5: Receiving Positions** 📥

When a connected device shares its location:

```dart
// Position characteristic subscription
positionChar.value.listen((value) {
  if (value.isNotEmpty) {
    final jsonString = utf8.decode(value);
    final position = PositionData.fromJsonString(jsonString);
    _sharedPositions[deviceId] = position;
    _positionReceivedController.add(position);
    debugPrint('📍 Received position from $deviceId: ${position.latitude}, ${position.longitude}');
    notifyListeners(); // Update UI
  }
});
```

**What happens**:
1. Raw bytes received via BLE characteristic
2. Decoded to JSON string
3. Parsed into `PositionData` object
4. Stored in `_sharedPositions` map
5. UI notified to update markers

### **Step 6: Map Display** 🗺️

Peer vehicles appear on the map in real-time:

```dart
// In navigation_screen.dart - _buildMarkers()
for (final entry in meshService.sharedPositions.entries) {
  final peerPosition = entry.value;
  
  markers.add(
    Marker(
      point: LatLng(peerPosition.latitude, peerPosition.longitude),
      child: Transform.rotate(
        angle: peerHeading * (3.14159 / 180),
        child: Icon(
          Icons.navigation,
          color: distance != null && distance < 50 
            ? Colors.red      // Close - potential collision
            : Colors.green,   // Safe distance
        ),
      ),
    ),
  );
}
```

**Marker Features**:
- 🔵 **Your vehicle**: Blue circle with navigation icon
- 🟢 **Safe peers**: Green markers (distance > 50m)
- 🔴 **Close peers**: Red markers (distance < 50m)
- 🧭 **Heading rotation**: Markers rotate to show direction
- 📏 **Distance display**: Shows meters away from you

---

## 🧪 Testing & Verification

### **Expected Log Output**

#### Device A (Advertising):
```
MeshNetworkService: Initialized successfully
MeshNetworkService: Started advertising as NaviSafe-A1B2C3D4
MeshNetworkService: Using fixed NaviSafe service UUID: 12345678-1234-1234-1234-123456789abc
```

#### Device B (Discovering):
```
MeshNetworkService: Scan found 15 devices
MeshNetworkService: Found device NaviSafe-A1B2C3D4 (RSSI: -65)
MeshNetworkService: Added NaviSafe device NaviSafe-A1B2C3D4 with RSSI -65
🚀 AUTO-CONNECTING to NaviSafe device NaviSafe-A1B2C3D4...
🔗 Connecting to NaviSafe-A1B2C3D4 (XX:XX:XX:XX:XX:XX)...
✅ Connected to NaviSafe-A1B2C3D4
🔍 Discovering services...
✅ NaviSafe service found
✅ Device XX:XX:XX:XX:XX:XX fully connected and monitoring
```

#### Both Devices (Position Sharing):
```
Device A:
📤 Broadcasted position to 1 devices

Device B:
📍 Received position from XX:XX:XX:XX:XX:XX: 28.1234567, 77.9876543
```

### **Troubleshooting**

#### ❌ "No devices found"
**Cause**: Devices not advertising or out of range  
**Fix**:
1. Verify both apps have BLE permissions granted
2. Check location permissions enabled
3. Ensure devices within ~45m range (RSSI > -79 dBm)
4. Restart both apps to trigger advertising

#### ❌ "Device found but not connecting"
**Cause**: Service UUID mismatch or connection timeout  
**Fix**:
1. Verify both apps using **same codebase** with fixed UUID
2. Check logs for "NaviSafe service not found" error
3. Increase connection timeout if in crowded BLE environment
4. Reduce RSSI threshold temporarily for testing: `-85` instead of `-79`

#### ❌ "Connected but no position updates"
**Cause**: GPS not active or broadcast not started  
**Fix**:
1. Verify navigation screen is open (starts broadcasting)
2. Check GPS is enabled and location acquired
3. Ensure `gnssService.positionStream` is emitting data
4. Look for "📡 No connected devices to broadcast position" log

#### ❌ "Markers not showing on map"
**Cause**: UI not updating or positions not stored  
**Fix**:
1. Check `_sharedPositions` map has entries
2. Verify `notifyListeners()` called after position received
3. Confirm `Consumer<MeshNetworkService>` wrapping map widget
4. Debug log `meshService.sharedPositions.length`

---

## 📊 Architecture Flow

```
┌─────────────────┐                    ┌─────────────────┐
│   Device A      │                    │   Device B      │
│   (AuraDrive)   │                    │   (AuraDrive)   │
└────────┬────────┘                    └────────┬────────┘
         │                                      │
         │ 1. Advertise                         │ 1. Advertise
         │    NaviSafe-A1B2C3D4                 │    NaviSafe-B5C6D7E8
         │    UUID: 12345678...                 │    UUID: 12345678...
         ├──────────────────────────────────────┤
         │                                      │
         │ 2. Scan & Discover                   │ 2. Scan & Discover
         │    Found: NaviSafe-B5C6D7E8 ✅       │    Found: NaviSafe-A1B2C3D4 ✅
         │    RSSI: -65 (Good)                  │    RSSI: -68 (Good)
         ├──────────────────────────────────────┤
         │                                      │
         │ 3. Auto-Connect                      │ 3. Auto-Connect
         │    Connect to B ───────────────────→ │    Accept connection
         │                                      │    Connect to A ←───────────
         ├──────────────────────────────────────┤
         │                                      │
         │ 4. Service Discovery                 │ 4. Service Discovery
         │    Find UUID: 12345678... ✅         │    Find UUID: 12345678... ✅
         │    Position Char: ...abd ✅          │    Position Char: ...abd ✅
         │    Vehicle Char: ...abe ✅           │    Vehicle Char: ...abe ✅
         ├──────────────────────────────────────┤
         │                                      │
         │ 5. Position Broadcast (Every 500ms)  │
         │    GPS: 28.123, 77.987               │    GPS: 28.125, 77.989
         │    Heading: 135°, Speed: 15.5 m/s    │    Heading: 270°, Speed: 20.2 m/s
         │    ────────────────────────────────→ │    ←────────────────────────────
         │                                      │
         │ 6. Map Display                       │ 6. Map Display
         │    🔵 Me: 28.123, 77.987             │    🔵 Me: 28.125, 77.989
         │    🟢 Peer B: 28.125, 77.989         │    🟢 Peer A: 28.123, 77.987
         │    Distance: 52m (Safe)              │    Distance: 52m (Safe)
         └──────────────────────────────────────┘
```

---

## 🔧 Configuration

### **Service & Characteristic UUIDs**

```dart
// Service UUID - MUST match on all devices
static const String naviSafeServiceUuid = 
    '12345678-1234-1234-1234-123456789abc';

// Position data characteristic
static const String positionCharacteristicUuid = 
    '12345678-1234-1234-1234-123456789abd';

// Vehicle data characteristic
static const String vehicleDataCharacteristicUuid = 
    '12345678-1234-1234-1234-123456789abe';
```

### **Connection Parameters**

```dart
int _maxClusterSize = 20;              // Max connected devices
static const int minRssiThreshold = -79;  // 30% signal strength
static const int maxConnectionAttempts = 5; // Retry count
const Duration timeout = Duration(seconds: 30); // Connection timeout
```

### **Scanning & Broadcasting**

```dart
static const Duration _scanInterval = Duration(seconds: 10);
static const Duration _reconnectInterval = Duration(seconds: 5);

// Broadcasting threshold
const double minMovementMeters = 1.0;    // Broadcast if moved > 1m
const double minHeadingChangeDegrees = 5.0; // Or heading changed > 5°
```

---

## 📱 UI Indicators

### **MeshNetworkWidget** (Shows connection status)

```dart
Consumer<MeshNetworkService>(
  builder: (context, meshService, _) {
    return Text(
      'Connected: ${meshService.connectedDeviceCount}',
      // Real-time count of connected AuraDrive devices
    );
  },
)
```

### **Map Markers** (Visual feedback)

- **Blue circle**: Your current position
- **Green markers**: Connected devices > 50m away
- **Red markers**: Connected devices < 50m (collision warning)
- **Rotation**: Shows vehicle heading direction

---

## ✅ Checklist for Testing

### On Both Devices:

- [ ] BLE permissions granted
- [ ] Location permissions granted
- [ ] GPS enabled and location acquired
- [ ] App installed from **same codebase** (same UUID)
- [ ] Navigation screen opened (triggers broadcasting)
- [ ] Devices within 45m range (RSSI > -79 dBm)

### Expected Results:

- [ ] Both devices show in discovery list with "NaviSafe-" prefix
- [ ] Auto-connect succeeds within 5-30 seconds
- [ ] "Connected: 1" (or more) shown in mesh network widget
- [ ] Peer markers appear on map
- [ ] Peer markers update position in real-time (~500ms)
- [ ] Markers rotate to show heading
- [ ] Distance shown between vehicles
- [ ] Color changes (green/red) based on proximity

---

## 🚀 Next Steps

1. ✅ **Test with 2 devices** running AuraDrive
2. ✅ **Verify auto-connect** works (check logs)
3. ✅ **Confirm position sharing** (markers on map)
4. ⚠️ **Scale test** with 3-5 devices in mesh
5. 🔄 **Stress test** connection reliability over 30+ minutes

---

**Date**: October 9, 2025  
**Status**: ✅ FIXED - Ready for Testing  
**Priority**: CRITICAL - Core feature for collision detection
