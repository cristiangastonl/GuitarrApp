import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/session.dart';
import '../models/song_riff.dart';
import 'stats_service.dart';
import 'audio_player_service.dart';

/// Intelligent Backing Tracks Service
/// Generates AI-powered backing tracks based on user's practice progress,
/// musical preferences, and current skill level
class IntelligentBackingTracksService {
  final StatsService _statsService;
  final AudioPlayerService _audioPlayerService;
  
  // Cache for generated backing tracks
  final Map<String, BackingTrack> _backingTracksCache = {};
  
  IntelligentBackingTracksService(this._statsService, this._audioPlayerService);
  
  /// Generate intelligent backing track for a specific riff/song
  Future<BackingTrack> generateBackingTrack({
    required String songRiffId,
    required String userId,
    BackingTrackStyle? preferredStyle,
    int? customBpm,
    BackingTrackComplexity? complexity,
  }) async {
    try {
      // Check cache first
      final cacheKey = _generateCacheKey(songRiffId, userId, preferredStyle, customBpm, complexity);
      if (_backingTracksCache.containsKey(cacheKey)) {
        return _backingTracksCache[cacheKey]!;
      }
      
      // Analyze user's skill level and preferences
      final userProfile = await _analyzeUserMusicProfile(userId);
      
      // Get song/riff information
      final songInfo = await _getSongRiffInfo(songRiffId);
      
      // Determine optimal backing track parameters
      final trackParams = await _calculateOptimalParameters(
        userProfile: userProfile,
        songInfo: songInfo,
        preferredStyle: preferredStyle,
        customBpm: customBpm,
        complexity: complexity,
      );
      
      // Generate the backing track
      final backingTrack = await _generateTrackWithParameters(
        songRiffId: songRiffId,
        parameters: trackParams,
        songInfo: songInfo,
      );
      
      // Cache the result
      _backingTracksCache[cacheKey] = backingTrack;
      
      return backingTrack;
    } catch (e) {
      throw BackingTrackException('Error generating backing track: $e');
    }
  }
  
  /// Get available backing track styles for a song
  List<BackingTrackStyle> getAvailableStyles(String genre) {
    final genreStyles = <String, List<BackingTrackStyle>>{
      'rock': [
        BackingTrackStyle.rockPower,
        BackingTrackStyle.rockAlternative,
        BackingTrackStyle.rockClassic,
        BackingTrackStyle.rockProgressive,
      ],
      'metal': [
        BackingTrackStyle.metalHeavy,
        BackingTrackStyle.metalProgressive,
        BackingTrackStyle.metalThrash,
        BackingTrackStyle.metalPower,
      ],
      'blues': [
        BackingTrackStyle.bluesTraditional,
        BackingTrackStyle.bluesRock,
        BackingTrackStyle.bluesJazz,
        BackingTrackStyle.bluesCountry,
      ],
      'jazz': [
        BackingTrackStyle.jazzSwing,
        BackingTrackStyle.jazzFusion,
        BackingTrackStyle.jazzSmooth,
        BackingTrackStyle.jazzLatin,
      ],
      'acoustic': [
        BackingTrackStyle.acousticFolk,
        BackingTrackStyle.acousticCountry,
        BackingTrackStyle.acousticClassical,
        BackingTrackStyle.acousticFingerstyle,
      ],
    };
    
    return genreStyles[genre.toLowerCase()] ?? [BackingTrackStyle.rockClassic];
  }
  
  /// Customize existing backing track
  Future<BackingTrack> customizeBackingTrack({
    required BackingTrack originalTrack,
    int? newBpm,
    BackingTrackStyle? newStyle,
    BackingTrackComplexity? newComplexity,
    List<TrackInstrument>? enabledInstruments,
    Map<TrackInstrument, double>? instrumentVolumes,
  }) async {
    try {
      final customizedTrack = originalTrack.copyWith(
        bpm: newBpm ?? originalTrack.bpm,
        style: newStyle ?? originalTrack.style,
        complexity: newComplexity ?? originalTrack.complexity,
        enabledInstruments: enabledInstruments ?? originalTrack.enabledInstruments,
        instrumentVolumes: instrumentVolumes ?? originalTrack.instrumentVolumes,
        lastModified: DateTime.now(),
      );
      
      // Regenerate audio with new parameters
      final updatedAudioPath = await _regenerateAudio(customizedTrack);
      
      return customizedTrack.copyWith(audioPath: updatedAudioPath);
    } catch (e) {
      throw BackingTrackException('Error customizing backing track: $e');
    }
  }
  
  /// Get backing tracks history for user
  Future<List<BackingTrack>> getUserBackingTracksHistory(String userId) async {
    try {
      // In a real implementation, this would fetch from database
      return _backingTracksCache.values
          .where((track) => track.userId == userId)
          .toList()
        ..sort((a, b) => b.lastModified.compareTo(a.lastModified));
    } catch (e) {
      throw BackingTrackException('Error fetching backing tracks history: $e');
    }
  }
  
  /// Analyze user's musical profile for backing track generation
  Future<UserMusicProfile> _analyzeUserMusicProfile(String userId) async {
    final sessions = await _statsService.getUserSessions(userId);
    
    if (sessions.isEmpty) {
      return UserMusicProfile.defaultProfile();
    }
    
    // Analyze practice patterns
    final genreFrequency = <String, int>{};
    final bpmPreferences = <int>[];
    final techniqueUsage = <String, int>{};
    double avgSkillLevel = 0.0;
    
    for (final session in sessions) {
      bpmPreferences.add(session.targetBpm);
      avgSkillLevel += session.overallScore;
      
      // In a real implementation, we'd fetch song riff data
      // For now, we'll simulate genre and technique data
    }
    
    avgSkillLevel = avgSkillLevel / sessions.length;
    
    // Calculate BPM preferences
    bpmPreferences.sort();
    final medianBpm = bpmPreferences[bpmPreferences.length ~/ 2];
    final bpmRange = BpmRange(
      min: bpmPreferences.isNotEmpty ? bpmPreferences.first - 20 : 80,
      max: bpmPreferences.isNotEmpty ? bpmPreferences.last + 20 : 120,
    );
    
    // Determine preferred genres (simulated)
    final preferredGenres = ['rock', 'metal', 'blues']; // Would be calculated from actual data
    
    // Calculate complexity preference
    final complexityPref = _calculateComplexityPreference(avgSkillLevel);
    
    return UserMusicProfile(
      skillLevel: avgSkillLevel,
      preferredGenres: preferredGenres,
      preferredBpmRange: bpmRange,
      medianBpm: medianBpm,
      complexityPreference: complexityPref,
      techniqueStrengths: ['rhythm', 'power-chords'], // Simulated
      techniqueWeaknesses: ['lead', 'bending'], // Simulated
      practiceHoursTotal: sessions.length * 30, // Approximation
    );
  }
  
  /// Get song/riff information
  Future<SongRiffInfo> _getSongRiffInfo(String songRiffId) async {
    // In a real implementation, this would fetch from database
    // For now, we'll return simulated data
    return SongRiffInfo(
      id: songRiffId,
      genre: 'rock',
      originalBpm: 120,
      keySignature: 'Em',
      timeSignature: '4/4',
      difficulty: 'medium',
      techniques: ['power-chords', 'palm-muting'],
      chordProgression: ['Em', 'C', 'G', 'D'],
      duration: const Duration(minutes: 3, seconds: 30),
    );
  }
  
  /// Calculate optimal backing track parameters
  Future<BackingTrackParameters> _calculateOptimalParameters({
    required UserMusicProfile userProfile,
    required SongRiffInfo songInfo,
    BackingTrackStyle? preferredStyle,
    int? customBpm,
    BackingTrackComplexity? complexity,
  }) async {
    // Determine BPM
    final optimalBpm = customBpm ?? _calculateOptimalBpm(userProfile, songInfo);
    
    // Determine style
    final optimalStyle = preferredStyle ?? _selectOptimalStyle(userProfile, songInfo);
    
    // Determine complexity
    final optimalComplexity = complexity ?? userProfile.complexityPreference;
    
    // Select instruments based on style and user preferences
    final instruments = _selectInstruments(optimalStyle, optimalComplexity, songInfo);
    
    // Calculate instrument volumes
    final volumes = _calculateInstrumentVolumes(instruments, userProfile);
    
    return BackingTrackParameters(
      bpm: optimalBpm,
      style: optimalStyle,
      complexity: optimalComplexity,
      keySignature: songInfo.keySignature,
      timeSignature: songInfo.timeSignature,
      chordProgression: songInfo.chordProgression,
      instruments: instruments,
      instrumentVolumes: volumes,
      duration: songInfo.duration,
    );
  }
  
  /// Generate backing track with specified parameters
  Future<BackingTrack> _generateTrackWithParameters({
    required String songRiffId,
    required BackingTrackParameters parameters,
    required SongRiffInfo songInfo,
  }) async {
    // In a real implementation, this would use AI/ML services or audio generation libraries
    // For now, we'll create a simulated backing track
    
    final trackId = _generateTrackId();
    final audioPath = await _generateAudioFile(parameters);
    
    return BackingTrack(
      id: trackId,
      songRiffId: songRiffId,
      userId: 'user_1', // Would be passed as parameter
      name: _generateTrackName(songInfo, parameters),
      audioPath: audioPath,
      bpm: parameters.bpm,
      style: parameters.style,
      complexity: parameters.complexity,
      keySignature: parameters.keySignature,
      timeSignature: parameters.timeSignature,
      chordProgression: parameters.chordProgression,
      enabledInstruments: parameters.instruments,
      instrumentVolumes: parameters.instrumentVolumes,
      duration: parameters.duration,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      quality: _calculateTrackQuality(parameters),
      tags: _generateTags(parameters, songInfo),
    );
  }
  
  /// Generate audio file for backing track
  Future<String> _generateAudioFile(BackingTrackParameters parameters) async {
    // In a real implementation, this would:
    // 1. Use AI music generation (like AIVA, Amper, or local ML models)
    // 2. Combine pre-recorded loops intelligently
    // 3. Use procedural audio generation
    
    // For now, we'll return a simulated path
    final fileName = 'backing_track_${DateTime.now().millisecondsSinceEpoch}.mp3';
    return 'assets/audio/backing_tracks/$fileName';
  }
  
  /// Regenerate audio for customized track
  Future<String> _regenerateAudio(BackingTrack track) async {
    // Simulate audio regeneration
    final fileName = 'backing_track_${track.id}_${DateTime.now().millisecondsSinceEpoch}.mp3';
    return 'assets/audio/backing_tracks/$fileName';
  }
  
  // Helper methods
  String _generateCacheKey(String songRiffId, String userId, BackingTrackStyle? style, int? bpm, BackingTrackComplexity? complexity) {
    return '$songRiffId:$userId:${style?.name ?? 'auto'}:${bpm ?? 'auto'}:${complexity?.name ?? 'auto'}';
  }
  
  String _generateTrackId() {
    return 'bt_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }
  
  String _generateTrackName(SongRiffInfo songInfo, BackingTrackParameters parameters) {
    return '${songInfo.id} - ${parameters.style.displayName} (${parameters.bpm} BPM)';
  }
  
  (int min, int max) _calculateBpmRange(List<int> bpmPreferences) {
    if (bpmPreferences.isEmpty) return (80, 140);
    
    bpmPreferences.sort();
    final q1 = bpmPreferences[bpmPreferences.length ~/ 4];
    final q3 = bpmPreferences[(bpmPreferences.length * 3) ~/ 4];
    
    return (q1, q3);
  }
  
  BackingTrackComplexity _calculateComplexityPreference(double skillLevel) {
    if (skillLevel < 40) return BackingTrackComplexity.simple;
    if (skillLevel < 70) return BackingTrackComplexity.intermediate;
    return BackingTrackComplexity.advanced;
  }
  
  int _calculateOptimalBpm(UserMusicProfile userProfile, SongRiffInfo songInfo) {
    // Start with original BPM
    int optimalBpm = songInfo.originalBpm;
    
    // Adjust based on user's skill level
    if (userProfile.skillLevel < 50) {
      // Slow down for beginners
      optimalBpm = (optimalBpm * 0.8).round();
    } else if (userProfile.skillLevel > 80) {
      // Can handle faster for advanced players
      optimalBpm = (optimalBpm * 1.1).round();
    }
    
    // Keep within user's preferred range
    final range = userProfile.preferredBpmRange;
    optimalBpm = optimalBpm.clamp(range.min, range.max);
    
    return optimalBpm;
  }
  
  BackingTrackStyle _selectOptimalStyle(UserMusicProfile userProfile, SongRiffInfo songInfo) {
    final availableStyles = getAvailableStyles(songInfo.genre);
    
    // Default to first available style for the genre
    if (availableStyles.isEmpty) return BackingTrackStyle.rockClassic;
    
    // Simple selection based on user's skill level
    if (userProfile.skillLevel < 40) {
      // Prefer simpler styles for beginners
      return availableStyles.first;
    } else if (userProfile.skillLevel > 80) {
      // Can handle more complex styles
      return availableStyles.length > 2 ? availableStyles[2] : availableStyles.last;
    }
    
    // Intermediate level gets middle option
    return availableStyles.length > 1 ? availableStyles[1] : availableStyles.first;
  }
  
  List<TrackInstrument> _selectInstruments(BackingTrackStyle style, BackingTrackComplexity complexity, SongRiffInfo songInfo) {
    final baseInstruments = [TrackInstrument.drums, TrackInstrument.bass];
    
    switch (style) {
      case BackingTrackStyle.rockClassic:
      case BackingTrackStyle.rockPower:
        baseInstruments.addAll([TrackInstrument.rhythmGuitar, TrackInstrument.organ]);
        break;
      case BackingTrackStyle.metalHeavy:
      case BackingTrackStyle.metalThrash:
        baseInstruments.addAll([TrackInstrument.rhythmGuitar, TrackInstrument.leadGuitar]);
        break;
      case BackingTrackStyle.bluesTraditional:
        baseInstruments.addAll([TrackInstrument.piano, TrackInstrument.harmonica]);
        break;
      case BackingTrackStyle.jazzSwing:
        baseInstruments.addAll([TrackInstrument.piano, TrackInstrument.saxophone]);
        break;
      default:
        baseInstruments.add(TrackInstrument.rhythmGuitar);
    }
    
    // Add complexity-based instruments
    if (complexity == BackingTrackComplexity.advanced) {
      baseInstruments.addAll([TrackInstrument.strings, TrackInstrument.synthesizer]);
    }
    
    return baseInstruments.toSet().toList(); // Remove duplicates
  }
  
  Map<TrackInstrument, double> _calculateInstrumentVolumes(List<TrackInstrument> instruments, UserMusicProfile userProfile) {
    final volumes = <TrackInstrument, double>{};
    
    for (final instrument in instruments) {
      switch (instrument) {
        case TrackInstrument.drums:
          volumes[instrument] = 0.8; // Prominent but not overpowering
          break;
        case TrackInstrument.bass:
          volumes[instrument] = 0.7;
          break;
        case TrackInstrument.rhythmGuitar:
          volumes[instrument] = 0.5; // Lower to leave space for user's guitar
          break;
        case TrackInstrument.leadGuitar:
          volumes[instrument] = 0.3; // Very low, just for accents
          break;
        default:
          volumes[instrument] = 0.6;
      }
    }
    
    return volumes;
  }
  
  BackingTrackQuality _calculateTrackQuality(BackingTrackParameters parameters) {
    // Simple quality assessment based on parameters
    if (parameters.instruments.length >= 4 && parameters.complexity == BackingTrackComplexity.advanced) {
      return BackingTrackQuality.professional;
    } else if (parameters.instruments.length >= 3) {
      return BackingTrackQuality.high;
    } else if (parameters.instruments.length >= 2) {
      return BackingTrackQuality.medium;
    }
    return BackingTrackQuality.basic;
  }
  
  List<String> _generateTags(BackingTrackParameters parameters, SongRiffInfo songInfo) {
    final tags = <String>[
      songInfo.genre,
      parameters.style.name,
      parameters.complexity.name,
      '${parameters.bpm}bpm',
      parameters.keySignature,
      parameters.timeSignature,
    ];
    
    tags.addAll(songInfo.techniques);
    tags.addAll(parameters.instruments.map((i) => i.name));
    
    return tags;
  }
}

// Data Models
class BackingTrack {
  final String id;
  final String songRiffId;
  final String userId;
  final String name;
  final String audioPath;
  final int bpm;
  final BackingTrackStyle style;
  final BackingTrackComplexity complexity;
  final String keySignature;
  final String timeSignature;
  final List<String> chordProgression;
  final List<TrackInstrument> enabledInstruments;
  final Map<TrackInstrument, double> instrumentVolumes;
  final Duration duration;
  final DateTime createdAt;
  final DateTime lastModified;
  final BackingTrackQuality quality;
  final List<String> tags;
  
  const BackingTrack({
    required this.id,
    required this.songRiffId,
    required this.userId,
    required this.name,
    required this.audioPath,
    required this.bpm,
    required this.style,
    required this.complexity,
    required this.keySignature,
    required this.timeSignature,
    required this.chordProgression,
    required this.enabledInstruments,
    required this.instrumentVolumes,
    required this.duration,
    required this.createdAt,
    required this.lastModified,
    required this.quality,
    required this.tags,
  });
  
  BackingTrack copyWith({
    String? id,
    String? songRiffId,
    String? userId,
    String? name,
    String? audioPath,
    int? bpm,
    BackingTrackStyle? style,
    BackingTrackComplexity? complexity,
    String? keySignature,
    String? timeSignature,
    List<String>? chordProgression,
    List<TrackInstrument>? enabledInstruments,
    Map<TrackInstrument, double>? instrumentVolumes,
    Duration? duration,
    DateTime? createdAt,
    DateTime? lastModified,
    BackingTrackQuality? quality,
    List<String>? tags,
  }) {
    return BackingTrack(
      id: id ?? this.id,
      songRiffId: songRiffId ?? this.songRiffId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      audioPath: audioPath ?? this.audioPath,
      bpm: bpm ?? this.bpm,
      style: style ?? this.style,
      complexity: complexity ?? this.complexity,
      keySignature: keySignature ?? this.keySignature,
      timeSignature: timeSignature ?? this.timeSignature,
      chordProgression: chordProgression ?? this.chordProgression,
      enabledInstruments: enabledInstruments ?? this.enabledInstruments,
      instrumentVolumes: instrumentVolumes ?? this.instrumentVolumes,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      quality: quality ?? this.quality,
      tags: tags ?? this.tags,
    );
  }
}

class BpmRange {
  final int min;
  final int max;
  
  const BpmRange({required this.min, required this.max});
}

class UserMusicProfile {
  final double skillLevel;
  final List<String> preferredGenres;
  final BpmRange preferredBpmRange;
  final int medianBpm;
  final BackingTrackComplexity complexityPreference;
  final List<String> techniqueStrengths;
  final List<String> techniqueWeaknesses;
  final int practiceHoursTotal;
  
  const UserMusicProfile({
    required this.skillLevel,
    required this.preferredGenres,
    required this.preferredBpmRange,
    required this.medianBpm,
    required this.complexityPreference,
    required this.techniqueStrengths,
    required this.techniqueWeaknesses,
    required this.practiceHoursTotal,
  });
  
  factory UserMusicProfile.defaultProfile() {
    return const UserMusicProfile(
      skillLevel: 30.0,
      preferredGenres: ['rock'],
      preferredBpmRange: BpmRange(min: 80, max: 120),
      medianBpm: 100,
      complexityPreference: BackingTrackComplexity.simple,
      techniqueStrengths: ['rhythm'],
      techniqueWeaknesses: ['lead', 'bending'],
      practiceHoursTotal: 0,
    );
  }
}

class SongRiffInfo {
  final String id;
  final String genre;
  final int originalBpm;
  final String keySignature;
  final String timeSignature;
  final String difficulty;
  final List<String> techniques;
  final List<String> chordProgression;
  final Duration duration;
  
  const SongRiffInfo({
    required this.id,
    required this.genre,
    required this.originalBpm,
    required this.keySignature,
    required this.timeSignature,
    required this.difficulty,
    required this.techniques,
    required this.chordProgression,
    required this.duration,
  });
}

class BackingTrackParameters {
  final int bpm;
  final BackingTrackStyle style;
  final BackingTrackComplexity complexity;
  final String keySignature;
  final String timeSignature;
  final List<String> chordProgression;
  final List<TrackInstrument> instruments;
  final Map<TrackInstrument, double> instrumentVolumes;
  final Duration duration;
  
  const BackingTrackParameters({
    required this.bpm,
    required this.style,
    required this.complexity,
    required this.keySignature,
    required this.timeSignature,
    required this.chordProgression,
    required this.instruments,
    required this.instrumentVolumes,
    required this.duration,
  });
}

// Enums
enum BackingTrackStyle {
  // Rock styles
  rockClassic('Classic Rock'),
  rockPower('Power Rock'),
  rockAlternative('Alternative Rock'),
  rockProgressive('Progressive Rock'),
  
  // Metal styles
  metalHeavy('Heavy Metal'),
  metalProgressive('Progressive Metal'),
  metalThrash('Thrash Metal'),
  metalPower('Power Metal'),
  
  // Blues styles
  bluesTraditional('Traditional Blues'),
  bluesRock('Blues Rock'),
  bluesJazz('Jazz Blues'),
  bluesCountry('Country Blues'),
  
  // Jazz styles
  jazzSwing('Swing Jazz'),
  jazzFusion('Jazz Fusion'),
  jazzSmooth('Smooth Jazz'),
  jazzLatin('Latin Jazz'),
  
  // Acoustic styles
  acousticFolk('Acoustic Folk'),
  acousticCountry('Acoustic Country'),
  acousticClassical('Classical'),
  acousticFingerstyle('Fingerstyle');
  
  const BackingTrackStyle(this.displayName);
  final String displayName;
}

enum BackingTrackComplexity {
  simple('Simple'),
  intermediate('Intermediate'),
  advanced('Advanced'),
  expert('Expert');
  
  const BackingTrackComplexity(this.displayName);
  final String displayName;
}

enum TrackInstrument {
  drums('Drums'),
  bass('Bass'),
  rhythmGuitar('Rhythm Guitar'),
  leadGuitar('Lead Guitar'),
  piano('Piano'),
  organ('Organ'),
  synthesizer('Synthesizer'),
  strings('Strings'),
  brass('Brass'),
  saxophone('Saxophone'),
  harmonica('Harmonica'),
  percussion('Percussion');
  
  const TrackInstrument(this.displayName);
  final String displayName;
}

enum BackingTrackQuality {
  basic('Basic'),
  medium('Medium'),
  high('High'),
  professional('Professional');
  
  const BackingTrackQuality(this.displayName);
  final String displayName;
}

class BackingTrackException implements Exception {
  final String message;
  
  const BackingTrackException(this.message);
  
  @override
  String toString() => 'BackingTrackException: $message';
}

// Riverpod providers
final intelligentBackingTracksServiceProvider = Provider<IntelligentBackingTracksService>((ref) {
  final statsService = ref.read(statsServiceProvider);
  final audioPlayerService = ref.read(audioPlayerServiceProvider.notifier);
  return IntelligentBackingTracksService(statsService, audioPlayerService);
});

final backingTrackProvider = FutureProvider.family<BackingTrack, BackingTrackRequest>((ref, request) async {
  final service = ref.read(intelligentBackingTracksServiceProvider);
  return service.generateBackingTrack(
    songRiffId: request.songRiffId,
    userId: request.userId,
    preferredStyle: request.preferredStyle,
    customBpm: request.customBpm,
    complexity: request.complexity,
  );
});

final userBackingTracksHistoryProvider = FutureProvider.family<List<BackingTrack>, String>((ref, userId) async {
  final service = ref.read(intelligentBackingTracksServiceProvider);
  return service.getUserBackingTracksHistory(userId);
});

final availableStylesProvider = Provider.family<List<BackingTrackStyle>, String>((ref, genre) {
  final service = ref.read(intelligentBackingTracksServiceProvider);
  return service.getAvailableStyles(genre);
});

class BackingTrackRequest {
  final String songRiffId;
  final String userId;
  final BackingTrackStyle? preferredStyle;
  final int? customBpm;
  final BackingTrackComplexity? complexity;
  
  const BackingTrackRequest({
    required this.songRiffId,
    required this.userId,
    this.preferredStyle,
    this.customBpm,
    this.complexity,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackingTrackRequest &&
        other.songRiffId == songRiffId &&
        other.userId == userId &&
        other.preferredStyle == preferredStyle &&
        other.customBpm == customBpm &&
        other.complexity == complexity;
  }
  
  @override
  int get hashCode {
    return Object.hash(songRiffId, userId, preferredStyle, customBpm, complexity);
  }
}