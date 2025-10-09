# How AuraDrive Works - Complete System Overview

## 🚗 App Purpose
**AuraDrive** (also branded as **NaviSafe**) is an autonomous vehicle safety and navigation app that uses:
- **BLE (Bluetooth Low Energy) mesh networking** to connect nearby vehicles
- **High-precision GPS/GNSS** for real-time location tracking
- **Accelerometer sensors** for collision detection
- **Real-time position sharing** between connected vehicles
- **OpenStreetMap** for navigation and routing

---

## 📱 App Flow - User Journey

### 1. **App Launch** 🚀
```
main.dart → Splash Screen → Permissions Screen → Navigation Screen
```

**What Happens:**
- App initializes 3 core services:
  - `GnssService` - GPS positioning
  - `MeshNetworkService` - BLE device connectivity
  - `AccelerometerCollisionService` - Crash detection
- Services are provided via `Provider` state management (available to all screens)

### 2. **Permissions Screen** 🔐
**Required Permissions:**
- ✅ Location (for GPS)
- ✅ Bluetooth Scan (to discover nearby devices)
- ✅ Bluetooth Connect (to connect to devices)
- ✅ Bluetooth Advertise (to broadcast own device)

**Why Needed:**
- Location: Get real-time GPS coordinates
- Bluetooth: Create mesh network with other AuraDrive users

### 3. **Navigation Screen** 🗺️
**Main App Interface** - Where all the magic happens!

---

## 🔧 Core Services - The Engine

### **Service 1: GNSS Service** 📍
**File:** `lib/services/gnss_service.dart`

**What It Does:**
- Gets your current GPS position continuously
- Provides high-accuracy positioning (bestForNavigation mode)
- Updates position every second (distanceFilter: 0)
- Calculates speed, heading, and accuracy

**Key Features:**
- Desktop simulation mode (for testing on Windows/Mac)
- Real-time position streaming
- Quality metrics (satellite count, accuracy)

**How It Works:**
```dart
// Initialize GPS
gnssService.initialize()

// Start tracking
gnssService.startPositioning()

// Listen to position updates
gnssService.positionStream.listen((position) {
  // Update map with new position
  // Share position via BLE
  // Update speed display
});
```

**Position Data Includes:**
- Latitude, Longitude
- Speed (km/h)
- Heading (direction in degrees)
- Accuracy (meters)
- Timestamp

---

### **Service 2: Mesh Network Service** 📡
**File:** `lib/services/mesh_network_service.dart`

**What It Does:**
- Creates a BLE mesh network of nearby AuraDrive devices
- Automatically discovers and connects to other users
- Shares your position with connected devices
- Receives positions from other vehicles

**BLE Architecture:**

#### **Advertising (Broadcasting):**
Every AuraDrive device advertises itself:
```
Service UUID: Generated from package name (unique to AuraDrive)
Device Name: "NaviSafe-XXXXXXXX" (random 8-char ID)
Manufacturer Data: App version
```

#### **Scanning (Discovery):**
Every 10 seconds, app scans for:
- Devices with AuraDrive service UUID
- Devices with name starting "NaviSafe"
- RSSI ≥ -79 dBm (30% signal strength minimum)

#### **Auto-Connection:**
When a NaviSafe device is found:
1. Check if already connected
2. Check if under max connections (20 devices)
3. Check connection attempts < 5
4. Auto-connect in background
5. Subscribe to position updates

#### **Position Sharing:**
Connected devices share data via BLE Characteristics:
```
Position Characteristic UUID: 12345678-1234-1234-1234-123456789abd
- Latitude
- Longitude
- Speed
- Heading
- Timestamp
- Device ID

Vehicle Data Characteristic UUID: 12345678-1234-1234-1234-123456789abe
- Vehicle type
- Speed
- Acceleration
- Direction
```

**Broadcasting Strategy:**
- Sends position every 500ms
- Only if position changed >1m OR heading changed >5°
- Uses `withoutResponse` mode for speed
- Smart filtering to save battery

**How It Works:**
```dart
// Initialize mesh network
meshService.initialize()

// Start advertising this device
meshService._attemptAdvertising()

// Start scanning for other devices
meshService.startScanning()

// Auto-connect to discovered NaviSafe devices
meshService.connectToDevice(deviceId)

// Broadcast your position
meshService.broadcastPositionData(positionData)

// Receive peer positions
meshService.positionReceivedStream.listen((peerPosition) {
  // Show peer vehicle on map
});
```

**Connection Management:**
- Max 20 simultaneous connections
- RSSI threshold: -79 dBm (30% signal, ~45m range)
- Connection timeout: 30 seconds
- Auto-reconnect on disconnect
- Smart retry (max 5 attempts)

---

### **Service 3: Accelerometer Collision Service** ⚠️
**File:** `lib/services/accelerometer_collision_service.dart`

**What It Does:**
- Monitors phone's accelerometer in real-time
- Detects crashes, hard braking, sharp turns
- Generates visual/audio alerts

**Detection Thresholds:**
- **Crash:** 12G force
- **Hard Braking:** 1.0G deceleration
- **Sharp Turn:** 0.8G lateral force
- **Motion Threshold:** 0.3G minimum (ignore small bumps)

**Alert Types:**
```dart
- "crash" → Critical severity → Red alert
- "braking" → High severity → Orange warning
- "turn" → Medium severity → Yellow caution
```

**How It Works:**
```dart
// Start monitoring
collisionService.startMonitoring()

// Listen for alerts
collisionService.alertStream.listen((alert) {
  // Show collision warning dialog
  // Log event
  // Notify nearby vehicles (future feature)
});
```

**Smoothing Algorithm:**
- Keeps 10-sample history
- Averages readings to reduce noise
- Cooldown period between alerts (5 seconds)

---

## 🗺️ Navigation Screen - Main UI

### **Map Display** 🌍
**Technology:** `flutter_map` + OpenStreetMap

**What's Shown:**
1. **Your Position** (blue marker)
   - Updates every second
   - Shows heading (rotation)
   - Auto-follows your movement

2. **Peer Vehicles** (green/red markers)
   - Green: Far away (>50m)
   - Red: Close (<50m) - collision warning zone
   - Shows heading direction
   - Real-time updates via BLE

3. **Route** (blue line)
   - Road-based routing (not straight line)
   - Calculated via OpenRouteService API
   - Shows distance, duration, instructions

4. **Map Controls:**
   - Zoom in/out buttons
   - Center on location button
   - Follow mode toggle

### **Top Info Panel** 📊
**Speed Display** (Google Maps style):
- Large speed number (km/h)
- GPS accuracy indicator:
  - **High** (0-10m) - Green
  - **Good** (10-20m) - Yellow
  - **Low** (>20m) - Red

### **Network Panel** 📡
Shows BLE mesh network status:
- **Discovered:** X devices (found nearby)
- **Connected:** X devices (actively sharing data)
- **Auto-Connect Status** (connecting indicator)
- List of discovered devices with:
  - Device name
  - Signal strength (RSSI)
  - Connection status

### **Safety Panel** ⚠️
Shows collision detection status:
- Monitoring: Active/Inactive
- Recent alerts list
- Sensor readings

### **Route Search** 🔍
- Tap search icon
- Enter destination address
- Shows route on map
- Turn-by-turn navigation

---

## 🔄 Real-Time Data Flow

### **Every Second:**
```
1. GPS updates position → GnssService
2. Position sent to NavigationScreen
3. Map marker updates
4. Speed display updates
5. Position broadcast via BLE → MeshNetworkService
6. Connected devices receive position
7. Peer positions displayed on map
```

### **Every 10 Seconds:**
```
1. BLE scan runs → MeshNetworkService
2. Discover new NaviSafe devices
3. Auto-connect to new devices (if <20 connected)
4. Update network panel UI
```

### **Continuous:**
```
1. Accelerometer monitoring → AccelerometerCollisionService
2. Calculate G-forces
3. Check thresholds
4. Generate alerts if exceeded
```

---

## 🌐 BLE Mesh Network - Device Discovery

### **How Devices Find Each Other:**

**Device A (Your Phone):**
```
1. Starts advertising: "NaviSafe-ABC123"
2. Starts scanning for other NaviSafe devices
3. Finds Device B: "NaviSafe-XYZ789" (RSSI: -65)
4. Auto-connects to Device B
5. Subscribes to Device B's position characteristic
6. Starts receiving Device B's location every 500ms
```

**Device B (Other User's Phone):**
```
1. Starts advertising: "NaviSafe-XYZ789"
2. Finds Device A: "NaviSafe-ABC123" (RSSI: -65)
3. Auto-connects to Device A
4. Subscribes to Device A's position characteristic
5. Both devices now share positions in real-time!
```

### **What You See:**
- Device B appears as a marker on your map
- Marker moves in real-time as Device B moves
- Distance calculated continuously
- Alert if Device B gets <50m (collision zone)

---

## 📍 Position Sharing Protocol

### **Data Format (JSON over BLE):**
```json
{
  "deviceId": "abc123...",
  "timestamp": "2025-10-09T12:34:56.789Z",
  "latitude": 28.7041,
  "longitude": 77.1025,
  "accuracy": 5.2,
  "speed": 45.3,
  "heading": 90.0
}
```

### **Broadcast Frequency:**
- **Normal:** Every 500ms
- **Smart Filter:** Only if moved >1m OR turned >5°
- **Battery Saver:** Reduces unnecessary transmissions

### **Reception:**
```dart
meshService.positionReceivedStream.listen((peerPosition) {
  // Update peer marker on map
  _peerPositions[peerPosition.deviceId] = LatLng(
    peerPosition.latitude,
    peerPosition.longitude,
  );
  
  // Calculate distance to peer
  double distance = calculateDistance(
    _currentPosition,
    peerPosition,
  );
  
  // Show warning if too close
  if (distance < 50.0) {
    showCollisionWarning();
  }
});
```

---

## ⚙️ Configuration & Settings

### **BLE Settings:**
```dart
minRssiThreshold = -79;  // 30% signal strength
maxClusterSize = 20;     // Max 20 connected devices
maxConnectionAttempts = 5; // Retry 5 times
connectionTimeout = 30s;  // 30 second timeout
scanInterval = 10s;      // Scan every 10 seconds
```

### **GPS Settings:**
```dart
LocationSettings(
  accuracy: LocationAccuracy.bestForNavigation,
  distanceFilter: 0,  // Update on any movement
  timeLimit: Duration(seconds: 5),
)
```

### **Collision Settings:**
```dart
crashThreshold = 12.0G;
brakingThreshold = 1.0G;
turnThreshold = 0.8G;
motionThreshold = 0.3G;
```

---

## 🎯 Key Features Summary

### ✅ **What Works:**
1. **GPS Tracking** - Real-time position (1Hz updates)
2. **BLE Discovery** - Finds nearby AuraDrive devices
3. **Auto-Connect** - Automatically connects to discovered devices
4. **Position Broadcasting** - Shares location via BLE
5. **Peer Position Reception** - Receives other vehicles' locations
6. **Map Display** - Shows you and all connected vehicles
7. **Speed Display** - Google Maps style with accuracy
8. **Collision Detection** - Accelerometer-based crash alerts
9. **Route Planning** - OpenStreetMap road routing
10. **Dark Mode** - Night driving friendly UI

### 🔧 **System Requirements:**
- **Android:** 8.0+ (API 26+)
- **iOS:** 13.0+
- **Bluetooth:** BLE 4.0+
- **Permissions:** Location, Bluetooth
- **Network:** Optional (for map tiles and routing)

### 📊 **Performance:**
- **Battery:** Moderate (BLE + GPS)
- **CPU:** Low (efficient scanning)
- **Memory:** ~50-100MB
- **Network:** Minimal (OSM tiles cached)
- **BLE Range:** ~45m (30% signal)

---

## 🚀 Future Enhancements

### Planned Features:
- [ ] Emergency SOS broadcast
- [ ] Group trip coordination
- [ ] Traffic density heatmap
- [ ] Crash notification to peers
- [ ] Voice navigation
- [ ] Offline maps
- [ ] Trip history/analytics
- [ ] Multi-hop mesh (device relay)

---

## 🐛 Troubleshooting

### **No devices found?**
- Ensure both devices running AuraDrive
- Check Bluetooth is ON
- Verify permissions granted
- Try moving closer (<45m)
- Check RSSI > -79 dBm

### **Connection timeout?**
- Too many BLE devices nearby (>20)
- Weak signal (RSSI < -79)
- Bluetooth interference
- Try restarting Bluetooth

### **No position updates?**
- Check GPS is enabled
- Ensure location permissions
- Go outside (better GPS signal)
- Wait for GPS lock (can take 30s)

### **App crashes?**
- Check all permissions granted
- Restart app
- Clear app cache
- Check Android/iOS version

---

## 📱 Tech Stack

**Frontend:**
- Flutter 3.x
- Provider (state management)
- flutter_map (OpenStreetMap)
- Material Design 3

**Services:**
- geolocator (GPS)
- flutter_blue_plus (BLE Central)
- flutter_ble_peripheral (BLE Peripheral)
- sensors_plus (Accelerometer)

**APIs:**
- OpenStreetMap (map tiles)
- OpenRouteService (routing)
- Nominatim (geocoding)

---

**Version:** 1.0.0  
**Last Updated:** October 9, 2025  
**Platform:** Android, iOS  
**License:** Proprietary
