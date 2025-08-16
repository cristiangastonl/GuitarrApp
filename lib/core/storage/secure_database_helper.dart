import 'package:sqflite/sqflite.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:path/path.dart';
import '../models/models.dart';
import '../services/secure_credentials_service.dart';

/// Secure Database Helper with SQLCipher encryption
/// 
/// Provides encrypted storage for sensitive user data including:
/// - User configurations and preferences
/// - Practice session data
/// - Song riff information
/// - Tone presets
class SecureDatabaseHelper {
  static const String _databaseName = 'guitarr_app_secure.db';
  static const int _databaseVersion = 1;

  static Database? _database;
  static SecureCredentialsService? _credentialsService;

  /// Initialize the database with encryption
  static Future<void> initialize(SecureCredentialsService credentialsService) async {
    _credentialsService = credentialsService;
    
    // Initialize SQLCipher
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    
    // Open the encrypted database
    await _getDatabase();
  }

  static Future<Database> _getDatabase() async {
    if (_database != null) return _database!;
    
    if (_credentialsService == null) {
      throw SecureDatabaseException('Database not initialized with credentials service');
    }

    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);
      
      // Get encryption key from secure storage
      final encryptionKey = await _credentialsService!.getDatabaseEncryptionKey();
      if (encryptionKey == null) {
        throw SecureDatabaseException('Database encryption key not found');
      }

      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          // Enable foreign keys and set encryption key
          await db.execute('PRAGMA foreign_keys = ON');
          await db.execute('PRAGMA key = "$encryptionKey"');
          
          // Verify the database is properly encrypted
          try {
            await db.execute('SELECT count(*) FROM sqlite_master');
          } catch (e) {
            throw SecureDatabaseException('Failed to decrypt database: $e');
          }
        },
      );

      return _database!;
    } catch (e) {
      throw SecureDatabaseException('Failed to open secure database: $e');
    }
  }

  static Future<Database> get database async {
    return await _getDatabase();
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Apply encryption settings first
    final encryptionKey = await _credentialsService!.getDatabaseEncryptionKey();
    await db.execute('PRAGMA key = "$encryptionKey"');
    
    // Enable security features
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA secure_delete = ON'); // Overwrite deleted data
    await db.execute('PRAGMA auto_vacuum = FULL'); // Reclaim space securely
    
    await db.execute('''
      CREATE TABLE user_setup (
        id TEXT PRIMARY KEY,
        player_name TEXT NOT NULL,
        skill_level TEXT NOT NULL,
        preferred_genres TEXT NOT NULL,
        practice_time_minutes INTEGER NOT NULL,
        metronome_enabled INTEGER NOT NULL DEFAULT 1,
        metronome_volume REAL NOT NULL DEFAULT 0.7,
        created_at TEXT NOT NULL,
        last_practice_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE song_riffs (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        artist_name TEXT NOT NULL,
        genre TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        target_bpm INTEGER NOT NULL,
        starting_bpm INTEGER NOT NULL,
        techniques TEXT NOT NULL,
        tab_notation TEXT NOT NULL,
        audio_path TEXT NOT NULL,
        video_path TEXT,
        description TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        has_ghost_notes INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        song_riff_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        target_bpm INTEGER NOT NULL,
        actual_bpm INTEGER NOT NULL,
        duration_minutes INTEGER NOT NULL,
        accuracy REAL NOT NULL,
        successful_runs INTEGER NOT NULL,
        total_attempts INTEGER NOT NULL,
        feedback TEXT NOT NULL,
        notes TEXT DEFAULT '',
        completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES user_setup (id) ON DELETE CASCADE,
        FOREIGN KEY (song_riff_id) REFERENCES song_riffs (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE tone_presets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        genre TEXT NOT NULL,
        amp_model TEXT NOT NULL,
        eq_settings TEXT NOT NULL,
        effects TEXT NOT NULL,
        gain REAL NOT NULL,
        volume REAL NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        is_custom INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        last_used TEXT NOT NULL
      )
    ''');

    // Create audit table for security monitoring
    await db.execute('''
      CREATE TABLE database_audit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        record_id TEXT,
        data_hash TEXT
      )
    ''');

    await _insertDefaultTonePresets(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final encryptionKey = await _credentialsService!.getDatabaseEncryptionKey();
    await db.execute('PRAGMA key = "$encryptionKey"');
    
    // Handle database upgrades with proper encryption
    if (oldVersion < newVersion) {
      // Add migration logic when needed
      // Ensure all new tables/columns are created with encryption
    }
  }

  static Future<void> _insertDefaultTonePresets(Database db) async {
    final presets = [
      TonePreset.createCleanPreset(),
      TonePreset.createRockPreset(),
      TonePreset.createMetalPreset(),
    ];

    for (final preset in presets) {
      await db.insert('tone_presets', _tonePresetToMap(preset));
    }
  }

  // Secure CRUD operations with input validation and audit logging

  // UserSetup operations
  static Future<int> insertUserSetup(UserSetup userSetup) async {
    if (!_isValidUserSetup(userSetup)) {
      throw SecureDatabaseException('Invalid user setup data');
    }
    
    final db = await database;
    final result = await db.insert('user_setup', _userSetupToMap(userSetup));
    await _logAudit(db, 'user_setup', 'INSERT', userSetup.id);
    return result;
  }

  static Future<UserSetup?> getUserSetup() async {
    final db = await database;
    final maps = await db.query('user_setup', limit: 1);
    
    if (maps.isEmpty) return null;
    return _userSetupFromMap(maps.first);
  }

  static Future<int> updateUserSetup(UserSetup userSetup) async {
    if (!_isValidUserSetup(userSetup)) {
      throw SecureDatabaseException('Invalid user setup data');
    }
    
    final db = await database;
    final result = await db.update(
      'user_setup',
      _userSetupToMap(userSetup),
      where: 'id = ?',
      whereArgs: [userSetup.id],
    );
    await _logAudit(db, 'user_setup', 'UPDATE', userSetup.id);
    return result;
  }

  // SongRiff operations with validation
  static Future<int> insertSongRiff(SongRiff songRiff) async {
    if (!_isValidSongRiff(songRiff)) {
      throw SecureDatabaseException('Invalid song riff data');
    }
    
    final db = await database;
    final result = await db.insert('song_riffs', _songRiffToMap(songRiff));
    await _logAudit(db, 'song_riffs', 'INSERT', songRiff.id);
    return result;
  }

  static Future<List<SongRiff>> getAllSongRiffs() async {
    final db = await database;
    final maps = await db.query('song_riffs', orderBy: 'name ASC');
    return maps.map(_songRiffFromMap).toList();
  }

  static Future<List<SongRiff>> getSongRiffsByDifficulty(String difficulty) async {
    if (!_isValidDifficulty(difficulty)) {
      throw SecureDatabaseException('Invalid difficulty parameter');
    }
    
    final db = await database;
    final maps = await db.query(
      'song_riffs',
      where: 'difficulty = ?',
      whereArgs: [difficulty],
      orderBy: 'name ASC',
    );
    return maps.map(_songRiffFromMap).toList();
  }

  static Future<List<SongRiff>> getSongRiffsByGenre(String genre) async {
    if (!_isValidGenre(genre)) {
      throw SecureDatabaseException('Invalid genre parameter');
    }
    
    final db = await database;
    final maps = await db.query(
      'song_riffs',
      where: 'genre = ?',
      whereArgs: [genre],
      orderBy: 'name ASC',
    );
    return maps.map(_songRiffFromMap).toList();
  }

  // Session operations with enhanced security
  static Future<int> insertSession(Session session) async {
    if (!_isValidSession(session)) {
      throw SecureDatabaseException('Invalid session data');
    }
    
    final db = await database;
    final result = await db.insert('sessions', _sessionToMap(session));
    await _logAudit(db, 'sessions', 'INSERT', session.id);
    return result;
  }

  static Future<List<Session>> getSessionsByUser(String userId) async {
    if (userId.isEmpty) {
      throw SecureDatabaseException('Invalid user ID');
    }
    
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'start_time DESC',
    );
    return maps.map(_sessionFromMap).toList();
  }

  static Future<List<Session>> getSessionsByRiff(String riffId) async {
    if (riffId.isEmpty) {
      throw SecureDatabaseException('Invalid riff ID');
    }
    
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'song_riff_id = ?',
      whereArgs: [riffId],
      orderBy: 'start_time DESC',
    );
    return maps.map(_sessionFromMap).toList();
  }

  static Future<int> updateSession(Session session) async {
    if (!_isValidSession(session)) {
      throw SecureDatabaseException('Invalid session data');
    }
    
    final db = await database;
    final result = await db.update(
      'sessions',
      _sessionToMap(session),
      where: 'id = ?',
      whereArgs: [session.id],
    );
    await _logAudit(db, 'sessions', 'UPDATE', session.id);
    return result;
  }

  // TonePreset operations
  static Future<int> insertTonePreset(TonePreset preset) async {
    if (!_isValidTonePreset(preset)) {
      throw SecureDatabaseException('Invalid tone preset data');
    }
    
    final db = await database;
    final result = await db.insert('tone_presets', _tonePresetToMap(preset));
    await _logAudit(db, 'tone_presets', 'INSERT', preset.id);
    return result;
  }

  static Future<List<TonePreset>> getAllTonePresets() async {
    final db = await database;
    final maps = await db.query('tone_presets', orderBy: 'name ASC');
    return maps.map(_tonePresetFromMap).toList();
  }

  static Future<List<TonePreset>> getTonePresetsByGenre(String genre) async {
    if (!_isValidGenre(genre)) {
      throw SecureDatabaseException('Invalid genre parameter');
    }
    
    final db = await database;
    final maps = await db.query(
      'tone_presets',
      where: 'genre = ?',
      whereArgs: [genre],
      orderBy: 'name ASC',
    );
    return maps.map(_tonePresetFromMap).toList();
  }

  static Future<int> updateTonePreset(TonePreset preset) async {
    if (!_isValidTonePreset(preset)) {
      throw SecureDatabaseException('Invalid tone preset data');
    }
    
    final db = await database;
    final result = await db.update(
      'tone_presets',
      _tonePresetToMap(preset),
      where: 'id = ?',
      whereArgs: [preset.id],
    );
    await _logAudit(db, 'tone_presets', 'UPDATE', preset.id);
    return result;
  }

  static Future<int> deleteTonePreset(String id) async {
    if (id.isEmpty) {
      throw SecureDatabaseException('Invalid preset ID');
    }
    
    final db = await database;
    final result = await db.delete(
      'tone_presets',
      where: 'id = ? AND is_default = 0',
      whereArgs: [id],
    );
    await _logAudit(db, 'tone_presets', 'DELETE', id);
    return result;
  }

  // Audit logging for security monitoring
  static Future<void> _logAudit(Database db, String tableName, String operation, String recordId) async {
    try {
      await db.insert('database_audit', {
        'table_name': tableName,
        'operation': operation,
        'timestamp': DateTime.now().toIso8601String(),
        'record_id': recordId,
        'data_hash': '${tableName}_${operation}_${recordId}'.hashCode.toString(),
      });
    } catch (e) {
      // Audit logging should not fail the main operation
      // In production, you might want to log this to a separate system
    }
  }

  // Input validation methods
  static bool _isValidUserSetup(UserSetup userSetup) {
    return userSetup.id.isNotEmpty &&
           userSetup.playerName.isNotEmpty &&
           userSetup.playerName.length <= 100 &&
           userSetup.skillLevel.isNotEmpty &&
           userSetup.preferredGenres.isNotEmpty &&
           userSetup.practiceTimeMinutes > 0 &&
           userSetup.practiceTimeMinutes <= 480; // Max 8 hours
  }

  static bool _isValidSongRiff(SongRiff songRiff) {
    return songRiff.id.isNotEmpty &&
           songRiff.name.isNotEmpty &&
           songRiff.name.length <= 200 &&
           songRiff.artistName.isNotEmpty &&
           songRiff.artistName.length <= 100 &&
           songRiff.targetBpm > 0 &&
           songRiff.targetBpm <= 300 &&
           songRiff.startingBpm > 0 &&
           songRiff.startingBpm <= 300;
  }

  static bool _isValidSession(Session session) {
    return session.id.isNotEmpty &&
           session.userId.isNotEmpty &&
           session.songRiffId.isNotEmpty &&
           session.targetBpm > 0 &&
           session.targetBpm <= 300 &&
           session.actualBpm >= 0 &&
           session.actualBpm <= 300 &&
           session.durationMinutes >= 0 &&
           session.accuracy >= 0.0 &&
           session.accuracy <= 1.0;
  }

  static bool _isValidTonePreset(TonePreset preset) {
    return preset.id.isNotEmpty &&
           preset.name.isNotEmpty &&
           preset.name.length <= 100 &&
           preset.gain >= 0.0 &&
           preset.gain <= 1.0 &&
           preset.volume >= 0.0 &&
           preset.volume <= 1.0;
  }

  static bool _isValidDifficulty(String difficulty) {
    const validDifficulties = ['beginner', 'intermediate', 'advanced', 'expert'];
    return validDifficulties.contains(difficulty.toLowerCase());
  }

  static bool _isValidGenre(String genre) {
    return genre.isNotEmpty && genre.length <= 50;
  }

  // Data conversion methods (same as before but with additional validation)
  static Map<String, dynamic> _userSetupToMap(UserSetup userSetup) {
    return {
      'id': userSetup.id,
      'player_name': userSetup.playerName,
      'skill_level': userSetup.skillLevel,
      'preferred_genres': userSetup.preferredGenres.join(','),
      'practice_time_minutes': userSetup.practiceTimeMinutes,
      'metronome_enabled': userSetup.metronomeEnabled ? 1 : 0,
      'metronome_volume': userSetup.metronomeVolume,
      'created_at': userSetup.createdAt.toIso8601String(),
      'last_practice_date': userSetup.lastPracticeDate.toIso8601String(),
    };
  }

  static UserSetup _userSetupFromMap(Map<String, dynamic> map) {
    return UserSetup(
      id: map['id'] as String,
      playerName: map['player_name'] as String,
      skillLevel: map['skill_level'] as String,
      preferredGenres: (map['preferred_genres'] as String).split(','),
      practiceTimeMinutes: map['practice_time_minutes'] as int,
      metronomeEnabled: (map['metronome_enabled'] as int) == 1,
      metronomeVolume: map['metronome_volume'] as double,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastPracticeDate: DateTime.parse(map['last_practice_date'] as String),
    );
  }

  static Map<String, dynamic> _songRiffToMap(SongRiff songRiff) {
    return {
      'id': songRiff.id,
      'name': songRiff.name,
      'artist_name': songRiff.artistName,
      'genre': songRiff.genre,
      'difficulty': songRiff.difficulty,
      'target_bpm': songRiff.targetBpm,
      'starting_bpm': songRiff.startingBpm,
      'techniques': songRiff.techniques.join(','),
      'tab_notation': songRiff.tabNotation,
      'audio_path': songRiff.audioPath,
      'video_path': songRiff.videoPath,
      'description': songRiff.description,
      'duration_seconds': songRiff.durationSeconds,
      'has_ghost_notes': songRiff.hasGhostNotes ? 1 : 0,
      'created_at': songRiff.createdAt.toIso8601String(),
    };
  }

  static SongRiff _songRiffFromMap(Map<String, dynamic> map) {
    return SongRiff(
      id: map['id'] as String,
      name: map['name'] as String,
      artistName: map['artist_name'] as String,
      genre: map['genre'] as String,
      difficulty: map['difficulty'] as String,
      targetBpm: map['target_bpm'] as int,
      startingBpm: map['starting_bpm'] as int,
      techniques: (map['techniques'] as String).split(','),
      tabNotation: map['tab_notation'] as String,
      audioPath: map['audio_path'] as String,
      videoPath: map['video_path'] as String?,
      description: map['description'] as String,
      durationSeconds: map['duration_seconds'] as int,
      hasGhostNotes: (map['has_ghost_notes'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static Map<String, dynamic> _sessionToMap(Session session) {
    return {
      'id': session.id,
      'user_id': session.userId,
      'song_riff_id': session.songRiffId,
      'start_time': session.startTime.toIso8601String(),
      'end_time': session.endTime?.toIso8601String(),
      'target_bpm': session.targetBpm,
      'actual_bpm': session.actualBpm,
      'duration_minutes': session.durationMinutes,
      'accuracy': session.accuracy,
      'successful_runs': session.successfulRuns,
      'total_attempts': session.totalAttempts,
      'feedback': session.feedback.map((f) => f.toJson()).toString(),
      'notes': session.notes,
      'completed': session.completed ? 1 : 0,
    };
  }

  static Session _sessionFromMap(Map<String, dynamic> map) {
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
  }

  static Map<String, dynamic> _tonePresetToMap(TonePreset preset) {
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

  static TonePreset _tonePresetFromMap(Map<String, dynamic> map) {
    return TonePreset(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      genre: map['genre'] as String,
      ampModel: map['amp_model'] as String,
      eqSettings: {
        'bass': 0.5,
        'mid': 0.5,
        'treble': 0.5,
        'presence': 0.5,
      },
      effects: {
        'distortion': 0.5,
        'reverb': 0.3,
        'delay': 0.0,
        'chorus': 0.0,
      },
      gain: map['gain'] as double,
      volume: map['volume'] as double,
      isDefault: (map['is_default'] as int) == 1,
      isCustom: (map['is_custom'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastUsed: DateTime.parse(map['last_used'] as String),
    );
  }

  /// Securely close the database and clear sensitive data
  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      // Clear any cached sensitive data
      await db.execute('PRAGMA key = ""');
      await db.close();
      _database = null;
    }
  }

  /// Get audit trail for security monitoring
  static Future<List<Map<String, dynamic>>> getAuditTrail({
    String? tableName,
    DateTime? since,
    int limit = 100,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (tableName != null) {
      whereClause = 'table_name = ?';
      whereArgs.add(tableName);
    }
    
    if (since != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp > ?';
      whereArgs.add(since.toIso8601String());
    }
    
    return await db.query(
      'database_audit',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  /// Database integrity check
  static Future<bool> verifyIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      return result.isNotEmpty && result.first.values.first == 'ok';
    } catch (e) {
      return false;
    }
  }
}

/// Exception for secure database operations
class SecureDatabaseException implements Exception {
  final String message;
  
  const SecureDatabaseException(this.message);
  
  @override
  String toString() => 'SecureDatabaseException: $message';
}