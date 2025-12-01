import 'package:usage_stats/usage_stats.dart';
import 'package:netvigilant/core/services/permission_manager.dart';

class AppUsageInfo {
  final Duration totalTimeInForeground;
  final int launchCount;
  final DateTime lastTimeUsed;

  AppUsageInfo({
    required this.totalTimeInForeground,
    required this.launchCount,
    required this.lastTimeUsed,
  });
}

class AppUsageService {
  static Future<bool> hasUsagePermission() async {
    return await PermissionManager.hasUsagePermission();
  }

  static Future<AppUsageInfo?> getAppUsageInfo(String packageName) async {
    try {
      if (await hasUsagePermission()) {
        DateTime endDate = DateTime.now();
        DateTime startDate = endDate.subtract(const Duration(days: 7));
        List<UsageInfo> usageStats =
            await UsageStats.queryUsageStats(startDate, endDate);
        UsageInfo? appUsage;
        for (var usage in usageStats) {
          if (usage.packageName == packageName) {
            appUsage = usage;
            break;
          }
        }

        List<EventUsageInfo> events =
            await UsageStats.queryEvents(startDate, endDate);
        int launchCount = 0;
        for (var event in events) {
          if (event.packageName == packageName &&
              event.eventType == 'ACTIVITY_RESUMED') {
            launchCount++;
          }
        }

        if (appUsage != null) {
          return AppUsageInfo(
            totalTimeInForeground:
                Duration(milliseconds: int.parse(appUsage.totalTimeInForeground!)),
            launchCount: launchCount,
            lastTimeUsed:
                DateTime.fromMillisecondsSinceEpoch(int.parse(appUsage.lastTimeUsed!)),
          );
        }
      }
    } catch (e) {
      print('Error fetching app usage info: $e');
    }
    return null;
  }
}
