import 'package:flutter/foundation.dart';
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
    final bluetoothAdvertiseStatus = await Permission.bluetoothAdvertise.status;

    // Check notification permissions
    final notificationStatus = await Permission.notification.status;

    final locationGranted =
        locationStatus.isGranted || locationAlwaysStatus.isGranted;
    final bluetoothGranted =
        bluetoothStatus.isGranted ||
        (bluetoothScanStatus.isGranted && bluetoothConnectStatus.isGranted && bluetoothAdvertiseStatus.isGranted);
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

    // If denied (but not permanently), show rationale and allow retry
    if (status.isDenied) {
      await _showRationaleDialog('Location', Permission.location);
    }

    // Also request background location if foreground was granted
    if (status.isGranted) {
      final alwaysStatus = await Permission.locationAlways.request();
      if (alwaysStatus.isDenied) {
        await _showRationaleDialog(
          'Background Location',
          Permission.locationAlways,
        );
      }
    }

    setState(() {
      _locationGranted = status.isGranted;
    });

    if (status.isPermanentlyDenied) {
      _showSettingsDialog('Location');
    }
  }

  Future<void> _requestBluetoothPermission() async {
    debugPrint('PermissionsScreen: Requesting Bluetooth permissions...');
    
    try {
      // On Android 12+ (API 31+), request new permissions first
      debugPrint('PermissionsScreen: Requesting new Bluetooth permissions (Android 12+)...');
      final scanStatus = await Permission.bluetoothScan.request();
      final connectStatus = await Permission.bluetoothConnect.request();
      final advertiseStatus = await Permission.bluetoothAdvertise.request();
      
      debugPrint('PermissionsScreen: Scan status: $scanStatus');
      debugPrint('PermissionsScreen: Connect status: $connectStatus');
      debugPrint('PermissionsScreen: Advertise status: $advertiseStatus');
      
      // Also request legacy permission for older devices
      debugPrint('PermissionsScreen: Requesting legacy Bluetooth permission...');
      final legacyStatus = await Permission.bluetooth.request();
      debugPrint('PermissionsScreen: Legacy Bluetooth status: $legacyStatus');
      
      final newPermissionsGranted = scanStatus.isGranted && connectStatus.isGranted && advertiseStatus.isGranted;
      final legacyGranted = legacyStatus.isGranted;
      final allGranted = newPermissionsGranted || legacyGranted;
      
      debugPrint('PermissionsScreen: New permissions granted: $newPermissionsGranted');
      debugPrint('PermissionsScreen: Legacy permission granted: $legacyGranted');
      debugPrint('PermissionsScreen: All Bluetooth permissions granted: $allGranted');
      
      setState(() {
        _bluetoothGranted = allGranted;
      });
      
      if (!allGranted) {
        // Check if any are permanently denied
        final permanentlyDenied = scanStatus.isPermanentlyDenied || 
            connectStatus.isPermanentlyDenied || 
            advertiseStatus.isPermanentlyDenied ||
            legacyStatus.isPermanentlyDenied;
            
        debugPrint('PermissionsScreen: Any permission permanently denied: $permanentlyDenied');
        
        if (permanentlyDenied) {
          _showSettingsDialog('Bluetooth');
        } else {
          await _showRationaleDialog('Bluetooth', Permission.bluetooth);
        }
      }
    } catch (e) {
      debugPrint('PermissionsScreen: Error requesting new Bluetooth permissions: $e');
      // Fallback: try legacy permission only
      debugPrint('PermissionsScreen: Falling back to legacy Bluetooth permission only...');
      final legacyStatus = await Permission.bluetooth.request();
      debugPrint('PermissionsScreen: Legacy fallback status: $legacyStatus');
      
      setState(() {
        _bluetoothGranted = legacyStatus.isGranted;
      });
      
      if (legacyStatus.isPermanentlyDenied) {
        debugPrint('PermissionsScreen: Legacy permission permanently denied');
        _showSettingsDialog('Bluetooth');
      } else if (!legacyStatus.isGranted) {
        debugPrint('PermissionsScreen: Legacy permission denied but not permanently');
        await _showRationaleDialog('Bluetooth', Permission.bluetooth);
      }
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

      if (status.isDenied) {
        await _showRationaleDialog('Notification', Permission.notification);
      }

      setState(() {
        _notificationGranted = status.isGranted;
      });

      if (status.isPermanentlyDenied) {
        _showSettingsDialog('Notification');
      }
    } catch (e) {
      // If notification permission is not available on this platform,
      // assume it's granted (iOS < 10, Android < 13)
      setState(() {
        _notificationGranted = true;
      });
    }
  }

  /// Show a short rationale dialog with options to retry the request or open app settings
  Future<void> _showRationaleDialog(
    String permissionName,
    Permission permission,
  ) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          '$permissionName Permission',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'This app needs $permissionName permission to work properly. Would you like to try granting it again or open app settings?',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final result = await permission.request();
              if (result.isPermanentlyDenied) {
                _showSettingsDialog(permissionName);
              } else {
                setState(() {
                  if (permission == Permission.location ||
                      permission == Permission.locationAlways) {
                    _locationGranted = result.isGranted;
                  } else if (permission == Permission.bluetooth ||
                      permission == Permission.bluetoothScan ||
                      permission == Permission.bluetoothConnect) {
                    _bluetoothGranted = result.isGranted;
                  } else if (permission == Permission.notification) {
                    _notificationGranted = result.isGranted;
                  }
                });
              }
            },
            child: const Text('Try Again'),
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
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const PhoneAuthScreen()));
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
                        backgroundColor:
                            (_locationGranted &&
                                _bluetoothGranted &&
                                _notificationGranted)
                            ? const Color(0xFF3A86FF)
                            : const Color(0xFF2C2C2E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor:
                            (_locationGranted &&
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
                child: Icon(icon, color: iconColor, size: 28),
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
                          Icon(Icons.check_circle, color: iconColor, size: 16),
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
