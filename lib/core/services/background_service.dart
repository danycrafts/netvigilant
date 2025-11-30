import 'package:workmanager/workmanager.dart';
import 'package:netvigilant/core/di/service_locator.dart';
import 'package:netvigilant/core/services/local_storage_service.dart';
import 'package:netvigilant/data/services/database_service.dart';
import 'package:netvigilant/core/utils/logger.dart';
import 'package:netvigilant/core/services/notification_service.dart'; // Import NotificationService

class BackgroundService {
  static const String _dataArchivalTaskName = 'dataArchivalTask';
  static const String _dailySummaryTaskName = 'dailySummaryTask';
  static const String _cleanupTaskName = 'cleanupTask';

  /// Initialize WorkManager and register background tasks
  static Future<void> initialize() async {
    await Workmanager().initialize(
      _callbackDispatcher,
    );
    
    // Register periodic tasks
    await _registerDataArchivalTask();
    await _registerDailySummaryTask();
    await _registerCleanupTask();
    
    log('BackgroundService: All background tasks registered');
  }

  /// Register hourly data archival task
  static Future<void> _registerDataArchivalTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        'netVigilantDataArchival',
        _dataArchivalTaskName,
        frequency: const Duration(hours: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false, // Allow even on low battery
          requiresCharging: false,
        ),
        inputData: <String, dynamic>{
          'taskType': 'dataArchival',
          'description': 'Aggregate and archive real-time data',
        },
      );
      log('BackgroundService: Data archival task registered');
    } catch (e) {
      log('BackgroundService: Error registering data archival task: $e');
    }
  }

  /// Register daily summary generation task
  static Future<void> _registerDailySummaryTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        'netVigilantDailySummary',
        _dailySummaryTaskName,
        frequency: const Duration(hours: 24),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
          requiresCharging: false,
        ),
        inputData: <String, dynamic>{
          'taskType': 'dailySummary',
          'description': 'Generate daily usage summaries',
        },
      );
      log('BackgroundService: Daily summary task registered');
    } catch (e) {
      log('BackgroundService: Error registering daily summary task: $e');
    }
  }

  /// Register cleanup task for old data
  static Future<void> _registerCleanupTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        'netVigilantCleanup',
        _cleanupTaskName,
        frequency: const Duration(days: 7),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
          requiresCharging: false,
        ),
        inputData: <String, dynamic>{
          'taskType': 'cleanup',
          'description': 'Clean up old archived data',
        },
      );
      log('BackgroundService: Cleanup task registered');
    } catch (e) {
      log('BackgroundService: Error registering cleanup task: $e');
    }
  }

  /// Cancel all background tasks
  static Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      log('BackgroundService: All background tasks cancelled');
    } catch (e) {
      log('BackgroundService: Error cancelling tasks: $e');
    }
  }

  /// Cancel a specific task
  static Future<void> cancelTask(String taskId) async {
    try {
      await Workmanager().cancelByUniqueName(taskId);
      log('BackgroundService: Task $taskId cancelled');
    } catch (e) {
      log('BackgroundService: Error cancelling task $taskId: $e');
    }
  }
}

/// Top-level callback function for background tasks
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    log("BackgroundService: Executing task: $task");
    log("BackgroundService: Task input data: $inputData");
    
    try {
      // Initialize minimal dependencies for background execution
      await _initializeBackgroundDependencies();
      
      switch (task) {
        case BackgroundService._dataArchivalTaskName:
          return await _executeDataArchival(inputData);
          
        case BackgroundService._dailySummaryTaskName:
          return await _executeDailySummary(inputData);
          
        case BackgroundService._cleanupTaskName:
          return await _executeCleanup(inputData);
          
        default:
          log('BackgroundService: Unknown task: $task');
          return false;
      }
    } catch (e, stackTrace) {
      log('BackgroundService: Error executing task $task: $e');
      log('BackgroundService: Stack trace: $stackTrace');
      return false;
    }
  });
}

/// Initialize minimal dependencies needed for background tasks
Future<void> _initializeBackgroundDependencies() async {
  try {
    await setupServiceLocator();
    log('BackgroundService: Dependencies initialized');
  } catch (e) {
    log('BackgroundService: Error initializing dependencies: $e');
    rethrow;
  }
}

/// Execute data archival task
Future<bool> _executeDataArchival(Map<String, dynamic>? inputData) async {
  try {
    log('BackgroundService: Starting data archival task');
    
    final databaseService = sl<DatabaseService>();
    final localStorageService = sl<LocalStorageService>();
    
    // Get current time for archival
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    
    // Archive real-time metrics from the last hour
    final realtimeMetrics = await databaseService.getRealTimeMetricsInRange(
      oneHourAgo,
      now,
    );
    
    log('BackgroundService: Found ${realtimeMetrics.length} real-time metrics to archive');
    
    // Aggregate and create summary data if we have metrics
    if (realtimeMetrics.isNotEmpty) {
      // Calculate aggregated metrics from speed data
      double avgDownloadSpeed = 0;
      double avgUploadSpeed = 0;
      double maxDownloadSpeed = 0;
      double maxUploadSpeed = 0;
      
      // Estimate bytes transferred based on speed over time (1 hour)
      const secondsInHour = 3600;
      double totalDownloadBytes = 0;
      double totalUploadBytes = 0;
      
      for (final metric in realtimeMetrics) {
        avgDownloadSpeed += metric.downlinkSpeed;
        avgUploadSpeed += metric.uplinkSpeed;
        
        if (metric.downlinkSpeed > maxDownloadSpeed) {
          maxDownloadSpeed = metric.downlinkSpeed;
        }
        if (metric.uplinkSpeed > maxUploadSpeed) {
          maxUploadSpeed = metric.uplinkSpeed;
        }
        
        // Estimate bytes based on speed (assuming average sampling interval)
        final samplingIntervalSec = secondsInHour / realtimeMetrics.length;
        totalDownloadBytes += metric.downlinkSpeed * samplingIntervalSec;
        totalUploadBytes += metric.uplinkSpeed * samplingIntervalSec;
      }
      
      // Calculate averages
      avgDownloadSpeed = avgDownloadSpeed / realtimeMetrics.length;
      avgUploadSpeed = avgUploadSpeed / realtimeMetrics.length;
      
      // Store aggregated hourly summary
      await localStorageService.storeHourlySummary(
        timestamp: oneHourAgo,
        totalDownloadBytes: totalDownloadBytes,
        totalUploadBytes: totalUploadBytes,
        avgDownloadSpeed: avgDownloadSpeed,
        avgUploadSpeed: avgUploadSpeed,
        maxDownloadSpeed: maxDownloadSpeed,
        maxUploadSpeed: maxUploadSpeed,
        totalAppsUsed: await databaseService.getActiveAppCount(oneHourAgo, now),
      );
      
      log('BackgroundService: Hourly summary created for ${oneHourAgo.hour}:00');
      
      // Clean up old real-time data (older than 24 hours)
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
      await databaseService.deleteRealTimeMetricsOlderThan(twentyFourHoursAgo);
      
      log('BackgroundService: Cleaned up real-time data older than 24 hours');
    }
    
    log('BackgroundService: Data archival task completed successfully');
    return true;
    
  } catch (e, stackTrace) {
    log('BackgroundService: Error in data archival: $e');
    log('BackgroundService: Stack trace: $stackTrace');
    return false;
  }
}

/// Execute daily summary generation task
Future<bool> _executeDailySummary(Map<String, dynamic>? inputData) async {
  try {
    log('BackgroundService: Starting daily summary task');
    
    final databaseService = sl<DatabaseService>();
    final localStorageService = sl<LocalStorageService>(); // Get NotificationService
    final notificationService = sl<NotificationService>(); // Get NotificationService
    
    // Get yesterday's data
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final startOfYesterday = yesterday;
    final endOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
    
    // Generate daily summary from app usage records
    final appUsageRecords = await databaseService.getAppUsageRecordsInRange(
      startOfYesterday,
      endOfYesterday,
    );
    
    log('BackgroundService: Found ${appUsageRecords.length} app usage records for daily summary');
    
    if (appUsageRecords.isNotEmpty) {
      // Calculate daily aggregates
      double totalDataUsage = 0;
      int totalActiveTime = 0;
      Map<String, double> appDataUsage = {};
      Map<String, int> appActiveTime = {};
      
      for (final record in appUsageRecords) {
        totalDataUsage += record.networkUsage;
        totalActiveTime += record.totalTimeInForeground;
        
        appDataUsage[record.packageName] = 
            (appDataUsage[record.packageName] ?? 0) + record.networkUsage;
        appActiveTime[record.packageName] = 
            (appActiveTime[record.packageName] ?? 0) + record.totalTimeInForeground;
      }
      
      // Get top 5 data consuming apps
      final topDataApps = appDataUsage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5);
      
      // Get top 5 most used apps by time
      final topTimeApps = appActiveTime.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5);
      
      // Create daily summary record
      await databaseService.insertDailySummary(
        date: startOfYesterday,
        totalDataUsage: totalDataUsage,
        totalActiveTime: totalActiveTime,
        topDataApps: topDataApps.map((e) => '${e.key}:${e.value}').toList(),
        topTimeApps: topTimeApps.map((e) => '${e.key}:${e.value}').toList(),
        uniqueAppsUsed: appDataUsage.length,
      );
      
      log('BackgroundService: Daily summary created for ${startOfYesterday.toIso8601String().split('T')[0]}');

      // --- Data Usage Alert Check ---
      final alertsEnabled = await localStorageService.getAlertsEnabled();
      if (alertsEnabled) {
        final alertThresholdBytes = await localStorageService.getAlertThreshold() * 1024 * 1024 * 1024; // Convert GB to Bytes
        if (totalDataUsage > alertThresholdBytes) {
          notificationService.showBasicNotification(
            id: 1001, // Unique ID for daily usage alert
            title: 'Daily Data Usage Alert!',
            body: 'You have used ${formatBytes(totalDataUsage)} today, exceeding your threshold of ${formatBytes(alertThresholdBytes)}.',
            payload: 'daily_usage_alert',
          );
          log('BackgroundService: Daily data usage alert triggered: ${formatBytes(totalDataUsage)}');
        }
      }
      // --- End Data Usage Alert Check ---
    }
    
    log('BackgroundService: Daily summary task completed successfully');
    return true;
    
  } catch (e, stackTrace) {
    log('BackgroundService: Error in daily summary: $e');
    log('BackgroundService: Stack trace: $stackTrace');
    return false;
  }
}

/// Execute cleanup task for old data
Future<bool> _executeCleanup(Map<String, dynamic>? inputData) async {
  try {
    log('BackgroundService: Starting cleanup task');
    
    final databaseService = sl<DatabaseService>();
    final localStorageService = sl<LocalStorageService>();
    
    // Get retention period from settings
    final retentionDays = await localStorageService.getDataRetentionPeriod();
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    
    log('BackgroundService: Cleaning data older than ${cutoffDate.toIso8601String()}');
    
    // Clean up old data based on retention policy
    final deletedAppUsage = await databaseService.deleteAppUsageRecordsOlderThan(cutoffDate);
    final deletedNetworkTraffic = await databaseService.deleteNetworkTrafficOlderThan(cutoffDate);
    final deletedDailySummaries = await databaseService.deleteDailySummariesOlderThan(cutoffDate);
    
    log('BackgroundService: Cleanup completed - '
        'App usage: $deletedAppUsage, '
        'Network traffic: $deletedNetworkTraffic, '
        'Daily summaries: $deletedDailySummaries');
    
    return true;
    
  } catch (e, stackTrace) {
    log('BackgroundService: Error in cleanup: $e');
    log('BackgroundService: Stack trace: $stackTrace');
    return false;
  }
}

// Helper function to format bytes to human readable - needs to be accessible in background
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