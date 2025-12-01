import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionManager {
  static const String _usagePermissionRequestedKey =
      'usagePermissionRequested';

  static Future<void> requestAndStoreUsagePermission() async {
    await Permission.usage.request();
    await markUsagePermissionAsked();
  }

  static Future<bool> hasUsagePermission() async {
    final status = await Permission.usage.status;
    return status.isGranted;
  }

  static Future<bool> shouldRequestUsagePermission() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_usagePermissionRequestedKey) ?? false);
  }

  static Future<void> markUsagePermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_usagePermissionRequestedKey, true);
  }
}
