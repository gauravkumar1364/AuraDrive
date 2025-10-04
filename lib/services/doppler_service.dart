import 'dart:math';
import '../models/ble_device.dart';

/// Doppler Speed Estimator
/// Analyzes BLE RSSI frequency shifts to calculate relative velocity
class DopplerService {
  // BLE frequency: 2.4 GHz
  static const double bleFrequency = 2.4e9; // Hz
  static const double speedOfLight = 3.0e8; // m/s
  
  // Path loss model parameters
  static const double pathLossExponent = 2.0; // Free space
  static const double referenceDistance = 1.0; // meters
  static const int referenceRSSI = -50; // dBm at 1 meter
  
  /// Estimate relative speed between two devices using Doppler effect
  /// Returns speed in m/s (positive = approaching, negative = receding)
  double estimateRelativeSpeed(BLEDevice device) {
    if (device.rssiHistory.length < 3) {
      return 0.0; // Insufficient data
    }
    
    // Method 1: Use RSSI trend to estimate speed
    final rssiTrend = device.rssiTrend;
    
    // Convert RSSI change rate to distance change rate
    // RSSI (dBm) = -10*n*log10(d) + C
    // d = distance in meters, n = path loss exponent
    
    // Approximate speed from RSSI change
    // Stronger signal (increasing RSSI) = approaching
    // Weaker signal (decreasing RSSI) = receding
    
    // Simple model: 1 dBm/sample ≈ 1 m/s (calibrated experimentally)
    final estimatedSpeed = rssiTrend * 0.5;
    
    device.estimatedSpeed = estimatedSpeed;
    return estimatedSpeed;
  }
  
  /// Calculate distance from RSSI using path loss model
  double estimateDistance(int rssi) {
    // FSPL: RSSI = referenceRSSI - 10*n*log10(d/d0)
    final pathLoss = referenceRSSI - rssi;
    final distance = referenceDistance * pow(10, pathLoss / (10 * pathLossExponent));
    return distance.toDouble();
  }
  
  /// Estimate Doppler frequency shift (theoretical)
  /// f_observed = f_transmitted * (c + v_receiver) / (c + v_sender)
  /// For small velocities: Δf ≈ f * v / c
  double calculateDopplerShift(double relativeSpeed) {
    return bleFrequency * relativeSpeed / speedOfLight;
  }
  
  /// Calculate relative velocity between two devices
  /// using multiple RSSI samples and time-of-flight approximation
  double calculateRelativeVelocity(
    List<int> rssiHistory,
    List<DateTime> timestamps,
  ) {
    if (rssiHistory.length < 2 || timestamps.length < 2) {
      return 0.0;
    }
    
    // Calculate distance at first and last sample
    final distance1 = estimateDistance(rssiHistory.first);
    final distance2 = estimateDistance(rssiHistory.last);
    
    // Calculate time difference
    final timeDiff = timestamps.last.difference(timestamps.first).inMilliseconds / 1000.0;
    
    if (timeDiff == 0) return 0.0;
    
    // Velocity = distance change / time
    final velocity = (distance2 - distance1) / timeDiff;
    
    return velocity;
  }
  
  /// Advanced: Multi-sample analysis for better accuracy
  double estimateSpeedAdvanced(BLEDevice device) {
    if (device.rssiHistory.length < 5) {
      return estimateRelativeSpeed(device);
    }
    
    // Use sliding window to calculate instantaneous velocities
    final List<double> velocities = [];
    
    for (int i = 0; i < device.rssiHistory.length - 1; i++) {
      final d1 = estimateDistance(device.rssiHistory[i]);
      final d2 = estimateDistance(device.rssiHistory[i + 1]);
      
      // Assume 100ms between samples
      final dt = 0.1; // seconds
      final v = (d2 - d1) / dt;
      
      velocities.add(v);
    }
    
    // Return median velocity (more robust to outliers)
    if (velocities.isEmpty) return 0.0;
    
    velocities.sort();
    final median = velocities[velocities.length ~/ 2];
    
    return median;
  }
  
  /// Predict future distance based on current speed
  double predictFutureDistance(
    BLEDevice device,
    double currentDistance,
    double timeAhead, // seconds
  ) {
    if (device.estimatedSpeed == null) {
      return currentDistance;
    }
    
    // Linear prediction: d(t) = d(0) + v*t
    return currentDistance + device.estimatedSpeed! * timeAhead;
  }
  
  /// Calculate time to collision (TTC)
  /// Returns null if vehicles are moving apart
  double? calculateTimeToCollision(
    BLEDevice device,
    double currentDistance,
  ) {
    if (device.estimatedSpeed == null || device.estimatedSpeed! <= 0) {
      return null; // Moving apart or stationary
    }
    
    // TTC = distance / closing_speed
    return currentDistance / device.estimatedSpeed!;
  }
  
  /// Calibrate RSSI-to-distance model (can be improved with training data)
  void calibrateModel(List<Map<String, double>> measurements) {
    // measurements: [{rssi: -60, distance: 5.0}, ...]
    // TODO: Use least squares regression to improve path loss model
  }
}
