abstract class ICacheRepository {
  Future<void> store<T>(String key, T data, {Duration? ttl});
  Future<T?> retrieve<T>(String key);
  Future<bool> exists(String key);
  Future<void> remove(String key);
  Future<void> clear();
}
