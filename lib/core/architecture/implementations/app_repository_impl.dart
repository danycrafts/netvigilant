import 'package:device_apps/device_apps.dart';
import '../interfaces/repository_interfaces.dart';

// SOLID - Single Responsibility: Only manages app data
class AppRepositoryImpl implements IAppRepository {
  @override
  Future<List<Application>> getInstalledApps<Application>() async {
    try {
      final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: false,
        onlyAppsWithLaunchIntent: true,
      );
      return apps.cast<Application>();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Application?> getAppDetails<Application>(String packageName) async {
    try {
      final app = await DeviceApps.getApp(packageName, true);
      return app as Application?;
    } catch (e) {
      return null;
    }
  }
}