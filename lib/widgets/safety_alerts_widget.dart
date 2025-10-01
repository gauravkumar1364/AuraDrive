import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/collision_detection_service.dart';
import '../models/models.dart';

/// Widget for displaying safety alerts and collision warnings
class SafetyAlertsWidget extends StatelessWidget {
  const SafetyAlertsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CollisionDetectionService>(
      builder: (context, collisionService, child) {
        final alerts = collisionService.activeAlerts
            .where((alert) => alert.isValid)
            .toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));

        if (alerts.isEmpty) {
          return Container(); // No alerts to show
        }

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getAlertColor(alerts.first.riskLevel),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getAlertColor(alerts.first.riskLevel),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getAlertIcon(alerts.first.riskLevel),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SAFETY ALERTS (${alerts.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Score: ${collisionService.safetyScore}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Alert list
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return _buildAlertItem(context, alert);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build individual alert item
  Widget _buildAlertItem(BuildContext context, CollisionAlert alert) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[700]!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert header
          Row(
            children: [
              Icon(
                _getAlertTypeIcon(alert.alertType),
                color: _getAlertColor(alert.riskLevel),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getAlertTitle(alert.alertType),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getAlertColor(alert.riskLevel),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alert.riskLevel.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Alert message
          Text(
            alert.message,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
            ),
          ),
          
          // Time and distance info
          if (alert.timeToCollision != null || alert.relativePosition.distance > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  if (alert.timeToCollision != null) ...[
                    Icon(
                      Icons.access_time,
                      color: Colors.orange,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'TTC: ${alert.timeToCollision!.toStringAsFixed(1)}s',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    Icons.social_distance,
                    color: Colors.blue,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${alert.relativePosition.distance.toStringAsFixed(1)}m ${alert.relativePosition.directionDescription}',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          // Recommended action for high priority alerts
          if (alert.riskLevel == CollisionRiskLevel.critical ||
              alert.riskLevel == CollisionRiskLevel.high)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow[800]!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.yellow[600]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Colors.yellow[600],
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        alert.recommendedAction,
                        style: TextStyle(
                          color: Colors.yellow[100],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Get color for alert risk level
  Color _getAlertColor(CollisionRiskLevel riskLevel) {
    return switch (riskLevel) {
      CollisionRiskLevel.critical => Colors.red[800]!,
      CollisionRiskLevel.high => Colors.red[600]!,
      CollisionRiskLevel.medium => Colors.orange[600]!,
      CollisionRiskLevel.low => Colors.yellow[600]!,
      CollisionRiskLevel.none => Colors.green[600]!,
    };
  }

  /// Get icon for alert risk level
  IconData _getAlertIcon(CollisionRiskLevel riskLevel) {
    return switch (riskLevel) {
      CollisionRiskLevel.critical => Icons.emergency,
      CollisionRiskLevel.high => Icons.warning,
      CollisionRiskLevel.medium => Icons.info,
      CollisionRiskLevel.low => Icons.notifications,
      CollisionRiskLevel.none => Icons.check_circle,
    };
  }

  /// Get icon for alert type
  IconData _getAlertTypeIcon(AlertType alertType) {
    return switch (alertType) {
      AlertType.proximity => Icons.social_distance,
      AlertType.collision => Icons.crisis_alert,
      AlertType.crash => Icons.car_crash,
      AlertType.emergency => Icons.emergency,
      AlertType.speeding => Icons.speed,
      AlertType.hardBraking => Icons.directions_car,
      AlertType.sharpTurn => Icons.turn_sharp_left,
      AlertType.laneDeviation => Icons.compare_arrows,
      AlertType.blindSpot => Icons.visibility_off,
      AlertType.rearApproach => Icons.arrow_forward,
    };
  }

  /// Get title for alert type
  String _getAlertTitle(AlertType alertType) {
    return switch (alertType) {
      AlertType.proximity => 'Proximity Warning',
      AlertType.collision => 'Collision Warning',
      AlertType.crash => 'CRASH DETECTED',
      AlertType.emergency => 'EMERGENCY',
      AlertType.speeding => 'Speed Warning',
      AlertType.hardBraking => 'Hard Braking',
      AlertType.sharpTurn => 'Sharp Turn',
      AlertType.laneDeviation => 'Lane Deviation',
      AlertType.blindSpot => 'Blind Spot',
      AlertType.rearApproach => 'Rear Approach',
    };
  }
}