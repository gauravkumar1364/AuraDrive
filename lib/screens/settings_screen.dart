import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import 'welcome_screen.dart';

/// Settings screen for app configuration and preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _settingsService = SettingsService();

  bool _soundAlerts = true;
  bool _vibrationAlerts = true;
  String _proximityThreshold = 'Normal';
  String _userId = '';
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUserData();
  }

  Future<void> _loadSettings() async {
    final soundAlerts = await _settingsService.getSoundAlerts();
    final vibrationAlerts = await _settingsService.getVibrationAlerts();
    final proximityThreshold = await _settingsService.getProximityThreshold();

    setState(() {
      _soundAlerts = soundAlerts;
      _vibrationAlerts = vibrationAlerts;
      _proximityThreshold = proximityThreshold;
    });
  }

  Future<void> _loadUserData() async {
    final profile = await _authService.getUserProfile();
    setState(() {
      _userId = profile['userId'] ?? 'Not available';
      _userName = profile['name'] ?? '';
      _userEmail = profile['email'] ?? '';
      _userPhone = profile['phone'] ?? '';
    });
  }

  Future<void> _setSoundAlerts(bool value) async {
    await _settingsService.setSoundAlerts(value);
    setState(() {
      _soundAlerts = value;
    });
  }

  Future<void> _setVibrationAlerts(bool value) async {
    await _settingsService.setVibrationAlerts(value);
    setState(() {
      _vibrationAlerts = value;
    });
  }

  Future<void> _setProximityThreshold(String value) async {
    await _settingsService.setProximityThreshold(value);
    setState(() {
      _proximityThreshold = value;
    });
  }

  void _copyDeviceId() {
    Clipboard.setData(ClipboardData(text: _userId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Device ID copied to clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF00C9A7),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.logout();
              if (!mounted) return;
              
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const WelcomeScreen(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B6E),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showHowToUse() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'How to Use AuraDrive',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHowToItem(
                '1. Keep Bluetooth On',
                'Ensure Bluetooth is always enabled for the mesh network to function.',
              ),
              const SizedBox(height: 12),
              _buildHowToItem(
                '2. Grant Permissions',
                'Allow location, Bluetooth, and notification permissions for full functionality.',
              ),
              const SizedBox(height: 12),
              _buildHowToItem(
                '3. Drive Safely',
                'Keep the app running in the background while driving to receive proximity alerts.',
              ),
              const SizedBox(height: 12),
              _buildHowToItem(
                '4. Monitor Map',
                'Green markers show nearby vehicles, red markers indicate potential risks.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Text(
            'AuraDrive respects your privacy.\n\n'
            '• Location data is used only for proximity detection\n'
            '• Data is shared only with nearby devices via Bluetooth\n'
            '• No data is stored on external servers\n'
            '• Your personal information is stored locally\n'
            '• You can delete your data anytime from settings\n\n'
            'For questions, contact us at:\nsupport@auradrive.app',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7B2CBF),
              ),
              child: const Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'About AuraDrive',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AuraDrive is a smart proximity system that helps you drive safer with real-time alerts from nearby vehicles.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Text(
                    'Made with',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '❤️',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'by',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'BODMAS',
                    style: TextStyle(
                      color: const Color(0xFF7B2CBF),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // User Profile Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7B2CBF),
                  ),
                  child: Center(
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Alert Preferences
          _buildSectionHeader('Alert Preferences'),
          _buildSwitchTile(
            title: 'Sound Alerts',
            subtitle: 'Play sound when vehicles are nearby',
            value: _soundAlerts,
            icon: Icons.volume_up,
            onChanged: _setSoundAlerts,
          ),
          _buildSwitchTile(
            title: 'Vibration',
            subtitle: 'Vibrate on proximity warnings',
            value: _vibrationAlerts,
            icon: Icons.vibration,
            onChanged: _setVibrationAlerts,
          ),

          // Proximity Thresholds
          _buildSectionHeader('Proximity Threshold'),
          _buildProximityOption('Normal', '25 meters', '25m'),
          _buildProximityOption('Far', '50 meters', '50m'),
          _buildProximityOption('Very Far', '100 meters', '100m'),

          // Device Information
          _buildSectionHeader('Device Information'),
          _buildInfoTile(
            title: 'Device ID',
            subtitle: _userId.length > 20 
                ? '${_userId.substring(0, 20)}...' 
                : _userId,
            icon: Icons.fingerprint,
            onTap: _copyDeviceId,
            trailing: const Icon(
              Icons.copy,
              color: Color(0xFF7B2CBF),
              size: 20,
            ),
          ),
          _buildInfoTile(
            title: 'Phone Number',
            subtitle: _userPhone,
            icon: Icons.phone,
          ),

          // Help & About
          _buildSectionHeader('Help & About'),
          _buildActionTile(
            title: 'How to Use',
            subtitle: 'Learn how to use AuraDrive',
            icon: Icons.help_outline,
            onTap: _showHowToUse,
          ),
          _buildActionTile(
            title: 'Privacy Policy',
            subtitle: 'View our privacy policy',
            icon: Icons.privacy_tip_outlined,
            onTap: _showPrivacyPolicy,
          ),
          _buildActionTile(
            title: 'About',
            subtitle: 'Version 1.0.0',
            icon: Icons.info_outline,
            onTap: _showAbout,
          ),

          // Logout
          _buildSectionHeader('Account'),
          _buildActionTile(
            title: 'Logout',
            subtitle: 'Sign out of your account',
            icon: Icons.logout,
            iconColor: const Color(0xFFFF4B6E),
            onTap: _showLogoutDialog,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF7B2CBF),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ),
        activeColor: const Color(0xFF7B2CBF),
      ),
    );
  }

  Widget _buildProximityOption(String label, String distance, String value) {
    final isSelected = _proximityThreshold == value;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: const Color(0xFF7B2CBF), width: 2)
            : null,
      ),
      child: ListTile(
        onTap: () => _setProximityThreshold(value),
        leading: Icon(
          Icons.radar,
          color: isSelected ? const Color(0xFF7B2CBF) : Colors.white54,
          size: 24,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF7B2CBF) : Colors.white,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          distance,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
        trailing: isSelected
            ? const Icon(
                Icons.check_circle,
                color: Color(0xFF7B2CBF),
              )
            : null,
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: const Color(0xFF7B2CBF),
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.3),
            ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: iconColor ?? const Color(0xFF7B2CBF),
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }
}
