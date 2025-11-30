// SOLID Principles: Interface Segregation Principle
// Storage abstractions for different data types and access patterns

/// Base storage interface
abstract class IStorage<T> {
  Future<void> save(String key, T value);
  Future<T?> get(String key);
  Future<void> delete(String key);
  Future<bool> exists(String key);
  Future<List<String>> getAllKeys();
  Future<void> clear();
}

/// Preferences storage interface for simple key-value pairs
abstract class IPreferencesStorage {
  Future<void> setBool(String key, bool value);
  Future<void> setInt(String key, int value);
  Future<void> setDouble(String key, double value);
  Future<void> setString(String key, String value);
  Future<void> setStringList(String key, List<String> value);
  
  Future<bool> getBool(String key, {bool defaultValue = false});
  Future<int> getInt(String key, {int defaultValue = 0});
  Future<double> getDouble(String key, {double defaultValue = 0.0});
  Future<String> getString(String key, {String defaultValue = ''});
  Future<List<String>> getStringList(String key, {List<String> defaultValue = const []});
  
  Future<void> remove(String key);
  Future<void> clear();
}

/// Database storage interface for complex data
abstract class IDatabaseStorage {
  Future<void> initialize();
  Future<void> close();
  Future<bool> isInitialized();
  Future<void> clearAllTables();
}

/// Time-series storage interface for time-based data
abstract class ITimeSeriesStorage<T> extends IStorage<T> {
  Future<void> saveTimeSeries(String seriesName, DateTime timestamp, T value);
  Future<List<T>> getTimeSeries(String seriesName, DateTime start, DateTime end);
  Future<List<T>> getLatestValues(String seriesName, int count);
  Future<void> deleteOlderThan(String seriesName, DateTime cutoff);
}

/// Cache storage interface with TTL support
abstract class ICacheStorage<T> extends IStorage<T> {
  Future<void> saveWithTtl(String key, T value, Duration ttl);
  Future<bool> isExpired(String key);
  Future<void> cleanupExpired();
}

/// Secure storage interface for sensitive data
abstract class ISecureStorage {
  Future<void> saveSecure(String key, String value);
  Future<String?> getSecure(String key);
  Future<void> deleteSecure(String key);
  Future<void> clearSecure();
  Future<bool> containsSecure(String key);
}

/// Blob storage interface for large files
abstract class IBlobStorage {
  Future<void> saveFile(String key, List<int> data);
  Future<List<int>?> getFile(String key);
  Future<void> deleteFile(String key);
  Future<int> getFileSize(String key);
  Future<DateTime?> getFileModifiedTime(String key);
  Future<List<String>> listFiles([String? prefix]);
}

/// Export storage interface for data export functionality
abstract class IExportStorage {
  Future<String> exportToCsv<T>(List<T> data, List<String> headers, List<String> Function(T) rowMapper);
  Future<String> exportToJson<T>(List<T> data);
  Future<String> exportToXml<T>(List<T> data, String rootElement, String itemElement);
  Future<void> saveToFile(String content, String filename);
  Future<String> getExportPath(String filename);
}