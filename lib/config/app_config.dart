class AppConfig {
  // App Information
  static const String appName = 'NaviSafe';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Autonomous Vehicle Navigation with Cooperative Positioning';
  
  // OpenStreetMap Configuration
  static const String osmTileServerUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmAttributionText = '© OpenStreetMap contributors';
  
  // GNSS Configuration
  static const double gnssUpdateIntervalMs = 100.0; // 10 Hz update rate
  static const double cooperativePositioningRadius = 100.0; // meters
  static const int maxCooperativeVehicles = 10;
  
  // Mesh Network Configuration
  static const String meshNetworkServiceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String positionCharacteristicUuid = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String vehicleDataCharacteristicUuid = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';
  static const int meshNetworkScanDurationSeconds = 5;
  static const int positionBroadcastIntervalMs = 500; // 2 Hz broadcast rate
  
  // Collision Detection Configuration
  static const double collisionThresholdAcceleration = 15.0; // m/s²
  static const double warningDistanceMeters = 50.0;
  static const double criticalDistanceMeters = 20.0;
  static const double emergencyDistanceMeters = 10.0;
  static const int accelerometerSampleRateHz = 50;
  
  // Navigation Configuration
  static const double defaultZoomLevel = 16.0;
  static const double vehicleIconSize = 40.0;
  static const double alertRadiusSize = 100.0;
  
  // Safety Configuration
  static const int maxAlertsDisplayed = 5;
  static const int alertDisplayDurationSeconds = 10;
  static const double maxSafeSpeed = 30.0; // km/h
  
  // Database Configuration
  static const String databaseName = 'navisafe_database.db';
  static const int databaseVersion = 1;
  static const int dataRetentionDays = 7;
  
  // Development Flags
  static const bool isDebugMode = true;
  static const bool enableMockGnss = true;
  static const bool enableMockMeshNetwork = true;
  static const bool enableLogging = true;
  
  // NavIC/IRNSS Configuration
  static const List<String> supportedGnssConstellations = [
    'GPS',
    'GLONASS', 
    'Galileo',
    'BeiDou',
    'NavIC', // Indian Regional Navigation Satellite System
    'QZSS'
  ];
  
  // Cooperative Positioning Algorithm Parameters
  static const double cooperativePositionWeight = 0.3;
  static const double kalmanFilterProcessNoise = 0.1;
  static const double kalmanFilterMeasurementNoise = 1.0;
  static const int cooperativePositionHistorySize = 10;
  
  // Performance Optimization
  static const int maxUIUpdateRateHz = 30;
  static const int backgroundTaskIntervalMs = 1000;
  static const bool enablePerformanceMonitoring = true;
}