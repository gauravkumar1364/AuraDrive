# Settings Screen Documentation

## Overview
A comprehensive settings screen that allows users to configure AuraDrive preferences, view their device information, and access help resources.

## Features

### 👤 User Profile Section
- **Profile Avatar** - Shows first letter of user's name in a circular purple badge
- **User Name** - Full name displayed prominently
- **Email Address** - User's email shown below name
- Modern card design with dark theme

### 🔔 Alert Preferences
**Sound Alerts**
- Toggle to enable/disable sound notifications
- Description: "Play sound when vehicles are nearby"
- Icon: Volume up
- Default: ON

**Vibration Alerts**
- Toggle to enable/disable vibration feedback
- Description: "Vibrate on proximity warnings"
- Icon: Vibration
- Default: ON

### 📏 Proximity Thresholds
Three distance options with visual selection:

**Normal (25 meters)**
- Default setting
- Good for urban driving
- Balanced between early warning and alert frequency

**Far (50 meters)**
- Extended warning distance
- Better for highway driving
- More time to react

**Very Far (100 meters)**
- Maximum warning distance
- Best for high-speed scenarios
- Maximum safety buffer

**UI Features:**
- Radio button style selection
- Purple border on selected option
- Checkmark icon for active choice
- Shows distance in meters

### 📱 Device Information
**Device ID**
- Displays unique UUID
- Truncated display (first 20 characters)
- **Tap to copy** to clipboard
- Copy icon indicator
- Shows success message when copied

**Phone Number**
- Displays registered phone number
- Read-only field
- Shows full number with country code

### ❓ Help & About

**How to Use**
- Opens helpful guide dialog
- 4-step tutorial:
  1. Keep Bluetooth On
  2. Grant Permissions
  3. Drive Safely
  4. Monitor Map
- Easy-to-follow instructions

**Privacy Policy**
- Complete privacy information
- Data usage transparency
- Contact information included
- Key points:
  - Location only for proximity
  - Bluetooth-only sharing
  - No external servers
  - Local data storage
  - User data control

**About AuraDrive**
- App version (1.0.0)
- App description
- Beautiful branding
- **Made with ❤️ by BODMAS** 💜
- Logo display

### 🚪 Account Management
**Logout**
- Red color indicator (destructive action)
- Confirmation dialog before logout
- Returns to welcome screen
- Clears session (keeps user data)

## Design

### Color Scheme
- **Background**: Pure black (`#000000`)
- **Cards**: Dark gray (`#1E1E1E`)
- **Primary Accent**: Purple (`#7B2CBF`)
- **Success**: Teal (`#00C9A7`)
- **Danger**: Red-pink (`#FF4B6E`)
- **Text**: White with opacity variations

### Layout Structure
```
┌─────────────────────────┐
│      Settings ⚙️        │ <- AppBar
├─────────────────────────┤
│   ┌───────────────┐    │
│   │ User Profile  │    │ <- Avatar, Name, Email
│   │     Card      │    │
│   └───────────────┘    │
├─────────────────────────┤
│  ALERT PREFERENCES      │
│  ├ Sound Alerts    [✓] │
│  └ Vibration      [✓]  │
├─────────────────────────┤
│  PROXIMITY THRESHOLD    │
│  ├ Normal (25m)    ✓   │
│  ├ Far (50m)           │
│  └ Very Far (100m)     │
├─────────────────────────┤
│  DEVICE INFORMATION     │
│  ├ Device ID      📋   │
│  └ Phone Number        │
├─────────────────────────┤
│  HELP & ABOUT          │
│  ├ How to Use     →    │
│  ├ Privacy Policy →    │
│  └ About          →    │
├─────────────────────────┤
│  ACCOUNT               │
│  └ Logout         →    │
└─────────────────────────┘
```

### Interaction Patterns
- **Switches**: Toggle on/off for boolean settings
- **Radio Selection**: Single choice for proximity
- **Tappable Cards**: Navigate to details or dialogs
- **Copy Action**: Tap device ID to copy
- **Confirmation Dialogs**: For destructive actions

## Technical Details

### Services Used
- `AuthService` - User profile data
- `SettingsService` - App preferences storage
- `SharedPreferences` - Persistent storage backend

### Settings Storage Keys
```dart
'sound_alerts' → bool
'vibration_alerts' → bool
'proximity_threshold' → String ('25m', '50m', '100m')
```

### Navigation
**Access from:**
- Navigation screen (Settings icon in AppBar)
- Direct navigation: `SettingsScreen()`

**Can navigate to:**
- Welcome screen (after logout)
- Dialogs (How to Use, Privacy, About)

## User Experience

### Loading Behavior
- Loads user profile on init
- Loads saved settings on init
- Shows current values immediately
- No loading spinners needed (fast local data)

### Feedback
- ✅ **Success**: Green snackbar when copying ID
- ⚠️ **Confirmation**: Dialog before logout
- 🎯 **Visual**: Purple highlights for active items
- 💬 **Informative**: Clear descriptions for all settings

### Accessibility
- Large tap targets (minimum 48dp)
- High contrast colors
- Clear section headers
- Descriptive icons
- Readable font sizes

## Special Feature: BODMAS Credit

Located in the "About" dialog:

```
      Made with
          ❤️
          by
       BODMAS
```

- Heart emoji (❤️) centered
- Purple-colored BODMAS text
- Bold and prominent
- Lettersp spacing for style
- Professional yet friendly

## Integration

### In NavigationScreen
```dart
IconButton(
  icon: const Icon(Icons.settings),
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  },
)
```

### Using Settings in App
```dart
final settingsService = SettingsService();

// Get settings
bool soundEnabled = await settingsService.getSoundAlerts();
bool vibrationEnabled = await settingsService.getVibrationAlerts();
String threshold = await settingsService.getProximityThreshold();
double meters = await settingsService.getProximityThresholdMeters();

// Update settings
await settingsService.setSoundAlerts(true);
await settingsService.setVibrationAlerts(false);
await settingsService.setProximityThreshold('50m');
```

## Files Created

### New Files
- `lib/screens/settings_screen.dart` - Complete settings UI
- `lib/services/settings_service.dart` - Settings management
- `SETTINGS_SCREEN.md` - This documentation

### Modified Files
- `lib/screens/navigation_screen.dart` - Added settings button

## Future Enhancements

Potential improvements:
1. **Theme Selection** - Light/Dark mode toggle
2. **Language Selection** - Multilingual support
3. **Unit Preferences** - Meters vs Feet
4. **Data Management** - Export/Import settings
5. **Notification Sounds** - Custom alert tones
6. **Advanced Settings** - Developer options
7. **Profile Edit** - Change name, email, photo
8. **Statistics** - Usage analytics display
9. **Backup & Restore** - Cloud sync option
10. **Feedback System** - In-app bug reports

## Credits

**Made with ❤️ by BODMAS**

The settings screen proudly displays this credit in the About dialog, acknowledging the creator with a heart emoji and stylized typography.
