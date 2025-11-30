import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:netvigilant/core/utils/logger.dart';
import 'package:netvigilant/domain/entities/app_info_entity.dart';

/// Service for discovering and managing all installed applications
/// Provides comprehensive app metadata and usage information
class AppDiscoveryService {
  static const MethodChannel _channel = MethodChannel('com.example.netvigilant/network_stats');
  
  static const Duration _cacheTimeout = Duration(minutes: 5);
  
  // Cache for discovered apps
  static final Map<String, List<AppInfoEntity>> _appCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  /// Get all installed applications with optional system apps
  static Future<List<AppInfoEntity>> getAllInstalledApps({
    bool includeSystemApps = false,
    bool includeIcons = false,
    bool useCache = true,
  }) async {
    final cacheKey = 'all_apps_${includeSystemApps}_$includeIcons';
    
    // Check cache first
    if (useCache && _isValidCache(cacheKey)) {
      log('AppDiscoveryService: Returning cached apps (${_appCache[cacheKey]?.length} apps)');
      return _appCache[cacheKey] ?? [];
    }
    
    try {
      log('AppDiscoveryService: Discovering all installed apps...');
      final startTime = DateTime.now();
      
      final List<dynamic>? result = await _channel.invokeMethod('getAllInstalledApps', {
        'includeSystemApps': includeSystemApps,
        'includeIcons': includeIcons,
      });
      
      if (result == null) {
        log('AppDiscoveryService: No apps returned from platform');
        return [];
      }
      
      final apps = result.map((data) => AppInfoEntity.fromMap(Map<String, dynamic>.from(data))).toList();
      
      // Cache the results
      _appCache[cacheKey] = apps;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      final duration = DateTime.now().difference(startTime);
      log('AppDiscoveryService: Discovered ${apps.length} apps in ${duration.inMilliseconds}ms');
      
      return apps;
      
    } catch (e) {
      log('AppDiscoveryService: Error getting all installed apps: $e');
      // Return cached data if available
      return _appCache[cacheKey] ?? [];
    }
  }
  
  /// Get all apps with real-time usage information
  static Future<List<AppInfoEntity>> getAllAppsWithUsage({
    bool useCache = false, // Usage data should be fresh
  }) async {
    const cacheKey = 'apps_with_usage';
    
    if (useCache && _isValidCache(cacheKey)) {
      return _appCache[cacheKey] ?? [];
    }
    
    try {
      log('AppDiscoveryService: Getting all apps with usage data...');
      final startTime = DateTime.now();
      
      final List<dynamic>? result = await _channel.invokeMethod('getAllAppsWithUsage');
      
      if (result == null) {
        log('AppDiscoveryService: No usage data returned from platform');
        return [];
      }
      
      final apps = result.map((data) => AppInfoEntity.fromMap(Map<String, dynamic>.from(data))).toList();
      
      if (useCache) {
        _appCache[cacheKey] = apps;
        _cacheTimestamps[cacheKey] = DateTime.now();
      }
      
      final duration = DateTime.now().difference(startTime);
      log('AppDiscoveryService: Retrieved ${apps.length} apps with usage in ${duration.inMilliseconds}ms');
      
      return apps;
      
    } catch (e) {
      log('AppDiscoveryService: Error getting apps with usage: $e');
      return [];
    }
  }
  
  /// Search apps by name or package name
  static Future<List<AppInfoEntity>> searchApps({
    required String query,
    bool includeSystemApps = false,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    try {
      log('AppDiscoveryService: Searching apps with query: "$query"');
      
      final List<dynamic>? result = await _channel.invokeMethod('searchApps', {
        'query': query,
        'includeSystemApps': includeSystemApps,
      });
      
      if (result == null) {
        return [];
      }
      
      final apps = result.map((data) => AppInfoEntity.fromMap(Map<String, dynamic>.from(data))).toList();
      
      log('AppDiscoveryService: Found ${apps.length} apps matching "$query"');
      return apps;
      
    } catch (e) {
      log('AppDiscoveryService: Error searching apps: $e');
      return [];
    }
  }
  
  /// Get apps by category
  static Future<List<AppInfoEntity>> getAppsByCategory(String category) async {
    try {
      log('AppDiscoveryService: Getting apps in category: $category');
      
      final List<dynamic>? result = await _channel.invokeMethod('getAppsByCategory', {
        'category': category,
      });
      
      if (result == null) {
        return [];
      }
      
      final apps = result.map((data) => AppInfoEntity.fromMap(Map<String, dynamic>.from(data))).toList();
      
      log('AppDiscoveryService: Found ${apps.length} apps in category "$category"');
      return apps;
      
    } catch (e) {
      log('AppDiscoveryService: Error getting apps by category: $e');
      return [];
    }
  }
  
  /// Get recently updated apps
  static Future<List<AppInfoEntity>> getRecentlyUpdatedApps({
    int daysBack = 7,
  }) async {
    try {
      log('AppDiscoveryService: Getting recently updated apps (last $daysBack days)');
      
      final List<dynamic>? result = await _channel.invokeMethod('getRecentlyUpdatedApps', {
        'daysBack': daysBack,
      });
      
      if (result == null) {
        return [];
      }
      
      final apps = result.map((data) => AppInfoEntity.fromMap(Map<String, dynamic>.from(data))).toList();
      
      log('AppDiscoveryService: Found ${apps.length} recently updated apps');
      return apps;
      
    } catch (e) {
      log('AppDiscoveryService: Error getting recently updated apps: $e');
      return [];
    }
  }
  
  /// Get available app categories
  static Future<List<String>> getAvailableCategories() async {
    try {
      final apps = await getAllInstalledApps(includeSystemApps: false);
      final categories = apps.map((app) => app.category).toSet().toList();
      categories.sort();
      
      log('AppDiscoveryService: Found ${categories.length} app categories');
      return categories;
      
    } catch (e) {
      log('AppDiscoveryService: Error getting categories: $e');
      return [];
    }
  }
  
  /// Get app statistics
  static Future<Map<String, dynamic>> getAppStatistics() async {
    try {
      final allApps = await getAllInstalledApps(includeSystemApps: true);
      final userApps = allApps.where((app) => !app.isSystemApp).toList();
      final systemApps = allApps.where((app) => app.isSystemApp).toList();
      
      final categories = <String, int>{};
      for (final app in userApps) {
        categories[app.category] = (categories[app.category] ?? 0) + 1;
      }
      
      final totalSize = userApps.fold<int>(0, (sum, app) => sum + app.appSize);
      
      return {
        'totalApps': allApps.length,
        'userApps': userApps.length,
        'systemApps': systemApps.length,
        'categoriesCount': categories.length,
        'categories': categories,
        'totalSize': totalSize,
        'averageSize': userApps.isNotEmpty ? totalSize / userApps.length : 0,
      };
      
    } catch (e) {
      log('AppDiscoveryService: Error getting app statistics: $e');
      return {};
    }
  }
  
  /// Clear all caches
  static Future<void> clearCache() async {
    try {
      _appCache.clear();
      _cacheTimestamps.clear();
      
      await _channel.invokeMethod('clearAppCache');
      
      log('AppDiscoveryService: Cache cleared successfully');
    } catch (e) {
      log('AppDiscoveryService: Error clearing cache: $e');
    }
  }
  
  /// Refresh app data (clear cache and reload)
  static Future<List<AppInfoEntity>> refreshApps({
    bool includeSystemApps = false,
    bool includeIcons = false,
  }) async {
    await clearCache();
    return getAllInstalledApps(
      includeSystemApps: includeSystemApps,
      includeIcons: includeIcons,
      useCache: false,
    );
  }
  
  /// Filter apps by various criteria
  static List<AppInfoEntity> filterApps(
    List<AppInfoEntity> apps, {
    String? nameQuery,
    String? category,
    bool? isSystemApp,
    bool? isRunning,
    int? minSize,
    int? maxSize,
    DateTime? installedAfter,
    DateTime? updatedAfter,
  }) {
    return apps.where((app) {
      // Name filter
      if (nameQuery != null && nameQuery.isNotEmpty) {
        if (!app.appName.toLowerCase().contains(nameQuery.toLowerCase()) &&
            !app.packageName.toLowerCase().contains(nameQuery.toLowerCase())) {
          return false;
        }
      }
      
      // Category filter
      if (category != null && app.category != category) {
        return false;
      }
      
      // System app filter
      if (isSystemApp != null && app.isSystemApp != isSystemApp) {
        return false;
      }
      
      // Running state filter
      if (isRunning != null && app.isRunning != isRunning) {
        return false;
      }
      
      // Size filters
      if (minSize != null && app.appSize < minSize) {
        return false;
      }
      if (maxSize != null && app.appSize > maxSize) {
        return false;
      }
      
      // Install time filter
      if (installedAfter != null && app.installTime.isBefore(installedAfter)) {
        return false;
      }
      
      // Update time filter
      if (updatedAfter != null && app.lastUpdateTime.isBefore(updatedAfter)) {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  /// Sort apps by various criteria
  static List<AppInfoEntity> sortApps(
    List<AppInfoEntity> apps, {
    AppSortCriteria sortBy = AppSortCriteria.name,
    bool ascending = true,
  }) {
    final sorted = List<AppInfoEntity>.from(apps);
    
    sorted.sort((a, b) {
      int comparison;
      
      switch (sortBy) {
        case AppSortCriteria.name:
          comparison = a.appName.compareTo(b.appName);
          break;
        case AppSortCriteria.size:
          comparison = a.appSize.compareTo(b.appSize);
          break;
        case AppSortCriteria.installTime:
          comparison = a.installTime.compareTo(b.installTime);
          break;
        case AppSortCriteria.updateTime:
          comparison = a.lastUpdateTime.compareTo(b.lastUpdateTime);
          break;
        case AppSortCriteria.cpuUsage:
          comparison = a.cpuUsage.compareTo(b.cpuUsage);
          break;
        case AppSortCriteria.memoryUsage:
          comparison = a.memoryUsage.compareTo(b.memoryUsage);
          break;
        case AppSortCriteria.networkUsage:
          comparison = a.networkUsage.compareTo(b.networkUsage);
          break;
        case AppSortCriteria.category:
          comparison = a.category.compareTo(b.category);
          break;
      }
      
      return ascending ? comparison : -comparison;
    });
    
    return sorted;
  }
  
  /// Check if cache is valid
  static bool _isValidCache(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    
    final age = DateTime.now().difference(timestamp);
    return age < _cacheTimeout;
  }
  
  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheEntries': _appCache.length,
      'timestamps': _cacheTimestamps.length,
      'totalCachedApps': _appCache.values.fold<int>(0, (sum, apps) => sum + apps.length),
    };
  }
  
  /// Convert app icon from base64 to bytes
  static Uint8List? decodeAppIcon(String? iconBase64) {
    if (iconBase64 == null || iconBase64.isEmpty) {
      return null;
    }
    
    try {
      return base64Decode(iconBase64);
    } catch (e) {
      log('AppDiscoveryService: Error decoding app icon: $e');
      return null;
    }
  }
}

/// Enum for app sorting criteria
enum AppSortCriteria {
  name,
  size,
  installTime,
  updateTime,
  cpuUsage,
  memoryUsage,
  networkUsage,
  category,
}

/// Extension methods for app lists
extension AppListExtensions on List<AppInfoEntity> {
  /// Get total size of all apps
  int get totalSize => fold<int>(0, (sum, app) => sum + app.appSize);
  
  /// Get apps by category
  List<AppInfoEntity> byCategory(String category) {
    return where((app) => app.category == category).toList();
  }
  
  /// Get running apps only
  List<AppInfoEntity> get runningApps {
    return where((app) => app.isRunning).toList();
  }
  
  /// Get user apps only (non-system)
  List<AppInfoEntity> get userApps {
    return where((app) => !app.isSystemApp).toList();
  }
  
  /// Get system apps only
  List<AppInfoEntity> get systemApps {
    return where((app) => app.isSystemApp).toList();
  }
  
  /// Get top apps by criteria
  List<AppInfoEntity> topBy(AppSortCriteria criteria, int count) {
    final sorted = AppDiscoveryService.sortApps(this, sortBy: criteria, ascending: false);
    return sorted.take(count).toList();
  }
}