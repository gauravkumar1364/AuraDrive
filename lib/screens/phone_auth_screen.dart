import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'email_auth_screen.dart';

/// Phone number authentication screen
class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _countryCode = '+91'; // Default to India
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState?.validate() ?? false) {
      final fullPhoneNumber = _countryCode + _phoneController.text;
      
      // Navigate to email auth screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EmailAuthScreen(
            phoneNumber: fullPhoneNumber,
          ),
        ),
      );
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (value.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Phone number must contain only digits';
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
                          'Enter Your Phone Number',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Subtitle
                        Text(
                          'We\'ll use this to keep your account secure and send you important alerts.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Phone input section
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
                                'PHONE NUMBER',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.5),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Country code and phone input
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Country code dropdown
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2C2C2E),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButton<String>(
                                      value: _countryCode,
                                      dropdownColor: const Color(0xFF2C2C2E),
                                      underline: const SizedBox(),
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.white,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: '+91',
                                          child: Text('🇮🇳 +91'),
                                        ),
                                        DropdownMenuItem(
                                          value: '+1',
                                          child: Text('🇺🇸 +1'),
                                        ),
                                        DropdownMenuItem(
                                          value: '+44',
                                          child: Text('🇬🇧 +44'),
                                        ),
                                        DropdownMenuItem(
                                          value: '+86',
                                          child: Text('🇨🇳 +86'),
                                        ),
                                        DropdownMenuItem(
                                          value: '+81',
                                          child: Text('🇯🇵 +81'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _countryCode = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 12),
                                  
                                  // Phone number input
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(15),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: '1234567890',
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
                                        errorStyle: const TextStyle(
                                          fontSize: 12,
                                          height: 1.5,
                                        ),
                                      ),
                                      validator: _validatePhone,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Info card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A86FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF3A86FF).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: const Color(0xFF3A86FF),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your phone number will be used for account verification and emergency alerts only.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
                                    height: 1.4,
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
                  
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A86FF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF2C2C2E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0xFF3A86FF).withOpacity(0.5),
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
                              'Continue',
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
        _buildIndicator(true),
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
