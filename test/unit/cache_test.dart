import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/cache/app_cache_manager.dart';

void main() {
  group('AppCacheManager Tests', () {
    late AppCacheManager cacheManager;

    setUp(() {
      cacheManager = AppCacheManager();
      cacheManager.clear(); // Start with clean cache
    });

    test('should store and retrieve data correctly', () {
      // Arrange
      const key = 'test_key';
      const data = 'test_data';

      // Act
      cacheManager.put(key, data);
      final result = cacheManager.get<String>(key);

      // Assert
      expect(result, equals(data));
    });

    test('should return null for non-existent keys', () {
      // Act
      final result = cacheManager.get<String>('non_existent_key');

      // Assert
      expect(result, isNull);
    });

    test('should handle different data types', () {
      // Arrange
      const stringKey = 'string_data';
      const stringData = 'hello world';
      
      const intKey = 'int_data';
      const intData = 42;
      
      const listKey = 'list_data';
      const listData = ['item1', 'item2', 'item3'];

      // Act
      cacheManager.put(stringKey, stringData);
      cacheManager.put(intKey, intData);
      cacheManager.put(listKey, listData);

      // Assert
      expect(cacheManager.get<String>(stringKey), equals(stringData));
      expect(cacheManager.get<int>(intKey), equals(intData));
      expect(cacheManager.get<List<String>>(listKey), equals(listData));
    });

    test('should overwrite existing entries', () {
      // Arrange
      const key = 'test_key';
      const originalData = 'original';
      const newData = 'updated';

      // Act
      cacheManager.put(key, originalData);
      cacheManager.put(key, newData);
      final result = cacheManager.get<String>(key);

      // Assert
      expect(result, equals(newData));
    });

    test('containsKey should work correctly', () {
      // Arrange
      const key = 'test_key';
      const data = 'test_data';

      // Act & Assert
      expect(cacheManager.containsKey(key), isFalse);
      
      cacheManager.put(key, data);
      expect(cacheManager.containsKey(key), isTrue);
      
      cacheManager.remove(key);
      expect(cacheManager.containsKey(key), isFalse);
    });

    test('clear should remove all entries', () {
      // Arrange
      cacheManager.put('key1', 'data1');
      cacheManager.put('key2', 'data2');
      cacheManager.put('key3', 'data3');

      // Act
      cacheManager.clear();

      // Assert
      expect(cacheManager.containsKey('key1'), isFalse);
      expect(cacheManager.containsKey('key2'), isFalse);
      expect(cacheManager.containsKey('key3'), isFalse);
    });

    test('getOrPut should return cached value or compute new one', () async {
      // Arrange
      const key = 'test_key';
      const cachedData = 'cached';
      const computedData = 'computed';
      
      bool computationCalled = false;

      // Act - first call should compute and cache
      final firstResult = await cacheManager.getOrPut(key, () async {
        computationCalled = true;
        return computedData;
      });

      // Put different data in cache
      cacheManager.put(key, cachedData);

      // Second call should return cached value
      computationCalled = false;
      final secondResult = await cacheManager.getOrPut(key, () async {
        computationCalled = true;
        return computedData;
      });

      // Assert
      expect(firstResult, equals(computedData));
      expect(secondResult, equals(cachedData));
      expect(computationCalled, isFalse); // Should not be called second time
    });

    test('cache stats should provide usage information', () {
      // Arrange
      cacheManager.put('key1', 'data1');
      cacheManager.put('key2', 'data2');

      // Act
      final stats = cacheManager.stats;

      // Assert
      expect(stats.size, equals(2));
      expect(stats.maxSize, greaterThan(0));
      expect(stats.utilizationRate, equals(2.0 / stats.maxSize));
    });

    group('CacheKeys', () {
      test('should provide consistent key generation', () {
        // Test static keys
        expect(CacheKeys.userSetup, equals('user_setup'));
        expect(CacheKeys.allPresets, equals('all_presets'));
        
        // Test dynamic keys
        expect(CacheKeys.presetsByGenre('rock'), equals('presets_genre_rock'));
        expect(CacheKeys.presetRecommendations('riff123'), equals('recommendations_riff123'));
        expect(CacheKeys.equipmentRecommendations('electric', 'tube'), 
               equals('equipment_electric_tube'));
      });
    });
  });
}