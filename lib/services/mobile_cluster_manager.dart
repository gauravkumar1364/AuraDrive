import 'dart:async';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/cluster.dart';
import '../models/vehicle.dart';
import '../models/ble_device.dart';

/// Mobile Cluster Manager
/// Battery-aware clustering with multi-armed bandit coordinator selection
class MobileClusterManager {
  // Clustering parameters
  static const int minClusterSize = 2;
  static const int maxClusterSize = 10;
  static const int rssiThreshold = -70; // dBm
  static const int batteryThreshold = 20; // percentage
  
  // Multi-armed bandit parameters
  static const double epsilon = 0.1; // Exploration rate
  static const double rewardDecay = 0.9; // Decay factor for old rewards
  
  // State
  Cluster? _currentCluster;
  final Map<String, double> _coordinatorRewards = {};
  final Map<String, int> _coordinatorSelections = {};
  
  // Streams
  final StreamController<Cluster?> _clusterController = 
      StreamController<Cluster?>.broadcast();
  
  Stream<Cluster?> get clusterStream => _clusterController.stream;
  
  /// Form cluster from nearby devices
  Cluster? formCluster(
    String myDeviceId,
    List<Vehicle> nearbyVehicles,
    Map<String, BLEDevice> bleDevices,
    int myBatteryLevel,
  ) {
    // Filter vehicles based on signal strength and battery
    final eligibleVehicles = nearbyVehicles.where((v) {
      final bleDevice = bleDevices[v.id];
      if (bleDevice == null) return false;
      
      return bleDevice.rssi > rssiThreshold && 
             bleDevice.isActive &&
             v.batteryLevel > batteryThreshold;
    }).toList();
    
    if (eligibleVehicles.length < minClusterSize - 1) {
      // Not enough vehicles to form cluster
      if (_currentCluster != null) {
        _currentCluster = null;
        _clusterController.add(null);
      }
      return null;
    }
    
    // Sort by RSSI (strongest signal first)
    eligibleVehicles.sort((a, b) {
      final rssiA = bleDevices[a.id]?.rssi ?? -100;
      final rssiB = bleDevices[b.id]?.rssi ?? -100;
      return rssiB.compareTo(rssiA);
    });
    
    // Select top vehicles for cluster
    final clusterMembers = eligibleVehicles
        .take(maxClusterSize - 1)
        .toList();
    
    // Add self
    clusterMembers.add(Vehicle(
      id: myDeviceId,
      deviceId: myDeviceId,
      position: const LatLng(0, 0),
      lastUpdate: DateTime.now(),
      batteryLevel: myBatteryLevel,
    ));
    
    // Select coordinator using multi-armed bandit
    final coordinatorId = _selectCoordinator(clusterMembers, bleDevices);
    
    final cluster = Cluster(
      id: '$myDeviceId-${DateTime.now().millisecondsSinceEpoch}',
      coordinatorId: coordinatorId,
      members: clusterMembers,
      createdAt: DateTime.now(),
      lastUpdate: DateTime.now(),
      memberRewards: Map.from(_coordinatorRewards),
    );
    
    _currentCluster = cluster;
    _clusterController.add(cluster);
    
    return cluster;
  }
  
  /// Select coordinator using epsilon-greedy multi-armed bandit
  String _selectCoordinator(
    List<Vehicle> members,
    Map<String, BLEDevice> bleDevices,
  ) {
    final random = Random();
    
    // Epsilon-greedy: explore with probability epsilon
    if (random.nextDouble() < epsilon) {
      // Explore: random selection
      return members[random.nextInt(members.length)].id;
    } else {
      // Exploit: select best coordinator based on rewards
      String bestCoordinator = members.first.id;
      double bestScore = _calculateCoordinatorScore(members.first, bleDevices);
      
      for (final member in members) {
        final score = _calculateCoordinatorScore(member, bleDevices);
        if (score > bestScore) {
          bestScore = score;
          bestCoordinator = member.id;
        }
      }
      
      return bestCoordinator;
    }
  }
  
  /// Calculate coordinator fitness score
  double _calculateCoordinatorScore(
    Vehicle vehicle,
    Map<String, BLEDevice> bleDevices,
  ) {
    // Factors:
    // 1. Battery level (higher is better)
    // 2. Historical reward (higher is better)
    // 3. Signal strength (higher is better)
    // 4. Stability (lower change count is better)
    
    final batteryScore = vehicle.batteryLevel / 100.0;
    final rewardScore = _coordinatorRewards[vehicle.id] ?? 0.5;
    
    final bleDevice = bleDevices[vehicle.id];
    final signalScore = bleDevice != null 
        ? ((bleDevice.rssi + 100) / 100).clamp(0.0, 1.0)
        : 0.5;
    
    final selections = _coordinatorSelections[vehicle.id] ?? 0;
    final stabilityScore = 1.0 / (1.0 + selections * 0.1);
    
    // Weighted combination
    return batteryScore * 0.4 + 
           rewardScore * 0.3 + 
           signalScore * 0.2 + 
           stabilityScore * 0.1;
  }
  
  /// Update coordinator reward based on performance
  void updateCoordinatorReward(
    String coordinatorId,
    bool messageDelivered,
    double networkStability,
  ) {
    // Calculate reward based on:
    // - Message delivery success
    // - Network stability
    
    final deliveryReward = messageDelivered ? 1.0 : 0.0;
    final reward = (deliveryReward + networkStability) / 2.0;
    
    // Update reward with decay for old values
    final currentReward = _coordinatorRewards[coordinatorId] ?? 0.5;
    _coordinatorRewards[coordinatorId] = 
        currentReward * rewardDecay + reward * (1 - rewardDecay);
    
    // Track selections
    _coordinatorSelections[coordinatorId] = 
        (_coordinatorSelections[coordinatorId] ?? 0) + 1;
  }
  
  /// Maintain cluster (remove inactive members, add new ones)
  void maintainCluster(
    String myDeviceId,
    List<Vehicle> nearbyVehicles,
    Map<String, BLEDevice> bleDevices,
  ) {
    if (_currentCluster == null) return;
    
    // Remove inactive or weak-signal members
    _currentCluster!.members.removeWhere((member) {
      if (member.id == myDeviceId) return false; // Keep self
      
      final bleDevice = bleDevices[member.id];
      return bleDevice == null ||
             !bleDevice.isActive ||
             bleDevice.rssi < rssiThreshold ||
             member.batteryLevel < batteryThreshold;
    });
    
    // Add new eligible members
    for (final vehicle in nearbyVehicles) {
      if (_currentCluster!.members.length >= maxClusterSize) break;
      
      if (!_currentCluster!.members.any((m) => m.id == vehicle.id)) {
        final bleDevice = bleDevices[vehicle.id];
        if (bleDevice != null &&
            bleDevice.rssi > rssiThreshold &&
            vehicle.batteryLevel > batteryThreshold) {
          _currentCluster!.addMember(vehicle);
        }
      }
    }
    
    // Check if cluster size is still valid
    if (_currentCluster!.members.length < minClusterSize) {
      _currentCluster = null;
      _clusterController.add(null);
    } else {
      _currentCluster!.lastUpdate = DateTime.now();
      _clusterController.add(_currentCluster);
    }
  }
  
  /// Check if coordinator should be changed
  bool shouldChangeCoordinator(
    List<Vehicle> members,
    Map<String, BLEDevice> bleDevices,
  ) {
    if (_currentCluster == null) return false;
    
    final currentCoordinator = members.firstWhere(
      (m) => m.id == _currentCluster!.coordinatorId,
      orElse: () => members.first,
    );
    
    // Change if current coordinator has low battery
    if (currentCoordinator.batteryLevel < batteryThreshold) {
      return true;
    }
    
    // Change if better candidate exists (exploration-exploitation)
    final bestScore = _calculateCoordinatorScore(currentCoordinator, bleDevices);
    
    for (final member in members) {
      if (member.id == currentCoordinator.id) continue;
      
      final score = _calculateCoordinatorScore(member, bleDevices);
      if (score > bestScore * 1.2) { // 20% better threshold
        return true;
      }
    }
    
    return false;
  }
  
  /// Change cluster coordinator
  void changeCoordinator(
    List<Vehicle> members,
    Map<String, BLEDevice> bleDevices,
  ) {
    if (_currentCluster == null) return;
    
    final newCoordinatorId = _selectCoordinator(members, bleDevices);
    _currentCluster!.updateCoordinator(newCoordinatorId);
    _clusterController.add(_currentCluster);
  }
  
  /// Get cluster density (vehicles per area)
  double getClusterDensity() {
    return _currentCluster?.calculateDensity() ?? 0.0;
  }
  
  /// Get network topology info
  Map<String, dynamic> getTopologyInfo() {
    if (_currentCluster == null) {
      return {'status': 'no_cluster'};
    }
    
    return {
      'clusterId': _currentCluster!.id,
      'size': _currentCluster!.size,
      'coordinatorId': _currentCluster!.coordinatorId,
      'isHealthy': _currentCluster!.isHealthy,
      'density': getClusterDensity(),
      'stability': _currentCluster!.networkStability,
      'coordinatorChanges': _currentCluster!.coordinatorChanges,
    };
  }
  
  /// Dispose resources
  void dispose() {
    _clusterController.close();
  }
}
