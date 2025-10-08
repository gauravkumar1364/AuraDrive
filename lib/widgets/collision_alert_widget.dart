import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accelerometer_collision_service.dart';

class CollisionAlertWidget extends StatefulWidget {
  const CollisionAlertWidget({Key? key}) : super(key: key);

  @override
  State<CollisionAlertWidget> createState() => _CollisionAlertWidgetState();
}

class _CollisionAlertWidgetState extends State<CollisionAlertWidget>
    with TickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Listen to collision alerts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = Provider.of<AccelerometerCollisionService>(
        context,
        listen: false,
      );
      service.alertStream.listen((alert) {
        _showAlert(alert);
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _showAlert(SimpleCollisionAlert alert) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildAlertOverlay(alert),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();

    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _hideAlert();
    });
  }

  void _hideAlert() {
    _animationController.reverse().then((_) {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildAlertOverlay(SimpleCollisionAlert alert) {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getAlertColor(alert),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(_getAlertIcon(alert), color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getAlertTitle(alert),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _hideAlert,
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getAlertColor(SimpleCollisionAlert alert) {
    switch (alert.type) {
      case 'crash':
        return alert.severity == 'critical'
            ? Colors.red[900]!
            : Colors.red[700]!;
      case 'braking':
        return alert.severity == 'high'
            ? Colors.orange[700]!
            : Colors.orange[600]!;
      case 'turn':
        return alert.severity == 'high' ? Colors.blue[700]! : Colors.blue[600]!;
      default:
        return Colors.grey[700]!;
    }
  }

  IconData _getAlertIcon(SimpleCollisionAlert alert) {
    switch (alert.type) {
      case 'crash':
        return Icons.warning;
      case 'braking':
        return Icons.speed;
      case 'turn':
        return Icons.turn_right;
      default:
        return Icons.info;
    }
  }

  String _getAlertTitle(SimpleCollisionAlert alert) {
    switch (alert.type) {
      case 'crash':
        return 'COLLISION ALERT';
      case 'braking':
        return 'HARD BRAKING';
      case 'turn':
        return 'SHARP TURN';
      default:
        return 'ALERT';
    }
  }

  @override
  Widget build(BuildContext context) {
    // This widget doesn't render anything directly
    // It only manages the overlay alerts
    return const SizedBox.shrink();
  }
}

// Extension widget to show recent alerts in a list
class RecentAlertsWidget extends StatelessWidget {
  const RecentAlertsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AccelerometerCollisionService>(
      builder: (context, service, child) {
        final alerts = service.recentAlerts;

        if (alerts.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No recent alerts',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Recent Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getAlertColor(alert.type),
                      child: Icon(
                        _getAlertIcon(alert.type),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      _getAlertTitle(alert.type),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(alert.message),
                    trailing: Text(
                      _formatTime(alert.timestamp),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getAlertColor(String type) {
    switch (type) {
      case 'crash':
        return Colors.red;
      case 'braking':
        return Colors.orange;
      case 'turn':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'crash':
        return Icons.warning;
      case 'braking':
        return Icons.speed;
      case 'turn':
        return Icons.turn_right;
      default:
        return Icons.info;
    }
  }

  String _getAlertTitle(String type) {
    switch (type) {
      case 'crash':
        return 'Collision Alert';
      case 'braking':
        return 'Hard Braking';
      case 'turn':
        return 'Sharp Turn';
      default:
        return 'Alert';
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
