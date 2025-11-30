import 'dart:async';
import 'dart:isolate';
import 'package:netvigilant/core/utils/logger.dart';
import 'package:netvigilant/domain/entities/app_usage_entity.dart';
import 'package:netvigilant/domain/entities/network_traffic_entity.dart';
import 'package:netvigilant/core/interfaces/data_processor.dart';

/// Concurrent data processor using Dart isolates for CPU-intensive operations
/// Provides thread-safe data processing for large datasets
class ConcurrentDataProcessor implements IConcurrentDataProcessor<Map<String, dynamic>, List<dynamic>> {
  static const int _maxConcurrentTasks = 4;
  static final Map<String, Isolate> _activeIsolates = {};
  static final Map<String, SendPort> _isolatePorts = {};
  static int _taskCounter = 0;

  /// Process app usage data concurrently in isolates
  static Future<List<AppUsageEntity>> processAppUsageDataConcurrently(
    List<Map<String, dynamic>> rawData,
  ) async {
    if (rawData.isEmpty) return [];

    try {
      // Split data into chunks for parallel processing
      final chunks = _splitIntoChunks(rawData, _maxConcurrentTasks);
      final futures = <Future<List<AppUsageEntity>>>[];

      for (final chunk in chunks) {
        if (chunk.isNotEmpty) {
          futures.add(_processAppUsageChunk(chunk));
        }
      }

      final results = await Future.wait(futures);
      final allResults = <AppUsageEntity>[];
      
      for (final result in results) {
        allResults.addAll(result);
      }

      log('ConcurrentDataProcessor: Processed ${allResults.length} app usage entities using ${futures.length} isolates');
      return allResults;

    } catch (e) {
      log('ConcurrentDataProcessor: Error processing app usage data: $e');
      // Fallback to synchronous processing
      return _processAppUsageSync(rawData);
    }
  }

  /// Process network traffic data concurrently
  static Future<List<NetworkTrafficEntity>> processNetworkTrafficConcurrently(
    List<Map<String, dynamic>> rawData,
  ) async {
    if (rawData.isEmpty) return [];

    try {
      final chunks = _splitIntoChunks(rawData, _maxConcurrentTasks);
      final futures = <Future<List<NetworkTrafficEntity>>>[];

      for (final chunk in chunks) {
        if (chunk.isNotEmpty) {
          futures.add(_processNetworkTrafficChunk(chunk));
        }
      }

      final results = await Future.wait(futures);
      final allResults = <NetworkTrafficEntity>[];
      
      for (final result in results) {
        allResults.addAll(result);
      }

      log('ConcurrentDataProcessor: Processed ${allResults.length} network traffic entities using ${futures.length} isolates');
      return allResults;

    } catch (e) {
      log('ConcurrentDataProcessor: Error processing network traffic data: $e');
      return _processNetworkTrafficSync(rawData);
    }
  }

  /// Aggregate data concurrently with custom aggregation function
  static Future<Map<String, T>> aggregateDataConcurrently<T>(
    List<Map<String, dynamic>> data,
    String keyField,
    T Function(List<Map<String, dynamic>>) aggregator,
  ) async {
    if (data.isEmpty) return {};

    try {
      // Group data by key
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final item in data) {
        final key = item[keyField]?.toString() ?? 'unknown';
        grouped[key] ??= [];
        grouped[key]!.add(item);
      }

      // Process groups concurrently
      final futures = <Future<MapEntry<String, T>>>[];
      
      for (final entry in grouped.entries) {
        futures.add(_processAggregationGroup(entry.key, entry.value, aggregator));
      }

      final results = await Future.wait(futures);
      return Map.fromEntries(results);

    } catch (e) {
      log('ConcurrentDataProcessor: Error in concurrent aggregation: $e');
      rethrow;
    }
  }

  /// Process large dataset with streaming and batching
  static Stream<List<T>> processLargeDatasetStream<T>(
    Stream<Map<String, dynamic>> dataStream,
    T Function(Map<String, dynamic>) processor,
    {int batchSize = 100}
  ) async* {
    final batch = <T>[];
    
    await for (final item in dataStream) {
      try {
        final processed = processor(item);
        batch.add(processed);

        if (batch.length >= batchSize) {
          yield List.from(batch);
          batch.clear();
        }
      } catch (e) {
        log('ConcurrentDataProcessor: Error processing stream item: $e');
        // Continue processing other items
      }
    }

    // Yield remaining items
    if (batch.isNotEmpty) {
      yield batch;
    }
  }

  /// Process app usage chunk in isolate
  static Future<List<AppUsageEntity>> _processAppUsageChunk(
    List<Map<String, dynamic>> chunk,
  ) async {
    final isolateId = 'app_usage_${++_taskCounter}';
    
    try {
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _appUsageIsolateEntryPoint,
        _IsolateMessage(receivePort.sendPort, chunk),
        debugName: isolateId,
      );

      _activeIsolates[isolateId] = isolate;

      final result = await receivePort.first as List<Map<String, dynamic>>;
      
      return result.map((data) => _createAppUsageEntity(data)).toList();

    } catch (e) {
      log('ConcurrentDataProcessor: Error in app usage isolate: $e');
      return _processAppUsageSync(chunk);
    } finally {
      _cleanupIsolate(isolateId);
    }
  }

  /// Process network traffic chunk in isolate
  static Future<List<NetworkTrafficEntity>> _processNetworkTrafficChunk(
    List<Map<String, dynamic>> chunk,
  ) async {
    final isolateId = 'network_traffic_${++_taskCounter}';
    
    try {
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _networkTrafficIsolateEntryPoint,
        _IsolateMessage(receivePort.sendPort, chunk),
        debugName: isolateId,
      );

      _activeIsolates[isolateId] = isolate;

      final result = await receivePort.first as List<Map<String, dynamic>>;
      
      return result.map((data) => _createNetworkTrafficEntity(data)).toList();

    } catch (e) {
      log('ConcurrentDataProcessor: Error in network traffic isolate: $e');
      return _processNetworkTrafficSync(chunk);
    } finally {
      _cleanupIsolate(isolateId);
    }
  }

  /// Process aggregation group in isolate
  static Future<MapEntry<String, T>> _processAggregationGroup<T>(
    String key,
    List<Map<String, dynamic>> data,
    T Function(List<Map<String, dynamic>>) aggregator,
  ) async {
    // Run aggregation synchronously since generic functions are complex to serialize
    try {
      final result = aggregator(data);
      return MapEntry(key, result);
    } catch (e) {
      log('ConcurrentDataProcessor: Error in aggregation: $e');
      rethrow;
    }
  }

  /// Split data into chunks for parallel processing
  static List<List<Map<String, dynamic>>> _splitIntoChunks(
    List<Map<String, dynamic>> data,
    int numberOfChunks,
  ) {
    if (data.length <= numberOfChunks) {
      return data.map((item) => [item]).toList();
    }

    final chunkSize = (data.length / numberOfChunks).ceil();
    final chunks = <List<Map<String, dynamic>>>[];

    for (int i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      chunks.add(data.sublist(i, end));
    }

    return chunks;
  }

  /// Fallback synchronous processing for app usage
  static List<AppUsageEntity> _processAppUsageSync(List<Map<String, dynamic>> data) {
    return data.map((item) => _createAppUsageEntity(item)).toList();
  }

  /// Fallback synchronous processing for network traffic
  static List<NetworkTrafficEntity> _processNetworkTrafficSync(List<Map<String, dynamic>> data) {
    return data.map((item) => _createNetworkTrafficEntity(item)).toList();
  }

  /// Create AppUsageEntity from map
  static AppUsageEntity _createAppUsageEntity(Map<String, dynamic> map) {
    return AppUsageEntity(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      networkUsage: (map['networkUsage'] as num?)?.toDouble() ?? 0.0,
      totalTimeInForeground: map['totalTimeInForeground'] ?? 0,
      cpuUsage: (map['cpuUsage'] as num?)?.toDouble() ?? 0.0,
      memoryUsage: (map['memoryUsage'] as num?)?.toDouble() ?? 0.0,
      batteryUsage: (map['batteryUsage'] as num?)?.toDouble() ?? 0.0,
      launchCount: map['launchCount'] ?? 0,
      lastTimeUsed: DateTime.fromMillisecondsSinceEpoch(
        map['lastTimeUsed'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Create NetworkTrafficEntity from map
  static NetworkTrafficEntity _createNetworkTrafficEntity(Map<String, dynamic> map) {
    return NetworkTrafficEntity(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      uid: map['uid'] ?? 0,
      rxBytes: map['rxBytes'] ?? 0,
      txBytes: map['txBytes'] ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      networkType: _parseNetworkType(map['networkType']),
      isBackgroundTraffic: map['isBackgroundTraffic'] ?? false,
    );
  }

  /// Parse network type from dynamic value
  static NetworkType _parseNetworkType(dynamic type) {
    if (type is String) {
      switch (type.toLowerCase()) {
        case 'wifi':
          return NetworkType.wifi;
        case 'mobile':
          return NetworkType.mobile;
        default:
          return NetworkType.unknown;
      }
    }
    return NetworkType.unknown;
  }

  /// Cleanup isolate resources
  static void _cleanupIsolate(String isolateId) {
    final isolate = _activeIsolates.remove(isolateId);
    isolate?.kill(priority: Isolate.immediate);
    _isolatePorts.remove(isolateId);
  }

  /// Cleanup all active isolates
  static void cleanupStatic() {
    for (final isolateId in _activeIsolates.keys.toList()) {
      _cleanupIsolate(isolateId);
    }
  }

  /// Get current isolate count for monitoring
  static int get activeIsolateCount => _activeIsolates.length;

  // Interface implementation methods
  @override
  Future<List<dynamic>> process(Map<String, dynamic> data) async {
    return [data]; // Simple pass-through for single item
  }

  @override
  Future<List<dynamic>> processBatch(List<Map<String, dynamic>> data) async {
    return data; // Simple pass-through for batch
  }

  @override
  bool validate(Map<String, dynamic> data) {
    return data.isNotEmpty; // Basic validation
  }

  @override
  Future<List<dynamic>> processConcurrently(List<Map<String, dynamic>> data) async {
    // Generic concurrent processing
    return data; // Simplified implementation
  }

  @override
  int getOptimalBatchSize(int dataSize) {
    return (dataSize / _maxConcurrentTasks).ceil();
  }

  @override
  void cleanup() {
    cleanupStatic();
  }
}

/// Isolate entry point for app usage processing
void _appUsageIsolateEntryPoint(_IsolateMessage message) {
  try {
    final data = message.data as List<Map<String, dynamic>>;
    final processedData = <Map<String, dynamic>>[];

    for (final item in data) {
      try {
        // Perform data validation and enhancement
        final processed = Map<String, dynamic>.from(item);
        
        // Add calculated fields
        processed['dataUsagePerHour'] = _calculateDataUsageRate(processed);
        processed['activityScore'] = _calculateActivityScore(processed);
        processed['processedAt'] = DateTime.now().millisecondsSinceEpoch;

        processedData.add(processed);
      } catch (e) {
        // Skip invalid items but continue processing
        continue;
      }
    }

    message.sendPort.send(processedData);
  } catch (e) {
    message.sendPort.send(<Map<String, dynamic>>[]);
  }
}

/// Isolate entry point for network traffic processing
void _networkTrafficIsolateEntryPoint(_IsolateMessage message) {
  try {
    final data = message.data as List<Map<String, dynamic>>;
    final processedData = <Map<String, dynamic>>[];

    for (final item in data) {
      try {
        final processed = Map<String, dynamic>.from(item);
        
        // Add calculated fields
        processed['totalBytes'] = (processed['rxBytes'] ?? 0) + (processed['txBytes'] ?? 0);
        processed['transferRate'] = _calculateTransferRate(processed);
        processed['networkEfficiency'] = _calculateNetworkEfficiency(processed);
        processed['processedAt'] = DateTime.now().millisecondsSinceEpoch;

        processedData.add(processed);
      } catch (e) {
        continue;
      }
    }

    message.sendPort.send(processedData);
  } catch (e) {
    message.sendPort.send(<Map<String, dynamic>>[]);
  }
}

/// Calculate data usage rate for app usage
double _calculateDataUsageRate(Map<String, dynamic> data) {
  try {
    final totalTime = data['totalTimeInForeground'] as int? ?? 0;
    final networkUsage = data['networkUsage'] as double? ?? 0.0;
    
    if (totalTime > 0) {
      return networkUsage / (totalTime / 3600000.0); // bytes per hour
    }
    return 0.0;
  } catch (e) {
    return 0.0;
  }
}

/// Calculate activity score based on usage metrics
double _calculateActivityScore(Map<String, dynamic> data) {
  try {
    final cpuUsage = data['cpuUsage'] as double? ?? 0.0;
    final memoryUsage = data['memoryUsage'] as double? ?? 0.0;
    final batteryUsage = data['batteryUsage'] as double? ?? 0.0;
    final timeInForeground = data['totalTimeInForeground'] as int? ?? 0;
    
    // Weighted activity score
    final score = (cpuUsage * 0.3) + 
                  (memoryUsage * 0.2) + 
                  (batteryUsage * 0.2) + 
                  (timeInForeground > 0 ? 30.0 : 0.0);
    
    return score.clamp(0.0, 100.0);
  } catch (e) {
    return 0.0;
  }
}

/// Calculate transfer rate for network traffic
double _calculateTransferRate(Map<String, dynamic> data) {
  try {
    final rxBytes = data['rxBytes'] as int? ?? 0;
    final txBytes = data['txBytes'] as int? ?? 0;
    final timestamp = data['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    
    final totalBytes = rxBytes + txBytes;
    final timeSpan = DateTime.now().millisecondsSinceEpoch - timestamp;
    
    if (timeSpan > 0) {
      return totalBytes / (timeSpan / 1000.0); // bytes per second
    }
    return 0.0;
  } catch (e) {
    return 0.0;
  }
}

/// Calculate network efficiency metric
double _calculateNetworkEfficiency(Map<String, dynamic> data) {
  try {
    final rxBytes = data['rxBytes'] as int? ?? 0;
    final txBytes = data['txBytes'] as int? ?? 0;
    
    if (rxBytes + txBytes > 0) {
      return (rxBytes.toDouble() / (rxBytes + txBytes).toDouble()) * 100.0;
    }
    return 0.0;
  } catch (e) {
    return 0.0;
  }
}

/// Message class for isolate communication
class _IsolateMessage {
  final SendPort sendPort;
  final dynamic data;

  _IsolateMessage(this.sendPort, this.data);
}