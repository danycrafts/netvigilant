import 'dart:async';
import 'package:device_apps/device_apps.dart';
import 'package:apptobe/core/services/cache_service.dart';
import 'package:apptobe/core/services/app_usage_service.dart';

// Simplified Application data class for cache serialization
// We'll store only the essential data and avoid implementing the full interface
class AppData {
  final String appName;
  final String packageName;
  final String? versionName;
  final bool systemApp;

  const AppData({
    required this.appName,
    required this.packageName,
    this.versionName,
    required this.systemApp,
  });

  Map<String, dynamic> toJson() => {
    'appName': appName,
    'packageName': packageName,
    'versionName': versionName,
    'systemApp': systemApp,
  };

  factory AppData.fromApplication(Application app) => AppData(
    appName: app.appName,
    packageName: app.packageName,
    versionName: app.versionName,
    systemApp: app.systemApp,
  );

  static AppData fromJson(Map<String, dynamic> json) => AppData(
    appName: json['appName'] ?? '',
    packageName: json['packageName'] ?? '',
    versionName: json['versionName'],
    systemApp: json['systemApp'] ?? false,
  );
}

class CachedAppInfo {
  final Application app;
  final AppUsageInfo? usageInfo;

  CachedAppInfo({
    required this.app,
    this.usageInfo,
  });

  Map<String, dynamic> toJson() => {
    'app': AppData.fromApplication(app).toJson(),
    'usageInfo': usageInfo != null ? {
      'packageName': usageInfo!.packageName,
      'appName': usageInfo!.appName,
      'totalTimeInForeground': usageInfo!.totalTimeInForeground.inMilliseconds,
      'launchCount': usageInfo!.launchCount,
      'lastTimeUsed': usageInfo!.lastTimeUsed.millisecondsSinceEpoch,
    } : null,
  };

  factory CachedAppInfo.fromJson(Map<String, dynamic> json, Application Function(AppData) appBuilder) {
    final appData = AppData.fromJson(json['app']);
    final usageData = json['usageInfo'];

    return CachedAppInfo(
      app: appBuilder(appData),
      usageInfo: usageData != null ? AppUsageInfo(
        packageName: usageData['packageName'],
        appName: usageData['appName'],
        totalTimeInForeground: Duration(milliseconds: usageData['totalTimeInForeground']),
        launchCount: usageData['launchCount'],
        lastTimeUsed: DateTime.fromMillisecondsSinceEpoch(usageData['lastTimeUsed']),
      ) : null,
    );
  }
}

class CachedAppService {
  static final CachedAppService _instance = CachedAppService._internal();
  factory CachedAppService() => _instance;
  CachedAppService._internal();

  final CacheService _cache = CacheService();

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
      await _cache.remove(key);
    }

    return await _cache.getOrFetch<AppUsageInfo?>(
      key,
      () => AppUsageService.getAppUsageInfo(packageName),
      ttl: const Duration(minutes: 10),
      persistToDisk: false,
      fromJson: (data) => data != null ? _appUsageInfoFromJson(data) : null,
    );
  }

  Future<void> invalidateAppsCache() async {
    await _cache.invalidate('apps');
    await _cache.invalidate(_appUsagePrefix);
  }

  Future<void> invalidateUsageCache() async {
    await _cache.invalidate(_appUsagePrefix);
  }

  static AppUsageInfo _appUsageInfoFromJson(dynamic data) {
    final map = data as Map<String, dynamic>;
    return AppUsageInfo(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      totalTimeInForeground: Duration(milliseconds: map['totalTimeInForeground'] ?? 0),
      launchCount: map['launchCount'] ?? 0,
      lastTimeUsed: DateTime.fromMillisecondsSinceEpoch(map['lastTimeUsed'] ?? 0),
    );
  }
}