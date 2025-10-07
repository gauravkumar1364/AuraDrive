import 'package:flutter/material.dart';
import '../models/collision_alert.dart';

class CollisionAcknowledgmentDialog extends StatelessWidget {
  final CollisionAlert alert;
  final Function() onAcknowledge;
  final Function() onEmergencyHelp;

  const CollisionAcknowledgmentDialog({
    super.key,
    required this.alert,
    required this.onAcknowledge,
    required this.onEmergencyHelp,
  });

  @override
  Widget build(BuildContext context) {
    final isHighRisk =
        alert.riskLevel == CollisionRiskLevel.critical ||
        alert.riskLevel == CollisionRiskLevel.high;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Alert Icon
            Icon(
              isHighRisk ? Icons.warning_amber_rounded : Icons.info_outline,
              color: isHighRisk ? Colors.red : Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),

            // Alert Message
            Text(
              alert.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Additional Info
            if (alert.timeToCollision != null) ...[
              Text(
                'Time to collision: ${alert.timeToCollision!.toStringAsFixed(1)}s',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Status Question
            const Text(
              'Are you okay?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Emergency Help Button
                if (isHighRisk)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onEmergencyHelp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Need Help'),
                    ),
                  ),

                if (isHighRisk) const SizedBox(width: 12),

                // I'm Okay Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAcknowledge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("I'm Okay"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
