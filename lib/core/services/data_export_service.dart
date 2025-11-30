import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:netvigilant/core/utils/logger.dart';
import 'package:netvigilant/data/services/database_service.dart';
import 'package:netvigilant/core/services/notification_service.dart';

class DataExportService {
  final DatabaseService _databaseService;
  final NotificationService _notificationService;

  DataExportService(this._databaseService, this._notificationService);

  Future<void> exportNetworkTrafficToCsv(
      {required DateTime startDate, required DateTime endDate}) async {
    try {
      _notificationService.showProgressNotification(
        id: 2001,
        title: 'Exporting Network Data',
        body: 'Preparing CSV export...',
        progress: 0,
        maxProgress: 100,
      );

      final networkTraffic =
          await _databaseService.getNetworkTrafficData(startDate: startDate, endDate: endDate);

      if (networkTraffic.isEmpty) {
        _notificationService.showBasicNotification(
            id: 2002,
            title: 'Export Failed',
            body: 'No network traffic data found for the selected period.');
        return;
      }

      final csvList = [
        <String>[
          'Timestamp',
          'Package Name',
          'App Name',
          'UID',
          'Rx Bytes',
          'Tx Bytes',
          'Network Type',
          'Is Background Traffic'
        ],
        ...networkTraffic.map((e) => [
              e.timestamp.toIso8601String(),
              e.packageName,
              e.appName,
              e.uid,
              e.rxBytes,
              e.txBytes,
              e.networkType,
              e.isBackgroundTraffic ? 'Yes' : 'No'
            ])
      ];

      final csvString = const ListToCsvConverter().convert(csvList);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/network_traffic_${_formatDate(startDate)}_${_formatDate(endDate)}.csv');
      await file.writeAsString(csvString);

      _notificationService.updateProgressNotification(
        id: 2001,
        title: 'Exporting Network Data',
        body: 'CSV export complete. Sharing file...',
        progress: 100,
        maxProgress: 100,
      );

      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'Network Traffic Data Export');
      _notificationService.cancelNotification(2001); // Cancel progress notification

      log('Network traffic exported to CSV and shared.');
    } catch (e) {
      log('Error exporting network traffic to CSV: $e');
      _notificationService.showBasicNotification(
          id: 2002, title: 'Export Error', body: 'Failed to export network traffic data.');
    }
  }

  Future<void> exportNetworkTrafficToJson(
      {required DateTime startDate, required DateTime endDate}) async {
    try {
      _notificationService.showProgressNotification(
        id: 2003,
        title: 'Exporting Network Data',
        body: 'Preparing JSON export...',
        progress: 0,
        maxProgress: 100,
      );

      final networkTraffic =
          await _databaseService.getNetworkTrafficData(startDate: startDate, endDate: endDate);

      if (networkTraffic.isEmpty) {
        _notificationService.showBasicNotification(
            id: 2004,
            title: 'Export Failed',
            body: 'No network traffic data found for the selected period.');
        return;
      }

      final jsonList = networkTraffic.map((e) => e.toMap()).toList();
      final jsonString = jsonEncode(jsonList);

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/network_traffic_${_formatDate(startDate)}_${_formatDate(endDate)}.json');
      await file.writeAsString(jsonString);

      _notificationService.updateProgressNotification(
        id: 2003,
        title: 'Exporting Network Data',
        body: 'JSON export complete. Sharing file...',
        progress: 100,
        maxProgress: 100,
      );

      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'Network Traffic Data Export');
      _notificationService.cancelNotification(2003); // Cancel progress notification

      log('Network traffic exported to JSON and shared.');
    } catch (e) {
      log('Error exporting network traffic to JSON: $e');
      _notificationService.showBasicNotification(
          id: 2004, title: 'Export Error', body: 'Failed to export network traffic data.');
    }
  }

  Future<void> exportAppUsageToCsv(
      {required DateTime startDate, required DateTime endDate}) async {
    try {
      _notificationService.showProgressNotification(
        id: 2005,
        title: 'Exporting App Usage',
        body: 'Preparing CSV export...',
        progress: 0,
        maxProgress: 100,
      );

      final appUsage = await _databaseService.getAppUsageData(startDate: startDate, endDate: endDate);

      if (appUsage.isEmpty) {
        _notificationService.showBasicNotification(
            id: 2006, title: 'Export Failed', body: 'No app usage data found for the selected period.');
        return;
      }

      final csvList = [
        <String>[
          'Timestamp',
          'Package Name',
          'App Name',
          'Network Usage',
          'Total Time In Foreground',
          'CPU Usage',
          'Memory Usage',
          'Battery Usage',
          'Launch Count',
          'Last Time Used'
        ],
        ...appUsage.map((e) => [
              e.lastTimeUsed.toIso8601String(), // Using lastTimeUsed as the main timestamp for app usage
              e.packageName,
              e.appName,
              e.networkUsage,
              e.totalTimeInForeground,
              e.cpuUsage,
              e.memoryUsage,
              e.batteryUsage,
              e.launchCount,
              e.lastTimeUsed.toIso8601String()
            ])
      ];

      final csvString = const ListToCsvConverter().convert(csvList);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/app_usage_${_formatDate(startDate)}_${_formatDate(endDate)}.csv');
      await file.writeAsString(csvString);

      _notificationService.updateProgressNotification(
        id: 2005,
        title: 'Exporting App Usage',
        body: 'CSV export complete. Sharing file...',
        progress: 100,
        maxProgress: 100,
      );

      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'App Usage Data Export');
      _notificationService.cancelNotification(2005);

      log('App usage exported to CSV and shared.');
    } catch (e) {
      log('Error exporting app usage to CSV: $e');
      _notificationService.showBasicNotification(
          id: 2006, title: 'Export Error', body: 'Failed to export app usage data.');
    }
  }

  Future<void> exportAppUsageToJson(
      {required DateTime startDate, required DateTime endDate}) async {
    try {
      _notificationService.showProgressNotification(
        id: 2007,
        title: 'Exporting App Usage',
        body: 'Preparing JSON export...',
        progress: 0,
        maxProgress: 100,
      );

      final appUsage = await _databaseService.getAppUsageData(startDate: startDate, endDate: endDate);

      if (appUsage.isEmpty) {
        _notificationService.showBasicNotification(
            id: 2008, title: 'Export Failed', body: 'No app usage data found for the selected period.');
        return;
      }

      final jsonList = appUsage.map((e) => e.toMap()).toList();
      final jsonString = jsonEncode(jsonList);

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/app_usage_${_formatDate(startDate)}_${_formatDate(endDate)}.json');
      await file.writeAsString(jsonString);

      _notificationService.updateProgressNotification(
        id: 2007,
        title: 'Exporting App Usage',
        body: 'JSON export complete. Sharing file...',
        progress: 100,
        maxProgress: 100,
      );

      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'App Usage Data Export');
      _notificationService.cancelNotification(2007);

      log('App usage exported to JSON and shared.');
    } catch (e) {
      log('Error exporting app usage to JSON: $e');
      _notificationService.showBasicNotification(
          id: 2008, title: 'Export Error', body: 'Failed to export app usage data.');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}