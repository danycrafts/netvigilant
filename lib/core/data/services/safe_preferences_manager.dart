import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/result.dart';

class SafePreferencesManager {
  static SafePreferencesManager? _instance;
  SharedPreferences? _prefs;

  SafePreferencesManager._();

  static SafePreferencesManager get instance {
    _instance ??= SafePreferencesManager._();
    return _instance!;
  }

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Result<bool>> getBool(String key, {bool defaultValue = false}) async {
    try {
      await _ensureInitialized();
      final value = _prefs!.getBool(key) ?? defaultValue;
      return Success(value);
    } catch (e) {
      return Failure('Failed to get bool value for key "$key": ${e.toString()}');
    }
  }

  Future<Result<void>> setBool(String key, bool value) async {
    try {
      await _ensureInitialized();
      await _prefs!.setBool(key, value);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to set bool value for key "$key": ${e.toString()}');
    }
  }

  Future<Result<String?>> getString(String key) async {
    try {
      await _ensureInitialized();
      final value = _prefs!.getString(key);
      return Success(value);
    } catch (e) {
      return Failure('Failed to get string value for key "$key": ${e.toString()}');
    }
  }

  Future<Result<void>> setString(String key, String value) async {
    try {
      await _ensureInitialized();
      await _prefs!.setString(key, value);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to set string value for key "$key": ${e.toString()}');
    }
  }

  Future<Result<int?>> getInt(String key) async {
    try {
      await _ensureInitialized();
      final value = _prefs!.getInt(key);
      return Success(value);
    } catch (e) {
      return Failure('Failed to get int value for key "$key": ${e.toString()}');
    }
  }

  Future<Result<void>> setInt(String key, int value) async {
    try {
      await _ensureInitialized();
      await _prefs!.setInt(key, value);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to set int value for key "$key": ${e.toString()}');
    }
  }

  Future<Result<void>> remove(String key) async {
    try {
      await _ensureInitialized();
      await _prefs!.remove(key);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to remove key "$key": ${e.toString()}');
    }
  }

  Future<Result<void>> removeMultiple(List<String> keys) async {
    try {
      await _ensureInitialized();
      for (final key in keys) {
        await _prefs!.remove(key);
      }
      return const Success(null);
    } catch (e) {
      return Failure('Failed to remove keys $keys: ${e.toString()}');
    }
  }

  Future<Result<void>> clear() async {
    try {
      await _ensureInitialized();
      await _prefs!.clear();
      return const Success(null);
    } catch (e) {
      return Failure('Failed to clear preferences: ${e.toString()}');
    }
  }
}