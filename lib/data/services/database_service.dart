import 'dart:async';
import 'package:netvigilant/data/database/database_helper.dart';
import 'package:netvigilant/data/database/database_entities.dart';
import 'package:netvigilant/domain/entities/app_usage_entity.dart';
import 'package:netvigilant/domain/entities/network_traffic_entity.dart';
import 'package:netvigilant/domain/entities/real_time_metrics_entity.dart';
import 'package:netvigilant/core/interfaces/storage.dart';

class DatabaseService implements IDatabaseStorage {
  final DatabaseHelper _databaseHelper;

  DatabaseService(this._databaseHelper);

  // App Usage Operations
  Future<void> saveAppUsageData(List<AppUsageEntity> appUsageList, DateTime recordDate) async {
    for (final appUsage in appUsageList) {
      final record = AppUsageRecord(
        packageName: appUsage.packageName,
        appName: appUsage.appName,
        networkUsage: appUsage.networkUsage,
        totalTimeInForeground: appUsage.totalTimeInForeground,
        cpuUsage: appUsage.cpuUsage,
        memoryUsage: appUsage.memoryUsage,
        batteryUsage: appUsage.batteryUsage,
        launchCount: appUsage.launchCount,
        lastTimeUsed: appUsage.lastTimeUsed,
        recordDate: recordDate,
      );
      await _databaseHelper.insertAppUsageRecord(record);
    }
  }

  Future<List<AppUsageEntity>> getAppUsageData({
    DateTime? startDate,
    DateTime? endDate,
    String? packageName,
  }) async {
    final records = await _databaseHelper.getAppUsageRecords(
      startDate: startDate,
      endDate: endDate,
      packageName: packageName,
    );

    return records.map((record) => AppUsageEntity(
      packageName: record.packageName,
      appName: record.appName,
      networkUsage: record.networkUsage,
      totalTimeInForeground: record.totalTimeInForeground,
      cpuUsage: record.cpuUsage,
      memoryUsage: record.memoryUsage,
      batteryUsage: record.batteryUsage,
      launchCount: record.launchCount,
      lastTimeUsed: record.lastTimeUsed,
    )).toList();
  }

  Future<Map<String, AppUsageEntity>> getLatestAppUsageMap() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    
    final records = await _databaseHelper.getAppUsageRecords(
      startDate: startOfToday,
      endDate: now,
    );

    final Map<String, AppUsageEntity> result = {};
    for (final record in records) {
      result[record.packageName] = AppUsageEntity(
        packageName: record.packageName,
        appName: record.appName,
        networkUsage: record.networkUsage,
        totalTimeInForeground: record.totalTimeInForeground,
        cpuUsage: record.cpuUsage,
        memoryUsage: record.memoryUsage,
        batteryUsage: record.batteryUsage,
        launchCount: record.launchCount,
        lastTimeUsed: record.lastTimeUsed,
      );
    }
    return result;
  }

  // Network Traffic Operations
  Future<void> saveNetworkTrafficData(List<NetworkTrafficEntity> trafficList) async {
    for (final traffic in trafficList) {
      final record = NetworkTrafficRecord(
        packageName: traffic.packageName,
        appName: traffic.appName,
        uid: traffic.uid, // Use traffic.uid directly
        rxBytes: traffic.rxBytes,
        txBytes: traffic.txBytes,
        timestamp: traffic.timestamp,
        networkType: traffic.networkType.toString().split('.').last,
        isBackgroundTraffic: traffic.isBackgroundTraffic,
      );
      await _databaseHelper.insertNetworkTrafficRecord(record);
    }
  }

  Future<List<NetworkTrafficEntity>> getNetworkTrafficData({
    DateTime? startDate,
    DateTime? endDate,
    String? packageName,
  }) async {
    final records = await _databaseHelper.getNetworkTrafficRecords(
      startDate: startDate,
      endDate: endDate,
      packageName: packageName,
    );

    return records.map((record) => NetworkTrafficEntity(
      packageName: record.packageName,
      appName: record.appName,
      uid: record.uid,
      rxBytes: record.rxBytes,
      txBytes: record.txBytes,
      timestamp: record.timestamp,
      networkType: NetworkType.values.firstWhere(
        (type) => type.toString().split('.').last == record.networkType,
        orElse: () => NetworkType.wifi,
      ),
      isBackgroundTraffic: record.isBackgroundTraffic,
    )).toList();
  }

  Future<Map<String, NetworkTrafficEntity>> getAggregatedNetworkUsageByUid({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final rawAggregatedData = await _databaseHelper.getAggregatedNetworkUsageByUidRaw(
      startDate: startDate,
      endDate: endDate,
    );

    final Map<String, NetworkTrafficEntity> aggregated = {};
    
    for (final map in rawAggregatedData) {
      final uid = map['uid'].toString();
      aggregated[uid] = NetworkTrafficEntity(
        packageName: map['packageName'],
        appName: map['appName'],
        uid: map['uid'],
        rxBytes: map['totalRxBytes'],
        txBytes: map['totalTxBytes'],
        timestamp: endDate ?? DateTime.now(), // Use endDate as aggregation timestamp
        networkType: NetworkType.unknown, // Aggregated, so specific network type might not apply
        isBackgroundTraffic: false, // Aggregated, so background distinction might not apply
      );
    }
    return aggregated;
  }

  // Real-time Metrics Operations
  Future<void> saveRealTimeMetrics(RealTimeMetricsEntity metrics) async {
    final record = RealTimeMetricsRecord(
      uplinkSpeed: metrics.uplinkSpeed,
      downlinkSpeed: metrics.downlinkSpeed,
      timestamp: DateTime.now(),
    );
    await _databaseHelper.insertRealTimeMetricsRecord(record);
  }

  Future<List<RealTimeMetricsEntity>> getRealTimeMetricsHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final records = await _databaseHelper.getRealTimeMetricsRecords(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );

    return records.map((record) => RealTimeMetricsEntity(
      uplinkSpeed: record.uplinkSpeed,
      downlinkSpeed: record.downlinkSpeed,
    )).toList();
  }

  // Daily Summary Operations
  Future<void> generateAndSaveDailySummary(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Calculate total data usage for the day
    final networkData = await getNetworkTrafficData(
      startDate: dayStart,
      endDate: dayEnd,
    );
    
    final totalDataUsage = networkData.fold<double>(
      0.0,
      (sum, traffic) => sum + traffic.rxBytes + traffic.txBytes,
    );

    // Calculate active apps count
    final activeApps = networkData.map((traffic) => traffic.packageName).toSet();
    final activeAppsCount = activeApps.length;

    // Get peak speeds
    final peakDownloadSpeed = await _databaseHelper.getPeakSpeedInPeriod(
      startDate: dayStart,
      endDate: dayEnd,
      isDownload: true,
    );

    final peakUploadSpeed = await _databaseHelper.getPeakSpeedInPeriod(
      startDate: dayStart,
      endDate: dayEnd,
      isDownload: false,
    );

    // Calculate total foreground time
    final appUsageData = await getAppUsageData(
      startDate: dayStart,
      endDate: dayEnd,
    );
    
    final totalForegroundTime = appUsageData.fold<int>(
      0,
      (sum, app) => sum + app.totalTimeInForeground,
    );

    final summary = DailySummaryRecord(
      date: dayStart,
      totalDataUsage: totalDataUsage,
      activeAppsCount: activeAppsCount,
      peakDownloadSpeed: peakDownloadSpeed,
      peakUploadSpeed: peakUploadSpeed,
      totalForegroundTime: totalForegroundTime,
    );

    await _databaseHelper.insertOrUpdateDailySummary(summary);
  }

  Future<DailySummaryRecord?> getDailySummary(DateTime date) async {
    return await _databaseHelper.getDailySummaryForDate(date);
  }

  Future<List<DailySummaryRecord>> getDailySummaryRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _databaseHelper.getDailySummaryRecords(
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Utility Methods
  Future<Map<String, double>> getTotalDataUsageByApp({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _databaseHelper.getTotalDataUsageByApp(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<double> getTotalDataUsageToday() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final summary = await getDailySummary(startOfDay);
    return summary?.totalDataUsage ?? 0.0;
  }

  Future<int> getActiveAppsCountToday() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final summary = await getDailySummary(startOfDay);
    return summary?.activeAppsCount ?? 0;
  }

  Future<double> getPeakSpeedToday({bool isDownload = true}) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final summary = await getDailySummary(startOfDay);
    return isDownload 
        ? (summary?.peakDownloadSpeed ?? 0.0)
        : (summary?.peakUploadSpeed ?? 0.0);
  }

  // Data Management
  Future<void> cleanupOldData(int daysToKeep) async {
    await _databaseHelper.deleteOldRecords('app_usage_records', daysToKeep);
    await _databaseHelper.deleteOldRecords('network_traffic_records', daysToKeep);
    await _databaseHelper.deleteOldRecords('realtime_metrics_records', daysToKeep);
    await _databaseHelper.deleteOldRecords('daily_summary_records', daysToKeep);
  }

  Future<void> clearAllData() async {
    await _databaseHelper.clearAllData();
  }

  @override
  Future<void> close() async {
    await _databaseHelper.close();
  }

  // Background service support methods
  Future<List<RealTimeMetricsRecord>> getRealTimeMetricsInRange(
    DateTime startTime,
    DateTime endTime,
  ) async {
    return await _databaseHelper.getRealTimeMetricsRecords(
      startDate: startTime,
      endDate: endTime,
    );
  }

  Future<int> getActiveAppCount(DateTime startTime, DateTime endTime) async {
    final networkData = await getNetworkTrafficData(
      startDate: startTime,
      endDate: endTime,
    );
    return networkData.map((traffic) => traffic.packageName).toSet().length;
  }

  Future<void> deleteRealTimeMetricsOlderThan(DateTime cutoffDate) async {
    await _databaseHelper.deleteRealTimeMetricsOlderThan(cutoffDate);
  }

  Future<List<AppUsageRecord>> getAppUsageRecordsInRange(
    DateTime startTime,
    DateTime endTime,
  ) async {
    return await _databaseHelper.getAppUsageRecords(
      startDate: startTime,
      endDate: endTime,
    );
  }

  Future<void> insertDailySummary({
    required DateTime date,
    required double totalDataUsage,
    required int totalActiveTime,
    required List<String> topDataApps,
    required List<String> topTimeApps,
    required int uniqueAppsUsed,
  }) async {
    final summary = DailySummaryRecord(
      date: date,
      totalDataUsage: totalDataUsage,
      activeAppsCount: uniqueAppsUsed,
      peakDownloadSpeed: 0.0, // Will be calculated separately if needed
      peakUploadSpeed: 0.0,   // Will be calculated separately if needed
      totalForegroundTime: totalActiveTime,
    );
    await _databaseHelper.insertOrUpdateDailySummary(summary);
  }

  Future<int> deleteAppUsageRecordsOlderThan(DateTime cutoffDate) async {
    return await _databaseHelper.deleteAppUsageRecordsOlderThan(cutoffDate);
  }

  Future<int> deleteNetworkTrafficOlderThan(DateTime cutoffDate) async {
    return await _databaseHelper.deleteNetworkTrafficOlderThan(cutoffDate);
  }

  Future<int> deleteDailySummariesOlderThan(DateTime cutoffDate) async {
    return await _databaseHelper.deleteDailySummariesOlderThan(cutoffDate);
  }

  Future<List<Map<String, dynamic>>> getAllNetworkTrafficData() async {
    return await _databaseHelper.getAllNetworkTrafficRaw();
  }

  // Interface implementation methods
  @override
  Future<void> initialize() async {
    // DatabaseHelper is initialized in its constructor, so no additional init needed
  }

  @override
  Future<bool> isInitialized() async {
    return true; // DatabaseHelper is always initialized after construction
  }

  @override
  Future<void> clearAllTables() async {
    await _databaseHelper.clearAllData();
  }
}