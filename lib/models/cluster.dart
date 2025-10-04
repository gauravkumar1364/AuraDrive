import 'vehicle.dart';

/// Represents a cluster of vehicles in BLE mesh network
class Cluster {
  final String id;
  String coordinatorId;
  final List<Vehicle> members;
  final DateTime createdAt;
  DateTime lastUpdate;
  
  // Cluster metrics
  double averageRSSI;
  int messageCount;
  double networkStability; // 0.0 to 1.0
  
  // Coordinator selection metrics
  int coordinatorChanges;
  Map<String, double> memberRewards; // Multi-armed bandit rewards

  Cluster({
    required this.id,
    required this.coordinatorId,
    required this.members,
    required this.createdAt,
    required this.lastUpdate,
    this.averageRSSI = 0.0,
    this.messageCount = 0,
    this.networkStability = 1.0,
    this.coordinatorChanges = 0,
    Map<String, double>? memberRewards,
  }) : memberRewards = memberRewards ?? {};

  /// Get coordinator vehicle
  Vehicle? get coordinator {
    try {
      return members.firstWhere((v) => v.id == coordinatorId);
    } catch (e) {
      return null;
    }
  }

  /// Get number of members
  int get size => members.length;

  /// Check if cluster is healthy (recent updates, stable coordinator)
  bool get isHealthy {
    final age = DateTime.now().difference(lastUpdate).inSeconds;
    return age < 10 && networkStability > 0.5 && members.isNotEmpty;
  }

  /// Calculate cluster density (members per area)
  double calculateDensity() {
    if (members.length < 2) return 0.0;
    
    // Simple approximation: members per square meter
    // In real implementation, calculate bounding box area
    return members.length / (averageRSSI.abs() + 1);
  }

  /// Add member to cluster
  void addMember(Vehicle vehicle) {
    if (!members.any((v) => v.id == vehicle.id)) {
      members.add(vehicle);
      lastUpdate = DateTime.now();
    }
  }

  /// Remove member from cluster
  void removeMember(String vehicleId) {
    members.removeWhere((v) => v.id == vehicleId);
    lastUpdate = DateTime.now();
  }

  /// Update coordinator
  void updateCoordinator(String newCoordinatorId) {
    if (coordinatorId != newCoordinatorId) {
      coordinatorId = newCoordinatorId;
      coordinatorChanges++;
      lastUpdate = DateTime.now();
    }
  }

  /// Create from JSON
  factory Cluster.fromJson(Map<String, dynamic> json) {
    return Cluster(
      id: json['id'] as String,
      coordinatorId: json['coordinatorId'] as String,
      members: (json['members'] as List<dynamic>)
          .map((m) => Vehicle.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
      averageRSSI: (json['averageRSSI'] as num?)?.toDouble() ?? 0.0,
      messageCount: json['messageCount'] as int? ?? 0,
      networkStability: (json['networkStability'] as num?)?.toDouble() ?? 1.0,
      coordinatorChanges: json['coordinatorChanges'] as int? ?? 0,
      memberRewards: (json['memberRewards'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ??
          {},
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coordinatorId': coordinatorId,
      'members': members.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastUpdate': lastUpdate.toIso8601String(),
      'averageRSSI': averageRSSI,
      'messageCount': messageCount,
      'networkStability': networkStability,
      'coordinatorChanges': coordinatorChanges,
      'memberRewards': memberRewards,
    };
  }

  /// Create a copy with updated fields
  Cluster copyWith({
    String? id,
    String? coordinatorId,
    List<Vehicle>? members,
    DateTime? createdAt,
    DateTime? lastUpdate,
    double? averageRSSI,
    int? messageCount,
    double? networkStability,
    int? coordinatorChanges,
    Map<String, double>? memberRewards,
  }) {
    return Cluster(
      id: id ?? this.id,
      coordinatorId: coordinatorId ?? this.coordinatorId,
      members: members ?? List.from(this.members),
      createdAt: createdAt ?? this.createdAt,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      averageRSSI: averageRSSI ?? this.averageRSSI,
      messageCount: messageCount ?? this.messageCount,
      networkStability: networkStability ?? this.networkStability,
      coordinatorChanges: coordinatorChanges ?? this.coordinatorChanges,
      memberRewards: memberRewards ?? Map.from(this.memberRewards),
    );
  }
}
