# Location Testing Guide

## Overview
AuraDrive now includes a **simulated location service** for testing on desktop (Windows, macOS, Linux) and emulators without GPS hardware.

## How It Works

### Automatic Detection
The app automatically detects if it's running on:
- ✅ **Desktop** (Windows/macOS/Linux) → Uses simulated location
- ✅ **Emulator without GPS** → Falls back to simulated location
- ✅ **Real Device** → Uses actual GPS

### Simulated Location Features

🚗 **Realistic Movement**
- Starts at Delhi, India (28.6139°N, 77.2090°E)
- Simulates vehicle movement at ~36 km/h (10 m/s)
- Random speed variations (±5 m/s)
- Random heading changes (±30°)
- Updates every second

📍 **Realistic Data**
- Latitude & Longitude that actually moves
- Speed and heading
- Accuracy (5-15 meters)
- Altitude (50-70 meters)
- Timestamp

## Console Output

When running on desktop, you'll see:
```
🖥️ Running on desktop - using simulated location
🚗 Simulated Location Service initialized
📍 Starting at: 28.6139, 77.2090
🎬 Started simulated location updates
```

If real GPS fails on mobile:
```
⚠️ Falling back to simulated location
```

## Testing on Different Platforms

### Windows (Your Current Platform)
```bash
flutter run -d windows
```
- **Result**: Uses simulated location automatically ✅
- **Console**: Shows simulated location messages
- **Map**: Vehicle appears and moves in Delhi

### Android Emulator
```bash
flutter run
```
- **Result**: Depends on emulator GPS settings
- **Fallback**: Uses simulation if GPS unavailable
- **Extended Controls**: Can also set location in emulator

### Real Android Device
```bash
flutter run
```
- **Result**: Uses real GPS
- **Permissions**: Requests location permission
- **Requirement**: Must grant location access

### iOS Simulator
```bash
flutter run
```
- **Result**: Can simulate location via Xcode
- **Fallback**: Uses our simulation if needed

## Customizing Simulation

### Change Starting Position
To modify the starting location, edit `simulated_location_service.dart`:

```dart
// Line 10-11
double _latitude = 28.6139;  // Change to your latitude
double _longitude = 77.2090; // Change to your longitude
```

Popular locations:
- **New York**: 40.7128, -74.0060
- **London**: 51.5074, -0.1278
- **Tokyo**: 35.6762, 139.6503
- **Mumbai**: 19.0760, 72.8777

### Change Speed/Heading
```dart
// Line 12-13
double _speed = 10.0;    // m/s (36 km/h)
double _heading = 45.0;  // degrees (northeast)
```

### Change Update Frequency
```dart
// Line 32-33
_timer = Timer.periodic(const Duration(seconds: 1), (timer) {
  // Change 'seconds: 1' to update faster/slower
});
```

## Programmatic Control

You can also control simulation from code:

```dart
final gnssService = GnssService();
await gnssService.initialize();

// Access the simulated service (if using simulation)
// Set custom position
gnssService._simulatedLocation.setStartPosition(40.7128, -74.0060);

// Set movement
gnssService._simulatedLocation.setMovementParams(
  speed: 20.0,  // 72 km/h
  heading: 90.0, // East
);
```

## Troubleshooting

### No Location on Windows
**Problem**: Map doesn't show location
**Solution**: Check console for `🚗 Simulated Location Service initialized`
- If missing, check GNSS service initialization
- Restart the app

### Permission Errors on Real Device
**Problem**: "Location permissions denied"
**Solution**: 
1. Go to device Settings
2. Apps → AuraDrive
3. Permissions → Location
4. Enable "Allow all the time"

### Emulator GPS Not Working
**Problem**: Emulator shows no location
**Solution**:
1. Extended Controls (⋮ icon)
2. Location tab
3. Set coordinates manually
**OR** let app use simulation automatically

## Verifying Location Works

### Check Console
Look for:
```
🖥️ Running on desktop - using simulated location
📍 Starting at: 28.6139, 77.2090
🎬 Started simulated location updates
GnssService: Started positioning
```

### Check Map
- Blue dot appears on map (your vehicle)
- Dot moves over time
- Position updates in real-time
- Speed and heading data shown

### Check Status Bar
Bottom status bar shows:
- **GNSS**: Satellite count (simulated: 8 sats)
- **Network**: Connected devices
- **Safety**: Active alerts

## Production Deployment

### For Release Builds
The simulation automatically disables on real devices:
```dart
_useSimulation = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
```

### Mobile Release (Android/iOS)
- ✅ Uses real GPS
- ✅ No simulation code runs
- ✅ Production-ready

## Benefits

✅ **Test Without GPS**
- Develop on Windows/macOS
- No need for Android device while coding

✅ **Consistent Testing**
- Predictable movement patterns
- Easy to reproduce bugs

✅ **Fast Development**
- No waiting for GPS lock
- Instant feedback

✅ **Mesh Network Testing**
- Simulate multiple devices
- Test collision detection
- Verify proximity alerts

## Next Steps

1. **Run the app** on Windows to see simulated location
2. **Test features** using the moving marker
3. **Deploy to Android** for real GPS testing
4. **Verify** both modes work correctly

The location service is now fully functional for both desktop testing and mobile deployment! 🎉
