import 'dart:io';
import 'package:flutter/services.dart';
import 'permission_manager.dart';

class AppUsageInfo {
  final String packageName;
  final String appName;
  final Duration totalTimeInForeground;
  final int launchCount;
  final DateTime lastTimeUsed;

  AppUsageInfo({
    required this.packageName,
    required this.appName,
    required this.totalTimeInForeground,
    required this.launchCount,
    required this.lastTimeUsed,
  });
}

class AppUsageService {
  static const platform = MethodChannel('app_usage_channel');

  static Future<bool> requestUsagePermission() async {
    if (Platform.isAndroid) {
      try {
        final result = await platform.invokeMethod('requestUsagePermission');
        return result ?? false;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  static Future<bool> hasUsagePermission() async {
    if (Platform.isAndroid) {
      try {
        final result = await platform.invokeMethod('hasUsagePermission');
        final hasPermission = result ?? false;
        
        // Update stored state if permission was granted
        if (hasPermission && !(await PermissionManager.hasStoredUsagePermission())) {
          await PermissionManager.markUsagePermissionGranted();
        }
        
        return hasPermission;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  static Future<List<AppUsageInfo>> getAppUsageStats() async {
    try {
      if (!Platform.isAndroid) {
        return [];
      }

      final hasPermission = await hasUsagePermission();
      if (!hasPermission) {
        return [];
      }

      final result = await platform.invokeMethod('getUsageStats');
      final List<dynamic> usageData = result ?? [];
      
      return usageData.map((data) => AppUsageInfo(
        packageName: data['packageName'] ?? '',
        appName: data['appName'] ?? '',
        totalTimeInForeground: Duration(milliseconds: data['totalTimeInForeground'] ?? 0),
        launchCount: data['launchCount'] ?? 0,
        lastTimeUsed: DateTime.fromMillisecondsSinceEpoch(data['lastTimeUsed'] ?? 0),
      )).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<AppUsageInfo?> getAppUsageInfo(String packageName) async {
    try {
      if (!Platform.isAndroid) {
        return null;
      }

      final hasPermission = await hasUsagePermission();
      if (!hasPermission) {
        return null;
      }

      final result = await platform.invokeMethod('getAppUsageInfo', packageName);
      if (result == null) return null;

      return AppUsageInfo(
        packageName: result['packageName'] ?? '',
        appName: result['appName'] ?? '',
        totalTimeInForeground: Duration(milliseconds: result['totalTimeInForeground'] ?? 0),
        launchCount: result['launchCount'] ?? 0,
        lastTimeUsed: DateTime.fromMillisecondsSinceEpoch(result['lastTimeUsed'] ?? 0),
      );
    } catch (e) {
      return null;
    }
  }
}