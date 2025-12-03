import 'dart:async';
import 'package:device_apps/device_apps.dart';
import 'package:apptobe/core/services/cache_service.dart';
import 'package:apptobe/core/services/app_usage_service.dart';
import 'package:apptobe/core/models/cached_app_info.dart';

class CachedAppService {
  static final CachedAppService _instance = CachedAppService._internal();
  factory CachedAppService() => _instance;
  CachedAppService._internal();

  final CacheService _cache = CacheService(const Duration(minutes: 30));

  static const String _appUsagePrefix = 'app_usage_';

  Future<List<Application>> getInstalledApps({
    bool includeAppIcons = true,
    bool includeSystemApps = true,
    bool onlyAppsWithLaunchIntent = false,
    bool forceRefresh = false,
  }) async {
    // For now, we'll skip complex caching for Application objects
    // and fetch them directly each time to avoid serialization issues
    return await DeviceApps.getInstalledApplications(
      includeAppIcons: includeAppIcons,
      includeSystemApps: includeSystemApps,
      onlyAppsWithLaunchIntent: onlyAppsWithLaunchIntent,
    );
  }

  Future<List<CachedAppInfo>> getAppsWithUsageStats({
    bool forceRefresh = false,
  }) async {
    // Get fresh app data but limit to reasonable number to prevent hanging
    final apps = await getInstalledApps(
      includeSystemApps: false,  // Skip system apps for performance
      onlyAppsWithLaunchIntent: true,  // Only apps that can be launched
    );
    
    final hasPermission = await AppUsageService.hasUsagePermission();
    
    if (!hasPermission) {
      return apps.take(50).map((app) => CachedAppInfo(app: app)).toList();
    }

    
    // Limit to first 50 apps to prevent hanging and process them in parallel
    final limitedApps = apps.take(50).toList();
    
    // Use Future.wait for parallel processing instead of sequential
    final usageInfoFutures = limitedApps.map((app) async {
      try {
        final usageInfo = await getAppUsageInfo(app.packageName, forceRefresh: forceRefresh)
            .timeout(const Duration(seconds: 2));
        return CachedAppInfo(app: app, usageInfo: usageInfo);
      } catch (e) {
        // If individual app fails, return without usage info
        return CachedAppInfo(app: app);
      }
    });

    final results = await Future.wait(usageInfoFutures);
    return results;
  }

  Future<AppUsageInfo?> getAppUsageInfo(
    String packageName, {
    bool forceRefresh = false,
  }) async {
    final key = '$_appUsagePrefix$packageName';
    
    if (forceRefresh) {
      _cache.remove(key);
    }

    return await _cache.getOrFetch(
      key,
      () => AppUsageService.getAppUsageInfo(packageName),
    );
  }

  Future<void> invalidateAppsCache() async {
    _cache.invalidate('apps');
    _cache.invalidate(_appUsagePrefix);
  }

  Future<void> invalidateUsageCache() async {
    _cache.invalidate(_appUsagePrefix);
  }
}
