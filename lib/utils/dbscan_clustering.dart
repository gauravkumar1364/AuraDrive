import 'dart:math' show pow, pi, log;
import '../models/models.dart';

class DBSCANCluster {
  // DBSCAN parameters
  final double
  eps; // Maximum distance between devices to be considered neighbors
  final int minPoints; // Minimum points to form a cluster

  DBSCANCluster({
    this.eps = 10.0, // Default 10 meters
    this.minPoints = 3, // Minimum 3 devices for a core point
  });

  // Calculate distance between two devices based on RSSI
  double _calculateDistance(int rssi) {
    // Convert RSSI to approximate distance in meters
    // Using the log-distance path loss model
    // d = 10^((|RSSI| - A)/(10 * n))
    // where A is the RSSI at 1 meter (typically -59 dBm for BLE)
    // and n is the path loss exponent (typically 2.0 for free space)
    const int referenceRssi = -59;
    const double pathLossExponent = 2.0;

    return pow(
      10,
      (rssi.abs() - referenceRssi) / (10 * pathLossExponent),
    ).toDouble();
  }

  // Find neighbors within eps distance
  List<int> _getNeighbors(List<NetworkDevice> devices, int pointIdx) {
    List<int> neighbors = [];
    final device = devices[pointIdx];

    for (int i = 0; i < devices.length; i++) {
      if (i != pointIdx) {
        double distance = _calculateDistance(devices[i].connectionStrength);
        if (distance <= eps) {
          neighbors.add(i);
        }
      }
    }

    return neighbors;
  }

  // Main DBSCAN clustering algorithm
  List<List<NetworkDevice>> cluster(List<NetworkDevice> devices) {
    if (devices.isEmpty) return [];

    Map<int, bool> visited = {};
    Map<int, bool> noise = {};
    Map<int, int> clusterLabels = {}; // Maps point index to cluster number
    List<List<NetworkDevice>> clusters = [];
    int currentCluster = 0;

    // For each point
    for (int i = 0; i < devices.length; i++) {
      if (visited[i] == true) continue;
      visited[i] = true;

      List<int> neighbors = _getNeighbors(devices, i);

      // If point is not a core point, mark as noise
      if (neighbors.length < minPoints - 1) {
        // -1 because neighbors doesn't include the point itself
        noise[i] = true;
        continue;
      }

      // Start a new cluster
      List<NetworkDevice> currentClusterDevices = [devices[i]];
      clusterLabels[i] = currentCluster;

      // Process neighbors
      List<int> seedSet = List.from(neighbors);
      for (int j = 0; j < seedSet.length; j++) {
        int currentPoint = seedSet[j];

        // Handle previously unvisited points
        if (visited[currentPoint] != true) {
          visited[currentPoint] = true;

          List<int> currentNeighbors = _getNeighbors(devices, currentPoint);
          if (currentNeighbors.length >= minPoints - 1) {
            seedSet.addAll(currentNeighbors.where((n) => !seedSet.contains(n)));
          }
        }

        // Add to cluster if not already in one
        if (clusterLabels[currentPoint] == null) {
          currentClusterDevices.add(devices[currentPoint]);
          clusterLabels[currentPoint] = currentCluster;
        }
      }

      clusters.add(currentClusterDevices);
      currentCluster++;
    }

    return clusters;
  }

  // Calculate optimal cluster size based on density
  int calculateOptimalClusterSize(List<NetworkDevice> devices) {
    if (devices.isEmpty) return 8; // Default max size

    // Get clusters
    List<List<NetworkDevice>> clusters = cluster(devices);

    if (clusters.isEmpty) return 8; // Default if no clusters formed

    // Calculate average density across clusters
    double totalDensity = 0;
    for (var cluster in clusters) {
      // Calculate cluster radius (max distance from any point to any other point)
      double maxDistance = 0;
      for (var device1 in cluster) {
        for (var device2 in cluster) {
          double distance = _calculateDistance(device1.connectionStrength);
          if (distance > maxDistance) maxDistance = distance;
        }
      }

      // Density = number of points / area (πr²)
      double area = pi * maxDistance * maxDistance;
      double density = cluster.length / (area > 0 ? area : 1);
      totalDensity += density;
    }

    double averageDensity = totalDensity / clusters.length;

    // Scale cluster size inversely with density
    // Higher density = smaller clusters, Lower density = larger clusters
    int baseSize = 8; // Base cluster size
    double densityFactor = 1.0 / (1.0 + log(1.0 + averageDensity));

    // Calculate optimal size (between 3 and 12)
    int optimalSize = (baseSize * densityFactor).round();
    return optimalSize.clamp(3, 12);
  }
}
