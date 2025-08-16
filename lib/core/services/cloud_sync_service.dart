import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../models/song_riff.dart';
import '../models/user_setup.dart';
import 'stats_service.dart';
import 'secure_credentials_service.dart';

/// Cloud Sync Service
/// Handles synchronization of user data across multiple devices
/// Provides offline-first functionality with intelligent conflict resolution
class CloudSyncService {
  final StatsService _statsService;
  final SecureCredentialsService _credentialsService;
  
  // Simulated cloud storage - in production this would connect to Firebase/AWS/etc
  static final Map<String, Map<String, dynamic>> _cloudStorage = {};
  
  // Local state management
  final Map<String, DateTime> _lastSyncTimes = {};
  final Map<String, List<SyncConflict>> _pendingConflicts = {};
  final StreamController<SyncStatus> _syncStatusController = StreamController.broadcast();
  final StreamController<List<SyncConflict>> _conflictsController = StreamController.broadcast();
  
  CloudSyncService(this._statsService, this._credentialsService);
  
  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  
  /// Stream of sync conflicts that need user resolution
  Stream<List<SyncConflict>> get conflictsStream => _conflictsController.stream;
  
  /// Initialize cloud sync for a user
  Future<void> initializeSync(String userId) async {
    try {
      await _createUserCloudSpace(userId);
      await _performInitialSync(userId);
    } catch (e) {
      throw CloudSyncException('Failed to initialize sync: $e');
    }
  }
  
  /// Perform full synchronization
  Future<SyncResult> performFullSync(String userId) async {
    _updateSyncStatus(SyncStatus.syncing);
    
    try {
      final localData = await _gatherLocalData(userId);
      final cloudData = await _fetchCloudData(userId);
      
      final conflicts = await _detectConflicts(localData, cloudData);
      
      if (conflicts.isNotEmpty) {
        _pendingConflicts[userId] = conflicts;
        _conflictsController.add(conflicts);
        _updateSyncStatus(SyncStatus.conflictsDetected);
        
        return SyncResult(
          success: false,
          conflicts: conflicts,
          message: 'Conflicts detected - user resolution required',
        );
      }
      
      final mergedData = await _mergeData(localData, cloudData);
      
      await _uploadToCloud(userId, mergedData);
      await _updateLocalData(userId, mergedData);
      
      _lastSyncTimes[userId] = DateTime.now();
      _updateSyncStatus(SyncStatus.synced);
      
      return SyncResult(
        success: true,
        syncedItems: mergedData.length,
        message: 'Sync completed successfully',
      );
    } catch (e) {
      _updateSyncStatus(SyncStatus.error);
      throw CloudSyncException('Sync failed: $e');
    }
  }
  
  /// Sync only practice sessions (incremental sync)
  Future<SyncResult> syncSessions(String userId) async {
    try {
      final lastSync = _lastSyncTimes[userId];
      final localSessions = await _getLocalSessionsSince(userId, lastSync);
      final cloudSessions = await _getCloudSessionsSince(userId, lastSync);
      
      final conflicts = await _detectSessionConflicts(localSessions, cloudSessions);
      
      if (conflicts.isNotEmpty) {
        return SyncResult(
          success: false,
          conflicts: conflicts,
          message: 'Session conflicts detected',
        );
      }
      
      // Upload new local sessions
      for (final session in localSessions) {
        await _uploadSession(userId, session);
      }
      
      // Download new cloud sessions
      for (final session in cloudSessions) {
        await _saveLocalSession(session);
      }
      
      return SyncResult(
        success: true,
        syncedItems: localSessions.length + cloudSessions.length,
        message: 'Sessions synced successfully',
      );
    } catch (e) {
      throw CloudSyncException('Session sync failed: $e');
    }
  }
  
  /// Sync user preferences and settings
  Future<void> syncUserPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      await _uploadUserPreferences(userId, preferences);
    } catch (e) {
      throw CloudSyncException('Failed to sync preferences: $e');
    }
  }
  
  /// Enable automatic background sync
  Future<void> enableAutoSync(String userId, {
    Duration interval = const Duration(minutes: 15),
  }) async {
    Timer.periodic(interval, (timer) async {
      try {
        if (await _shouldAutoSync(userId)) {
          await syncSessions(userId);
        }
      } catch (e) {
        // Silent fail for background sync
      }
    });
  }
  
  /// Resolve sync conflicts
  Future<void> resolveConflicts(String userId, List<ConflictResolution> resolutions) async {
    try {
      final conflicts = _pendingConflicts[userId] ?? [];
      
      for (final resolution in resolutions) {
        final conflict = conflicts.firstWhere((c) => c.id == resolution.conflictId);
        
        switch (resolution.strategy) {
          case ResolutionStrategy.useLocal:
            await _applyLocalVersion(userId, conflict);
            break;
          case ResolutionStrategy.useCloud:
            await _applyCloudVersion(userId, conflict);
            break;
          case ResolutionStrategy.merge:
            await _applyMergedVersion(userId, conflict, resolution.mergedData);
            break;
        }
      }
      
      _pendingConflicts[userId] = [];
      _conflictsController.add([]);
      _updateSyncStatus(SyncStatus.synced);
    } catch (e) {
      throw CloudSyncException('Failed to resolve conflicts: $e');
    }
  }
  
  /// Get sync statistics
  Future<SyncStatistics> getSyncStatistics(String userId) async {
    try {
      final lastSync = _lastSyncTimes[userId];
      final pendingConflicts = _pendingConflicts[userId]?.length ?? 0;
      final cloudSize = await _getCloudDataSize(userId);
      
      return SyncStatistics(
        lastSyncTime: lastSync,
        pendingConflicts: pendingConflicts,
        cloudDataSize: cloudSize,
        autoSyncEnabled: true, // Would check actual setting
        totalSessions: await _getTotalSessionsCount(userId),
        syncedDevices: await _getSyncedDevicesCount(userId),
      );
    } catch (e) {
      throw CloudSyncException('Failed to get sync statistics: $e');
    }
  }
  
  /// Export all user data for backup
  Future<UserDataExport> exportUserData(String userId) async {
    try {
      final sessions = await _statsService.getUserSessions(userId);
      final preferences = await _getUserPreferences(userId);
      
      return UserDataExport(
        userId: userId,
        exportDate: DateTime.now(),
        sessions: sessions,
        preferences: preferences,
        version: '1.0',
      );
    } catch (e) {
      throw CloudSyncException('Failed to export user data: $e');
    }
  }
  
  /// Import user data from backup
  Future<void> importUserData(String userId, UserDataExport exportData) async {
    try {
      _updateSyncStatus(SyncStatus.importing);
      
      // Import sessions
      for (final session in exportData.sessions) {
        await _saveLocalSession(session);
      }
      
      // Import preferences
      await _setUserPreferences(userId, exportData.preferences);
      
      // Upload to cloud
      await performFullSync(userId);
      
      _updateSyncStatus(SyncStatus.synced);
    } catch (e) {
      _updateSyncStatus(SyncStatus.error);
      throw CloudSyncException('Failed to import user data: $e');
    }
  }
  
  /// Check if device is online and can sync
  Future<bool> canSync() async {
    // In a real implementation, this would check network connectivity
    return true;
  }
  
  /// Get offline queue size
  int getOfflineQueueSize(String userId) {
    // In a real implementation, this would return the number of items waiting to sync
    return 0;
  }
  
  // Private methods
  Future<void> _createUserCloudSpace(String userId) async {
    _cloudStorage[userId] ??= {
      'sessions': <String, dynamic>{},
      'preferences': <String, dynamic>{},
      'metadata': {
        'created': DateTime.now().toIso8601String(),
        'lastModified': DateTime.now().toIso8601String(),
      },
    };
  }
  
  Future<void> _performInitialSync(String userId) async {
    // Check if this is the first sync
    if (!_cloudStorage.containsKey(userId)) {
      await _createUserCloudSpace(userId);
    }
    
    await performFullSync(userId);
  }
  
  Future<Map<String, dynamic>> _gatherLocalData(String userId) async {
    final sessions = await _statsService.getUserSessions(userId);
    final preferences = await _getUserPreferences(userId);
    
    return {
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'preferences': preferences,
      'lastModified': DateTime.now().toIso8601String(),
    };
  }
  
  Future<Map<String, dynamic>> _fetchCloudData(String userId) async {
    return _cloudStorage[userId] ?? {};
  }
  
  Future<List<SyncConflict>> _detectConflicts(
    Map<String, dynamic> localData,
    Map<String, dynamic> cloudData,
  ) async {
    final conflicts = <SyncConflict>[];
    
    // Check for session conflicts
    final localSessions = localData['sessions'] as List? ?? [];
    final cloudSessions = cloudData['sessions'] as Map? ?? {};
    
    for (final localSession in localSessions) {
      final sessionId = localSession['id'] as String;
      final cloudSession = cloudSessions[sessionId];
      
      if (cloudSession != null) {
        final localModified = DateTime.parse(localSession['startTime'] as String);
        final cloudModified = DateTime.parse(cloudSession['startTime'] as String);
        
        if (localModified != cloudModified) {
          conflicts.add(SyncConflict(
            id: _generateConflictId(),
            type: ConflictType.session,
            itemId: sessionId,
            localData: localSession,
            cloudData: cloudSession,
            localModified: localModified,
            cloudModified: cloudModified,
          ));
        }
      }
    }
    
    return conflicts;
  }
  
  Future<Map<String, dynamic>> _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> cloudData,
  ) async {
    final merged = Map<String, dynamic>.from(cloudData);
    
    // Merge sessions (newer wins)
    final localSessions = localData['sessions'] as List? ?? [];
    final cloudSessions = merged['sessions'] as Map? ?? {};
    
    for (final localSession in localSessions) {
      final sessionId = localSession['id'] as String;
      final cloudSession = cloudSessions[sessionId];
      
      if (cloudSession == null) {
        // New local session
        cloudSessions[sessionId] = localSession;
      } else {
        // Compare timestamps and keep newer
        final localTime = DateTime.parse(localSession['startTime'] as String);
        final cloudTime = DateTime.parse(cloudSession['startTime'] as String);
        
        if (localTime.isAfter(cloudTime)) {
          cloudSessions[sessionId] = localSession;
        }
      }
    }
    
    merged['sessions'] = cloudSessions;
    merged['lastModified'] = DateTime.now().toIso8601String();
    
    return merged;
  }
  
  Future<void> _uploadToCloud(String userId, Map<String, dynamic> data) async {
    _cloudStorage[userId] = data;
  }
  
  Future<void> _updateLocalData(String userId, Map<String, dynamic> data) async {
    // In a real implementation, this would update the local database
    // For now, we'll simulate it
  }
  
  Future<List<Session>> _getLocalSessionsSince(String userId, DateTime? since) async {
    final allSessions = await _statsService.getUserSessions(userId);
    
    if (since == null) return allSessions;
    
    return allSessions.where((session) => session.startTime.isAfter(since)).toList();
  }
  
  Future<List<Session>> _getCloudSessionsSince(String userId, DateTime? since) async {
    // Simulate fetching from cloud
    return [];
  }
  
  Future<List<SyncConflict>> _detectSessionConflicts(
    List<Session> localSessions,
    List<Session> cloudSessions,
  ) async {
    // Simplified conflict detection
    return [];
  }
  
  Future<void> _uploadSession(String userId, Session session) async {
    final cloudData = _cloudStorage[userId] ??= {};
    final sessions = cloudData['sessions'] as Map<String, dynamic>? ?? {};
    sessions[session.id] = session.toJson();
    cloudData['sessions'] = sessions;
  }
  
  Future<void> _saveLocalSession(Session session) async {
    // In a real implementation, this would save to local database
  }
  
  Future<void> _uploadUserPreferences(String userId, Map<String, dynamic> preferences) async {
    final cloudData = _cloudStorage[userId] ??= {};
    cloudData['preferences'] = preferences;
  }
  
  Future<bool> _shouldAutoSync(String userId) async {
    final lastSync = _lastSyncTimes[userId];
    if (lastSync == null) return true;
    
    final timeSinceLastSync = DateTime.now().difference(lastSync);
    return timeSinceLastSync.inMinutes >= 15;
  }
  
  Future<void> _applyLocalVersion(String userId, SyncConflict conflict) async {
    // Apply local version to cloud
    await _uploadToCloud(userId, {'${conflict.itemId}': conflict.localData});
  }
  
  Future<void> _applyCloudVersion(String userId, SyncConflict conflict) async {
    // Apply cloud version to local
    if (conflict.type == ConflictType.session && conflict.cloudData != null) {
      final session = Session.fromJson(conflict.cloudData!);
      await _saveLocalSession(session);
    }
  }
  
  Future<void> _applyMergedVersion(String userId, SyncConflict conflict, Map<String, dynamic>? mergedData) async {
    if (mergedData == null) return;
    
    // Apply merged version to both local and cloud
    await _uploadToCloud(userId, {'${conflict.itemId}': mergedData});
    
    if (conflict.type == ConflictType.session) {
      final session = Session.fromJson(mergedData);
      await _saveLocalSession(session);
    }
  }
  
  Future<Map<String, dynamic>> _getUserPreferences(String userId) async {
    // In a real implementation, this would fetch from local storage
    return {};
  }
  
  Future<void> _setUserPreferences(String userId, Map<String, dynamic> preferences) async {
    // In a real implementation, this would save to local storage
  }
  
  Future<int> _getCloudDataSize(String userId) async {
    final data = _cloudStorage[userId];
    if (data == null) return 0;
    
    final jsonString = jsonEncode(data);
    return jsonString.length;
  }
  
  Future<int> _getTotalSessionsCount(String userId) async {
    final sessions = await _statsService.getUserSessions(userId);
    return sessions.length;
  }
  
  Future<int> _getSyncedDevicesCount(String userId) async {
    // In a real implementation, this would track devices
    return 1;
  }
  
  void _updateSyncStatus(SyncStatus status) {
    _syncStatusController.add(status);
  }
  
  String _generateConflictId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  void dispose() {
    _syncStatusController.close();
    _conflictsController.close();
  }
}

// Data Models
class SyncResult {
  final bool success;
  final int syncedItems;
  final List<SyncConflict> conflicts;
  final String message;
  
  const SyncResult({
    required this.success,
    this.syncedItems = 0,
    this.conflicts = const [],
    required this.message,
  });
}

class SyncConflict {
  final String id;
  final ConflictType type;
  final String itemId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic>? cloudData;
  final DateTime localModified;
  final DateTime cloudModified;
  
  const SyncConflict({
    required this.id,
    required this.type,
    required this.itemId,
    required this.localData,
    this.cloudData,
    required this.localModified,
    required this.cloudModified,
  });
}

class ConflictResolution {
  final String conflictId;
  final ResolutionStrategy strategy;
  final Map<String, dynamic>? mergedData;
  
  const ConflictResolution({
    required this.conflictId,
    required this.strategy,
    this.mergedData,
  });
}

class SyncStatistics {
  final DateTime? lastSyncTime;
  final int pendingConflicts;
  final int cloudDataSize;
  final bool autoSyncEnabled;
  final int totalSessions;
  final int syncedDevices;
  
  const SyncStatistics({
    this.lastSyncTime,
    required this.pendingConflicts,
    required this.cloudDataSize,
    required this.autoSyncEnabled,
    required this.totalSessions,
    required this.syncedDevices,
  });
}

class UserDataExport {
  final String userId;
  final DateTime exportDate;
  final List<Session> sessions;
  final Map<String, dynamic> preferences;
  final String version;
  
  const UserDataExport({
    required this.userId,
    required this.exportDate,
    required this.sessions,
    required this.preferences,
    required this.version,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'exportDate': exportDate.toIso8601String(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'preferences': preferences,
      'version': version,
    };
  }
  
  factory UserDataExport.fromJson(Map<String, dynamic> json) {
    return UserDataExport(
      userId: json['userId'],
      exportDate: DateTime.parse(json['exportDate']),
      sessions: (json['sessions'] as List)
          .map((s) => Session.fromJson(s))
          .toList(),
      preferences: json['preferences'],
      version: json['version'],
    );
  }
}

// Enums
enum SyncStatus {
  synced,
  syncing,
  conflictsDetected,
  error,
  offline,
  importing,
}

enum ConflictType {
  session,
  preferences,
  userSetup,
}

enum ResolutionStrategy {
  useLocal,
  useCloud,
  merge,
}

class CloudSyncException implements Exception {
  final String message;
  
  const CloudSyncException(this.message);
  
  @override
  String toString() => 'CloudSyncException: $message';
}

// Riverpod providers
final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final statsService = ref.read(statsServiceProvider);
  final credentialsService = ref.read(secureCredentialsServiceProvider);
  return CloudSyncService(statsService, credentialsService);
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final service = ref.read(cloudSyncServiceProvider);
  return service.syncStatusStream;
});

final syncConflictsProvider = StreamProvider<List<SyncConflict>>((ref) {
  final service = ref.read(cloudSyncServiceProvider);
  return service.conflictsStream;
});

final syncStatisticsProvider = FutureProvider.family<SyncStatistics, String>((ref, userId) async {
  final service = ref.read(cloudSyncServiceProvider);
  return service.getSyncStatistics(userId);
});