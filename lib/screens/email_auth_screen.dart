import 'package:flutter/material.dart';
import 'navigation_screen.dart';
import '../services/auth_service.dart';

/// Email authentication screen
class EmailAuthScreen extends StatefulWidget {
  final String phoneNumber;

  const EmailAuthScreen({super.key, required this.phoneNumber});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Save user data and get unique user ID
        final userId = await _authService.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: widget.phoneNumber,
          password: 'N/A', // We're not using password auth in this flow
        );

        // Mark onboarding as complete
        await _authService.completeOnboarding();

        if (!mounted) return;

        // Show success message with user ID
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome! Your ID: ${userId.substring(0, 8)}...'),
            backgroundColor: const Color(0xFF00C9A7),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to main screen and remove all previous routes
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const NavigationScreen()),
          (route) => false, // Remove all previous routes
        );
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF4B6E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60),

                        // Back button
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                        ),

                        const SizedBox(height: 40),

                        // Title
                        const Text(
                          'Complete Your Profile',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          'Just a few more details to get you started on your safer driving journey.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 50),

                        // Name input
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FULL NAME',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.5),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'John Doe',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF2C2C2E),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  errorStyle: const TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                                validator: _validateName,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Email input
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EMAIL ADDRESS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.5),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'john@example.com',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF2C2C2E),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  errorStyle: const TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                                validator: _validateEmail,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Phone number display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C9A7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF00C9A7).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: const Color(0xFF00C9A7),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Phone Number Verified',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.phoneNumber,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page indicators
                  _buildPageIndicators(),
                  const SizedBox(height: 24),

                  // Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C9A7),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF2C2C2E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0xFF00C9A7).withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
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

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIndicator(false),
        const SizedBox(width: 8),
        _buildIndicator(false),
        const SizedBox(width: 8),
        _buildIndicator(false),
        const SizedBox(width: 8),
        _buildIndicator(false),
        const SizedBox(width: 8),
        _buildIndicator(true),
      ],
    );
  }

  Widget _buildIndicator(bool isActive) {
    return Container(
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF00C9A7)
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
