# 📚 AuraDrive Documentation Index

## Welcome to AuraDrive!

This is your complete documentation hub for understanding and using the AuraDrive (NaviSafe) autonomous vehicle navigation and safety system.

---

## 📖 Documentation Files

### **1. HOW_AURADRIVE_WORKS.md** 🔧
**→ Complete technical explanation of how the app works**

**Read this to understand:**
- Overall app architecture
- How the 3 core services work (GPS, BLE, Collision Detection)
- Data flow between components
- BLE mesh network protocol
- Position sharing mechanism
- Tech stack and APIs used

**Best for:** Developers, technical users, understanding the system

---

### **2. ARCHITECTURE_DIAGRAM.md** 📊
**→ Visual diagrams and flow charts**

**Contains:**
- ASCII art diagrams showing system flow
- Service interaction visualizations
- Data flow diagrams
- Network topology examples
- Signal strength reference tables
- State management flow
- Troubleshooting decision trees

**Best for:** Visual learners, quick reference, debugging

---

### **3. QUICK_REFERENCE.md** 📱
**→ User guide and quick start**

**Covers:**
- How to use the app (step-by-step)
- Map features and controls
- Network panel explanation
- Collision detection alerts
- Common issues and solutions
- Best practices
- Privacy information

**Best for:** End users, first-time users, quick help

---

### **4. CONNECTION_RELIABILITY_FIX.md** 🔧
**→ Recent BLE connection improvements**

**Details:**
- RSSI threshold bug fix (> to >=)
- Connection timeout increase (15s → 30s)
- Connection attempt tracking improvements
- Device cleanup on error
- Testing results and impacts

**Best for:** Understanding recent fixes, debugging connection issues

---

### **5. RSSI_30_PERCENT_THRESHOLD.md** 📡
**→ Signal strength requirement update**

**Explains:**
- Why 30% signal threshold (-79 dBm)
- RSSI to signal percentage conversion
- Benefits vs trade-offs
- Impact on device discovery
- Range calculations

**Best for:** Network optimization, range planning

---

### **6. DYNAMIC_CONNECTED_COUNTER_FIX.md** 🔢
**→ Connected device counter fix**

**Covers:**
- Problem: Counter always showing 0
- Root cause: NetworkDevice status not updated
- Solution: Status lifecycle management
- Testing scenarios

**Best for:** UI state management, counter debugging

---

### **7. AUTO_CONNECT_LOCATION_SHARING.md** 🔄
**→ Automatic connection and position sharing**

**Details:**
- Auto-connect on discovery implementation
- Real-time position broadcasting
- Smart filtering (movement/heading threshold)
- Battery optimization

**Best for:** Understanding auto-connect behavior

---

## 🎯 Quick Navigation

### **I want to...**

#### **Understand how the app works overall**
→ Read: `HOW_AURADRIVE_WORKS.md`  
→ Then: `ARCHITECTURE_DIAGRAM.md` for visuals

#### **Learn how to use the app**
→ Read: `QUICK_REFERENCE.md`

#### **Debug connection issues**
→ Read: `CONNECTION_RELIABILITY_FIX.md`  
→ Check: `ARCHITECTURE_DIAGRAM.md` troubleshooting section

#### **Understand signal strength requirements**
→ Read: `RSSI_30_PERCENT_THRESHOLD.md`

#### **Fix "Connected: 0" issue**
→ Read: `DYNAMIC_CONNECTED_COUNTER_FIX.md`

#### **Understand auto-connect feature**
→ Read: `AUTO_CONNECT_LOCATION_SHARING.md`

---

## 🚀 Getting Started (New Users)

### **For End Users:**
1. Read `QUICK_REFERENCE.md` - How to use the app
2. Open app, grant permissions
3. Start driving with a friend who also has the app
4. Watch them appear on your map!

### **For Developers:**
1. Read `HOW_AURADRIVE_WORKS.md` - System architecture
2. Review `ARCHITECTURE_DIAGRAM.md` - Visual flows
3. Check recent fixes in `CONNECTION_RELIABILITY_FIX.md`
4. Explore source code with documentation as reference

---

## 🔑 Key Concepts

### **BLE Mesh Network**
- Bluetooth Low Energy peer-to-peer network
- No internet required for position sharing
- Range: ~45 meters (30% signal threshold)
- Max 20 connections per device
- Auto-discovery and connection

### **Position Sharing**
- GPS coordinates shared every 500ms via BLE
- Smart filtering (only if moved >1m or turned >5°)
- JSON format, ~50 bytes per update
- Peer-to-peer (no server involved)

### **Service UUID**
- Unique identifier: `12345678-1234-1234-1234-123456789abc`
- All AuraDrive devices use this UUID
- Allows devices to find each other
- Generated from app package name

### **RSSI Threshold**
- Current: -79 dBm (30% signal strength)
- Ensures reliable connections
- Reduces timeouts and failed connections
- Trade-off: Shorter range but better quality

---

## 📊 System Requirements

### **Minimum:**
- Android 8.0+ (API 26) or iOS 13+
- Bluetooth 4.0+ (BLE capable)
- GPS/GNSS capability
- 100MB free storage
- 2GB RAM

### **Recommended:**
- Android 10+ or iOS 14+
- Bluetooth 5.0+
- Dual-frequency GNSS
- 4GB RAM
- Internet connection (for maps)

---

## 🐛 Troubleshooting Quick Links

| Problem | Solution Document |
|---------|-------------------|
| No devices found | `QUICK_REFERENCE.md` → Common Issues #2 |
| Connection timeout | `CONNECTION_RELIABILITY_FIX.md` |
| Weak signal | `RSSI_30_PERCENT_THRESHOLD.md` |
| Counter shows 0 | `DYNAMIC_CONNECTED_COUNTER_FIX.md` |
| No auto-connect | `AUTO_CONNECT_LOCATION_SHARING.md` |
| No GPS signal | `QUICK_REFERENCE.md` → Common Issues #1 |
| Map not loading | `QUICK_REFERENCE.md` → Common Issues #4 |

---

## 🔧 Technical Reference

### **Services:**
1. **GnssService** (`lib/services/gnss_service.dart`)
   - GPS positioning
   - Location accuracy monitoring
   - Position streaming

2. **MeshNetworkService** (`lib/services/mesh_network_service.dart`)
   - BLE advertising/scanning
   - Auto-connection
   - Position broadcasting
   - Peer discovery

3. **AccelerometerCollisionService** (`lib/services/accelerometer_collision_service.dart`)
   - Crash detection
   - Hard braking alerts
   - Sharp turn warnings

### **Key Constants:**
```dart
// BLE Settings
minRssiThreshold = -79;           // 30% signal
maxClusterSize = 20;              // Max connections
maxConnectionAttempts = 5;        // Retry limit
connectionTimeout = 30s;          // Timeout duration
scanInterval = 10s;               // Scan frequency

// Position Sharing
broadcastInterval = 500ms;        // Update frequency
movementThreshold = 1.0m;         // Min movement
headingThreshold = 5.0°;          // Min heading change

// Collision Detection
crashThreshold = 12.0G;           // Crash force
brakingThreshold = 1.0G;          // Hard brake force
turnThreshold = 0.8G;             // Sharp turn force
```

---

## 📝 Recent Updates

### **October 9, 2025:**
- ✅ Fixed RSSI threshold bug (-90 to -79)
- ✅ Increased connection timeout (15s to 30s)
- ✅ Improved retry logic (proper attempt tracking)
- ✅ Added device cleanup on connection failure
- ✅ Fixed dynamic connected counter (status updates)
- ✅ Created comprehensive documentation suite

---

## 📞 Support & Contribution

### **Documentation Updates:**
When adding new features or fixes:
1. Update relevant .md files
2. Add entry to this index
3. Update version number
4. Document breaking changes

### **Code Comments:**
- All services have inline documentation
- Complex algorithms explained in comments
- Debug logs include emoji for easy filtering

### **Debug Logging:**
Look for these prefixes in logs:
- 🚀 = Initialization
- 📡 = BLE/Network
- 📍 = GPS/Location
- ⚠️ = Warnings
- ❌ = Errors
- ✅ = Success
- 🔗 = Connection
- 📤 = Broadcasting
- 📥 = Receiving

---

## 🎓 Learning Path

### **Level 1: Basic Understanding**
1. Read `QUICK_REFERENCE.md` (30 min)
2. Install and test app (15 min)
3. Review `ARCHITECTURE_DIAGRAM.md` visuals (20 min)

### **Level 2: Technical Knowledge**
1. Read `HOW_AURADRIVE_WORKS.md` (60 min)
2. Review service source code (90 min)
3. Understand BLE protocol (30 min)

### **Level 3: Advanced Development**
1. Study all fix documentation (45 min)
2. Review state management patterns (30 min)
3. Contribute fixes or features (ongoing)

---

## 📦 File Structure

```
AuraDrive/
├── Documentation/
│   ├── README_DOCS.md (this file)
│   ├── HOW_AURADRIVE_WORKS.md
│   ├── ARCHITECTURE_DIAGRAM.md
│   ├── QUICK_REFERENCE.md
│   ├── CONNECTION_RELIABILITY_FIX.md
│   ├── RSSI_30_PERCENT_THRESHOLD.md
│   ├── DYNAMIC_CONNECTED_COUNTER_FIX.md
│   └── AUTO_CONNECT_LOCATION_SHARING.md
│
├── lib/
│   ├── main.dart
│   ├── services/
│   │   ├── gnss_service.dart
│   │   ├── mesh_network_service.dart
│   │   └── accelerometer_collision_service.dart
│   ├── screens/
│   │   ├── navigation_screen.dart
│   │   ├── permissions_screen.dart
│   │   └── splash_screen.dart
│   └── models/
│       ├── position_data.dart
│       └── network_device.dart
│
└── README.md (main project README)
```

---

## 🌟 Key Features Summary

### **✅ What Works:**
- Real-time GPS tracking (1Hz updates)
- BLE device auto-discovery
- Auto-connection to NaviSafe devices
- Position sharing via BLE (500ms updates)
- Peer position display on map
- Speed display (Google Maps style)
- Collision detection (accelerometer)
- Route planning (OpenStreetMap)
- Dark mode support

### **🚧 Future Enhancements:**
- Emergency SOS broadcast
- Crash notification to peers
- Multi-hop mesh routing
- Offline maps
- Voice navigation
- Trip analytics

---

## 📖 External References

### **Technologies Used:**
- Flutter: https://flutter.dev
- Provider: https://pub.dev/packages/provider
- flutter_blue_plus: https://pub.dev/packages/flutter_blue_plus
- geolocator: https://pub.dev/packages/geolocator
- flutter_map: https://pub.dev/packages/flutter_map
- OpenStreetMap: https://www.openstreetmap.org

### **APIs:**
- OpenRouteService: https://openrouteservice.org
- Nominatim: https://nominatim.org

---

**Version:** 1.0.0  
**Last Updated:** October 9, 2025  
**Maintained by:** AuraDrive Development Team

**Happy Coding! 🚗💨**
