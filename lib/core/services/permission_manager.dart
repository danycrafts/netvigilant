import 'package:shared_preferences/shared_preferences.dart';
import 'app_usage_service.dart';

/// SOLID: Single responsibility for permission state management
/// KISS: Simple, focused permission tracking
class PermissionManager {
  static const String _usagePermissionKey = 'app_usage_permission_granted';
  static const String _usagePermissionAskedKey = 'app_usage_permission_asked';

  /// Check if usage permission was already granted and stored
  static Future<bool> hasStoredUsagePermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_usagePermissionKey) ?? false;
  }

  /// Check if we've already asked for usage permission before
  static Future<bool> hasAskedForUsagePermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_usagePermissionAskedKey) ?? false;
  }

  /// Store that usage permission was granted
  static Future<void> markUsagePermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_usagePermissionKey, true);
    await prefs.setBool(_usagePermissionAskedKey, true);
  }

  /// Store that we asked for permission (even if denied)
  static Future<void> markUsagePermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_usagePermissionAskedKey, true);
  }

  /// Clear stored permission (for testing or reset)
  static Future<void> clearUsagePermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usagePermissionKey);
    await prefs.remove(_usagePermissionAskedKey);
  }

  /// Check if we need to ask for usage permission
  /// DRY: Combines multiple checks in one method
  static Future<bool> shouldRequestUsagePermission() async {
    // Already asked before
    if (await hasAskedForUsagePermission()) {
      return false;
    }

    // Already have actual permission
    if (await AppUsageService.hasUsagePermission()) {
      await markUsagePermissionGranted();
      return false;
    }

    return true;
  }

  /// Complete permission flow - request and store result
  static Future<bool> requestAndStoreUsagePermission() async {
    final granted = await AppUsageService.requestUsagePermission();
    
    if (granted) {
      await markUsagePermissionGranted();
    } else {
      await markUsagePermissionAsked();
    }
    
    return granted;
  }
}