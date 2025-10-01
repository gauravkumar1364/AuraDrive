# NaviSafe - Autonomous Vehicle Navigation App

NaviSafe is a Flutter application designed for autonomous vehicle navigation using cooperative smartphone positioning, GNSS (including NavIC), and Bluetooth Low Energy (BLE) mesh networking with OpenStreetMap.

## Features

- **Cooperative Positioning**: Enhanced GNSS accuracy through smartphone-to-smartphone data sharing
- **Mesh Networking**: BLE-based peer-to-peer communication for real-time vehicle data exchange
- **Collision Detection**: Real-time collision risk assessment using IMU sensors
- **Safety Alerts**: Priority-based safety alert system with visual and audio notifications
- **OpenStreetMap Integration**: Real-time navigation with custom vehicle markers and safety overlays
- **NavIC Support**: Indian Regional Navigation Satellite System (IRNSS) integration
- **Multi-Platform**: Supports Android and iOS with platform-specific optimizations

## Architecture

### Core Components

1. **Data Models** (`lib/models/`)
   - `PositionData`: GNSS positioning with cooperative enhancement
   - `VehicleData`: Vehicle state including velocity, acceleration, and device info
   - `NetworkDevice`: BLE mesh network device management
   - `CollisionAlert`: Safety alert system with risk levels
   - `GnssQuality`: GNSS quality metrics and constellation support

2. **Services** (`lib/services/`)
   - `GnssService`: GNSS positioning with cooperative algorithms
   - `MeshNetworkService`: BLE device discovery and data broadcasting
   - `CollisionDetectionService`: Real-time collision detection using sensors

3. **UI Components** (`lib/screens/` & `lib/widgets/`)
   - `NavigationScreen`: Main navigation interface with OpenStreetMap
   - `SafetyAlertsWidget`: Dynamic safety alert display
   - `MeshNetworkWidget`: Network status and device management

4. **Configuration** (`lib/config/`)
   - `AppConfig`: Centralized application configuration and parameters

5. **Utilities** (`lib/utils/`)
   - `NavigationUtils`: Helper functions for calculations and formatting

## Prerequisites

- Flutter SDK 3.24.3 or later
- Dart 3.9.2 or later
- Android Studio or VS Code with Flutter extensions
- Android device with API level 21+ for BLE and location features
- iOS device with iOS 11+ for Core Location and Core Bluetooth

## Setup Instructions

### 1. Clone and Install Dependencies

```bash
git clone <repository-url>
cd navisafe_app
flutter pub get
```

### 2. OpenStreetMap Configuration

NaviSafe uses OpenStreetMap which requires **no API keys** and is completely free to use. The app is pre-configured with:

- **Tile Server**: OpenStreetMap standard tile server
- **Attribution**: Proper attribution to OpenStreetMap contributors
- **Offline Support**: Can be extended to support offline tile caching

No additional configuration needed for maps!

### 3. Platform-Specific Setup

#### Android
The following permissions are already configured in `AndroidManifest.xml`:
- Location (Fine and Coarse)
- Bluetooth (including BLE)
- Sensors and Activity Recognition
- Internet and Network State
- Storage and Wake Lock

#### iOS
The following permissions are configured in `Info.plist`:
- Location (When In Use, Always)
- Bluetooth (Always, Peripheral)
- Motion and Fitness
- Camera and Microphone (for future features)

### 4. Build and Run

```bash
# Debug build
flutter run

# Release build
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## Configuration

### GNSS Settings
```dart
// lib/config/app_config.dart
static const double gnssUpdateIntervalMs = 100.0; // 10 Hz
static const double cooperativePositioningRadius = 100.0; // meters
static const int maxCooperativeVehicles = 10;
```

### Mesh Network Settings
```dart
static const int meshNetworkScanDurationSeconds = 5;
static const int positionBroadcastIntervalMs = 500; // 2 Hz
```

### Safety Settings
```dart
static const double warningDistanceMeters = 50.0;
static const double criticalDistanceMeters = 20.0;
static const double emergencyDistanceMeters = 10.0;
```

## Usage

1. **Grant Permissions**: Allow location and Bluetooth permissions when prompted
2. **Start Navigation**: The app will automatically start GNSS positioning and BLE scanning
3. **Mesh Networking**: Nearby vehicles running NaviSafe will automatically connect
4. **Safety Alerts**: Watch for collision warnings and follow recommended actions
5. **Cooperative Positioning**: Enhanced accuracy when multiple vehicles are connected

## Development Notes

### Mock Data
For development and testing, mock data is enabled by default:
```dart
// lib/config/app_config.dart
static const bool enableMockGnss = true;
static const bool enableMockMeshNetwork = true;
```

### Debugging
Enable detailed logging:
```dart
static const bool enableLogging = true;
static const bool isDebugMode = true;
```

### Performance Monitoring
Monitor app performance:
```dart
static const bool enablePerformanceMonitoring = true;
static const int maxUIUpdateRateHz = 30;
```

## Supported GNSS Constellations

- GPS (Global Positioning System)
- GLONASS (Russian)
- Galileo (European)
- BeiDou (Chinese)
- **NavIC/IRNSS** (Indian Regional Navigation Satellite System)
- QZSS (Japanese)

## Troubleshooting

### Common Issues

1. **Location Not Working**:
   - Check if location permissions are granted
   - Ensure location services are enabled
   - Verify GPS is working in other apps

2. **Bluetooth Issues**:
   - Ensure Bluetooth is enabled
   - Check if BLE is supported on device
   - Grant all Bluetooth permissions

3. **Google Maps Not Loading**:
   - Verify API key is correctly configured
   - Check if Maps SDK is enabled in Google Cloud Console
   - Ensure internet connection is available

4. **App Crashes**:
   - Check device compatibility (API level 21+ for Android)
   - Verify all dependencies are properly installed
   - Review device logs for specific error messages

### Performance Tips

1. **Battery Optimization**:
   - Disable battery optimization for NaviSafe
   - Use power-saving mode when not actively navigating

2. **Network Efficiency**:
   - Monitor data usage in mesh networking
   - Adjust broadcast intervals based on vehicle density

3. **Sensor Accuracy**:
   - Calibrate device sensors regularly
   - Ensure device is mounted securely in vehicle

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For technical support or feature requests, please create an issue in the GitHub repository.

---

**NaviSafe** - Enhancing autonomous vehicle safety through cooperative navigation technology.
