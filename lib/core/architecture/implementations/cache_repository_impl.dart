import 'package:apptobe/core/interfaces/cache_repository.dart';
import 'package:apptobe/core/services/cache_service.dart';

class CacheRepositoryImpl implements ICacheRepository {
  final CacheService _cacheService;

  CacheRepositoryImpl(this._cacheService);

  @override
  Future<void> store<T>(String key, T data, {Duration? ttl}) async {
    _cacheService.set(key, data);
  }

  @override
  Future<T?> retrieve<T>(String key) async {
    return _cacheService.get(key) as T?;
  }

  @override
  Future<bool> exists(String key) async {
    return _cacheService.get(key) != null;
  }

  @override
  Future<void> remove(String key) async {
    _cacheService.remove(key);
  }

  @override
  Future<void> clear() async {
    _cacheService.clear();
  }
}
