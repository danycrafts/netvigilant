import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../interfaces/user_repository.dart';
import '../models/user_profile.dart';

class UserRepository implements IUserRepository {
  static const String _emailNotificationsKey = 'email_notifications';
  static const String _phoneNotificationsKey = 'phone_notifications';
  static const String _pushNotificationsKey = 'push_notifications';
  
  // Fallback storage for when SharedPreferences fails
  static final Map<String, dynamic> _fallbackStorage = {};

  @override
  Future<UserProfile> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return UserProfile(
        firstName: prefs.getString('firstName') ?? 'User',
        lastName: prefs.getString('lastName') ?? 'Name',
        username: prefs.getString('username') ?? 'username',
        email: prefs.getString('email') ?? 'user.name@example.com',
        phone: prefs.getString('phone') ?? '',
      );
    } catch (e) {
      if (kDebugMode) {
        print('SharedPreferences error in getUserProfile: $e');
      }
      
      return UserProfile(
        firstName: _fallbackStorage['firstName'] as String? ?? 'User',
        lastName: _fallbackStorage['lastName'] as String? ?? 'Name',
        username: _fallbackStorage['username'] as String? ?? 'username',
        email: _fallbackStorage['email'] as String? ?? 'user.name@example.com',
        phone: _fallbackStorage['phone'] as String? ?? '',
      );
    }
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('firstName', profile.firstName);
      await prefs.setString('lastName', profile.lastName);
      await prefs.setString('username', profile.username);
      await prefs.setString('email', profile.email);
      await prefs.setString('phone', profile.phone);
    } catch (e) {
      if (kDebugMode) {
        print('SharedPreferences error in updateUserProfile: $e');
      }
      
      // Store in fallback
      _fallbackStorage['firstName'] = profile.firstName;
      _fallbackStorage['lastName'] = profile.lastName;
      _fallbackStorage['username'] = profile.username;
      _fallbackStorage['email'] = profile.email;
      _fallbackStorage['phone'] = profile.phone;
    }
  }

  @override
  Future<Map<String, bool>> getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'email': prefs.getBool(_emailNotificationsKey) ?? true,
        'phone': prefs.getBool(_phoneNotificationsKey) ?? false,
        'push': prefs.getBool(_pushNotificationsKey) ?? true,
      };
    } catch (e) {
      if (kDebugMode) {
        print('SharedPreferences error in getNotificationSettings: $e');
      }
      
      return {
        'email': _fallbackStorage[_emailNotificationsKey] as bool? ?? true,
        'phone': _fallbackStorage[_phoneNotificationsKey] as bool? ?? false,
        'push': _fallbackStorage[_pushNotificationsKey] as bool? ?? true,
      };
    }
  }

  @override
  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_emailNotificationsKey, settings['email'] ?? true);
      await prefs.setBool(_phoneNotificationsKey, settings['phone'] ?? false);
      await prefs.setBool(_pushNotificationsKey, settings['push'] ?? true);
    } catch (e) {
      if (kDebugMode) {
        print('SharedPreferences error in updateNotificationSettings: $e');
      }
      
      // Store in fallback
      _fallbackStorage[_emailNotificationsKey] = settings['email'] ?? true;
      _fallbackStorage[_phoneNotificationsKey] = settings['phone'] ?? false;
      _fallbackStorage[_pushNotificationsKey] = settings['push'] ?? true;
    }
  }
}