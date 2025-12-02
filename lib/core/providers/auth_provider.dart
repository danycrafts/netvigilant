import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isGuestMode = false;
  String? _userEmail;
  String? _userId;
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isGuestMode => _isGuestMode;
  String? get userEmail => _userEmail;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadAuthState();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _loadAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      _isGuestMode = prefs.getBool('is_guest_mode') ?? false;
      _userEmail = prefs.getString('user_email');
      _userId = prefs.getString('user_id');
    } catch (e) {
      if (kDebugMode) {
        print('Error loading auth state: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _performLogin(String email) async {
    _isLoggedIn = true;
    _isGuestMode = false;
    _userEmail = email;
    _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.remove('is_guest_mode');
    await prefs.setString('user_email', email);
    await prefs.setString('user_id', _userId!);
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      if (email.isNotEmpty && password.length >= 6) {
        await _performLogin(email);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      _errorMessage = 'An unexpected error occurred. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String email, String password, String confirmPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      if (email.isNotEmpty && 
          password.length >= 6 && 
          password == confirmPassword) {
        await _performLogin(email);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Please check your registration details and try again.';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Registration error: $e');
      }
      _errorMessage = 'An unexpected error occurred. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _isGuestMode = false;
    _userEmail = null;
    _userId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('is_guest_mode');
    await prefs.remove('user_email');
    await prefs.remove('user_id');

    notifyListeners();
  }

  Future<void> setGuestMode() async {
    _isGuestMode = true;
    _isLoggedIn = false;
    _userEmail = null;
    _userId = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest_mode', true);
      await prefs.remove('is_logged_in');
      await prefs.remove('user_email');
      await prefs.remove('user_id');
    } catch (e) {
      if (kDebugMode) {
        print('Error setting guest mode: $e');
      }
    }

    notifyListeners();
  }
}