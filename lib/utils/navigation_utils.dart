import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class NavigationUtils {
  /// Calculate distance between two geographic points using Haversine formula
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    
    double lat1Rad = _degreesToRadians(lat1);
    double lat2Rad = _degreesToRadians(lat2);
    double deltaLatRad = _degreesToRadians(lat2 - lat1);
    double deltaLonRad = _degreesToRadians(lon2 - lon1);
    
    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLonRad / 2) * math.sin(deltaLonRad / 2);
        
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadiusKm * c * 1000; // Convert to meters
  }
  
  /// Calculate bearing between two geographic points
  static double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    double lat1Rad = _degreesToRadians(lat1);
    double lat2Rad = _degreesToRadians(lat2);
    double deltaLonRad = _degreesToRadians(lon2 - lon1);
    
    double y = math.sin(deltaLonRad) * math.cos(lat2Rad);
    double x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLonRad);
        
    double bearingRad = math.atan2(y, x);
    double bearingDeg = _radiansToDegrees(bearingRad);
    
    return (bearingDeg + 360) % 360; // Normalize to 0-360 degrees
  }
  
  /// Calculate time to collision based on current positions and velocities
  static double? calculateTimeToCollision(
    double lat1, double lon1, double velocity1, double heading1,
    double lat2, double lon2, double velocity2, double heading2
  ) {
    // Convert velocities from km/h to m/s
    double v1ms = velocity1 * 1000 / 3600;
    double v2ms = velocity2 * 1000 / 3600;
    
    // Calculate relative velocity components
    double v1x = v1ms * math.cos(_degreesToRadians(heading1));
    double v1y = v1ms * math.sin(_degreesToRadians(heading1));
    double v2x = v2ms * math.cos(_degreesToRadians(heading2));
    double v2y = v2ms * math.sin(_degreesToRadians(heading2));
    
    double relativeVx = v1x - v2x;
    double relativeVy = v1y - v2y;
    
    // Calculate relative position
    double distance = calculateDistance(lat1, lon1, lat2, lon2);
    double bearing = calculateBearing(lat1, lon1, lat2, lon2);
    
    double relativePx = distance * math.cos(_degreesToRadians(bearing));
    double relativePy = distance * math.sin(_degreesToRadians(bearing));
    
    // Calculate time to closest approach
    double relativeSpeed = math.sqrt(relativeVx * relativeVx + relativeVy * relativeVy);
    if (relativeSpeed < 0.1) return null; // Vehicles moving at similar speed/direction
    
    double timeToClosest = -(relativePx * relativeVx + relativePy * relativeVy) / 
        (relativeVx * relativeVx + relativeVy * relativeVy);
        
    if (timeToClosest < 0) return null; // Vehicles moving away from each other
    
    // Calculate minimum distance at closest approach
    double closestPx = relativePx + relativeVx * timeToClosest;
    double closestPy = relativePy + relativeVy * timeToClosest;
    double minDistance = math.sqrt(closestPx * closestPx + closestPy * closestPy);
    
    // Return time to collision if minimum distance is less than safe threshold
    return minDistance < 10.0 ? timeToClosest : null; // 10m safety threshold
  }
  
  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
  
  /// Convert radians to degrees
  static double _radiansToDegrees(double radians) {
    return radians * 180.0 / math.pi;
  }
  
  /// Format distance for display
  static String formatDistance(double distanceMeters) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)}m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
    }
  }
  
  /// Format speed for display
  static String formatSpeed(double speedKmh) {
    return '${speedKmh.toStringAsFixed(1)} km/h';
  }
  
  /// Format time for display
  static String formatTime(double timeSeconds) {
    if (timeSeconds < 60) {
      return '${timeSeconds.toStringAsFixed(1)}s';
    } else {
      int minutes = (timeSeconds / 60).floor();
      int seconds = (timeSeconds % 60).floor();
      return '${minutes}m ${seconds}s';
    }
  }
  
  /// Check if location permission is granted
  static Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }
  
  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }
  
  /// Check if location services are enabled
  static Future<bool> checkLocationServices() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  /// Calculate cooperative position using weighted average
  static Map<String, double> calculateCooperativePosition(
    List<Map<String, double>> positions,
    List<double> weights
  ) {
    if (positions.isEmpty) {
      throw ArgumentError('Position list cannot be empty');
    }
    
    if (positions.length != weights.length) {
      throw ArgumentError('Positions and weights lists must have same length');
    }
    
    double totalWeight = weights.reduce((a, b) => a + b);
    double weightedLat = 0.0;
    double weightedLon = 0.0;
    double weightedAccuracy = 0.0;
    
    for (int i = 0; i < positions.length; i++) {
      double weight = weights[i] / totalWeight;
      weightedLat += positions[i]['latitude']! * weight;
      weightedLon += positions[i]['longitude']! * weight;
      weightedAccuracy += positions[i]['accuracy']! * weight;
    }
    
    return {
      'latitude': weightedLat,
      'longitude': weightedLon,
      'accuracy': weightedAccuracy,
    };
  }
  
  /// Calculate GNSS quality score based on satellite count and accuracy
  static double calculateGnssQuality(int satelliteCount, double accuracy) {
    // Normalize satellite count (0-20 satellites -> 0-1 score)
    double satelliteScore = math.min(satelliteCount / 20.0, 1.0);
    
    // Normalize accuracy (0-10m accuracy -> 1-0 score)
    double accuracyScore = math.max(0.0, 1.0 - (accuracy / 10.0));
    
    // Combined score with equal weighting
    return (satelliteScore + accuracyScore) / 2.0;
  }
  
  /// Generate unique device identifier for mesh networking
  static String generateDeviceId() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    math.Random random = math.Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }
}