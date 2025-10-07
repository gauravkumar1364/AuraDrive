# BLE Automatic Connection Setup Guide

## 🎯 Current Status

**✅ FIXED Issues:**
1. ✅ Collision detection working perfectly (Sharp RIGHT turn detected!)
2. ✅ GNSS positioning active
3. ✅ Android manifest permissions corrected
4. ✅ MinSDK set to 23 for proper BLE support

**⚠️ Issue Found:**
```
D/permissions_handler( 3014): Bluetooth permission missing in manifest
I/flutter ( 3014): MeshNetworkService: Permission denied: Permission.bluetooth
```

**Root Cause:** The `permission_handler` plugin was checking for legacy permission declarations that weren't properly configured for Android 12+.

---

## 🔧 Fixes Applied

### 1. Android Manifest (FIXED)

**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    
    <!-- Bluetooth permissions for Android 11 and below -->
    <uses-permission android:name="android.permission.BLUETOOTH" 
        android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" 
        android:maxSdkVersion="30" />
    
    <!-- Bluetooth permissions for Android 12+ (API 31+) -->
    <!-- IMPORTANT: Dual declaration for permission_handler compatibility -->
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" 
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN"
        tools:targetApi="s"
        android:usesPermissionFlags="neverForLocation" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
    
    <!-- Location required for BLE on Android -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
</manifest>
```

**Why this works:**
- Added `xmlns:tools` namespace for Android tools attributes
- Dual `BLUETOOTH_SCAN` declarations: one for API 31-32, one with `neverForLocation` for 33+
- Properly scoped legacy permissions with `maxSdkVersion`

### 2. Build Configuration (FIXED)

**File:** `android/app/build.gradle.kts`

```kotlin
defaultConfig {
    applicationId = "com.example.project"
    minSdk = 23  // Required for BLE + permission_handler
    targetSdk = 34  // Stable API
    compileSdk = 36
}
```

**Why minSdk 23:**
- Full BLE 4.2 support
- Proper runtime permissions (Android 6.0+)
- Required for `permission_handler` plugin
- Android 12+ Bluetooth permission handling

---

## 📱 Step-by-Step Setup

### Step 1: Clean Rebuild (REQUIRED)

```powershell
# In your AuraDrive directory
flutter clean
flutter pub get
flutter build apk --debug
```

**Why:** Manifest changes require a full rebuild to take effect.

### Step 2: Uninstall Old App

```powershell
# Remove the old app completely
adb uninstall com.example.project

# Or manually on device:
# Settings → Apps → NaviSafe → Uninstall
```

**Why:** Permission changes don't update on app upgrades, only clean installs.

### Step 3: Install Fresh Build

```powershell
flutter install
# or
flutter run
```

### Step 4: Grant Permissions

When the app launches, you'll see permission requests. Grant ALL of these:

1. ✅ **Location** → Allow all the time
2. ✅ **Bluetooth** → Allow
3. ✅ **Nearby devices** → Allow (Android 12+)
4. ✅ **Notifications** → Allow

**Manual verification:**
```
Settings → Apps → NaviSafe → Permissions

Should show:
✅ Location: Allowed all the time
✅ Nearby devices: Allowed
✅ Physical activity: Allowed
✅ Notifications: Allowed
```

### Step 5: Enable Required Settings

Make sure these are ON:
- ✅ Bluetooth (in Quick Settings)
- ✅ Location/GPS (in Quick Settings)
- ✅ Wi-Fi (recommended for better performance)

---

## 🚀 Using the New BLE Auto-Connect Service

### Basic Usage

```dart
import 'package:auradrive/services/ble_auto_connect_service.dart';

// Initialize the service
final bleService = BLEAutoConnectService();

// Start automatic connection
await bleService.initialize();
await bleService.startAutoConnect();

// Listen to discovered devices
bleService.devicesStream.listen((devices) {
  print('Discovered ${devices.length} devices');
  for (final device in devices.values) {
    print('  - ${device.name}: ${device.rssi} dBm, Connected: ${device.isConnected}');
  }
});

// Listen to connection events
bleService.connectionEventStream.listen((event) {
  if (event.startsWith('connected:')) {
    final deviceId = event.split(':')[1];
    print('Device connected: $deviceId');
  } else if (event.startsWith('disconnected:')) {
    final deviceId = event.split(':')[1];
    print('Device disconnected: $deviceId');
  }
});

// Listen to received data
bleService.dataStream.listen((data) {
  print('Received data from ${data['deviceId']}: $data');
});

// Send data to a specific device
await bleService.sendData('device_id', {
  'type': 'position',
  'lat': 28.6139,
  'lon': 77.2090,
  'speed': 15.5,
});

// Broadcast data to all connected devices
await bleService.broadcastData({
  'type': 'alert',
  'message': 'Sharp RIGHT turn detected',
  'severity': 'medium',
});

// Get statistics
final stats = bleService.getStatistics();
print('Connected devices: ${stats['connectedDevices']}');
print('Discovered devices: ${stats['discoveredDevices']}');
```

---

## 🔄 How Auto-Connect Works

### Discovery Phase
1. **Continuous scanning** every 10 seconds
2. **RSSI filtering**: Only devices with signal > -85 dBm
3. **AuraDrive detection**: Looks for custom service UUID `6e400001-b5a3-f393-e0a9-e50e24dcca9e`

### Auto-Connection Phase
1. **Strong signal devices** (RSSI > -70 dBm) are auto-connected
2. **Max 10 devices** connected simultaneously
3. **15-second timeout** per connection attempt

### Reconnection Phase
1. **Disconnected devices** added to reconnect queue
2. **5-second delay** before reconnection attempt
3. **Automatic retry** if device is still in range

### Data Exchange
- **Notify characteristic**: `6e400003-b5a3-f393-e0a9-e50e24dcca9e` (receive data)
- **Write characteristic**: `6e400002-b5a3-f393-e0a9-e50e24dcca9e` (send data)
- **Format**: JSON over UTF-8

---

## 🏗️ Integration with Dashboard

### Add to Dashboard Screen

```dart
import 'package:auradrive/services/ble_auto_connect_service.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late BLEAutoConnectService _bleService;
  
  @override
  void initState() {
    super.initState();
    _bleService = BLEAutoConnectService();
    _initializeBLE();
  }
  
  Future<void> _initializeBLE() async {
    final success = await _bleService.initialize();
    if (success) {
      await _bleService.startAutoConnect();
    } else {
      // Show error dialog
      _showBLEErrorDialog();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AuraDrive'),
        actions: [
          // BLE Status Indicator
          StreamBuilder<int>(
            initialData: 0,
            builder: (context, snapshot) {
              final connectedCount = _bleService.connectedDeviceCount;
              return IconButton(
                icon: Badge(
                  label: Text('$connectedCount'),
                  child: Icon(
                    connectedCount > 0 ? Icons.bluetooth_connected : Icons.bluetooth,
                    color: connectedCount > 0 ? Colors.green : Colors.grey,
                  ),
                ),
                onPressed: _showBLEDevices,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // BLE Status Card
          _buildBLEStatusCard(),
          
          // Collision Alerts (working!)
          _buildCollisionAlertsCard(),
          
          // Rest of dashboard...
        ],
      ),
    );
  }
  
  Widget _buildBLEStatusCard() {
    return StreamBuilder<Map<String, BLEDevice>>(
      stream: _bleService.devicesStream,
      builder: (context, snapshot) {
        final devices = snapshot.data?.values.toList() ?? [];
        final connected = devices.where((d) => d.isConnected).length;
        
        return Card(
          child: ListTile(
            leading: Icon(
              connected > 0 ? Icons.bluetooth_connected : Icons.bluetooth_searching,
              color: connected > 0 ? Colors.green : Colors.orange,
            ),
            title: Text('BLE Mesh Network'),
            subtitle: Text('$connected connected, ${devices.length} discovered'),
            trailing: _bleService.isScanning 
                ? CircularProgressIndicator() 
                : Icon(Icons.check_circle, color: Colors.green),
            onTap: _showBLEDevices,
          ),
        );
      },
    );
  }
  
  void _showBLEDevices() {
    showModalBottomSheet(
      context: context,
      builder: (context) => BLEDevicesSheet(bleService: _bleService),
    );
  }
  
  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }
}
```

### BLE Devices Sheet

```dart
class BLEDevicesSheet extends StatelessWidget {
  final BLEAutoConnectService bleService;
  
  const BLEDevicesSheet({required this.bleService});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text('BLE Devices', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<Map<String, BLEDevice>>(
              stream: bleService.devicesStream,
              builder: (context, snapshot) {
                final devices = snapshot.data?.values.toList() ?? [];
                
                if (devices.isEmpty) {
                  return Center(child: Text('No devices found'));
                }
                
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: Icon(
                        device.isConnected 
                            ? Icons.bluetooth_connected 
                            : Icons.bluetooth,
                        color: device.isConnected ? Colors.green : Colors.grey,
                      ),
                      title: Text(device.name),
                      subtitle: Text(
                        'RSSI: ${device.rssi} dBm\n'
                        'Sent: ${device.messagesSent}, Received: ${device.messagesReceived}',
                      ),
                      trailing: device.isConnected
                          ? Chip(label: Text('Connected'), backgroundColor: Colors.green)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🧪 Testing

### Test 1: Permission Verification

```powershell
# Run app and check logs
flutter run --verbose | Select-String "Permission"

# Should see:
# ✅ All permissions granted
# ✅ No "Permission denied" errors
```

### Test 2: BLE Discovery

```powershell
# Check BLE scanning logs
flutter run | Select-String "BLE Auto Connect"

# Should see:
# ✅ BLE Auto Connect: Service initialized successfully
# ✅ BLE Auto Connect: Auto-connect started
# ✅ BLE Auto Connect: Scan cycle completed. Found X devices
# ✅ BLE Auto Connect: Discovered device: ...
```

### Test 3: Two-Device Connection

**Setup:**
1. Install AuraDrive on TWO phones
2. Grant all permissions on both
3. Keep devices within 10 meters

**Expected:**
- Both apps should discover each other
- Auto-connection initiated
- Data exchange working
- Connection events logged

---

## 📊 Service UUIDs

### AuraDrive Custom UUIDs

```
Service UUID:  6e400001-b5a3-f393-e0a9-e50e24dcca9e
Write Char:    6e400002-b5a3-f393-e0a9-e50e24dcca9e
Notify Char:   6e400003-b5a3-f393-e0a9-e50e24dcca9e
```

**Note:** These are Nordic UART Service (NUS) compatible UUIDs, widely supported.

---

## ⚙️ Configuration Options

### Adjust in `ble_auto_connect_service.dart`:

```dart
// Connection limits
static const int maxAutoConnectDevices = 10;  // Max simultaneous connections

// Timing
static const int reconnectDelay = 5;  // Seconds between reconnect attempts
static const int connectionTimeout = 15;  // Seconds to wait for connection

// Signal strength
static const int rssiThreshold = -85;  // Minimum RSSI to consider device
static const int strongRssiThreshold = -70;  // RSSI for auto-connect
```

### For more devices:
```dart
static const int maxAutoConnectDevices = 20;  // Increase limit
```

### For weaker signals:
```dart
static const int rssiThreshold = -95;  // Accept weaker signals
static const int strongRssiThreshold = -80;  // Lower auto-connect threshold
```

### For faster reconnection:
```dart
static const int reconnectDelay = 3;  // Faster retry
```

---

## 🐛 Troubleshooting

### Issue: "Bluetooth permission missing in manifest"

**Solution:**
1. Clean build: `flutter clean`
2. Uninstall app completely
3. Rebuild: `flutter build apk --debug`
4. Reinstall fresh

### Issue: No devices discovered

**Check:**
1. ✅ Bluetooth enabled on device
2. ✅ Location/GPS enabled
3. ✅ All permissions granted
4. ✅ Another BLE device nearby (test with phone/watch)

**Logs to check:**
```bash
adb logcat | grep -i bluetooth
```

### Issue: Permission denied at runtime

**Solution:**
```dart
// Add manual permission request before BLE init
import 'package:permission_handler/permission_handler.dart';

Future<void> requestAllPermissions() async {
  await [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.bluetoothAdvertise,
    Permission.location,
  ].request();
}
```

### Issue: Auto-connect not working

**Check:**
1. Device advertising AuraDrive service UUID?
2. RSSI strong enough? (check `strongRssiThreshold`)
3. Already at max connections? (check `maxAutoConnectDevices`)

---

## 📈 Performance Tips

1. **Battery optimization**: Adjust scan frequency in production
2. **Connection limits**: Keep maxAutoConnectDevices ≤ 10 for stability
3. **RSSI filtering**: Higher threshold = fewer connections = better performance
4. **Data payload**: Keep JSON messages < 512 bytes for BLE MTU limits

---

## 🎉 Success Indicators

When everything is working, you should see:

```
✅ BLE Auto Connect: Service initialized successfully
✅ BLE Auto Connect: Auto-connect started
✅ BLE Auto Connect: Scan cycle completed. Found X devices
✅ BLE Auto Connect: Discovered device: Phone_Name (RSSI: -65 dBm)
✅ BLE Auto Connect: Attempting auto-connect to device_id
✅ BLE Auto Connect: Successfully connected to device_id
✅ BLE Auto Connect: Received data from device_id: position, speed, heading
✅ BLE Auto Connect: Data sent to device_id
✅ BLE Auto Connect: Broadcast sent to 3/3 devices
```

---

**Last Updated:** October 7, 2025  
**Status:** ✅ READY TO TEST  
**Version:** 2.0
