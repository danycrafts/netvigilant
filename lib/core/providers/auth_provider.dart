import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _userEmail;
  String? _userId;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get userEmail => _userEmail;
  String? get userId => _userId;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
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

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      if (email.isNotEmpty && password.length >= 6) {
        _isLoggedIn = true;
        _userEmail = email;
        _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_email', email);
        await prefs.setString('user_id', _userId!);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
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
        _isLoggedIn = true;
        _userEmail = email;
        _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_email', email);
        await prefs.setString('user_id', _userId!);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Registration error: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userEmail = null;
    _userId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('user_email');
    await prefs.remove('user_id');

    notifyListeners();
  }
}