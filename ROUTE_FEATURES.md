# Dashboard Route Features - User Guide

## 🗺️ Source & Destination Markers

The dashboard now includes interactive route planning with source and destination markers.

## Features Added

### 1. **Interactive Map Markers**
- **Current Position** (Blue Navigation Icon) - Shows your real-time location with heading
- **Source** (Green Pin) - Starting point of your route
- **Destination** (Red Flag) - End point of your route

### 2. **Route Visualization**
- **Blue Line** - Direct route path between source and destination
- **Distance Display** - Real-time distance calculation in meters
- **ETA Display** - Estimated time of arrival based on current speed

### 3. **Control Buttons** (Bottom Right)

| Button | Icon | Function |
|--------|------|----------|
| **Green Pin** | 📍 | Tap to enter source selection mode, then tap map to set source |
| **Red Flag** | 🚩 | Tap to enter destination selection mode, then tap map to set destination |
| **Blue Target** | 🎯 | Set current location as source |
| **Clear** | ❌ | Remove source and destination markers |

## How to Use

### Setting a Route

1. **Set Source Location:**
   - Option A: Tap the green pin button, then tap on the map where you want to start
   - Option B: Tap the blue "My Location" button to use current position as source

2. **Set Destination:**
   - Tap the red flag button
   - Tap on the map where you want to go
   - The route line will appear automatically

3. **View Route Info:**
   - Distance is shown in the top-left info card
   - ETA is calculated based on current speed
   - Route line connects source to destination

### Clearing the Route

- Tap the grey "Clear" button (❌) to remove all markers and route line

## Route Information Card

When both source and destination are set, a white info card appears showing:

- **Distance**: Direct line distance in meters
- **ETA**: Estimated time based on:
  - Current speed if moving (>0.5 m/s)
  - Walking speed (1.5 m/s ≈ 5.4 km/h) if stationary

## Visual Indicators

### Selection Mode
When in selection mode, a black banner appears at the top:
- **"Tap on map to set SOURCE location"** (when green pin is active)
- **"Tap on map to set DESTINATION location"** (when red flag is active)

### Current Position
- The blue navigation icon rotates based on your heading/direction
- Updates in real-time as you move

## Integration with Autonomous Features

The route markers work alongside:
- ✅ **Collision Detection** - Warnings shown below the map
- ✅ **Cluster Status** - Display nearby vehicles and cluster info
- ✅ **Speed Tracking** - Real-time speed affects ETA calculation
- ✅ **BLE Mesh Network** - Route shared with nearby vehicles (future)

## Example Use Cases

### 1. **Test Collision Detection**
- Set destination ahead
- Walk/drive toward it
- Monitor collision warnings with nearby vehicles

### 2. **Navigation Testing**
- Set source and destination
- Follow the route line
- Verify Kalman filtering accuracy

### 3. **Cluster Formation**
- Set common destination for multiple phones
- Watch cluster formation as vehicles converge
- Monitor coordinator selection

## Technical Details

### Distance Calculation
```dart
Uses latlong2 Distance class
Haversine formula for accurate GPS distance
Returns meters between two LatLng points
```

### ETA Calculation
```dart
ETA = Distance / Speed
Speed sources:
  1. Current GPS speed (if moving)
  2. Fallback: 1.5 m/s walking speed
Display: Seconds (<60s), Minutes (<1h), Hours (>1h)
```

### Route Rendering
```dart
PolylineLayer with:
  - Blue stroke (4px width)
  - White border (2px)
  - 70% opacity
  - Direct line between points
```

## Future Enhancements

Planned features:
- [ ] Turn-by-turn navigation
- [ ] Multi-waypoint routes
- [ ] Alternative route suggestions
- [ ] Traffic-aware routing
- [ ] Route sharing via VANET
- [ ] Offline map caching
- [ ] Route history

## Tips

1. **Accuracy**: GPS works best outdoors with clear sky view
2. **Speed**: Stand still for a moment to get accurate position before setting markers
3. **Testing**: Use two phones to test route following and collision detection
4. **Markers**: Tap and hold markers to drag them (future feature)

---

**Note**: Current implementation shows direct line. Real road navigation requires routing API integration (future enhancement).
