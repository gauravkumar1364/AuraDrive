# Quick Start - BLE Auto-Connect Fix

## 🚀 Run This Now!

```powershell
# Option 1: Use the automated script
.\rebuild_ble.ps1

# Option 2: Manual steps
flutter clean
adb uninstall com.example.project
flutter run
```

## ✅ Grant These Permissions

When the app starts, tap **Allow** for:
1. Location → **Allow all the time**
2. Bluetooth → **Allow**
3. Nearby devices → **Allow** 
4. Notifications → **Allow**

## ✅ Enable These Settings

Quick Settings (swipe down from top):
1. Turn ON **Bluetooth**
2. Turn ON **Location/GPS**

## ✅ What Should Happen

You should see these logs:
```
✅ CollisionDetectionService: Initialized successfully
✅ GnssService: Started positioning
✅ BLE Auto Connect: Service initialized successfully
✅ BLE Auto Connect: Auto-connect started
✅ BLE Auto Connect: Scan cycle completed. Found X devices
```

## ✅ Already Working!

Your collision detection is working perfectly:
```
✅ CollisionDetectionService: Alert added: Sharp RIGHT turn: 4.1 m/s² (0.4G)
```

## ❌ What Was Broken (Now Fixed)

```
❌ D/permissions_handler: Bluetooth permission missing in manifest
❌ MeshNetworkService: Permission denied: Permission.bluetooth
```

## 📖 More Info

- **Full setup guide:** `BLE_AUTO_CONNECT_GUIDE.md`
- **Collision config:** `COLLISION_DETECTION_CONFIG.md`
- **All fixes summary:** `FIXES_SUMMARY.md`
- **Quick reference:** `QUICK_REFERENCE_THRESHOLDS.md`

---

**That's it! Just run the rebuild script and grant permissions.**
