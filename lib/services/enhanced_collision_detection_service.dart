import 'dart:async';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/vehicle.dart';
import '../models/ble_device.dart';
import 'doppler_service.dart';
import 'kalman_gps_service.dart';

/// Enhanced Collision Detection Engine
/// Multi-modal risk assessment using Doppler speed, GPS, and trajectory analysis
class CollisionDetectionService {
  final DopplerService _dopplerService;
  final KalmanGPSService _kalmanService;
  
  // Collision thresholds
  static const double criticalDistance = 10.0; // meters
  static const double warningDistance = 30.0; // meters
  static const double criticalTTC = 3.0; // seconds
  static const double warningTTC = 10.0; // seconds
  
  // Risk weights for multi-modal assessment
  static const double distanceWeight = 0.4;
  static const double speedWeight = 0.3;
  static const double trajectoryWeight = 0.3;
  
  // Collision alerts
  final StreamController<Map<String, dynamic>> _alertController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get alertStream => _alertController.stream;
  
  CollisionDetectionService(this._dopplerService, this._kalmanService);
  
  /// Calculate collision risk between self and another vehicle
  double calculateCollisionRisk(Vehicle self, Vehicle other, BLEDevice? bleDevice) {
    // 1. Distance-based risk
    final distance = _calculateDistance(self.position, other.position);
    final distanceRisk = _calculateDistanceRisk(distance);
    
    // 2. Speed-based risk (relative speed from Doppler)
    double speedRisk = 0.0;
    if (bleDevice != null) {
      final relativeSpeed = _dopplerService.estimateRelativeSpeed(bleDevice);
      speedRisk = _calculateSpeedRisk(relativeSpeed, distance);
    } else if (other.relativeSpeed != null) {
      speedRisk = _calculateSpeedRisk(other.relativeSpeed!, distance);
    }
    
    // 3. Trajectory-based risk
    final trajectoryRisk = _calculateTrajectoryRisk(self, other);
    
    // Combined risk (weighted average)
    final totalRisk = (distanceRisk * distanceWeight) +
                      (speedRisk * speedWeight) +
                      (trajectoryRisk * trajectoryWeight);
    
    return totalRisk.clamp(0.0, 1.0);
  }
  
  /// Calculate distance between two positions
  double _calculateDistance(LatLng pos1, LatLng pos2) {
    const Distance distance = Distance();
    return distance.distance(pos1, pos2);
  }
  
  /// Calculate risk based on distance
  double _calculateDistanceRisk(double distance) {
    if (distance < criticalDistance) {
      return 1.0; // Maximum risk
    } else if (distance < warningDistance) {
      // Linear interpolation between critical and warning
      return 1.0 - ((distance - criticalDistance) / (warningDistance - criticalDistance)) * 0.5;
    } else {
      // Exponential decay for larger distances
      return 0.5 * exp(-(distance - warningDistance) / 50.0);
    }
  }
  
  /// Calculate risk based on relative speed
  double _calculateSpeedRisk(double relativeSpeed, double distance) {
    if (relativeSpeed <= 0) {
      return 0.0; // Moving apart
    }
    
    // Calculate TTC
    final ttc = distance / relativeSpeed;
    
    if (ttc < criticalTTC) {
      return 1.0;
    } else if (ttc < warningTTC) {
      return 1.0 - ((ttc - criticalTTC) / (warningTTC - criticalTTC)) * 0.6;
    } else {
      return 0.4 * exp(-(ttc - warningTTC) / 20.0);
    }
  }
  
  /// Calculate risk based on trajectory intersection
  double _calculateTrajectoryRisk(Vehicle self, Vehicle other) {
    // Calculate if trajectories will intersect
    
    // Get velocity vectors
    final selfVelocity = _kalmanService.getVelocity();
    final selfVx = selfVelocity[0];
    final selfVy = selfVelocity[1];
    
    // Estimate other vehicle's velocity (simplified)
    final otherHeadingRad = other.heading * pi / 180;
    final otherVx = other.speed * cos(otherHeadingRad);
    final otherVy = other.speed * sin(otherHeadingRad);
    
    // Relative velocity
    final relVx = otherVx - selfVx;
    final relVy = otherVy - selfVy;
    
    // If relative velocity is very small, no collision risk from trajectory
    if (sqrt(relVx * relVx + relVy * relVy) < 0.1) {
      return 0.0;
    }
    
    // Convert positions to local coordinates for calculation
    final dx = (other.position.longitude - self.position.longitude) * 111320 * cos(self.position.latitude * pi / 180);
    final dy = (other.position.latitude - self.position.latitude) * 111320;
    
    // Time to CPA
    final tcpa = -(dx * relVx + dy * relVy) / (relVx * relVx + relVy * relVy);
    
    if (tcpa < 0) {
      return 0.0; // CPA is in the past
    }
    
    // Distance at CPA
    final cpaX = dx + relVx * tcpa;
    final cpaY = dy + relVy * tcpa;
    final cpaDistance = sqrt(cpaX * cpaX + cpaY * cpaY);
    
    // Risk based on CPA distance
    if (cpaDistance < criticalDistance) {
      return 1.0;
    } else if (cpaDistance < warningDistance) {
      return 1.0 - (cpaDistance - criticalDistance) / (warningDistance - criticalDistance);
    } else {
      return 0.0;
    }
  }
  
  /// Analyze collision risk with all nearby vehicles
  Future<List<Map<String, dynamic>>> analyzeCollisions(
    Vehicle self,
    List<Vehicle> nearbyVehicles,
    Map<String, BLEDevice> bleDevices,
  ) async {
    final collisionWarnings = <Map<String, dynamic>>[];
    
    for (final other in nearbyVehicles) {
      if (other.id == self.id) continue;
      
      final bleDevice = bleDevices[other.id];
      final risk = calculateCollisionRisk(self, other, bleDevice);
      
      if (risk > 0.3) { // Threshold for warning
        final warning = {
          'vehicleId': other.id,
          'risk': risk,
          'distance': _calculateDistance(self.position, other.position),
          'relativeSpeed': bleDevice?.estimatedSpeed ?? other.relativeSpeed,
          'timestamp': DateTime.now(),
          'severity': _getSeverity(risk),
        };
        
        collisionWarnings.add(warning);
        
        // Emit alert for critical risks
        if (risk > 0.7) {
          _alertController.add(warning);
        }
      }
    }
    
    // Sort by risk (highest first)
    collisionWarnings.sort((a, b) => 
        (b['risk'] as double).compareTo(a['risk'] as double)
    );
    
    return collisionWarnings;
  }
  
  /// Get severity level from risk score
  String _getSeverity(double risk) {
    if (risk >= 0.8) return 'CRITICAL';
    if (risk >= 0.6) return 'HIGH';
    if (risk >= 0.4) return 'MEDIUM';
    return 'LOW';
  }
  
  /// Check for imminent collision (sub-100ms detection)
  bool checkImminentCollision(Vehicle self, Vehicle other, BLEDevice? bleDevice) {
    final distance = _calculateDistance(self.position, other.position);
    
    if (distance > criticalDistance) return false;
    
    final risk = calculateCollisionRisk(self, other, bleDevice);
    
    return risk > 0.8; // Critical threshold
  }
  
  /// Predict collision point
  LatLng? predictCollisionPoint(Vehicle self, Vehicle other) {
    // Simple linear extrapolation - future enhancement can use velocity
    // For simplification, return midpoint if collision risk is high
    final distance = _calculateDistance(self.position, other.position);
    
    if (distance < criticalDistance) {
      return LatLng(
        (self.position.latitude + other.position.latitude) / 2,
        (self.position.longitude + other.position.longitude) / 2,
      );
    }
    
    return null;
  }
  
  /// Dispose resources
  void dispose() {
    _alertController.close();
  }
}
