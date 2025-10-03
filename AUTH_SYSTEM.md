# Authentication System Documentation

## Overview
AuraDrive now includes a complete authentication system with persistent login and automatic navigation based on user state.

## Features Implemented

### 1. ✅ Persistent Login
- **User stays logged in** after closing and reopening the app
- **No repeated login** required once authenticated
- **Unique User ID** generated for each user using UUID v4

### 2. ✅ Smart Navigation
- **Splash Screen** → Checks login status
- **If logged in** → Goes directly to Navigation Screen
- **If not logged in** → Shows onboarding flow

### 3. ✅ Auto-Skip Permissions
- **Checks permissions on load**
- **If all granted** → Automatically proceeds to next screen (500ms delay)
- **If missing** → Shows permission request UI

### 4. ✅ User Data Storage
Uses `SharedPreferences` to store:
- User ID (UUID v4)
- Full Name
- Email Address
- Phone Number
- Login Status
- Onboarding Completion Status

## App Flow

### First Time Users
```
1. Splash Screen (2s animation)
   ↓
2. Welcome Screen (Onboarding)
   ↓
3. How It Works Screen
   ↓
4. Permissions Screen (auto-skips if granted)
   ↓
5. Phone Auth Screen
   ↓
6. Email Auth Screen
   ↓
7. Navigation Screen (Main App)
```

### Returning Users (Logged In)
```
1. Splash Screen (2s animation)
   ↓
2. Navigation Screen (Main App) ✨
```

### Returning Users (Permissions Already Granted)
```
1. Splash Screen
   ↓
2. Welcome Screen
   ↓
3. How It Works
   ↓
4. Permissions Screen (auto-skips in 500ms) ✨
   ↓
5. Phone Auth
   ↓
6. Email Auth
   ↓
7. Navigation Screen
```

## AuthService API

### Check Login Status
```dart
final authService = AuthService();
bool isLoggedIn = await authService.isLoggedIn();
```

### Login/Register User
```dart
String userId = await authService.login(
  name: 'John Doe',
  email: 'john@example.com',
  phone: '+91234567890',
);
// Returns: unique UUID like "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
```

### Get User Data
```dart
String? userId = await authService.getUserId();
String? name = await authService.getUserName();
String? email = await authService.getUserEmail();
String? phone = await authService.getUserPhone();

// Or get complete profile
Map<String, String?> profile = await authService.getUserProfile();
```

### Update Profile
```dart
await authService.updateProfile(
  name: 'Jane Doe',
  email: 'jane@example.com',
);
```

### Logout
```dart
// Soft logout (keeps user data)
await authService.logout();

// Hard logout (clears all data)
await authService.clearAllData();
```

### Complete Onboarding
```dart
await authService.completeOnboarding();
```

## Storage Keys
The following keys are used in SharedPreferences:
- `user_id` - Unique UUID for the user
- `user_name` - Full name
- `user_email` - Email address
- `user_phone` - Phone number with country code
- `is_logged_in` - Boolean login status
- `onboarding_complete` - Boolean onboarding status

## Unique ID Generation
- Uses `uuid` package to generate UUID v4
- Format: `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`
- Example: `f47ac10b-58cc-4372-a567-0e02b2c3d479`
- Generated once on first login
- Persists for the lifetime of the app installation

## User Experience

### Success Message
When user completes registration, they see:
```
"Welcome! Your ID: f47ac10b..."
```
Shows first 8 characters of their unique ID as confirmation.

### Loading States
- **Splash Screen**: 2-second animation before checking auth
- **Email Auth**: Shows loading spinner during registration
- **Permissions**: 500ms delay before auto-skip

### Error Handling
- Try-catch blocks around all async operations
- User-friendly error messages via SnackBar
- Red error notifications
- Green success notifications

## Security Considerations

### Current Implementation
- Data stored locally using SharedPreferences
- No encryption (suitable for demo/development)
- User ID is a random UUID (not based on personal info)

### Production Recommendations
For production use, consider:
1. **Encrypt sensitive data** using `flutter_secure_storage`
2. **Add backend authentication** with JWT tokens
3. **Implement refresh tokens** for session management
4. **Add biometric authentication** option
5. **Hash/salt passwords** if implementing password auth
6. **Add device fingerprinting** for security
7. **Implement rate limiting** for auth attempts

## Testing

### Test First Time User
```dart
// Clear all data
final authService = AuthService();
await authService.clearAllData();
// Restart app → Should show onboarding
```

### Test Returning User
```dart
// Login a user
await authService.login(
  name: 'Test User',
  email: 'test@example.com',
  phone: '+1234567890',
);
// Restart app → Should go directly to navigation
```

### Test Permission Skip
1. Grant all permissions manually in device settings
2. Close and clear app data
3. Restart app and go through onboarding
4. Permissions screen should auto-skip

## Files Changed

### New Files
- `lib/services/auth_service.dart` - Authentication service
- `lib/screens/splash_screen.dart` - Initial loading screen
- `AUTH_SYSTEM.md` - This documentation

### Modified Files
- `lib/main.dart` - Changed home screen to SplashScreen
- `lib/screens/email_auth_screen.dart` - Added AuthService integration
- `lib/screens/permissions_screen.dart` - Added auto-skip logic
- `pubspec.yaml` - Added shared_preferences and uuid packages

## Package Dependencies

### Added Packages
```yaml
shared_preferences: ^2.2.2  # Persistent local storage
uuid: ^4.2.1                # Generate unique identifiers
```

### Installation
```bash
flutter pub get
```

## Future Enhancements

Possible improvements:
1. **Social Login** - Google, Facebook, Apple Sign In
2. **Email Verification** - Send verification code
3. **Phone OTP** - SMS-based verification
4. **Profile Pictures** - Avatar upload and storage
5. **Settings Screen** - Edit profile, logout option
6. **Backend Integration** - Sync with remote server
7. **Multi-device Support** - Same account on multiple devices
8. **Account Recovery** - Forgot password, email recovery
9. **Two-Factor Authentication** - Extra security layer
10. **Analytics** - Track user engagement
