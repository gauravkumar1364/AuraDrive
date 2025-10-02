import 'dart:convert';
import 'position_data.dart';

/// Model representing collision alerts and risk assessments
class CollisionAlert {
  final String alertId;
  final String sourceDeviceId;
  final String? targetDeviceId;
  final CollisionRiskLevel riskLevel;
  final double? timeToCollision; // seconds
  final RelativePosition relativePosition;
  final AlertType alertType;
  final DateTime timestamp;
  final DateTime? expiresAt;
  final String message;
  final Map<String, dynamic>? additionalData;

  const CollisionAlert({
    required this.alertId,
    required this.sourceDeviceId,
    this.targetDeviceId,
    required this.riskLevel,
    this.timeToCollision,
    required this.relativePosition,
    required this.alertType,
    required this.timestamp,
    this.expiresAt,
    required this.message,
    this.additionalData,
  });

  /// Create CollisionAlert from JSON
  factory CollisionAlert.fromJson(Map<String, dynamic> json) {
    return CollisionAlert(
      alertId: json['alertId'] as String,
      sourceDeviceId: json['sourceDeviceId'] as String,
      targetDeviceId: json['targetDeviceId'] as String?,
      riskLevel: CollisionRiskLevel.values.firstWhere(
        (e) => e.name == json['riskLevel'],
        orElse: () => CollisionRiskLevel.low,
      ),
      timeToCollision: json['timeToCollision'] != null
          ? (json['timeToCollision'] as num).toDouble()
          : null,
      relativePosition: RelativePosition.fromJson(
        json['relativePosition'] as Map<String, dynamic>,
      ),
      alertType: AlertType.values.firstWhere(
        (e) => e.name == json['alertType'],
        orElse: () => AlertType.proximity,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      message: json['message'] as String,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'sourceDeviceId': sourceDeviceId,
      'targetDeviceId': targetDeviceId,
      'riskLevel': riskLevel.name,
      'timeToCollision': timeToCollision,
      'relativePosition': relativePosition.toJson(),
      'alertType': alertType.name,
      'timestamp': timestamp.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'message': message,
      'additionalData': additionalData,
    };
  }

  /// Convert to JSON string
  String toJsonString() => json.encode(toJson());

  /// Create from JSON string
  factory CollisionAlert.fromJsonString(String jsonString) {
    return CollisionAlert.fromJson(json.decode(jsonString) as Map<String, dynamic>);
  }

  /// Check if alert is still valid (not expired)
  bool get isValid {
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Check if alert is urgent (requires immediate attention)
  bool get isUrgent =>
      riskLevel == CollisionRiskLevel.critical ||
      riskLevel == CollisionRiskLevel.high ||
      (timeToCollision != null && timeToCollision! < 5.0);

  /// Check if alert is recent (within last 30 seconds)
  bool get isRecent =>
      DateTime.now().difference(timestamp).inSeconds < 30;

  /// Get alert priority (0-100, higher = more urgent)
  int get priority {
    int basePriority = switch (riskLevel) {
      CollisionRiskLevel.critical => 100,
      CollisionRiskLevel.high => 80,
      CollisionRiskLevel.medium => 60,
      CollisionRiskLevel.low => 40,
      CollisionRiskLevel.none => 20,
    };

    // Adjust based on time to collision
    if (timeToCollision != null) {
      if (timeToCollision! < 2.0) {
        basePriority += 20;
      } else if (timeToCollision! < 5.0) {
        basePriority += 10;
      } else if (timeToCollision! < 10.0) {
        basePriority += 5;
      }
    }

    // Adjust based on distance
    if (relativePosition.distance < 10.0) {
      basePriority += 15;
    } else if (relativePosition.distance < 25.0) {
      basePriority += 10;
    } else if (relativePosition.distance < 50.0) {
      basePriority += 5;
    }

    // Adjust based on alert type
    if (alertType == AlertType.crash) {
      basePriority += 50;
    } else if (alertType == AlertType.emergency) {
      basePriority += 30;
    }

    return basePriority.clamp(0, 100);
  }

  /// Get recommended action based on alert
  String get recommendedAction {
    return switch (riskLevel) {
      CollisionRiskLevel.critical => 'IMMEDIATE ACTION REQUIRED - Apply brakes or steer away',
      CollisionRiskLevel.high => 'Reduce speed and maintain safe distance',
      CollisionRiskLevel.medium => 'Increase awareness and prepare to react',
      CollisionRiskLevel.low => 'Monitor situation',
      CollisionRiskLevel.none => 'Continue normal operation',
    };
  }

  /// Copy with new values
  CollisionAlert copyWith({
    String? alertId,
    String? sourceDeviceId,
    String? targetDeviceId,
    CollisionRiskLevel? riskLevel,
    double? timeToCollision,
    RelativePosition? relativePosition,
    AlertType? alertType,
    DateTime? timestamp,
    DateTime? expiresAt,
    String? message,
    Map<String, dynamic>? additionalData,
  }) {
    return CollisionAlert(
      alertId: alertId ?? this.alertId,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      targetDeviceId: targetDeviceId ?? this.targetDeviceId,
      riskLevel: riskLevel ?? this.riskLevel,
      timeToCollision: timeToCollision ?? this.timeToCollision,
      relativePosition: relativePosition ?? this.relativePosition,
      alertType: alertType ?? this.alertType,
      timestamp: timestamp ?? this.timestamp,
      expiresAt: expiresAt ?? this.expiresAt,
      message: message ?? this.message,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'CollisionAlert(id: $alertId, risk: $riskLevel, '
           'ttc: ${timeToCollision?.toStringAsFixed(1)}s, '
           'distance: ${relativePosition.distance.toStringAsFixed(1)}m)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollisionAlert &&
          runtimeType == other.runtimeType &&
          alertId == other.alertId;

  @override
  int get hashCode => alertId.hashCode;
}

/// Enum for collision risk levels
enum CollisionRiskLevel {
  none,     // No risk detected
  low,      // Low risk, monitoring recommended
  medium,   // Medium risk, caution advised
  high,     // High risk, immediate attention required
  critical, // Critical risk, emergency action needed
}

/// Enum for alert types
enum AlertType {
  proximity,      // Proximity warning
  collision,      // Collision warning
  crash,          // Crash detected
  emergency,      // Emergency situation
  speeding,       // Speed-related warning
  hardBraking,    // Hard braking detected
  sharpTurn,      // Sharp turn detected
  laneDeviation,  // Lane deviation warning
  blindSpot,      // Blind spot warning
  rearApproach,   // Vehicle approaching from rear
}

/// Model for relative position between vehicles
class RelativePosition {
  final double distance; // meters
  final double bearing;  // degrees from north
  final double? relativeSpeed; // m/s (positive = approaching)
  final DirectionQuadrant quadrant;
  final double? verticalSeparation; // meters (positive = above)
  final DateTime timestamp;

  const RelativePosition({
    required this.distance,
    required this.bearing,
    this.relativeSpeed,
    required this.quadrant,
    this.verticalSeparation,
    required this.timestamp,
  });

  factory RelativePosition.fromJson(Map<String, dynamic> json) {
    return RelativePosition(
      distance: (json['distance'] as num).toDouble(),
      bearing: (json['bearing'] as num).toDouble(),
      relativeSpeed: json['relativeSpeed'] != null
          ? (json['relativeSpeed'] as num).toDouble()
          : null,
      quadrant: DirectionQuadrant.values.firstWhere(
        (e) => e.name == json['quadrant'],
        orElse: () => DirectionQuadrant.front,
      ),
      verticalSeparation: json['verticalSeparation'] != null
          ? (json['verticalSeparation'] as num).toDouble()
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'bearing': bearing,
      'relativeSpeed': relativeSpeed,
      'quadrant': quadrant.name,
      'verticalSeparation': verticalSeparation,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Check if target is approaching
  bool get isApproaching => relativeSpeed != null && relativeSpeed! > 0;

  /// Check if target is receding
  bool get isReceding => relativeSpeed != null && relativeSpeed! < 0;

  /// Get human-readable direction
  String get directionDescription {
    return switch (quadrant) {
      DirectionQuadrant.front => 'ahead',
      DirectionQuadrant.frontLeft => 'front-left',
      DirectionQuadrant.left => 'left',
      DirectionQuadrant.rearLeft => 'rear-left',
      DirectionQuadrant.rear => 'behind',
      DirectionQuadrant.rearRight => 'rear-right',
      DirectionQuadrant.right => 'right',
      DirectionQuadrant.frontRight => 'front-right',
    };
  }

  /// Get estimated time to closest approach
  double? get timeToClosestApproach {
    if (relativeSpeed == null || relativeSpeed! <= 0) return null;
    return distance / relativeSpeed!;
  }

  /// Create from two positions
  static RelativePosition fromPositions(
    PositionData source,
    PositionData target, {
    double? relativeSpeed,
  }) {
    final double distance = source.distanceTo(target);
    final double bearing = source.bearingTo(target);
    final DirectionQuadrant quadrant = _getQuadrantFromBearing(bearing);
    
    return RelativePosition(
      distance: distance,
      bearing: bearing,
      relativeSpeed: relativeSpeed,
      quadrant: quadrant,
      verticalSeparation: target.altitude != null && source.altitude != null
          ? target.altitude! - source.altitude!
          : null,
      timestamp: DateTime.now(),
    );
  }

  static DirectionQuadrant _getQuadrantFromBearing(double bearing) {
    final double normalizedBearing = bearing % 360;
    
    if (normalizedBearing >= 337.5 || normalizedBearing < 22.5) {
      return DirectionQuadrant.front;
    } else if (normalizedBearing >= 22.5 && normalizedBearing < 67.5) {
      return DirectionQuadrant.frontRight;
    } else if (normalizedBearing >= 67.5 && normalizedBearing < 112.5) {
      return DirectionQuadrant.right;
    } else if (normalizedBearing >= 112.5 && normalizedBearing < 157.5) {
      return DirectionQuadrant.rearRight;
    } else if (normalizedBearing >= 157.5 && normalizedBearing < 202.5) {
      return DirectionQuadrant.rear;
    } else if (normalizedBearing >= 202.5 && normalizedBearing < 247.5) {
      return DirectionQuadrant.rearLeft;
    } else if (normalizedBearing >= 247.5 && normalizedBearing < 292.5) {
      return DirectionQuadrant.left;
    } else {
      return DirectionQuadrant.frontLeft;
    }
  }
}

/// Enum for direction quadrants around a vehicle
enum DirectionQuadrant {
  front,
  frontRight,
  right,
  rearRight,
  rear,
  rearLeft,
  left,
  frontLeft,
}