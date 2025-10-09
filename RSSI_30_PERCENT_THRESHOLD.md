# RSSI Threshold Update: 30% Signal Strength Minimum

## Change Summary

Updated minimum RSSI threshold from **-90 dBm** to **-79 dBm** to only connect to devices with **≥30% network signal strength**.

## Technical Details

### RSSI to Signal Strength Conversion
RSSI (Received Signal Strength Indicator) typically ranges from -30 dBm (excellent) to -100 dBm (unusable):

| RSSI (dBm) | Signal % | Quality | Range (approx) |
|------------|----------|---------|----------------|
| -30 to -50 | 100%     | Excellent | 0-10m |
| -50 to -60 | 75-99%   | Very Good | 10-20m |
| -60 to -70 | 50-74%   | Good | 20-35m |
| -70 to -80 | 25-49%   | Fair | 35-50m |
| **-79** | **~30%** | **Minimum Acceptable** | **~45m** |
| -80 to -90 | 10-24%   | Poor | 50-65m |
| -90 to -100 | 0-9%    | Very Poor/Unusable | 65m+ |

### Code Change

**File**: `lib/services/mesh_network_service.dart`  
**Line**: 133

```dart
// BEFORE:
static const int minRssiThreshold = -90; // More lenient signal threshold

// AFTER:
static const int minRssiThreshold = -79; // 30% signal strength threshold
```

## Impact Analysis

### ✅ Benefits

1. **Higher Connection Reliability**
   - Devices below 30% often experience:
     - Frequent disconnections
     - High packet loss (>20%)
     - Slow data transmission
     - Unreliable position sharing
   
2. **Reduced Connection Timeouts**
   - Weak signals take longer to establish connection
   - Timeout rate decreases dramatically above -80 dBm
   
3. **Better Battery Efficiency**
   - BLE consumes more power maintaining weak connections
   - Constant reconnection attempts drain battery
   
4. **Improved Data Quality**
   - Position updates more reliable
   - Real-time location sharing more accurate
   - Fewer corrupted/incomplete packets

### ⚠️ Trade-offs

1. **Reduced Device Discovery Range**
   - Previous: ~60-65m range (-90 dBm)
   - Current: ~45m range (-79 dBm)
   - **Impact**: ~15-20m reduction in effective mesh range
   
2. **Fewer Devices in Discovery List**
   - Based on previous logs (22-32 devices found):
     - ~40-50% of devices were between -79 to -90 dBm
     - Estimated reduction: 10-15 devices filtered out
   
3. **Stricter Connection Requirements**
   - Users need to be physically closer for auto-connect
   - Urban environments with obstacles may see fewer connections

## Expected Behavior Changes

### Before (-90 dBm threshold):
```
MeshNetworkService: Found device Unknown Device 71:F (RSSI: -90)
MeshNetworkService: Added BLE device Unknown Device 71:F with RSSI -90 ✅
🚀 AUTO-CONNECTING to device...
[FBP] connection timeout ❌ (weak signal)
```

### After (-79 dBm threshold):
```
MeshNetworkService: Found device Unknown Device 71:F (RSSI: -90)
MeshNetworkService: Rejected device - RSSI -90 below threshold -79 ❌

MeshNetworkService: Found device Unknown Device 39:F (RSSI: -63)
MeshNetworkService: Added BLE device Unknown Device 39:F with RSSI -63 ✅
🚀 AUTO-CONNECTING to device...
✅ Connected successfully (strong signal)
```

## Testing Observations

From your previous logs, here's what will change:

### Devices Previously Accepted (Now REJECTED):
- Unknown Device 71:F (RSSI: -90) ❌
- Unknown Device DB:9 (RSSI: -89) ❌
- Unknown Device 1D:E (RSSI: -85) ❌
- Unknown Device 7E:8 (RSSI: -82) ❌

### Devices Still Accepted:
- Unknown Device 3A:3 (RSSI: -46) ✅ Excellent
- Unknown Device 5C:1 (RSSI: -50) ✅ Excellent
- Unknown Device 61:B (RSSI: -58) ✅ Very Good
- Unknown Device 39:F (RSSI: -63) ✅ Good
- Unknown Device 33:8 (RSSI: -68) ✅ Good
- Unknown Device 31:1 (RSSI: -74) ✅ Fair
- Unknown Device 3C:E (RSSI: -74) ✅ Fair
- Unknown Device 03:D (RSSI: -78) ✅ Fair (just above threshold)

## Recommendation: Dynamic Threshold (Future Enhancement)

Consider implementing adaptive RSSI thresholds based on environment:

```dart
int _calculateMinRssi(int deviceCount, double avgRssi) {
  if (deviceCount > 20) {
    // Crowded environment - be more selective
    return -75; // ~40% signal
  } else if (avgRssi < -85) {
    // Sparse environment - be more lenient
    return -85; // ~20% signal
  }
  return -79; // Default 30%
}
```

## Configuration

If you want to adjust the threshold:

**More Strict** (40-50% signal, ~30-40m range):
```dart
static const int minRssiThreshold = -70;
```

**Current** (30% signal, ~45m range):
```dart
static const int minRssiThreshold = -79; // ✅ Current setting
```

**More Lenient** (20% signal, ~50-55m range):
```dart
static const int minRssiThreshold = -85;
```

**Original** (14% signal, ~60-65m range):
```dart
static const int minRssiThreshold = -90;
```

## Testing Checklist

- [ ] Verify devices below -79 dBm are rejected in logs
- [ ] Confirm connection success rate improves (fewer timeouts)
- [ ] Test effective range in open area (~45m expected)
- [ ] Monitor "Connected: X" counter with strong signals only
- [ ] Validate position sharing reliability
- [ ] Check battery consumption over 30-minute session

---

**Date**: October 9, 2025  
**Status**: ✅ Implemented  
**Priority**: MEDIUM - Quality over Quantity
**Rationale**: Better to have 2-3 solid connections than 10 unreliable ones
