import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../interfaces/user_repository.dart';
import '../repositories/user_repository.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfile _userProfile = UserProfile(
    firstName: 'User',
    lastName: 'Name',
    username: 'username',
    email: 'user.name@example.com',
    phone: '',
  );

  bool _emailNotifications = true;
  bool _phoneNotifications = false;
  bool _pushNotifications = true;
  
  late final IUserRepository _userRepository;
  bool _isLoading = false;

  UserProfile get userProfile => _userProfile;
  bool get emailNotifications => _emailNotifications;
  bool get phoneNotifications => _phoneNotifications;
  bool get pushNotifications => _pushNotifications;
  bool get isLoading => _isLoading;

  UserProfileProvider({IUserRepository? userRepository}) {
    _userRepository = userRepository ?? UserRepository();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _userProfile = await _userRepository.getUserProfile();
      final settings = await _userRepository.getNotificationSettings();
      _emailNotifications = settings['email'] ?? true;
      _phoneNotifications = settings['phone'] ?? false;
      _pushNotifications = settings['push'] ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    try {
      await _userRepository.updateUserProfile(newProfile);
      _userProfile = newProfile;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile: $e');
      }
    }
  }

  Future<void> updateEmailNotifications(bool enabled) async {
    _emailNotifications = enabled;
    await _updateNotificationSettings();
  }

  Future<void> updatePhoneNotifications(bool enabled) async {
    _phoneNotifications = enabled;
    await _updateNotificationSettings();
  }

  Future<void> updatePushNotifications(bool enabled) async {
    _pushNotifications = enabled;
    await _updateNotificationSettings();
  }

  Future<void> _updateNotificationSettings() async {
    try {
      final settings = {
        'email': _emailNotifications,
        'phone': _phoneNotifications,
        'push': _pushNotifications,
      };
      await _userRepository.updateNotificationSettings(settings);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating notification settings: $e');
      }
    }
  }
}