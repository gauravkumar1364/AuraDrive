import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Service for calculating road-based routes between locations
class RoutingService {
  // Using OSRM (Open Source Routing Machine) - free, no API key needed
  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1';
  
  /// Calculate route between two points
  /// Returns list of LatLng points following actual roads
  Future<List<LatLng>?> getRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'driving', // driving, walking, cycling
  }) async {
    try {
      // Build OSRM request URL
      final url = Uri.parse(
        '$_osrmBaseUrl/$profile/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson'
      );
      
      debugPrint('Fetching route: $url');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          
          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            
            // Convert coordinates to LatLng list
            final points = coordinates.map((coord) {
              return LatLng(
                (coord[1] as num).toDouble(), // latitude
                (coord[0] as num).toDouble(), // longitude
              );
            }).toList();
            
            debugPrint('Route found with ${points.length} points');
            debugPrint('Distance: ${(route['distance'] / 1000).toStringAsFixed(2)} km');
            debugPrint('Duration: ${(route['duration'] / 60).toStringAsFixed(0)} min');
            
            return points;
          }
        }
      } else {
        debugPrint('Routing error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Route calculation error: $e');
    }
    
    // Fallback: return straight line if routing fails
    return [start, end];
  }
  
  /// Get route with additional information (distance, duration)
  Future<RouteInfo?> getRouteInfo({
    required LatLng start,
    required LatLng end,
    String profile = 'driving',
  }) async {
    try {
      final url = Uri.parse(
        '$_osrmBaseUrl/$profile/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson'
      );
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          
          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            
            final points = coordinates.map((coord) {
              return LatLng(
                (coord[1] as num).toDouble(),
                (coord[0] as num).toDouble(),
              );
            }).toList();
            
            return RouteInfo(
              points: points,
              distanceMeters: (route['distance'] as num).toDouble(),
              durationSeconds: (route['duration'] as num).toDouble(),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Route info error: $e');
    }
    
    // Fallback
    return RouteInfo(
      points: [start, end],
      distanceMeters: _calculateDistance(start, end),
      durationSeconds: 0,
    );
  }
  
  /// Calculate straight-line distance between two points (in meters)
  double _calculateDistance(LatLng start, LatLng end) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, start, end);
  }
}

/// Route information model
class RouteInfo {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  
  RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
  
  double get distanceKm => distanceMeters / 1000;
  double get durationMinutes => durationSeconds / 60;
  
  String get formattedDistance {
    if (distanceKm < 1) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
  
  String get formattedDuration {
    final hours = (durationMinutes / 60).floor();
    final mins = (durationMinutes % 60).round();
    
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}
