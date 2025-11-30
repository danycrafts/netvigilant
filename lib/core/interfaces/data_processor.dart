// SOLID Principles: Interface Segregation Principle (ISP)
// Each interface has a single responsibility and is focused

/// Generic data processor interface
abstract class IDataProcessor<T, R> {
  /// Process data and return result
  Future<R> process(T data);
  
  /// Process data in batches for large datasets
  Future<R> processBatch(List<T> data);
  
  /// Validate input data before processing
  bool validate(T data);
}

/// Concurrent data processor interface extending base processor
abstract class IConcurrentDataProcessor<T, R> extends IDataProcessor<T, R> {
  /// Process data using multiple isolates
  Future<R> processConcurrently(List<T> data);
  
  /// Get optimal batch size for concurrent processing
  int getOptimalBatchSize(int dataSize);
  
  /// Cleanup resources
  void cleanup();
}

/// Cache interface for data processors
abstract class IProcessorCache<K, V> {
  /// Get cached result
  V? get(K key);
  
  /// Cache result
  void put(K key, V value);
  
  /// Clear cache
  void clear();
  
  /// Check if key exists
  bool containsKey(K key);
  
  /// Get cache size
  int get size;
}

/// Metrics interface for performance monitoring
abstract class IProcessorMetrics {
  /// Record processing time
  void recordProcessingTime(String operation, Duration duration);
  
  /// Record cache hit
  void recordCacheHit(String operation);
  
  /// Record cache miss
  void recordCacheMiss(String operation);
  
  /// Get processing statistics
  Map<String, dynamic> getStatistics();
  
  /// Reset statistics
  void reset();
}