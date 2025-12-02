import 'package:device_apps/device_apps.dart';
import '../interfaces/service_interfaces.dart';

// SOLID - Single Responsibility: Only handles app launching
class AppLaunchServiceImpl implements IAppLaunchService {
  @override
  Future<bool> launchApp(String packageName) async {
    try {
      return await DeviceApps.openApp(packageName);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> canLaunchApp(String packageName) async {
    try {
      final app = await DeviceApps.getApp(packageName);
      return app != null;
    } catch (e) {
      return false;
    }
  }
}