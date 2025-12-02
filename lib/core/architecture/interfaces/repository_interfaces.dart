// SOLID - Interface Segregation Principle
// Each repository has a single, well-defined responsibility

abstract class IAppRepository {
  Future<List<T>> getInstalledApps<T>();
  Future<T?> getAppDetails<T>(String packageName);
}

abstract class IUsageRepository {
  Future<bool> hasUsagePermission();
  Future<bool> requestUsagePermission();
  Future<T?> getUsageInfo<T>(String packageName);
  Future<List<T>> getAllUsageStats<T>();
}

abstract class ILocationRepository {
  Future<T?> getCurrentLocation<T>();
  Future<bool> hasLocationPermission();
  Future<bool> requestLocationPermission();
}

abstract class INetworkRepository {
  Future<T?> getWifiNetworkInfo<T>();
  Future<T?> getMobileNetworkInfo<T>();
  Stream<T> watchNetworkChanges<T>();
}

abstract class IPermissionRepository {
  Future<bool> hasPermission(String permission);
  Future<bool> requestPermission(String permission);
  Future<void> storePermissionState(String permission, bool granted);
  Future<bool> getStoredPermissionState(String permission);
}

abstract class ICacheRepository {
  Future<void> store<T>(String key, T data, {Duration? ttl});
  Future<T?> retrieve<T>(String key);
  Future<bool> exists(String key);
  Future<void> remove(String key);
  Future<void> clear();
}