import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Authentication service to manage user sessions and persistent login
class AuthService {
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyUserPassword = 'user_password_hash';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keySavePassword = 'save_password';

  final Uuid _uuid = const Uuid();

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  /// Get current user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Get user name
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  /// Get user phone
  Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserPhone);
  }

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Check if save password is enabled
  Future<bool> isSavePasswordEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySavePassword) ?? false;
  }

  /// Set save password preference
  Future<void> setSavePassword(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySavePassword, value);
  }

  /// Register new user
  Future<String> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    bool savePassword = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if email already exists
    final existingEmail = prefs.getString(_keyUserEmail);
    if (existingEmail == email) {
      throw Exception('Email already registered. Please login instead.');
    }
    
    // Generate new user ID
    final userId = _uuid.v4();
    
    // Hash the password
    final passwordHash = _hashPassword(password);
    
    // Save user data
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserPhone, phone);
    await prefs.setString(_keyUserPassword, passwordHash);
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setBool(_keySavePassword, savePassword);
    
    return userId;
  }

  /// Login existing user
  Future<bool> login({
    required String email,
    required String password,
    bool savePassword = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get stored credentials
    final storedEmail = prefs.getString(_keyUserEmail);
    final storedPasswordHash = prefs.getString(_keyUserPassword);
    
    if (storedEmail == null || storedPasswordHash == null) {
      return false; // No user registered
    }
    
    if (storedEmail != email) {
      return false; // Email doesn't match
    }
    
    // Verify password
    final passwordHash = _hashPassword(password);
    if (passwordHash != storedPasswordHash) {
      return false; // Wrong password
    }
    
    // Login successful
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setBool(_keySavePassword, savePassword);
    
    return true;
  }

  /// Check if user exists (for password reset)
  Future<bool> userExists(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString(_keyUserEmail);
    return storedEmail == email;
  }

  /// Reset password
  Future<bool> resetPassword({
    required String email,
    required String phone,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Verify email and phone match
    final storedEmail = prefs.getString(_keyUserEmail);
    final storedPhone = prefs.getString(_keyUserPhone);
    
    if (storedEmail != email || storedPhone != phone) {
      return false; // Credentials don't match
    }
    
    // Update password
    final passwordHash = _hashPassword(newPassword);
    await prefs.setString(_keyUserPassword, passwordHash);
    
    return true;
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, true);
  }

  /// Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    // Note: We keep user data in case they want to login again
  }

  /// Clear all user data (complete sign out)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserPhone);
    await prefs.remove(_keyUserPassword);
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyOnboardingComplete);
    await prefs.remove(_keySavePassword);
  }

  /// Get complete user profile
  Future<Map<String, String?>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_keyUserId),
      'name': prefs.getString(_keyUserName),
      'email': prefs.getString(_keyUserEmail),
      'phone': prefs.getString(_keyUserPhone),
    };
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (name != null) {
      await prefs.setString(_keyUserName, name);
    }
    if (email != null) {
      await prefs.setString(_keyUserEmail, email);
    }
    if (phone != null) {
      await prefs.setString(_keyUserPhone, phone);
    }
  }
}
