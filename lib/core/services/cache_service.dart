import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;

  Map<String, dynamic> toJson() => {
    'data': data,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'ttl': ttl.inMilliseconds,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return CacheEntry<T>(
      data: fromJson(json['data']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      ttl: Duration(milliseconds: json['ttl']),
    );
  }
}

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, CacheEntry> _memoryCache = {};
  SharedPreferences? _prefs;

  static const String _cachePrefix = 'cache_';

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> set<T>(
    String key,
    T data, {
    Duration? ttl,
    bool persistToDisk = false,
  }) async {
    final entry = CacheEntry<T>(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl ?? const Duration(minutes: 30),
    );

    _memoryCache[key] = entry;

    if (persistToDisk) {
      await _initPrefs();
      await _prefs!.setString(
        '$_cachePrefix$key',
        jsonEncode(entry.toJson()),
      );
    }
  }

  Future<T?> get<T>(
    String key, {
    T Function(dynamic)? fromJson,
    bool checkDisk = false,
  }) async {
    CacheEntry? entry = _memoryCache[key];

    if (entry == null && checkDisk) {
      await _initPrefs();
      final cached = _prefs!.getString('$_cachePrefix$key');
      if (cached != null && fromJson != null) {
        try {
          final json = jsonDecode(cached);
          entry = CacheEntry.fromJson(json, fromJson);
          _memoryCache[key] = entry;
        } catch (e) {
          await _prefs!.remove('$_cachePrefix$key');
        }
      }
    }

    if (entry == null || entry.isExpired) {
      await remove(key);
      return null;
    }

    return entry.data as T;
  }

  Future<bool> has(String key) async {
    final data = await get(key, checkDisk: true);
    return data != null;
  }

  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _initPrefs();
    await _prefs!.remove('$_cachePrefix$key');
  }

  Future<void> clear() async {
    _memoryCache.clear();
    await _initPrefs();
    final keys = _prefs!.getKeys()
        .where((key) => key.startsWith(_cachePrefix))
        .toList();
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }

  Future<void> invalidate(String pattern) async {
    final keysToRemove = _memoryCache.keys
        .where((key) => key.contains(pattern))
        .toList();
    
    for (final key in keysToRemove) {
      await remove(key);
    }
  }

  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetchFunction, {
    Duration? ttl,
    bool persistToDisk = false,
    T Function(dynamic)? fromJson,
  }) async {
    T? cached = await get<T>(key, fromJson: fromJson, checkDisk: persistToDisk);
    if (cached != null) {
      return cached;
    }

    final data = await fetchFunction();
    await set(key, data, ttl: ttl, persistToDisk: persistToDisk);
    return data;
  }
}