# AuraDrive Architecture - Visual Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        AuraDrive App                             │
│                     (NaviSafe System)                            │
└─────────────────────────────────────────────────────────────────┘

╔═══════════════════════════════════════════════════════════════╗
║                    APP LAUNCH SEQUENCE                          ║
╚═══════════════════════════════════════════════════════════════╝

    main.dart
       ↓
    Initialize Services:
    ├─ GnssService (GPS)
    ├─ MeshNetworkService (BLE)
    └─ AccelerometerCollisionService (Sensors)
       ↓
    Splash Screen
       ↓
    Permissions Screen → [Grant: Location, Bluetooth]
       ↓
    Navigation Screen ✅ [MAIN APP]


╔═══════════════════════════════════════════════════════════════╗
║               NAVIGATION SCREEN COMPONENTS                      ║
╚═══════════════════════════════════════════════════════════════╝

┌────────────────────────────────────────────────────────────────┐
│  ┌──────────────────────────────────────────────────────┐      │
│  │  App Bar: "NaviSafe Navigation"          🔍 ⚙️ 📡    │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                 │
│  ┌──────────────────────────────────────────────────────┐      │
│  │  Speed Display:   65 km/h  [GPS: High Accuracy]      │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                 │
│  ┌──────────────────────────────────────────────────────┐      │
│  │                                                       │      │
│  │                  MAP VIEW                             │      │
│  │              (OpenStreetMap)                          │      │
│  │                                                       │      │
│  │   🔵 ← You (blue marker)                            │      │
│  │                                                       │      │
│  │              🟢 ← Peer Device (far)                 │      │
│  │                                                       │      │
│  │   🔴 ← Peer Device (close, <50m warning)           │      │
│  │                                                       │      │
│  │        ━━━━━ Route (blue line)                      │      │
│  │                                                       │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                 │
│  Floating Buttons:                                              │
│  [+] Zoom In   [-] Zoom Out   [⊙] Center   [🧭] Follow        │
└────────────────────────────────────────────────────────────────┘


╔═══════════════════════════════════════════════════════════════╗
║                 3 CORE SERVICES RUNNING                         ║
╚═══════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────┐
│  SERVICE 1: GNSS Service (GPS Tracking) 📍                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  GPS Satellite                                                   │
│      🛰️                                                          │
│       ↓                                                          │
│  Phone GPS Chip                                                  │
│       ↓                                                          │
│  GnssService.startPositioning()                                  │
│       ↓                                                          │
│  Every 1 second:                                                 │
│  ┌────────────────────────────────┐                             │
│  │ Position Data:                 │                             │
│  │  • Latitude: 28.7041           │                             │
│  │  • Longitude: 77.1025          │                             │
│  │  • Speed: 65 km/h              │                             │
│  │  • Heading: 90° (East)         │                             │
│  │  • Accuracy: 5m                │                             │
│  └────────────────────────────────┘                             │
│       ↓                                                          │
│  positionStream → Navigation Screen                              │
│       ↓                                                          │
│  Update Map Marker + Broadcast via BLE                           │
└─────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│  SERVICE 2: Mesh Network Service (BLE) 📡                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────┐         ┌─────────────────┐               │
│  │   Your Phone    │ ←BLE→   │  Other User's   │               │
│  │  (Device A)     │         │    Phone        │               │
│  │                 │         │   (Device B)    │               │
│  │ NaviSafe-ABC123 │         │ NaviSafe-XYZ789 │               │
│  └─────────────────┘         └─────────────────┘               │
│          ↑                           ↑                           │
│          │                           │                           │
│    Advertising                 Advertising                       │
│    Scanning                    Scanning                          │
│          │                           │                           │
│          └───── Auto-Connect ────────┘                           │
│                                                                  │
│  ADVERTISING (Broadcasting):                                     │
│  • Service UUID: 12345678-1234-1234-1234-123456789abc           │
│  • Name: "NaviSafe-XXXXXXXX"                                    │
│  • Every 10 seconds                                              │
│                                                                  │
│  SCANNING (Discovery):                                           │
│  • Look for "NaviSafe-*" devices                                │
│  • Filter: RSSI ≥ -79 dBm (30% signal)                          │
│  • Every 10 seconds                                              │
│                                                                  │
│  AUTO-CONNECT:                                                   │
│  • When NaviSafe device found → Auto-connect                     │
│  • Max 20 connections                                            │
│  • Timeout: 30 seconds                                           │
│  • Retry: Up to 5 times                                          │
│                                                                  │
│  POSITION BROADCASTING:                                          │
│  Every 500ms:                                                    │
│  ┌────────────────────────────────┐                             │
│  │ Your Position (JSON)           │                             │
│  │  {                             │                             │
│  │   deviceId: "abc123",          │ ──BLE──→ Connected Devices  │
│  │   lat: 28.7041,                │                             │
│  │   lon: 77.1025,                │                             │
│  │   speed: 65,                   │                             │
│  │   heading: 90                  │                             │
│  │  }                             │                             │
│  └────────────────────────────────┘                             │
│       ↓                                                          │
│  Peer devices receive → Show on their maps                       │
│                                                                  │
│  POSITION RECEPTION:                                             │
│  ┌────────────────────────────────┐                             │
│  │ Peer Position (from Device B)  │                             │
│  │  {                             │                             │
│  │   deviceId: "xyz789",          │ ←BLE── From Connected Device│
│  │   lat: 28.7050,                │                             │
│  │   lon: 77.1030,                │                             │
│  │   speed: 50,                   │                             │
│  │   heading: 180                 │                             │
│  │  }                             │                             │
│  └────────────────────────────────┘                             │
│       ↓                                                          │
│  Show peer marker on your map                                    │
└─────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│  SERVICE 3: Accelerometer Collision Service ⚠️                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Phone Accelerometer Sensor                                      │
│       ↓                                                          │
│  Continuous monitoring (100Hz)                                   │
│       ↓                                                          │
│  Calculate G-force:                                              │
│  magnitude = √(x² + y² + z²)                                    │
│       ↓                                                          │
│  Check Thresholds:                                               │
│  ┌─────────────────────────┐                                    │
│  │ IF magnitude > 12G      │ → CRASH ALERT 🔴                  │
│  │ IF magnitude > 1.0G     │ → HARD BRAKE 🟠                   │
│  │ IF magnitude > 0.8G     │ → SHARP TURN 🟡                   │
│  └─────────────────────────┘                                    │
│       ↓                                                          │
│  Generate Alert                                                  │
│       ↓                                                          │
│  Show Dialog + Log Event                                         │
└─────────────────────────────────────────────────────────────────┘


╔═══════════════════════════════════════════════════════════════╗
║              DATA FLOW: EVERY SECOND                            ║
╚═══════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────┐
│  1️⃣  GPS updates position                                        │
│       ↓                                                          │
│  2️⃣  GnssService emits new PositionData                          │
│       ↓                                                          │
│  3️⃣  Navigation Screen receives update                           │
│       ↓                                                          │
│  4️⃣  Map marker moves to new position                            │
│       ↓                                                          │
│  5️⃣  Speed display updates                                       │
│       ↓                                                          │
│  6️⃣  Position broadcast via BLE to connected devices             │
│       ↓                                                          │
│  7️⃣  Other devices receive your position                         │
│       ↓                                                          │
│  8️⃣  Your marker appears/moves on their maps                     │
│       ↓                                                          │
│  9️⃣  Their positions sent back to you                            │
│       ↓                                                          │
│  🔟  Their markers appear/move on your map                       │
│                                                                  │
│  🔄 REPEAT EVERY SECOND                                          │
└─────────────────────────────────────────────────────────────────┘


╔═══════════════════════════════════════════════════════════════╗
║          BLE MESH NETWORK: MULTI-DEVICE SCENARIO                ║
╚═══════════════════════════════════════════════════════════════╝

        Device A (You)          Device B (Car 1)      Device C (Car 2)
            📱                      📱                     📱
     NaviSafe-ABC123          NaviSafe-XYZ789       NaviSafe-PQR456
            │                       │                      │
            │◄──────BLE────────────►│                      │
            │                       │                      │
            │◄────────────BLE──────────────────────────────┘
            │                       │
            │                       │◄────BLE────►Device D
            │                                     NaviSafe-LMN321
            │
            │◄──BLE──►Device E (Bike 1)
                     NaviSafe-GHI654

All devices continuously share positions:
- A sees: B, C, D, E on map
- B sees: A, C, D on map  
- C sees: A, B on map
- D sees: B, C on map
- E sees: A on map

Total connections per device limited to 20 max.


╔═══════════════════════════════════════════════════════════════╗
║                POSITION SHARING PROTOCOL                        ║
╚═══════════════════════════════════════════════════════════════╝

Device A (Your Phone)
    ↓
Get GPS position every 1s
    ↓
┌──────────────────────────────┐
│ Current Position:            │
│  Lat: 28.7041               │
│  Lon: 77.1025               │
│  Speed: 65 km/h             │
│  Heading: 90°               │
└──────────────────────────────┘
    ↓
Check if changed:
  - Moved > 1 meter? ✅
  - OR heading changed > 5°? ✅
    ↓
YES → Broadcast via BLE
    ↓
┌──────────────────────────────┐
│ JSON Data (50 bytes):        │
│  {                           │
│    "deviceId": "abc123",     │
│    "timestamp": "2025...",   │
│    "latitude": 28.7041,      │
│    "longitude": 77.1025,     │
│    "speed": 65.0,            │
│    "heading": 90.0,          │
│    "accuracy": 5.2           │
│  }                           │
└──────────────────────────────┘
    ↓
Write to BLE Characteristic
(UUID: 12345678-1234-1234-1234-123456789abd)
    ↓
    ├──→ Device B receives ✅
    ├──→ Device C receives ✅
    ├──→ Device D receives ✅
    └──→ Device E receives ✅
         ↓
    All connected devices update their maps
    showing your new position!


╔═══════════════════════════════════════════════════════════════╗
║                  NETWORK PANEL VIEW                             ║
╚═══════════════════════════════════════════════════════════════╝

┌────────────────────────────────────────────────────┐
│  Mesh Network Status                               │
├────────────────────────────────────────────────────┤
│  Discovered: 12 devices                            │
│  Connected: 5 devices                              │
│  Auto-Connect: ⚡ Active                           │
├────────────────────────────────────────────────────┤
│                                                    │
│  📱 NaviSafe-ABC123 (You)                         │
│     RSSI: -45 dBm ▓▓▓▓▓ [100%]                   │
│     Status: 🟢 Advertising                        │
│                                                    │
│  🚗 NaviSafe-XYZ789                               │
│     RSSI: -63 dBm ▓▓▓░░ [60%]                    │
│     Status: 🟢 Connected                          │
│     Distance: 25m                                  │
│                                                    │
│  🚙 NaviSafe-PQR456                               │
│     RSSI: -71 dBm ▓▓░░░ [40%]                    │
│     Status: 🟢 Connected                          │
│     Distance: 40m                                  │
│                                                    │
│  🏍️ NaviSafe-LMN321                               │
│     RSSI: -78 dBm ▓░░░░ [30%]                    │
│     Status: 🟢 Connected                          │
│     Distance: 45m                                  │
│                                                    │
│  🚕 NaviSafe-GHI654                               │
│     RSSI: -82 dBm ░░░░░ [20%]                    │
│     Status: ⚠️ Disconnected (weak signal)         │
│                                                    │
└────────────────────────────────────────────────────┘


╔═══════════════════════════════════════════════════════════════╗
║                  SIGNAL STRENGTH GUIDE                          ║
╚═══════════════════════════════════════════════════════════════╝

RSSI (dBm)    Signal %    Quality      Range      Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-30 to -50    100%        Excellent    0-10m      ✅ Auto-connect
-50 to -60    75-99%      Very Good    10-20m     ✅ Auto-connect
-60 to -70    50-74%      Good         20-35m     ✅ Auto-connect
-70 to -79    30-49%      Fair         35-45m     ✅ Auto-connect
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-79          30%         THRESHOLD    ~45m       ← Current limit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-80 to -90    10-24%      Poor         50-65m     ❌ Rejected
-90 to -100   0-9%        Very Poor    65m+       ❌ Rejected


╔═══════════════════════════════════════════════════════════════╗
║                    COLLISION DETECTION                          ║
╚═══════════════════════════════════════════════════════════════╝

Accelerometer readings (continuous):
    ↓
Calculate total G-force:
magnitude = √(x² + y² + z²)
    ↓
Smooth with 10-sample average
    ↓
Check against thresholds:

┌──────────────────────────────────────────┐
│  IF magnitude > 12.0G                    │
│    ↓                                     │
│  🔴 CRASH DETECTED!                      │
│    ↓                                     │
│  Show Critical Alert Dialog              │
│  Log crash event                         │
│  (Future: Notify emergency services)     │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│  IF magnitude > 1.0G                     │
│    ↓                                     │
│  🟠 HARD BRAKING DETECTED!               │
│    ↓                                     │
│  Show Warning Toast                      │
│  Log event                               │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│  IF magnitude > 0.8G                     │
│    ↓                                     │
│  🟡 SHARP TURN DETECTED!                 │
│    ↓                                     │
│  Show Caution Toast                      │
│  Log event                               │
└──────────────────────────────────────────┘


╔═══════════════════════════════════════════════════════════════╗
║                      STATE MANAGEMENT                           ║
╚═══════════════════════════════════════════════════════════════╝

Provider Pattern (pub.dev/packages/provider)

main.dart:
    ↓
MultiProvider wraps entire app:
    ├─ GnssService
    ├─ MeshNetworkService  
    └─ AccelerometerCollisionService
    ↓
All screens can access via:
    ↓
Consumer<GnssService>(
  builder: (context, gnssService, child) {
    // React to GPS updates
    return Text('Speed: ${gnssService.currentPosition.speed}');
  }
)
    ↓
When service calls notifyListeners():
    ↓
All Consumer widgets rebuild automatically!


╔═══════════════════════════════════════════════════════════════╗
║                     BATTERY OPTIMIZATION                        ║
╚═══════════════════════════════════════════════════════════════╝

GPS Service:
  ✅ Uses best accuracy only when needed
  ✅ Distance filter: 0 (but smart broadcasting)
  
BLE Service:
  ✅ Scans every 10s (not continuous)
  ✅ Broadcasts only when position changes >1m
  ✅ Uses writeWithoutResponse (faster, less power)
  ✅ Auto-disconnects weak signals (<30%)
  
Accelerometer:
  ✅ Normal sample rate (not ultra-high)
  ✅ Smoothing reduces processing
  ✅ Cooldown between alerts (5s)

Result: ~4-6 hours continuous use


╔═══════════════════════════════════════════════════════════════╗
║                   TROUBLESHOOTING FLOW                          ║
╚═══════════════════════════════════════════════════════════════╝

Problem: No devices found
    ↓
Check: Is Bluetooth ON? 
    └─ NO → Enable Bluetooth
    └─ YES ↓
Check: Are permissions granted?
    └─ NO → Grant all permissions
    └─ YES ↓
Check: Is other device running AuraDrive?
    └─ NO → Open AuraDrive on other phone
    └─ YES ↓
Check: Are you close enough? (<45m)
    └─ NO → Move closer
    └─ YES ↓
Check: Is RSSI > -79 dBm?
    └─ NO → Move closer or remove obstacles
    └─ YES → Should work! Check logs

Problem: Connection timeout
    ↓
Check: Signal strength
    └─ Weak → Move closer
    └─ Strong ↓
Check: Too many BLE devices nearby?
    └─ YES → Move to quieter area
    └─ NO ↓
Try: Restart Bluetooth
Try: Restart app
Try: Wait 30s (auto-retry)
