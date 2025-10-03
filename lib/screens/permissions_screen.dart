import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'phone_auth_screen.dart';

/// Permissions screen that requests necessary permissions
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _locationGranted = false;
  bool _bluetoothGranted = false;
  bool _notificationGranted = false;
  
  bool _isCheckingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkExistingPermissions();
  }

  Future<void> _checkExistingPermissions() async {
    // Check location permissions
    final locationStatus = await Permission.location.status;
    final locationAlwaysStatus = await Permission.locationAlways.status;
    
    // Check bluetooth permissions
    final bluetoothStatus = await Permission.bluetooth.status;
    final bluetoothScanStatus = await Permission.bluetoothScan.status;
    final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
    
    // Check notification permissions
    final notificationStatus = await Permission.notification.status;

    final locationGranted = locationStatus.isGranted || locationAlwaysStatus.isGranted;
    final bluetoothGranted = bluetoothStatus.isGranted || 
                        (bluetoothScanStatus.isGranted && bluetoothConnectStatus.isGranted);
    final notificationGranted = notificationStatus.isGranted;

    setState(() {
      _locationGranted = locationGranted;
      _bluetoothGranted = bluetoothGranted;
      _notificationGranted = notificationGranted;
      _isCheckingPermissions = false;
    });

    // If all permissions are already granted, automatically proceed
    if (locationGranted && bluetoothGranted && notificationGranted) {
      // Wait a bit to show the screen briefly
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _continue();
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    // Check current status first
    final currentStatus = await Permission.location.status;
    
    if (currentStatus.isGranted) {
      // Already granted, just check background permission
      final alwaysStatus = await Permission.locationAlways.status;
      if (!alwaysStatus.isGranted) {
        await Permission.locationAlways.request();
      }
      setState(() {
        _locationGranted = true;
      });
      return;
    }
    
    if (currentStatus.isPermanentlyDenied) {
      _showSettingsDialog('Location');
      return;
    }
    
    // Request permission
    final status = await Permission.location.request();
    
    // Also request background location if foreground was granted
    if (status.isGranted) {
      await Permission.locationAlways.request();
    }
    
    setState(() {
      _locationGranted = status.isGranted;
    });

    if (status.isPermanentlyDenied) {
      _showSettingsDialog('Location');
    }
  }

  Future<void> _requestBluetoothPermission() async {
    // Check current status first
    final currentStatus = await Permission.bluetooth.status;
    final scanStatus = await Permission.bluetoothScan.status;
    final connectStatus = await Permission.bluetoothConnect.status;
    
    // If all permissions are already granted, just update state
    if (currentStatus.isGranted && scanStatus.isGranted && connectStatus.isGranted) {
      setState(() {
        _bluetoothGranted = true;
      });
      return;
    }
    
    if (currentStatus.isPermanentlyDenied) {
      _showSettingsDialog('Bluetooth');
      return;
    }
    
    // Request bluetooth permission
    final status = await Permission.bluetooth.request();
    
    bool allGranted = status.isGranted;
    
    // Request additional Android 12+ permissions if base bluetooth was granted
    if (status.isGranted) {
      final scanResult = await Permission.bluetoothScan.request();
      final connectResult = await Permission.bluetoothConnect.request();
      allGranted = scanResult.isGranted && connectResult.isGranted;
    }
    
    setState(() {
      _bluetoothGranted = allGranted;
    });

    if (status.isPermanentlyDenied) {
      _showSettingsDialog('Bluetooth');
    }
  }

  Future<void> _requestNotificationPermission() async {
    // Check current status first
    final currentStatus = await Permission.notification.status;
    
    if (currentStatus.isGranted) {
      setState(() {
        _notificationGranted = true;
      });
      return;
    }
    
    if (currentStatus.isPermanentlyDenied) {
      _showSettingsDialog('Notification');
      return;
    }
    
    // On Android 13+ (API 33+), notification permission is available
    // On older versions, notifications are granted by default
    try {
      final status = await Permission.notification.request();
      
      setState(() {
        _notificationGranted = status.isGranted;
      });

      if (status.isPermanentlyDenied) {
        _showSettingsDialog('Notification');
      } else if (status.isDenied) {
        // On some platforms, notifications might not require explicit permission
        // In that case, we can assume they're "granted"
        setState(() {
          _notificationGranted = true;
        });
      }
    } catch (e) {
      // If notification permission is not available on this platform,
      // assume it's granted (iOS < 10, Android < 13)
      setState(() {
        _notificationGranted = true;
      });
    }
  }

  void _showSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          '$permissionName Permission',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Please enable $permissionName permission in settings to use this feature.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A86FF),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _continue() {
    if (_locationGranted && _bluetoothGranted && _notificationGranted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PhoneAuthScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please grant all permissions to continue'),
          backgroundColor: const Color(0xFFFF4B6E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      
                      // Title
                      const Text(
                        'Permissions Required',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Subtitle
                      Text(
                        'AuraDrive needs access to function correctly.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 50),
                      
                      // Location Permission Card
                      _buildPermissionCard(
                        icon: Icons.location_on,
                        iconColor: const Color(0xFF3A86FF),
                        title: 'Location Access (Always On)',
                        description:
                            'Required to track your vehicle\'s position and detect risks, even when the app is in the background.',
                        buttonText: 'Grant Location',
                        isGranted: _locationGranted,
                        onTap: _requestLocationPermission,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Bluetooth Permission Card
                      _buildPermissionCard(
                        icon: Icons.bluetooth,
                        iconColor: const Color(0xFF00C9A7),
                        title: 'Bluetooth Access',
                        description:
                            'Required to connect with other AuraDrive users nearby.',
                        buttonText: 'Grant Bluetooth',
                        isGranted: _bluetoothGranted,
                        onTap: _requestBluetoothPermission,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Notification Permission Card
                      _buildPermissionCard(
                        icon: Icons.notifications,
                        iconColor: const Color(0xFFFF4B6E),
                        title: 'Notification Access',
                        description:
                            'Required to send you critical collision warnings.',
                        buttonText: 'Grant Notification',
                        isGranted: _notificationGranted,
                        onTap: _requestNotificationPermission,
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
                  
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_locationGranted &&
                                _bluetoothGranted &&
                                _notificationGranted)
                            ? const Color(0xFF3A86FF)
                            : const Color(0xFF2C2C2E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: (_locationGranted &&
                                _bluetoothGranted &&
                                _notificationGranted)
                            ? const Color(0xFF3A86FF).withOpacity(0.5)
                            : Colors.transparent,
                      ),
                      child: const Text(
                        'Continue',
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
                        color: const Color(0xFF3A86FF).withOpacity(0.8),
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
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonText,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? iconColor.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
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
                    if (isGranted)
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: iconColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Granted',
                            style: TextStyle(
                              fontSize: 12,
                              color: iconColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
              height: 1.4,
            ),
          ),
          if (!isGranted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
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
        _buildIndicator(false),
        const SizedBox(width: 8),
        _buildIndicator(true),
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
