import 'package:flutter_test/flutter_test.dart';
import 'package:apptobe/core/services/cache_service.dart';

void main() {
  group('CacheService', () {
    late CacheService<String> cacheService;

    setUp(() {
      cacheService = CacheService<String>(const Duration(seconds: 1));
    });

    test('should store and retrieve a value', () {
      cacheService.set('key', 'value');
      expect(cacheService.get('key'), 'value');
    });

    test('should return null for an expired value', () async {
      cacheService.set('key', 'value');
      await Future.delayed(const Duration(seconds: 2));
      expect(cacheService.get('key'), null);
    });

    test('should return null for a non-existent value', () {
      expect(cacheService.get('key'), null);
    });

    test('should remove a value', () {
      cacheService.set('key', 'value');
      cacheService.remove('key');
      expect(cacheService.get('key'), null);
    });

    test('should clear all values', () {
      cacheService.set('key1', 'value1');
      cacheService.set('key2', 'value2');
      cacheService.clear();
      expect(cacheService.get('key1'), null);
      expect(cacheService.get('key2'), null);
    });

    test('should fetch a value if it does not exist', () async {
      final value = await cacheService.getOrFetch('key', () async => 'value');
      expect(value, 'value');
      expect(cacheService.get('key'), 'value');
    });

    test('should not fetch a value if it exists', () async {
      cacheService.set('key', 'value');
      final value = await cacheService.getOrFetch('key', () async => 'new-value');
      expect(value, 'value');
      expect(cacheService.get('key'), 'value');
    });
  });
}
