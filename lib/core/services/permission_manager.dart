import 'package:usage_stats/usage_stats.dart';

class PermissionManager {
  static Future<void> requestAndStoreUsagePermission() async {
    await UsageStats.grantUsagePermission();
  }

  static Future<bool> hasUsagePermission() async {
    return await UsageStats.checkUsagePermission() ?? false;
  }
}
