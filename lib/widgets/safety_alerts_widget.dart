import 'package:flutter/material.dart';import 'package:flutter/material.dart';import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../services/accelerometer_collision_service.dart';import 'package:provider/provider.dart';import 'package:provider/provider.dart';



/// Simple widget for displaying collision detection statusimport '../services/accelerometer_collision_service.dart';import '../services/accelerometer_collision_service.dart';

class SafetyAlertsWidget extends StatelessWidget {

  const SafetyAlertsWidget({super.key});import '../models/models.dart';



  @override/// Widget for displaying collision detection status

  Widget build(BuildContext context) {

    return Consumer<AccelerometerCollisionService>(class SafetyAlertsWidget extends StatelessWidget {/// Widget for displaying safety alerts and collision warnings

      builder: (context, collisionService, child) {

        if (!collisionService.isMonitoring) {  const SafetyAlertsWidget({super.key});class SafetyAlertsWidget extends StatelessWidget {

          return Card(

            color: Colors.red.withOpacity(0.8),  const SafetyAlertsWidget({super.key});

            child: Padding(

              padding: const EdgeInsets.all(8.0),  @override

              child: Row(

                mainAxisSize: MainAxisSize.min,  Widget build(BuildContext context) {  @override

                children: [

                  const Icon(Icons.warning, color: Colors.white, size: 20),    return Consumer<AccelerometerCollisionService>(  Widget build(BuildContext context) {

                  const SizedBox(width: 8),

                  const Text(      builder: (context, collisionService, child) {    return Consumer<AccelerometerCollisionService>(

                    'Collision Detection OFF',

                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),        if (!collisionService.isMonitoring) {      builder: (context, collisionService, child) {

                  ),

                ],          return Container(        // Since AccelerometerCollisionService doesn't have activeAlerts,

              ),

            ),            margin: const EdgeInsets.all(8.0),        // we'll show monitoring status instead

          );

        }            child: Card(        if (!collisionService.isMonitoring) {



        return Card(              color: Colors.red.withOpacity(0.9),          return Container(); // No monitoring, no alerts to show

          color: Colors.green.withOpacity(0.8),

          child: Padding(              child: Padding(        }

            padding: const EdgeInsets.all(8.0),

            child: Row(                padding: const EdgeInsets.all(12.0),

              mainAxisSize: MainAxisSize.min,

              children: [                child: Row(        return Container(

                const Icon(Icons.shield, color: Colors.white, size: 20),

                const SizedBox(width: 8),                  children: [          margin: const EdgeInsets.all(8.0),

                const Text(

                  'Collision Detection ON',                    const Icon(          child: Card(

                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),

                ),                      Icons.warning,            color: Colors.green.withOpacity(0.9),

              ],

            ),                      color: Colors.white,            child: Padding(

          ),

        );                      size: 24,              padding: const EdgeInsets.all(12.0),

      },

    );                    ),              child: Row(

  }

}                    const SizedBox(width: 8),                children: [

                    Expanded(                  const Icon(

                      child: Column(                    Icons.shield_outlined,

                        crossAxisAlignment: CrossAxisAlignment.start,                    color: Colors.white,

                        mainAxisSize: MainAxisSize.min,                    size: 24,

                        children: [                  ),

                          const Text(                  const SizedBox(width: 8),

                            'Collision Detection Inactive',                  Expanded(

                            style: TextStyle(                    child: Column(

                              color: Colors.white,                      crossAxisAlignment: CrossAxisAlignment.start,

                              fontWeight: FontWeight.bold,                      mainAxisSize: MainAxisSize.min,

                              fontSize: 14,                      children: [

                            ),                        const Text(

                          ),                          'Collision Detection Active',

                          Text(                          style: TextStyle(

                            'Safety monitoring is currently disabled',                            color: Colors.white,

                            style: TextStyle(                            fontWeight: FontWeight.bold,

                              color: Colors.white.withOpacity(0.9),                            fontSize: 14,

                              fontSize: 12,                          ),

                            ),                        ),

                          ),                        Text(

                        ],                          'Monitoring for crashes, hard braking & sharp turns',

                      ),                          style: TextStyle(

                    ),                            color: Colors.white.withOpacity(0.9),

                  ],                            fontSize: 12,

                ),                          ),

              ),                        ),

            ),                      ],

          );                    ),

        }                  ),

                ],

        return Container(              ),

          margin: const EdgeInsets.all(8.0),            ),

          child: Card(          ),

            color: Colors.green.withOpacity(0.9),        );

            child: Padding(        }

              padding: const EdgeInsets.all(12.0),

              child: Row(        return Container(

                children: [          margin: const EdgeInsets.all(8),

                  const Icon(          decoration: BoxDecoration(

                    Icons.shield_outlined,            color: Colors.black.withOpacity(0.9),

                    color: Colors.white,            borderRadius: BorderRadius.circular(12),

                    size: 24,            border: Border.all(

                  ),              color: _getAlertColor(alerts.first.riskLevel),

                  const SizedBox(width: 8),              width: 2,

                  Expanded(            ),

                    child: Column(          ),

                      crossAxisAlignment: CrossAxisAlignment.start,          child: Column(

                      mainAxisSize: MainAxisSize.min,            mainAxisSize: MainAxisSize.min,

                      children: [            children: [

                        const Text(              // Header

                          'Collision Detection Active',              Container(

                          style: TextStyle(                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                            color: Colors.white,                decoration: BoxDecoration(

                            fontWeight: FontWeight.bold,                  color: _getAlertColor(alerts.first.riskLevel),

                            fontSize: 14,                  borderRadius: const BorderRadius.vertical(

                          ),                    top: Radius.circular(10),

                        ),                  ),

                        Text(                ),

                          'Monitoring: Crashes (12G+), Hard Braking (1.0G+), Sharp Turns (0.8G+)',                child: Row(

                          style: TextStyle(                  children: [

                            color: Colors.white.withOpacity(0.9),                    Icon(

                            fontSize: 12,                      _getAlertIcon(alerts.first.riskLevel),

                          ),                      color: Colors.white,

                        ),                      size: 20,

                      ],                    ),

                    ),                    const SizedBox(width: 8),

                  ),                    Text(

                  Container(                      'SAFETY ALERTS (${alerts.length})',

                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),                      style: const TextStyle(

                    decoration: BoxDecoration(                        color: Colors.white,

                      color: Colors.white.withOpacity(0.2),                        fontWeight: FontWeight.bold,

                      borderRadius: BorderRadius.circular(12),                        fontSize: 14,

                    ),                      ),

                    child: const Text(                    ),

                      'ACTIVE',                    const Spacer(),

                      style: TextStyle(                    Text(

                        color: Colors.white,                      'Score: ${collisionService.safetyScore}',

                        fontSize: 10,                      style: const TextStyle(

                        fontWeight: FontWeight.bold,                        color: Colors.white,

                      ),                        fontSize: 12,

                    ),                      ),

                  ),                    ),

                ],                  ],

              ),                ),

            ),              ),

          ),              

        );              // Alert list

      },              Container(

    );                constraints: const BoxConstraints(maxHeight: 200),

  }                child: ListView.builder(

}                  shrinkWrap: true,
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