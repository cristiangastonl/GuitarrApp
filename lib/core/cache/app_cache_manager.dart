import 'dart:async';
import 'dart:collection';

/// High-performance in-memory cache manager with LRU eviction
class AppCacheManager {
  static const int _defaultMaxSize = 100;
  static const Duration _staticDefaultTtl = Duration(minutes: 30);
  
  final int _maxSize;
  final Duration _defaultTtl;
  final LinkedHashMap<String, _CacheEntry> _cache = LinkedHashMap();
  final Map<String, Timer> _timers = {};

  static final AppCacheManager _instance = AppCacheManager._internal();
  factory AppCacheManager() => _instance;

  AppCacheManager._internal({
    int maxSize = _defaultMaxSize,
    Duration defaultTtl = _staticDefaultTtl,
  }) : _maxSize = maxSize, _defaultTtl = defaultTtl;

  /// Store data in cache with optional TTL
  void put<T>(String key, T data, {Duration? ttl}) {
    final effectiveTtl = ttl ?? _defaultTtl;
    
    // Cancel existing timer if any
    _timers[key]?.cancel();
    
    // Remove if already exists to update LRU order
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }
    
    // Add new entry
    _cache[key] = _CacheEntry(data, DateTime.now().add(effectiveTtl));
    
    // Set up expiration timer
    _timers[key] = Timer(effectiveTtl, () {
      _cache.remove(key);
      _timers.remove(key);
    });
    
    // Evict oldest entries if over max size
    while (_cache.length > _maxSize) {
      final oldestKey = _cache.keys.first;
      _evict(oldestKey);
    }
  }

  /// Retrieve data from cache
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    // Check if expired
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _evict(key);
      return null;
    }
    
    // Move to end (most recently used)
    _cache.remove(key);
    _cache[key] = entry;
    
    return entry.data as T?;
  }

  /// Get data with fallback function if not cached
  Future<T> getOrPut<T>(String key, Future<T> Function() fallback, {Duration? ttl}) async {
    final cached = get<T>(key);
    if (cached != null) return cached;
    
    final data = await fallback();
    put(key, data, ttl: ttl);
    return data;
  }

  /// Check if key exists and is not expired
  bool containsKey(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _evict(key);
      return false;
    }
    
    return true;
  }

  /// Remove entry from cache
  void remove(String key) {
    _evict(key);
  }

  /// Clear all entries
  void clear() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _cache.clear();
  }

  /// Get cache statistics
  CacheStats get stats => CacheStats(
    size: _cache.length,
    maxSize: _maxSize,
    hitRate: _hitCount / (_hitCount + _missCount).clamp(1, double.infinity),
  );

  void _evict(String key) {
    _cache.remove(key);
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  // Hit/miss tracking for analytics
  int _hitCount = 0;
  int _missCount = 0;

  void _recordHit() => _hitCount++;
  void _recordMiss() => _missCount++;
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry(this.data, this.expiresAt);
}

class CacheStats {
  final int size;
  final int maxSize;
  final double hitRate;

  const CacheStats({
    required this.size,
    required this.maxSize,
    required this.hitRate,
  });

  double get utilizationRate => size / maxSize;
}

/// Cache keys for commonly used data
class CacheKeys {
  static const String userSetup = 'user_setup';
  static const String allPresets = 'all_presets';
  static const String recentSessions = 'recent_sessions';
  static const String achievements = 'achievements';
  static const String backingTracks = 'backing_tracks';
  
  // Preset-specific keys
  static String presetsByGenre(String genre) => 'presets_genre_$genre';
  static String presetRecommendations(String riffId) => 'recommendations_$riffId';
  static String equipmentRecommendations(String guitarType, String ampType) => 
      'equipment_${guitarType}_$ampType';
  
  // Session-specific keys
  static String userSessions(String userId) => 'sessions_$userId';
  static String riffSessions(String riffId) => 'riff_sessions_$riffId';
}