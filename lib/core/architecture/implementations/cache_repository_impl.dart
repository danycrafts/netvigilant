import '../interfaces/repository_interfaces.dart';
import '../../services/cache_service.dart';

// SOLID - Single Responsibility: Only manages cache operations
class CacheRepositoryImpl implements ICacheRepository {
  final CacheService _cacheService;

  const CacheRepositoryImpl({
    required CacheService cacheService,
  }) : _cacheService = cacheService;

  @override
  Future<void> store<T>(String key, T data, {Duration? ttl}) async {
    await _cacheService.set(key, data, ttl: ttl);
  }

  @override
  Future<T?> retrieve<T>(String key) async {
    return await _cacheService.get<T>(key);
  }

  @override
  Future<bool> exists(String key) async {
    final data = await _cacheService.get(key);
    return data != null;
  }

  @override
  Future<void> remove(String key) async {
    await _cacheService.remove(key);
  }

  @override
  Future<void> clear() async {
    await _cacheService.clear();
  }
}