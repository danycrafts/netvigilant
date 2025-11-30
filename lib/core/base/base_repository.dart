// DRY Principle: Base repository with common functionality
// Eliminates code duplication across repository implementations

import 'dart:async';
import 'package:netvigilant/core/interfaces/repository.dart';
import 'package:netvigilant/core/interfaces/storage.dart';
import 'package:netvigilant/core/utils/logger.dart';

/// Base repository implementation with common functionality
abstract class BaseRepository<T, K> implements ICacheableRepository<T, K> {
  final ICacheStorage<T>? _cache;
  final Duration _cacheTtl;
  final String _entityName;

  BaseRepository({
    ICacheStorage<T>? cache,
    Duration cacheTtl = const Duration(minutes: 5),
    required String entityName,
  })  : _cache = cache,
        _cacheTtl = cacheTtl,
        _entityName = entityName;

  /// Abstract methods to be implemented by subclasses
  Future<T?> fetchFromSource(K id);
  Future<List<T>> fetchAllFromSource();
  Future<void> saveToSource(T entity);
  Future<void> saveAllToSource(List<T> entities);
  Future<void> deleteFromSource(K id);
  Future<void> clearSource();
  K extractId(T entity);

  @override
  Future<T?> getById(K id) async {
    try {
      // Try cache first
      final cached = await getFromCache(id);
      if (cached != null) {
        log('BaseRepository: Cache hit for $_entityName with id: $id');
        return cached;
      }

      // Fetch from source
      final entity = await fetchFromSource(id);
      if (entity != null) {
        await saveToCache(entity);
      }

      return entity;
    } catch (e) {
      log('BaseRepository: Error getting $_entityName by id $id: $e');
      rethrow;
    }
  }

  @override
  Future<List<T>> getAll() async {
    try {
      final entities = await fetchAllFromSource();
      
      // Cache entities if cache is available
      if (_cache != null) {
        for (final entity in entities) {
          await saveToCache(entity);
        }
      }

      return entities;
    } catch (e) {
      log('BaseRepository: Error getting all $_entityName: $e');
      rethrow;
    }
  }

  @override
  Future<void> save(T entity) async {
    try {
      await saveToSource(entity);
      await saveToCache(entity);
      log('BaseRepository: Saved $_entityName with id: ${extractId(entity)}');
    } catch (e) {
      log('BaseRepository: Error saving $_entityName: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveAll(List<T> entities) async {
    try {
      await saveAllToSource(entities);
      
      // Cache entities if cache is available
      if (_cache != null) {
        for (final entity in entities) {
          await saveToCache(entity);
        }
      }

      log('BaseRepository: Saved ${entities.length} $_entityName entities');
    } catch (e) {
      log('BaseRepository: Error saving $_entityName entities: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteById(K id) async {
    try {
      await deleteFromSource(id);
      await invalidateCache(id);
      log('BaseRepository: Deleted $_entityName with id: $id');
    } catch (e) {
      log('BaseRepository: Error deleting $_entityName with id $id: $e');
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await clearSource();
      await clearCache();
      log('BaseRepository: Cleared all $_entityName entities');
    } catch (e) {
      log('BaseRepository: Error clearing $_entityName: $e');
      rethrow;
    }
  }

  @override
  Future<T?> getFromCache(K id) async {
    if (_cache == null) return null;
    
    try {
      return await _cache.get(id.toString());
    } catch (e) {
      log('BaseRepository: Cache error for $_entityName with id $id: $e');
      return null;
    }
  }

  @override
  Future<void> saveToCache(T entity) async {
    if (_cache == null) return;
    
    try {
      final id = extractId(entity);
      await _cache.saveWithTtl(id.toString(), entity, _cacheTtl);
    } catch (e) {
      log('BaseRepository: Error caching $_entityName: $e');
      // Don't rethrow cache errors
    }
  }

  @override
  Future<void> invalidateCache(K id) async {
    if (_cache == null) return;
    
    try {
      await _cache.delete(id.toString());
    } catch (e) {
      log('BaseRepository: Error invalidating cache for $_entityName with id $id: $e');
      // Don't rethrow cache errors
    }
  }

  @override
  Future<void> clearCache() async {
    if (_cache == null) return;
    
    try {
      await _cache.clear();
    } catch (e) {
      log('BaseRepository: Error clearing cache for $_entityName: $e');
      // Don't rethrow cache errors
    }
  }
}

/// Base time-based repository with date range functionality
abstract class BaseTimeBasedRepository<T> extends BaseRepository<T, String> implements ITimeBasedRepository<T> {
  BaseTimeBasedRepository({
    super.cache,
    super.cacheTtl = const Duration(minutes: 5),
    required super.entityName,
  });

  /// Abstract methods for time-based operations
  Future<List<T>> fetchByDateRange(DateTime start, DateTime end);
  Future<List<T>> fetchLatest(int count);
  Future<void> deleteOlderThanFromSource(DateTime cutoff);
  DateTime extractTimestamp(T entity);

  @override
  Future<List<T>> getByDateRange(DateTime start, DateTime end) async {
    try {
      final entities = await fetchByDateRange(start, end);
      
      // Cache entities if cache is available
      if (_cache != null) {
        for (final entity in entities) {
          await saveToCache(entity);
        }
      }

      return entities;
    } catch (e) {
      log('BaseTimeBasedRepository: Error getting $_entityName by date range: $e');
      rethrow;
    }
  }

  @override
  Future<List<T>> getLatest(int count) async {
    try {
      final entities = await fetchLatest(count);
      
      // Cache entities if cache is available
      if (_cache != null) {
        for (final entity in entities) {
          await saveToCache(entity);
        }
      }

      return entities;
    } catch (e) {
      log('BaseTimeBasedRepository: Error getting latest $_entityName: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteOlderThan(DateTime cutoff) async {
    try {
      await deleteOlderThanFromSource(cutoff);
      // Note: Cache cleanup could be more sophisticated here
      await clearCache();
      log('BaseTimeBasedRepository: Deleted $_entityName older than $cutoff');
    } catch (e) {
      log('BaseTimeBasedRepository: Error deleting old $_entityName: $e');
      rethrow;
    }
  }
}

/// Base aggregation repository with common aggregation functionality
abstract class BaseAggregationRepository<T, R> implements IAggregationRepository<T, R> {
  final String _entityName;

  BaseAggregationRepository({required String entityName}) : _entityName = entityName;

  /// Abstract methods for aggregation operations
  Future<R> performAggregation(DateTime start, DateTime end, String groupBy);
  Future<Map<String, R>> performFieldAggregation(DateTime start, DateTime end, String field);
  Future<List<R>> performTopNQuery(DateTime start, DateTime end, int n, String orderBy);

  @override
  Future<R> aggregate(DateTime start, DateTime end, String groupBy) async {
    try {
      final result = await performAggregation(start, end, groupBy);
      log('BaseAggregationRepository: Aggregated $_entityName by $groupBy');
      return result;
    } catch (e) {
      log('BaseAggregationRepository: Error aggregating $_entityName: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, R>> aggregateByField(DateTime start, DateTime end, String field) async {
    try {
      final result = await performFieldAggregation(start, end, field);
      log('BaseAggregationRepository: Aggregated $_entityName by field $field');
      return result;
    } catch (e) {
      log('BaseAggregationRepository: Error aggregating $_entityName by field: $e');
      rethrow;
    }
  }

  @override
  Future<List<R>> getTopN(DateTime start, DateTime end, int n, String orderBy) async {
    try {
      final result = await performTopNQuery(start, end, n, orderBy);
      log('BaseAggregationRepository: Retrieved top $n $_entityName ordered by $orderBy');
      return result;
    } catch (e) {
      log('BaseAggregationRepository: Error getting top $_entityName: $e');
      rethrow;
    }
  }
}