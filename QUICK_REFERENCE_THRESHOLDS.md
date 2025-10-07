# Collision Detection - Quick Reference Card

## 🎯 Threshold Values (At a Glance)

### Crash Detection
```
Moderate:  29.4 m/s² (3.0G) ⚠️
Severe:    49.0 m/s² (5.0G) 🚨
```

### Hard Braking
```
Hard:      -5.0 m/s² (0.51G) ⚠️
Emergency: -8.0 m/s² (0.82G) 🚨
```

### Sharp Turn (with Direction!)
```
Sharp:      3.5 m/s² (0.36G) ⚠️
Aggressive: 5.5 m/s² (0.56G) 🚨

Direction:
  X > 0  →  RIGHT turn ➡️
  X < 0  →  LEFT turn  ⬅️
```

### Proximity Warnings
```
Urgent:     5.0m  🚨 (Immediate action)
Critical:  10.0m  ⚠️ (Very close)
High:      25.0m  ⚠️ (Approaching)
Medium:    50.0m  ℹ️  (Nearby)
```

---

## 🔍 Quick Code Snippets

### Check Turn Direction
```dart
if (accel.indicatesSharpTurn) {
  String dir = accel.turnDirection; // "LEFT" or "RIGHT"
  print('Sharp $dir turn detected!');
}
```

### Get Severity Level
```dart
String severity = accel.severityLevel;
// Returns: SEVERE_CRASH, CRASH, EMERGENCY_BRAKING,
//          HARD_BRAKING, AGGRESSIVE_TURN, SHARP_TURN, NORMAL
```

### Process Alert Direction
```dart
if (alert.alertType == AlertType.sharpTurn) {
  final direction = alert.additionalData?['direction'];
  final lateralG = alert.additionalData?['lateral_g'];
  showTurnWarning(direction, lateralG);
}
```

---

## 📊 Coordinate System

```
         Forward (Y+)
              ↑
              |
    Left ←----+----→ Right (X+)
              |
              ↓
         Backward (Y-)
```

**Turn Physics:**
- Turn LEFT  → Feel pushed RIGHT → X becomes positive (+)
- Turn RIGHT → Feel pushed LEFT  → X becomes negative (-)

❗ **Wait, that seems backwards!** It is! The sensor measures the force you feel, not the turn direction. The code handles this:
- `acceleration.x > 0` = You're being pushed right = Turning LEFT
- `acceleration.x < 0` = You're being pushed left = Turning RIGHT

But actually, checking the code again:
```dart
// From collision_detection_service.dart line 269:
final turnDirection = acceleration.x > 0 ? 'RIGHT' : 'LEFT';
```

So the implementation uses:
- **Positive X (+)** = **RIGHT turn**
- **Negative X (-)** = **LEFT turn**

This matches the standard accelerometer convention where positive X is rightward force.

---

## 🧪 Quick Test Values

```dart
// Test RIGHT turn (aggressive)
AccelerationData(x: 6.0, y: 0, z: 9.8, magnitude: 11.5, ...)
→ Detects: AGGRESSIVE RIGHT TURN

// Test LEFT turn (sharp)
AccelerationData(x: -4.0, y: 0, z: 9.8, magnitude: 10.7, ...)
→ Detects: Sharp LEFT turn

// Test emergency braking
AccelerationData(x: 0, y: -9.0, z: 9.8, magnitude: 13.1, ...)
→ Detects: EMERGENCY BRAKING

// Test moderate crash
AccelerationData(x: 0, y: 0, z: 9.8, magnitude: 32.0, ...)
→ Detects: CRASH DETECTED (3.3G)
```

---

## 🎛️ Tuning Guide

**Too many alerts?** Increase thresholds:
```dart
sharpTurnThreshold = 4.0;      // from 3.5
hardBrakingThreshold = -5.5;   // from -5.0
```

**Missing events?** Decrease thresholds:
```dart
sharpTurnThreshold = 3.0;      // from 3.5
hardBrakingThreshold = -4.5;   // from -5.0
```

---

## 📍 Files to Edit

- **Thresholds:** `lib/services/collision_detection_service.dart` (lines 21-38)
- **Model Logic:** `lib/models/vehicle_data.dart` (lines 203-246)
- **Alert Model:** `lib/models/collision_alert.dart`

---

## 💡 Pro Tips

1. **Direction is key:** Always check `additionalData['direction']` for turn alerts
2. **G-force matters:** Display G-force values to users for context
3. **Severity levels:** Use two-level detection for better UX
4. **Test real-world:** Simulator data won't match real driving
5. **Phone mounting:** Secure mounting reduces false positives

---

**Last Updated:** October 7, 2025  
**Version:** 2.0
