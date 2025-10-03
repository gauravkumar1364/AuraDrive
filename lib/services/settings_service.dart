import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app settings and preferences
class SettingsService {
  static const String _keySoundAlerts = 'sound_alerts';
  static const String _keyVibrationAlerts = 'vibration_alerts';
  static const String _keyProximityThreshold = 'proximity_threshold';

  /// Get sound alerts setting
  Future<bool> getSoundAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySoundAlerts) ?? true; // Default: enabled
  }

  /// Set sound alerts setting
  Future<void> setSoundAlerts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundAlerts, value);
  }

  /// Get vibration alerts setting
  Future<bool> getVibrationAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyVibrationAlerts) ?? true; // Default: enabled
  }

  /// Set vibration alerts setting
  Future<void> setVibrationAlerts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVibrationAlerts, value);
  }

  /// Get proximity threshold setting
  /// Returns: '25m', '50m', or '100m'
  Future<String> getProximityThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProximityThreshold) ?? '25m'; // Default: Normal (25m)
  }

  /// Set proximity threshold setting
  Future<void> setProximityThreshold(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProximityThreshold, value);
  }

  /// Get proximity threshold in meters
  Future<double> getProximityThresholdMeters() async {
    final threshold = await getProximityThreshold();
    switch (threshold) {
      case '25m':
        return 25.0;
      case '50m':
        return 50.0;
      case '100m':
        return 100.0;
      default:
        return 25.0;
    }
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundAlerts, true);
    await prefs.setBool(_keyVibrationAlerts, true);
    await prefs.setString(_keyProximityThreshold, '25m');
  }
}
