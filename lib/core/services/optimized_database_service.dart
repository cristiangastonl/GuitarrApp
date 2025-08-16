import 'dart:async';
import 'package:flutter/foundation.dart';
import '../storage/database_helper.dart';
import '../models/models.dart';
import '../cache/app_cache_manager.dart';

/// Optimized database service with caching and batch operations
class OptimizedDatabaseService {
  static final OptimizedDatabaseService _instance = OptimizedDatabaseService._internal();
  factory OptimizedDatabaseService() => _instance;
  OptimizedDatabaseService._internal();

  final AppCacheManager _cache = AppCacheManager();
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  /// Get user setup with caching
  Future<UserSetup?> getUserSetup() async {
    return _cache.getOrPut(
      CacheKeys.userSetup,
      () => DatabaseHelper.getUserSetup(),
      ttl: const Duration(hours: 1),
    );
  }

  /// Get all presets with caching
  Future<List<TonePreset>> getAllPresets() async {
    return _cache.getOrPut(
      CacheKeys.allPresets,
      () => DatabaseHelper.getAllTonePresets(),
      ttl: const Duration(minutes: 15),
    );
  }

  /// Get presets by genre with caching and deduplication
  Future<List<TonePreset>> getPresetsByGenre(String genre) async {
    final key = CacheKeys.presetsByGenre(genre);
    
    // Check for pending request to avoid duplicate queries
    if (_pendingRequests.containsKey(key)) {
      return await _pendingRequests[key]!.future as List<TonePreset>;
    }

    final completer = Completer<List<TonePreset>>();
    _pendingRequests[key] = completer;

    try {
      final result = await _cache.getOrPut(
        key,
        () => DatabaseHelper.getTonePresetsByGenre(genre),
        ttl: const Duration(minutes: 10),
      );
      
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(key);
    }
  }

  /// Get user sessions with optimized pagination
  Future<List<Session>> getUserSessions(String userId, {int limit = 50, int offset = 0}) async {
    if (offset == 0) {
      // Cache only the first page
      return _cache.getOrPut(
        CacheKeys.userSessions(userId),
        () => _getUserSessionsPaginated(userId, limit, offset),
        ttl: const Duration(minutes: 5),
      );
    }
    
    // Don't cache subsequent pages
    return _getUserSessionsPaginated(userId, limit, offset);
  }

  Future<List<Session>> _getUserSessionsPaginated(String userId, int limit, int offset) async {
    // Use raw SQL for better performance with large datasets
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT * FROM sessions 
      WHERE user_id = ? 
      ORDER BY start_time DESC 
      LIMIT ? OFFSET ?
      ''',
      [userId, limit, offset],
    );
    
    return compute(_parseSessionsIsolate, maps);
  }

  /// Batch insert presets for better performance
  Future<void> insertPresetsBatch(List<TonePreset> presets) async {
    final db = await DatabaseHelper.database;
    final batch = db.batch();
    
    for (final preset in presets) {
      batch.insert('tone_presets', _tonePresetToMap(preset));
    }
    
    await batch.commit(noResult: true);
    
    // Invalidate related cache entries
    _cache.remove(CacheKeys.allPresets);
    for (final preset in presets) {
      _cache.remove(CacheKeys.presetsByGenre(preset.genre));
    }
  }

  /// Insert session with cache management
  Future<int> insertSession(Session session) async {
    final result = await DatabaseHelper.insertSession(session);
    
    // Invalidate user sessions cache
    _cache.remove(CacheKeys.userSessions(session.userId));
    _cache.remove(CacheKeys.recentSessions);
    
    return result;
  }

  /// Update preset with cache invalidation
  Future<int> updatePreset(TonePreset preset) async {
    final result = await DatabaseHelper.updateTonePreset(preset);
    
    // Invalidate related caches
    _cache.remove(CacheKeys.allPresets);
    _cache.remove(CacheKeys.presetsByGenre(preset.genre));
    
    return result;
  }

  /// Warm up cache with frequently used data
  Future<void> warmUpCache() async {
    await Future.wait([
      getUserSetup(),
      getAllPresets(),
      // Pre-load popular genres
      getPresetsByGenre('rock'),
      getPresetsByGenre('metal'),
      getPresetsByGenre('blues'),
    ]);
  }

  /// Clear all caches
  void clearCache() {
    _cache.clear();
  }

  /// Get cache statistics
  CacheStats get cacheStats => _cache.stats;

  // Helper method for preset mapping (moved here for batch operations)
  Map<String, dynamic> _tonePresetToMap(TonePreset preset) {
    return {
      'id': preset.id,
      'name': preset.name,
      'description': preset.description,
      'genre': preset.genre,
      'amp_model': preset.ampModel,
      'eq_settings': preset.eqSettings.toString(),
      'effects': preset.effects.toString(),
      'gain': preset.gain,
      'volume': preset.volume,
      'is_default': preset.isDefault ? 1 : 0,
      'is_custom': preset.isCustom ? 1 : 0,
      'created_at': preset.createdAt.toIso8601String(),
      'last_used': preset.lastUsed.toIso8601String(),
    };
  }
}

/// Isolate function to parse sessions (CPU-intensive operation)
List<Session> _parseSessionsIsolate(List<Map<String, dynamic>> maps) {
  return maps.map((map) {
    final List<SessionFeedback> feedback = [];
    
    return Session(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      songRiffId: map['song_riff_id'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null 
          ? DateTime.parse(map['end_time'] as String)
          : null,
      targetBpm: map['target_bpm'] as int,
      actualBpm: map['actual_bpm'] as int,
      durationMinutes: map['duration_minutes'] as int,
      accuracy: map['accuracy'] as double,
      successfulRuns: map['successful_runs'] as int,
      totalAttempts: map['total_attempts'] as int,
      feedback: feedback,
      notes: map['notes'] as String,
      completed: (map['completed'] as int) == 1,
    );
  }).toList();
}