import 'package:shared_preferences/shared_preferences.dart';
import '../interfaces/repository_interfaces.dart';
import '../../services/permission_manager.dart';

// SOLID - Single Responsibility: Only manages permission state
class PermissionRepositoryImpl implements IPermissionRepository {
  static const String _permissionPrefix = 'permission_';

  @override
  Future<bool> hasPermission(String permission) async {
    switch (permission) {
      case 'usage':
        return await PermissionManager.hasUsagePermission();
      case 'location':
        return await PermissionManager.hasLocationPermission();
      default:
        return false;
    }
  }

  @override
  Future<bool> requestPermission(String permission) async {
    switch (permission) {
      case 'usage':
        return await PermissionManager.requestAndStoreUsagePermission();
      case 'location':
        return await PermissionManager.requestLocationPermission();
      default:
        return false;
    }
  }

  @override
  Future<void> storePermissionState(String permission, bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_permissionPrefix$permission', granted);
    } catch (e) {
      // Silent fail for storage issues
    }
  }

  @override
  Future<bool> getStoredPermissionState(String permission) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_permissionPrefix$permission') ?? false;
    } catch (e) {
      return false;
    }
  }
}