# Speed Display Improvements - Google Maps Style

## Overview
The speed display has been enhanced to provide accurate, real-time speed readings similar to Google Maps navigation.

## Key Improvements

### 1. **Accurate GPS Speed Reading**
- Uses actual GPS speed data from `Position.speed` (in m/s)
- Converts to km/h using precise formula: `speed_kmh = speed_ms × 3.6`
- Filters invalid speeds (negative values or > 200 m/s)
- Filters GPS noise for stationary vehicles (< 1 km/h threshold)

### 2. **Enhanced Location Settings**
```dart
LocationSettings(
  accuracy: LocationAccuracy.bestForNavigation,
  distanceFilter: 0,  // Update on any movement
  timeLimit: Duration(seconds: 5),  // Fast updates
)
```

### 3. **Visual Feedback**
- **Border Colors:**
  - 🔴 Red: Speed > 80 km/h (speeding alert)
  - 🟢 Green: Moving (speed ≥ 1 km/h)
  - ⚪ Grey: Stationary (speed < 1 km/h)

- **GPS Accuracy Indicator:**
  - 🟢 "GPS High": Accuracy < 10m
  - 🟡 "GPS Good": Accuracy 10-20m
  - 🟠 "GPS Low": Accuracy > 20m
  - ⚪ "No GPS": No position data

### 4. **Google Maps Style Display**
- Large 52px font for easy reading
- Integer display (no decimals) like Google Maps
- Compact "km/h" label
- Dark gradient background with shadows
- Positioned at bottom-left (above footer)

## How It Works

### Speed Calculation Flow
```
GPS Position Update
    ↓
Extract speed (m/s)
    ↓
Validate (0 ≤ speed < 200 m/s)
    ↓
Convert to km/h (× 3.6)
    ↓
Round to integer
    ↓
Display
```

### Update Frequency
- **Real-time updates** via `Consumer<GnssService>`
- GPS updates on any movement (`distanceFilter: 0`)
- Automatic re-render when position changes
- Debug logging for troubleshooting

## Debug Output
The speed display includes debug logging:
```
🚗 Speed: 5.50 m/s = 19.8 km/h → Display: 20 km/h
⚠️ No GPS position data available
```

## Troubleshooting

### Speed Not Showing?
1. **Check GPS permissions**: Settings → Apps → AuraDrive → Permissions → Location
2. **Enable high accuracy GPS**: Settings → Location → Mode → High accuracy
3. **Check debug output**: Look for "Speed:" messages in console
4. **Verify GPS signal**: Check the accuracy indicator shows "GPS High" or "GPS Good"

### Speed Inaccurate?
1. **Wait for GPS lock**: Initial readings may be unstable
2. **Check accuracy**: GPS accuracy < 20m recommended
3. **Move steadily**: GPS speed is most accurate during constant motion
4. **Avoid tunnels/buildings**: GPS requires clear sky view

### Speed Updates Slowly?
1. **Check location settings**: Should use `bestForNavigation`
2. **Verify GNSS service**: Check initialization in logs
3. **Battery optimization**: Disable battery optimization for AuraDrive
4. **Background restrictions**: Allow app to run in background

## Technical Details

### Position Data Flow
```
GnssService (Provider)
    ↓ Stream
NavigationScreen (Consumer)
    ↓ Build
SpeedDisplay Widget
```

### Accuracy Thresholds
- **High accuracy**: < 10 meters (ideal for navigation)
- **Good accuracy**: 10-20 meters (acceptable)
- **Low accuracy**: > 20 meters (may be inaccurate)

### Speed Validation
- Minimum: 0 m/s (stationary)
- Maximum: 200 m/s (≈ 720 km/h, sanity check)
- Noise filter: < 1 km/h treated as stationary
- Invalid speeds (negative): Replaced with 0

## Configuration

### Speed Alert Threshold
Change speeding threshold in `navigation_screen.dart`:
```dart
color: speedKmh > 80  // Change 80 to desired limit
    ? Colors.red[400]!
    : ...
```

### Movement Threshold
Change minimum speed for "moving" status:
```dart
final isMoving = speedKmh >= 1.0;  // Change 1.0 to desired threshold
```

### Update Frequency
Modify in `gnss_service.dart`:
```dart
distanceFilter: 0,  // 0 = update always, >0 = update every X meters
```

## Performance

### Battery Impact
- Uses GPS continuously when navigation active
- Optimized with `bestForNavigation` mode
- Updates only on position change
- No unnecessary calculations

### CPU Usage
- Lightweight calculations (multiplication, rounding)
- Consumer pattern ensures efficient rebuilds
- No polling or timers required

## Future Enhancements
- [ ] Average speed calculation
- [ ] Speed limit warnings from map data
- [ ] Speed history graph
- [ ] Export speed data
- [ ] Customizable speed units (mph/km/h)
- [ ] Speed smoothing algorithm for cleaner readings
