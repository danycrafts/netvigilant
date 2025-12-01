import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../interfaces/theme_service.dart';

class ThemeService implements IThemeService {
  static const String _themeKey = 'is_dark_mode';
  static bool _fallbackDarkMode = false;
  static bool _usesFallback = false;

  @override
  Future<bool> isDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _usesFallback = false;
      return prefs.getBool(_themeKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('SharedPreferences error in isDarkMode: $e');
      }
      _usesFallback = true;
      return _fallbackDarkMode;
    }
  }

  @override
  Future<void> setDarkMode(bool isDarkMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDarkMode);
      _usesFallback = false;
    } catch (e) {
      if (kDebugMode) {
        print('SharedPreferences error in setDarkMode: $e');
      }
      _fallbackDarkMode = isDarkMode;
      _usesFallback = true;
    }
  }

  @override
  Future<void> toggleTheme() async {
    final currentMode = await isDarkMode();
    await setDarkMode(!currentMode);
  }

  bool get usesFallback => _usesFallback;
}