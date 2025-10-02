import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'permissions_screen.dart';

/// How It Works screen explaining AuraDrive functionality
class HowItWorksScreen extends StatefulWidget {
  const HowItWorksScreen({super.key});

  @override
  State<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends State<HowItWorksScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _lineController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _lineAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the network dots
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Line animation for dotted lines
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _lineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _lineController,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        
                        // Title
                        const Text(
                          'How It Works',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Description
                        Text(
                          'AuraDrive uses your phone\'s sensors and\nBluetooth to create a local network, detecting\nother users around you without relying on servers.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 50),
                        
                        // Network visualization
                        _buildNetworkVisualization(),
                        
                        const SizedBox(height: 50),
                        
                        // Feature cards
                        _buildFeatureCard(
                          icon: Icons.wifi_tethering,
                          title: 'Local Network',
                          description: 'Direct device-to-device communication',
                          color: const Color(0xFF7B2CBF),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildFeatureCard(
                          icon: Icons.track_changes,
                          title: 'Real-time Detection',
                          description: 'Instant alerts as vehicles approach',
                          color: const Color(0xFF00C9A7),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildFeatureCard(
                          icon: Icons.wifi_off,
                          title: 'No Internet Required',
                          description: 'Works completely offline',
                          color: const Color(0xFF3A86FF),
                        ),
                        
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Bottom navigation
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Page indicators
                    _buildPageIndicators(),
                    const SizedBox(height: 24),
                    
                    // Next button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PermissionsScreen(),
                              ),
                            );
                          },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A86FF), // Blue
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFF3A86FF).withOpacity(0.5),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Back button
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildNetworkVisualization() {
    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated dotted lines
          CustomPaint(
            size: const Size(280, 280),
            painter: DottedLinesPainter(
              animation: _lineAnimation,
            ),
          ),
          
          // Center device (You)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDeviceNode(
                color: Colors.white,
                size: 60,
                icon: Icons.smartphone,
                isPulsing: false,
              ),
              const SizedBox(height: 8),
              const Text(
                'You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          // Top-left driver
          Positioned(
            top: 30,
            left: 30,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Column(
                children: [
                  _buildDeviceNode(
                    color: const Color(0xFF00C9A7),
                    size: 50,
                    icon: Icons.smartphone,
                    isPulsing: true,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Driver',
                    style: TextStyle(
                      color: Color(0xFF00C9A7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Top-right driver
          Positioned(
            top: 30,
            right: 30,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Column(
                children: [
                  _buildDeviceNode(
                    color: const Color(0xFF00C9A7),
                    size: 50,
                    icon: Icons.smartphone,
                    isPulsing: true,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Driver',
                    style: TextStyle(
                      color: Color(0xFF00C9A7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom driver
          Positioned(
            bottom: 20,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Column(
                children: [
                  _buildDeviceNode(
                    color: const Color(0xFF00C9A7),
                    size: 50,
                    icon: Icons.smartphone,
                    isPulsing: true,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Driver',
                    style: TextStyle(
                      color: Color(0xFF00C9A7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildDeviceNode({
    required Color color,
    required double size,
    required IconData icon,
    required bool isPulsing,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: isPulsing ? 20 : 15,
            spreadRadius: isPulsing ? 3 : 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color == Colors.white ? const Color(0xFF1A0B2E) : Colors.white,
        size: size * 0.5,
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D1B4E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIndicator(false),
        const SizedBox(width: 8),
        _buildIndicator(true),
        const SizedBox(width: 8),
        _buildIndicator(false),
        const SizedBox(width: 8),
        _buildIndicator(false),
        const SizedBox(width: 8),
        _buildIndicator(false),
      ],
    );
  }

  Widget _buildIndicator(bool isActive) {
    return Container(
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF3A86FF)
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Custom painter for animated dotted lines
class DottedLinesPainter extends CustomPainter {
  final Animation<double> animation;

  DottedLinesPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00C9A7).withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw dotted lines to each driver position
    _drawDottedLine(canvas, paint, center, Offset(80, 80)); // Top-left
    _drawDottedLine(canvas, paint, center, Offset(size.width - 80, 80)); // Top-right
    _drawDottedLine(canvas, paint, center, Offset(size.width / 2, size.height - 80)); // Bottom
  }

  void _drawDottedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final extractPath = metric.extractPath(
          distance,
          distance + dashWidth,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(DottedLinesPainter oldDelegate) => true;
}
