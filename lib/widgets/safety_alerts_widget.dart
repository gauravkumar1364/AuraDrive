import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accelerometer_collision_service.dart';

/// Widget for displaying safety alerts and collision warnings
class SafetyAlertsWidget extends StatelessWidget {
  const SafetyAlertsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccelerometerCollisionService>(
      builder: (context, collisionService, child) {
        // Show monitoring status
        if (!collisionService.isMonitoring) {
          return Container(
            margin: const EdgeInsets.all(8.0),
            child: Card(
              color: Colors.red.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Collision Detection Inactive',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Safety monitoring is currently disabled',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Show active monitoring status
        return Container(
          margin: const EdgeInsets.all(8.0),
          child: Card(
            color: Colors.green.withOpacity(0.9),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Collision Detection Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Monitoring for crashes, hard braking & sharp turns',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
