import 'package:latlong2/latlong.dart';

/// Message types for VANET communication
enum VANETMessageType {
  emergency,      // Collision warning, accident
  safety,         // Lane change, braking
  traffic,        // Traffic conditions, congestion
  infotainment,   // General information
  cluster,        // Cluster management
  heartbeat,      // Keep-alive messages
}

/// Priority levels for message handling
enum MessagePriority {
  critical,  // Emergency messages (immediate processing)
  high,      // Safety messages
  medium,    // Traffic updates
  low,       // Infotainment
}

/// VANET message for vehicle-to-vehicle communication
class VANETMessage {
  final String id;
  final String senderId;
  final VANETMessageType type;
  final MessagePriority priority;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final int ttl; // Time to live (hops)
  
  // Location context
  final LatLng? senderPosition;
  final double? senderSpeed;
  final double? senderHeading;
  
  // Routing
  String? targetClusterId;
  List<String> routePath; // IDs of nodes that forwarded this message
  
  // Validation
  String? signature; // For security (future enhancement)

  VANETMessage({
    required this.id,
    required this.senderId,
    required this.type,
    required this.priority,
    required this.payload,
    required this.timestamp,
    this.ttl = 5,
    this.senderPosition,
    this.senderSpeed,
    this.senderHeading,
    this.targetClusterId,
    List<String>? routePath,
    this.signature,
  }) : routePath = routePath ?? [];

  /// Create collision warning message
  factory VANETMessage.collisionWarning({
    required String senderId,
    required LatLng position,
    required double speed,
    required double heading,
    required double collisionRisk,
    required String targetVehicleId,
  }) {
    return VANETMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      type: VANETMessageType.emergency,
      priority: MessagePriority.critical,
      payload: {
        'warning': 'collision_imminent',
        'collisionRisk': collisionRisk,
        'targetVehicleId': targetVehicleId,
      },
      timestamp: DateTime.now(),
      senderPosition: position,
      senderSpeed: speed,
      senderHeading: heading,
      ttl: 3, // Critical messages have short TTL
    );
  }

  /// Create cluster update message
  factory VANETMessage.clusterUpdate({
    required String senderId,
    required String clusterId,
    required String coordinatorId,
    required int memberCount,
  }) {
    return VANETMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      type: VANETMessageType.cluster,
      priority: MessagePriority.medium,
      payload: {
        'clusterId': clusterId,
        'coordinatorId': coordinatorId,
        'memberCount': memberCount,
      },
      timestamp: DateTime.now(),
      targetClusterId: clusterId,
    );
  }

  /// Create heartbeat message
  factory VANETMessage.heartbeat({
    required String senderId,
    required LatLng position,
    required double speed,
    required double heading,
    String? clusterId,
  }) {
    return VANETMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      type: VANETMessageType.heartbeat,
      priority: MessagePriority.low,
      payload: {
        'status': 'active',
        'clusterId': clusterId,
      },
      timestamp: DateTime.now(),
      senderPosition: position,
      senderSpeed: speed,
      senderHeading: heading,
      ttl: 2, // Heartbeats don't travel far
    );
  }

  /// Check if message is still valid (not expired)
  bool get isValid {
    final age = DateTime.now().difference(timestamp).inSeconds;
    // Critical messages expire in 2s, others in 10s
    final maxAge = priority == MessagePriority.critical ? 2 : 10;
    return age < maxAge && ttl > 0;
  }

  /// Check if message should be forwarded
  bool shouldForward(String nodeId) {
    // Don't forward if TTL exhausted
    if (ttl <= 0) return false;
    
    // Don't forward if already in route path
    if (routePath.contains(nodeId)) return false;
    
    // Don't forward expired messages
    if (!isValid) return false;
    
    return true;
  }

  /// Create forwarded copy with decremented TTL
  VANETMessage forward(String forwarderId) {
    return VANETMessage(
      id: id,
      senderId: senderId,
      type: type,
      priority: priority,
      payload: payload,
      timestamp: timestamp,
      ttl: ttl - 1,
      senderPosition: senderPosition,
      senderSpeed: senderSpeed,
      senderHeading: senderHeading,
      targetClusterId: targetClusterId,
      routePath: [...routePath, forwarderId],
      signature: signature,
    );
  }

  /// Create from JSON
  factory VANETMessage.fromJson(Map<String, dynamic> json) {
    return VANETMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      type: VANETMessageType.values.firstWhere(
        (e) => e.toString() == 'VANETMessageType.${json['type']}',
      ),
      priority: MessagePriority.values.firstWhere(
        (e) => e.toString() == 'MessagePriority.${json['priority']}',
      ),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      ttl: json['ttl'] as int? ?? 5,
      senderPosition: json['senderPosition'] != null
          ? LatLng(
              json['senderPosition']['latitude'] as double,
              json['senderPosition']['longitude'] as double,
            )
          : null,
      senderSpeed: (json['senderSpeed'] as num?)?.toDouble(),
      senderHeading: (json['senderHeading'] as num?)?.toDouble(),
      targetClusterId: json['targetClusterId'] as String?,
      routePath: (json['routePath'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      signature: json['signature'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl,
      'senderPosition': senderPosition != null
          ? {
              'latitude': senderPosition!.latitude,
              'longitude': senderPosition!.longitude,
            }
          : null,
      'senderSpeed': senderSpeed,
      'senderHeading': senderHeading,
      'targetClusterId': targetClusterId,
      'routePath': routePath,
      'signature': signature,
    };
  }

  @override
  String toString() {
    return 'VANETMessage(id: $id, type: $type, priority: $priority, sender: $senderId)';
  }
}
