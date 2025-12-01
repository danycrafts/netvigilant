import '../models/user_profile.dart';

abstract class IUserRepository {
  Future<UserProfile> getUserProfile();
  Future<void> updateUserProfile(UserProfile profile);
  Future<Map<String, bool>> getNotificationSettings();
  Future<void> updateNotificationSettings(Map<String, bool> settings);
}