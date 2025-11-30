// SOLID Principles: Interface Segregation & Dependency Inversion
// Abstractions for repository pattern implementation

/// Base repository interface
abstract class IRepository<T, K> {
  Future<T?> getById(K id);
  Future<List<T>> getAll();
  Future<void> save(T entity);
  Future<void> saveAll(List<T> entities);
  Future<void> deleteById(K id);
  Future<void> clear();
}

/// Cache-enabled repository interface
abstract class ICacheableRepository<T, K> extends IRepository<T, K> {
  Future<T?> getFromCache(K id);
  Future<void> saveToCache(T entity);
  Future<void> invalidateCache(K id);
  Future<void> clearCache();
}

/// Time-based data repository interface
abstract class ITimeBasedRepository<T> extends IRepository<T, String> {
  Future<List<T>> getByDateRange(DateTime start, DateTime end);
  Future<List<T>> getLatest(int count);
  Future<void> deleteOlderThan(DateTime cutoff);
}

/// Aggregation repository interface
abstract class IAggregationRepository<T, R> {
  Future<R> aggregate(DateTime start, DateTime end, String groupBy);
  Future<Map<String, R>> aggregateByField(DateTime start, DateTime end, String field);
  Future<List<R>> getTopN(DateTime start, DateTime end, int n, String orderBy);
}

/// Network data repository interface
abstract class INetworkRepository {
  // Permission management
  Future<bool?> hasUsageStatsPermission();
  Future<void> requestUsageStatsPermission();
  Future<bool?> hasIgnoreBatteryOptimizationPermission();
  Future<void> requestIgnoreBatteryOptimizationPermission();
  Future<void> openBatteryOptimizationSettings();
  
  // Data retrieval
  Future<Map<String, dynamic>> getHistoricalAppUsage({required DateTime start, required DateTime end});
  Future<List<dynamic>> getNetworkUsage({required DateTime start, required DateTime end});
  Future<List<dynamic>> getAppUsage({required DateTime start, required DateTime end});
  Future<Map<String, dynamic>> getAggregatedNetworkUsageByUid({required DateTime start, required DateTime end});
  Future<List<dynamic>> getAllHistoricalNetworkTraffic();
  
  // Monitoring
  Stream<Map<String, dynamic>> getLiveTrafficStream();
  Future<void> startContinuousMonitoring();
  Future<void> stopContinuousMonitoring();
}

/// App discovery repository interface
abstract class IAppDiscoveryRepository {
  Future<List<Map<String, dynamic>>> getAllInstalledApps({bool includeSystemApps = false, bool includeIcons = false});
  Future<List<Map<String, dynamic>>> getAllAppsWithUsage();
  Future<List<Map<String, dynamic>>> searchApps(String query, {bool includeSystemApps = false});
  Future<List<Map<String, dynamic>>> getAppsByCategory(String category);
  Future<List<Map<String, dynamic>>> getRecentlyUpdatedApps(int daysBack);
  Future<void> clearAppCache();
}