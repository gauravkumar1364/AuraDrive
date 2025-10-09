# AuraDrive - Quick Reference Guide

## 🚀 Quick Start

### **What AuraDrive Does:**
- Connects nearby AuraDrive users via Bluetooth
- Shares real-time GPS locations between connected devices
- Shows all connected vehicles on a map
- Detects collisions using phone sensors
- Provides turn-by-turn navigation

---

## 📱 How to Use

### **Step 1: Open App**
- App opens → Splash screen → Permissions screen

### **Step 2: Grant Permissions**
✅ Location  
✅ Bluetooth Scan  
✅ Bluetooth Connect  
✅ Bluetooth Advertise  

### **Step 3: Navigation Screen Opens**
You'll see:
- **Map** with your position (blue marker)
- **Speed** display at top
- **Network** panel (tap 📡 icon)
- **Route search** (tap 🔍 icon)

### **Step 4: Connect to Other Drivers**
- **Automatic!** No action needed
- App scans for nearby AuraDrive users every 10 seconds
- Auto-connects to discovered devices
- Their positions appear on your map as green/red markers

---

## 🗺️ Map Features

### **Markers:**
- 🔵 **Blue** = You (your current position)
- 🟢 **Green** = Other vehicle (far away, >50m)
- 🔴 **Red** = Other vehicle (close, <50m) ⚠️ Warning!

### **Controls:**
- **[+]** = Zoom in
- **[-]** = Zoom out  
- **[⊙]** = Center on your location
- **[🧭]** = Toggle follow mode (map auto-moves with you)

### **Speed Display:**
- Shows current speed (km/h)
- GPS accuracy indicator:
  - **High** (green) = 0-10m accuracy
  - **Good** (yellow) = 10-20m accuracy
  - **Low** (red) = >20m accuracy

---

## 📡 BLE Mesh Network

### **How It Works:**
1. Your phone broadcasts: "I'm NaviSafe-XXXXXXXX"
2. Other AuraDrive phones hear you
3. They auto-connect to you
4. You both share GPS positions every 500ms
5. You see each other on the map in real-time!

### **Network Panel** (tap 📡):
Shows:
- **Discovered:** How many AuraDrive devices nearby
- **Connected:** How many actively sharing location
- Device list with signal strength

### **Connection Rules:**
- Only connects to devices with ≥30% signal strength
- Maximum 20 connections per device
- Auto-reconnects if disconnected
- Range: ~45 meters (150 feet)

---

## ⚠️ Collision Detection

### **What It Monitors:**
- Phone accelerometer (G-forces)
- Detects: Crashes, hard braking, sharp turns

### **Thresholds:**
- **Crash:** 12G+ → 🔴 Critical alert
- **Hard Brake:** 1.0G+ → 🟠 Warning
- **Sharp Turn:** 0.8G+ → 🟡 Caution

### **What Happens:**
- Alert dialog appears
- Event logged
- (Future: Notify nearby vehicles)

---

## 🔍 Route Search

### **How to Navigate:**
1. Tap search icon (🔍)
2. Enter destination address
3. Route appears on map (blue line)
4. Shows distance and estimated time
5. Follow the route!

---

## ⚙️ Settings

Access via gear icon (⚙️):
- Theme (Light/Dark/Auto)
- Map style
- Speed units (km/h or mph)
- Clear cache
- About

---

## 🔋 Battery Usage

**Moderate** - Similar to Google Maps with Bluetooth on

**Tips to Save Battery:**
- Turn off when not driving
- Reduce brightness
- Close other apps
- Enable battery saver mode

---

## 🐛 Common Issues

### **1. No GPS signal?**
- Go outside (GPS doesn't work indoors well)
- Wait 30-60 seconds for GPS lock
- Check Location is enabled in phone settings

### **2. No nearby devices found?**
- Ensure other person has AuraDrive installed and open
- Both devices must grant all permissions
- Move closer (<45 meters)
- Check Bluetooth is ON

### **3. Devices found but not connecting?**
- Signal may be too weak (move closer)
- Too many Bluetooth devices nearby (interference)
- Try restarting Bluetooth
- Wait 30 seconds (auto-retry active)

### **4. Map not loading?**
- Check internet connection (for map tiles)
- Wait for data to download
- Zoom out and back in

### **5. Speed showing 0?**
- GPS may not have lock yet (wait)
- You may not be moving
- Accuracy may be low (go outside)

---

## 📊 Technical Specs

### **Requirements:**
- Android 8.0+ or iOS 13+
- Bluetooth 4.0+ (BLE)
- GPS capability
- ~100MB storage
- Internet (for maps, optional for BLE)

### **Network:**
- **Technology:** Bluetooth Low Energy (BLE) 
- **Range:** ~45 meters (30% signal threshold)
- **Max Connections:** 20 devices
- **Update Rate:** Position shared every 500ms
- **Data Size:** ~50 bytes per update

### **GPS:**
- **Accuracy:** Best for navigation mode
- **Update Rate:** Every second
- **Simulated:** Available on desktop (testing)

---

## 🎯 Best Practices

### **For Best Experience:**
1. ✅ Keep phone mounted (easier to view)
2. ✅ Ensure GPS has clear sky view
3. ✅ Both drivers open app before driving
4. ✅ Stay within 45m range for connection
5. ✅ Enable location "Always" (not just "While using")
6. ✅ Keep Bluetooth ON
7. ✅ Charge phone (continuous GPS drains battery)

### **Safety First:**
⚠️ **DO NOT** use phone while driving  
⚠️ Set up route BEFORE starting drive  
⚠️ Use voice navigation when available  
⚠️ Pull over to change settings  

---

## 🔐 Privacy

### **What's Shared:**
- ✅ Your GPS location (only with connected devices)
- ✅ Your speed and heading
- ✅ Device ID (random, anonymous)

### **What's NOT Shared:**
- ❌ Your name or personal info
- ❌ Phone number
- ❌ Contacts
- ❌ Other apps data
- ❌ Location stored on servers (peer-to-peer only!)

### **Data Storage:**
- Location shared **directly** device-to-device
- No cloud upload
- No server tracking
- Disconnected = No sharing

---

## 📞 Support

### **Need Help?**
1. Check this guide
2. Read HOW_AURADRIVE_WORKS.md
3. Check ARCHITECTURE_DIAGRAM.md
4. Review debug logs (Settings → Debug)

### **Report Issues:**
Include:
- Android/iOS version
- Phone model
- What happened
- Error messages (if any)
- Screenshots

---

## 🆕 Version Info

**Current Version:** 1.0.0  
**Last Updated:** October 9, 2025  
**Platform:** Android, iOS  

### **Recent Changes:**
- ✅ Fixed RSSI threshold (now -79 dBm for 30% signal)
- ✅ Increased connection timeout (15s → 30s)
- ✅ Improved connection retry logic (up to 5 attempts)
- ✅ Added device cleanup on failed connections
- ✅ Dynamic connected device counter
- ✅ Google Maps-style speed display

---

## 🚗 Typical Use Cases

### **1. Group Road Trip:**
- 3 cars traveling together
- All install AuraDrive
- See each other's positions in real-time
- Know if someone falls behind
- Coordinate stops

### **2. Fleet Management:**
- Delivery drivers
- See all nearby colleagues
- Coordinate routes
- Avoid overlapping areas

### **3. Safety Monitoring:**
- Parent tracking teen driver (with consent)
- Both have app open
- Monitor speed and location
- Collision alerts

### **4. Autonomous Vehicle Testing:**
- Test vehicles share positions
- Real-time awareness
- Collision prevention
- Data logging

---

## ⌨️ Keyboard Shortcuts (Desktop Testing)

When running on Windows/Mac for development:
- **Space** = Toggle simulation
- **Arrow Keys** = Move simulated position
- **+/-** = Zoom in/out
- **F** = Toggle follow mode

---

## 📈 Performance Tips

### **Optimize for Speed:**
- Close background apps
- Clear app cache (Settings)
- Restart app if sluggish
- Enable developer options → GPU rendering

### **Optimize for Range:**
- Remove obstacles between devices
- Higher elevation = better signal
- Avoid metal buildings
- Open areas work best

---

**Happy Driving! Stay Safe! 🚗💨**
