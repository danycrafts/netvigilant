import 'package:device_apps/device_apps.dart';
import '../interfaces/repository_interfaces.dart';
import '../../services/permission_manager.dart';

// SOLID - Single Responsibility: Only manages usage statistics
class UsageRepositoryImpl implements IUsageRepository {
  @override
  Future<bool> hasUsagePermission() async {
    return await PermissionManager.hasStoredUsagePermission();
  }

  @override
  Future<bool> requestUsagePermission() async {
    try {
      return await PermissionManager.requestAndStoreUsagePermission();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AppUsageInfo?> getUsageInfo<AppUsageInfo>(String packageName) async {
    try {
      final app = await DeviceApps.getApp(packageName);
      if (app == null) return null;

      // Create a mock usage info from app data
      final usageInfo = {
        'packageName': app.packageName,
        'appName': app.appName,
        'lastUsed': DateTime.now().millisecondsSinceEpoch,
        'totalTimeInForeground': 0,
        'activations': 1,
      };
      return usageInfo as AppUsageInfo?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<AppUsageInfo>> getAllUsageStats<AppUsageInfo>() async {
    try {
      final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: false,
        includeSystemApps: false,
        onlyAppsWithLaunchIntent: true,
      );

      final usageStats = <Map<String, dynamic>>[];
      for (final app in apps) {
        usageStats.add({
          'packageName': app.packageName,
          'appName': app.appName,
          'lastUsed': DateTime.now().millisecondsSinceEpoch,
          'totalTimeInForeground': 0,
          'activations': 1,
        });
      }

      return usageStats.cast<AppUsageInfo>();
    } catch (e) {
      return [];
    }
  }
}