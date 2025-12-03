import 'dart:async';

class CacheService<T> {
  final Map<String, T> _cache = {};
  final Map<String, DateTime> _timestamps = {};
  final Duration _ttl;

  CacheService(this._ttl);

  void set(String key, T value) {
    _cache[key] = value;
    _timestamps[key] = DateTime.now();
  }

  T? get(String key) {
    if (_cache.containsKey(key) && !_isExpired(key)) {
      return _cache[key];
    }
    return null;
  }

  void remove(String key) {
    _cache.remove(key);
    _timestamps.remove(key);
  }

  void clear() {
    _cache.clear();
    _timestamps.clear();
  }

  Future<T> getOrFetch(String key, Future<T> Function() fetchFunction) async {
    final cachedValue = get(key);
    if (cachedValue != null) {
      return cachedValue;
    }

    final fetchedValue = await fetchFunction();
    set(key, fetchedValue);
    return fetchedValue;
  }

  void invalidate(String key) {
    remove(key);
  }

  bool _isExpired(String key) {
    final timestamp = _timestamps[key];
    if (timestamp == null) {
      return true;
    }
    return DateTime.now().difference(timestamp) > _ttl;
  }
}
