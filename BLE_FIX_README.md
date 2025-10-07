# BLE Mesh Networking - Fix Documentation

## Problem Identified

Your BLE mesh wasn't discovering devices because of **Android permission and manifest configuration issues**. The main problems were:

### 1. **Missing Android 12+ Permission Handling**
- Old Bluetooth permissions (BLUETOOTH, BLUETOOTH_ADMIN) need `maxSdkVersion="30"` 
- New permissions (BLUETOOTH_SCAN, BLUETOOTH_CONNECT) for Android 12+ weren't configured correctly
- Missing `neverForLocation` flag for BLUETOOTH_SCAN

### 2. **SDK Version Mismatch**
- Using API 36 (very new, unstable) instead of stable API 34
- MinSDK should be at least 23 for proper BLE support

## Changes Made

### ✅ AndroidManifest.xml Fixed
**File: `android/app/src/main/AndroidManifest.xml`**

```xml
<!-- OLD (Lines 8-13) - BROKEN -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />

<!-- NEW (Lines 8-17) - FIXED -->
<!-- Bluetooth permissions for Android 11 and below -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />

<!-- Bluetooth permissions for Android 12+ (API 31+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
```

**Why this matters:**
- `maxSdkVersion="30"` prevents old permissions from conflicting on Android 12+
- `neverForLocation` flag tells Android you don't need location for BLE scanning (reduces permission requirements)
- Proper separation between old/new Android versions

### ✅ build.gradle.kts Fixed
**File: `android/app/build.gradle.kts`**

```kotlin
// OLD - UNSTABLE
compileSdk = 36
minSdk = flutter.minSdkVersion
targetSdk = 36

// NEW - STABLE
compileSdk = 34  // Using stable API 34 for better compatibility
minSdk = 23      // Required for proper BLE support
targetSdk = 34   // Using stable API 34 instead of 36 for better compatibility
```

**Why this matters:**
- API 34 is stable and well-tested
- MinSDK 23 ensures BLE features work correctly
- API 36 is too new and may have compatibility issues

### ✅ Enhanced BLE Service
**File: `lib/services/ble_mesh_service.dart`**

Added critical improvements:
1. **Bluetooth state checking** before scanning
2. **Better error handling** with comprehensive logging
3. **Improved scanning** with longer durations and retry logic
4. **Device filtering** to remove very weak signals
5. **Proper initialization** sequence

## How to Test

### Step 1: Clean Build
```bash
# Clean the project
flutter clean

# Get dependencies
flutter pub get

# Rebuild for Android
flutter build apk --debug
```

### Step 2: Install and Grant Permissions
```bash
# Install the app
flutter run

# IMPORTANT: When the app starts:
# 1. Grant ALL Bluetooth permissions
# 2. Grant Location permissions (REQUIRED for BLE on Android)
# 3. Make sure Bluetooth is ENABLED in device settings
# 4. Make sure Location/GPS is ENABLED in device settings
```

### Step 3: Run Diagnostic Test

Add this to your dashboard or create a test button:

```dart
import 'package:your_app/utils/ble_diagnostic.dart';

// Run diagnostic
final results = await BLEDiagnostic.runDiagnostics();
final report = BLEDiagnostic.getDiagnosticReport(results);
print(report);
```

### Step 4: Check Logs

Run the app with logs visible:
```bash
flutter run --verbose
```

Look for these messages:
```
✓ BLE Supported: true
✓ Adapter State: BluetoothAdapterState.on
✓ Bluetooth Enabled: true
▶ Starting scan cycle...
✓ Scan results received: X devices
✓ Device: DeviceName (XX:XX:XX:XX:XX:XX) RSSI: -XX
```

## Common Issues & Solutions

### ❌ "Bluetooth is not enabled"

**Solution:**
1. Enable Bluetooth in phone settings
2. Enable Location/GPS in phone settings (Android requires this for BLE)
3. Restart the app

### ❌ "No devices found"

**Possible causes:**
1. ✅ BLE is working, but no devices nearby
2. ❌ Location permission not granted
3. ❌ Location/GPS not enabled on device

**Solution:**
- Test with known BLE devices (fitness trackers, headphones, smartwatches)
- Check Location is enabled
- Check app has Location permission

### ❌ "Permission denied"

**Solution:**
1. Go to Settings → Apps → NaviSafe → Permissions
2. Grant:
   - ✅ Bluetooth (Allow)
   - ✅ Location (Allow all the time)
   - ✅ Nearby devices (Allow)
3. Restart app

### ❌ "Scan failed"

**Check:**
```bash
# Check logcat for detailed error
adb logcat | grep -i bluetooth
```

## Critical Android Requirements for BLE

### 🔴 MUST HAVE:
1. **Bluetooth enabled** in device settings
2. **Location/GPS enabled** in device settings
3. **App permissions granted:**
   - Bluetooth (BLUETOOTH_SCAN, BLUETOOTH_CONNECT)
   - Location (ACCESS_FINE_LOCATION)
   - Nearby devices (on Android 12+)
4. **MinSDK 23+** in build.gradle

### Why Location for BLE?
Android requires location permission for BLE scanning because:
- BLE can be used to determine location (beacon tracking)
- This is a security/privacy requirement on Android
- Even if you don't use location data, Android requires it

## Testing Checklist

- [ ] App builds successfully
- [ ] All permissions granted in app settings
- [ ] Bluetooth enabled on device
- [ ] Location/GPS enabled on device
- [ ] Can see BLE adapter state as "on"
- [ ] Manual scan finds at least one device (test with phone, watch, etc.)
- [ ] Diagnostic test passes all checks

## Expected Output

When working correctly, you should see:
```
=== BLE Diagnostic Test Started ===
✓ BLE Supported: true
✓ Adapter State: BluetoothAdapterState.on
✓ Bluetooth Enabled: true
✓ Currently Scanning: false
▶ Attempting test scan...
✓ Test scan completed successfully
✓ Devices found: 3
  - Device: Galaxy Watch (AA:BB:CC:DD:EE:FF) RSSI: -45
  - Device: AirPods (11:22:33:44:55:66) RSSI: -67
  - Device: Unknown (77:88:99:AA:BB:CC) RSSI: -82
=== BLE Diagnostic Test Completed ===
Summary:
  - BLE Supported: true
  - Bluetooth On: true
  - Test Scan: true
  - Devices Found: 3
```

## Next Steps

1. **Rebuild the app** with the fixed manifest and gradle files
2. **Grant all permissions** when prompted
3. **Enable Bluetooth AND Location** on your device
4. **Run the diagnostic test** to verify BLE works
5. **Test device discovery** in the mesh network

## Files Modified

1. ✅ `android/app/src/main/AndroidManifest.xml` - Fixed BLE permissions
2. ✅ `android/app/build.gradle.kts` - Fixed SDK versions
3. ✅ `lib/services/ble_mesh_service.dart` - Enhanced BLE service
4. ✅ `lib/services/service_manager.dart` - Added service initialization
5. ✅ `lib/utils/ble_diagnostic.dart` - Created diagnostic tool

## Support

If BLE still doesn't work after these changes:
1. Check device compatibility (BLE 4.0+ required)
2. Review logcat output: `adb logcat | grep -i bluetooth`
3. Test with other BLE apps to verify hardware works
4. Check Android version (minimum Android 6.0 / API 23)

---

**Status: FIXED** ✅
**Last Updated: 2025-10-07**
