# Permission Testing Guide

## Issues Fixed

### 1. Bluetooth Permission Runtime Handling
- **Problem**: App was checking Bluetooth permissions incorrectly, not accounting for different Android versions
- **Fix**: Updated `MeshNetworkService._checkPermissions()` to properly handle Android 12+ vs legacy permissions
- **Added**: Comprehensive debug logging for permission status tracking

### 2. BLASTBufferQueue Buffer Overflow
- **Problem**: FlutterMap was being rebuilt too frequently causing graphics buffer exhaustion
- **Fix**: Added map controller, throttled position updates (500ms), and reduced unnecessary map redraws
- **Result**: Should reduce `BLASTBufferQueue: Can't acquire next buffer` errors

## Testing Steps

### Test on Different Android Versions

#### Android 11 and below:
1. Install app on device with Android 11 or below
2. Check that legacy Bluetooth permission (`android.permission.BLUETOOTH`) is requested and granted
3. Look for debug logs: `"MeshNetworkService: Legacy Bluetooth permission granted"`

#### Android 12+ (API 31+):
1. Install app on device with Android 12 or higher
2. Check that new Bluetooth permissions are requested:
   - `BLUETOOTH_SCAN`
   - `BLUETOOTH_CONNECT` 
   - `BLUETOOTH_ADVERTISE`
3. Look for debug logs: `"MeshNetworkService: New Bluetooth permissions (Android 12+) granted"`

### Debug Logs to Monitor

Enable debug logging and look for these messages:

**Permission Checking:**
```
MeshNetworkService: Checking permissions...
MeshNetworkService: Location permission granted
MeshNetworkService: Bluetooth scan permission: PermissionStatus.granted
MeshNetworkService: Bluetooth connect permission: PermissionStatus.granted
MeshNetworkService: Bluetooth advertise permission: PermissionStatus.granted
MeshNetworkService: New Bluetooth permissions (Android 12+) granted
MeshNetworkService: All permissions granted
```

**Permission Request (from UI):**
```
PermissionsScreen: Requesting Bluetooth permissions...
PermissionsScreen: Requesting new Bluetooth permissions (Android 12+)...
PermissionsScreen: Scan status: PermissionStatus.granted
PermissionsScreen: Connect status: PermissionStatus.granted
PermissionsScreen: Advertise status: PermissionStatus.granted
PermissionsScreen: All Bluetooth permissions granted: true
```

### Performance Testing

**BLASTBufferQueue Issues:**
1. Navigate to dashboard screen with map
2. Scroll/fling on map repeatedly
3. Move around to trigger GPS updates
4. Monitor logs for reduction in `BLASTBufferQueue` errors

**Expected Improvements:**
- Less frequent `BLASTBufferQueue: Can't acquire next buffer` errors
- Smoother map animations during GPS updates
- Reduced UI thread blocking

### Test Commands

```bash
# Monitor logs during testing
adb logcat | grep -E "(MeshNetworkService|PermissionsScreen|BLASTBufferQueue)"

# Filter for permission-related logs only
adb logcat | grep -E "(MeshNetworkService.*permission|PermissionsScreen.*permission)"

# Filter for buffer-related issues
adb logcat | grep "BLASTBufferQueue"
```

## Expected Results

✅ **Bluetooth permissions should work on all Android versions**
✅ **Reduced BLASTBufferQueue errors during map usage**
✅ **Comprehensive logging for debugging permission issues**
✅ **Smoother map performance during GPS updates**

## Troubleshooting

If permissions still fail:
1. Check if device has Bluetooth hardware: `PackageManager.hasSystemFeature(BLUETOOTH_LE)`
2. Verify Bluetooth is enabled: `BluetoothAdapter.isEnabled()`
3. Check for permission rationale: App settings → Permissions
4. Try clearing app data and reinstalling

If BLASTBufferQueue errors persist:
1. Reduce map update frequency in `_mapUpdateThrottle` 
2. Check for other UI components causing excessive redraws
3. Consider using `RepaintBoundary` widgets around map components