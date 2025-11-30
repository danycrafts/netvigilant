import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netvigilant/core/di/service_locator.dart';
import 'package:netvigilant/data/services/database_service.dart';
import 'package:netvigilant/domain/entities/network_traffic_entity.dart';

// Database Service Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return sl<DatabaseService>();
});

// Today's statistics from database
final todayDataUsageProvider = FutureProvider<double>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getTotalDataUsageToday();
});

final todayActiveAppsProvider = FutureProvider<int>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getActiveAppsCountToday();
});

final todayPeakSpeedProvider = FutureProvider<double>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getPeakSpeedToday(isDownload: true);
});

// App-specific data from database
final appSpecificDataProvider = FutureProvider.family<Map<String, double>, String>((ref, packageName) async {
  final databaseService = ref.watch(databaseServiceProvider);
  final now = DateTime.now();
  final startOfWeek = now.subtract(const Duration(days: 7));
  
  // Get network data for this app
  final networkData = await databaseService.getNetworkTrafficData(
    startDate: startOfWeek,
    endDate: now,
    packageName: packageName,
  );
  
  final totalBytes = networkData.fold<double>(
    0.0,
    (sum, traffic) => sum + traffic.rxBytes + traffic.txBytes,
  );
  
  // Get app usage data
  final appUsageData = await databaseService.getAppUsageData(
    startDate: startOfWeek,
    endDate: now,
    packageName: packageName,
  );
  
  final totalForegroundTime = appUsageData.fold<int>(
    0,
    (sum, app) => sum + app.totalTimeInForeground,
  );
  
  return {
    'totalBytes': totalBytes,
    'foregroundTimeHours': totalForegroundTime / (1000 * 60 * 60), // Convert ms to hours
    'avgBatteryUsage': appUsageData.isNotEmpty 
        ? appUsageData.map((app) => app.batteryUsage).reduce((a, b) => a + b) / appUsageData.length
        : 0.0,
  };
});

// New: App-specific daily network usage for charts
final appDailyNetworkUsageProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, packageName) async {
  final databaseService = ref.watch(databaseServiceProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day); // Today's start
  final sevenDaysAgo = startOfDay.subtract(const Duration(days: 7));

  final networkData = await databaseService.getNetworkTrafficData(
    startDate: sevenDaysAgo,
    endDate: now,
    packageName: packageName,
  );

  // Group data by day
  final Map<int, double> dailyUsage = {}; // Key: day (milliseconds since epoch), Value: total bytes
  for (final traffic in networkData) {
    final dayKey = DateTime(traffic.timestamp.year, traffic.timestamp.month, traffic.timestamp.day).millisecondsSinceEpoch;
    dailyUsage.update(dayKey, (value) => value + (traffic.rxBytes + traffic.txBytes).toDouble(), ifAbsent: () => (traffic.rxBytes + traffic.txBytes).toDouble());
  }

  // Ensure data for all last 7 days
  final List<Map<String, dynamic>> result = [];
  for (int i = 0; i < 7; i++) {
    final day = sevenDaysAgo.add(Duration(days: i));
    final dayKey = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    result.add({
      'timestamp': dayKey,
      'totalBytes': (dailyUsage[dayKey] ?? 0).toDouble(),
    });
  }
  return result;
});

// New: App-specific network type breakdown (WiFi vs. Mobile)
final appNetworkTypeBreakdownProvider = FutureProvider.family<Map<String, double>, String>((ref, packageName) async {
  final databaseService = ref.watch(databaseServiceProvider);
  final now = DateTime.now();
  final startOfWeek = now.subtract(const Duration(days: 7)); // Look at last 7 days for breakdown

  final networkData = await databaseService.getNetworkTrafficData(
    startDate: startOfWeek,
    endDate: now,
    packageName: packageName,
  );

  double wifiBytes = 0.0;
  double mobileBytes = 0.0;

  for (final traffic in networkData) {
    if (traffic.networkType == NetworkType.wifi) {
      wifiBytes += (traffic.rxBytes + traffic.txBytes);
    } else if (traffic.networkType == NetworkType.mobile) {
      mobileBytes += (traffic.rxBytes + traffic.txBytes);
    }
  }

  return {
    'wifiBytes': wifiBytes,
    'mobileBytes': mobileBytes,
  };
});

// New: App-specific background usage
final appBackgroundUsageProvider = FutureProvider.family<double, String>((ref, packageName) async {
  final databaseService = ref.watch(databaseServiceProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1); // Get background usage for current month

  final networkData = await databaseService.getNetworkTrafficData(
    startDate: startOfMonth,
    endDate: now,
    packageName: packageName,
  );

  double backgroundBytes = 0.0;
  for (final traffic in networkData) {
    if (traffic.isBackgroundTraffic == true) {
      backgroundBytes += (traffic.rxBytes + traffic.txBytes);
    }
  }
  return backgroundBytes;
});


// Weekly data usage by app
final weeklyDataUsageByAppProvider = FutureProvider<Map<String, double>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  final now = DateTime.now();
  final startOfWeek = now.subtract(const Duration(days: 7));
  
  return await databaseService.getTotalDataUsageByApp(
    startDate: startOfWeek,
    endDate: now,
  );
});

// Daily summaries for chart data
final dailySummariesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  final now = DateTime.now();
  final sevenDaysAgo = now.subtract(const Duration(days: 7));
  
  final summaries = await databaseService.getDailySummaryRange(
    startDate: sevenDaysAgo,
    endDate: now,
  );
  
  return summaries.map((summary) => {
    'date': summary.date,
    'totalDataUsage': summary.totalDataUsage,
    'activeAppsCount': summary.activeAppsCount,
    'peakDownloadSpeed': summary.peakDownloadSpeed,
    'peakUploadSpeed': summary.peakUploadSpeed,
  }).toList();
});

// Helper function to format bytes to human readable
String formatBytes(double bytes) {
  if (bytes < 1024) {
    return '${bytes.toStringAsFixed(0)} B';
  } else if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  } else if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  } else {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

// Helper function to format time
String formatTime(double hours) {
  if (hours < 1) {
    final minutes = (hours * 60).round();
    return '${minutes}m';
  } else {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m}m';
  }
}