import 'package:netvigilant/core/services/local_storage_service.dart';
import 'package:workmanager/workmanager.dart' as wm;

abstract class BackgroundMonitoringDataSource {
  Future<void> startBackgroundTask();
  Future<void> stopBackgroundTask();
  Future<bool> isBackgroundTaskActive();
}

class BackgroundMonitoringDataSourceImpl implements BackgroundMonitoringDataSource {
  final LocalStorageService _localStorageService;

  BackgroundMonitoringDataSourceImpl({
    required LocalStorageService localStorageService,
  }) : _localStorageService = localStorageService;

  @override
  Future<void> startBackgroundTask() async {
    await wm.Workmanager().registerPeriodicTask(
      "networkUsageFetch",
      "fetchNetworkUsage",
      initialDelay: const Duration(minutes: 1),
      frequency: const Duration(minutes: 15),
      constraints: wm.Constraints(
        networkType: wm.NetworkType.connected,
      ),
    );
    await _localStorageService.saveBackgroundMonitoringStatus(true);
  }

  @override
  Future<void> stopBackgroundTask() async {
    await wm.Workmanager().cancelByUniqueName("networkUsageFetch");
    await _localStorageService.saveBackgroundMonitoringStatus(false);
  }

  @override
  Future<bool> isBackgroundTaskActive() async {
    return await _localStorageService.getBackgroundMonitoringStatus();
  }
}