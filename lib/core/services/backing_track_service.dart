import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Backing track information model
class BackingTrack {
  final String id;
  final String name;
  final String artist;
  final String genre;
  final int bpm;
  final Duration duration;
  final String audioPath; // Local asset path or URL
  final String? albumImagePath;
  final List<String> techniques;
  final String difficulty;
  
  const BackingTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.genre,
    required this.bpm,
    required this.duration,
    required this.audioPath,
    this.albumImagePath,
    required this.techniques,
    required this.difficulty,
  });
  
  /// Check if backing track has local audio
  bool get hasAudio => audioPath.isNotEmpty;
  
  /// Get full audio URL/path
  String get fullAudioPath {
    if (audioPath.startsWith('http')) {
      return audioPath; // External URL
    }
    return audioPath; // Local asset path (already includes assets/ prefix)
  }
}

/// Service for managing backing tracks
class BackingTrackService {
  
  /// Get all available backing tracks
  List<BackingTrack> getAllBackingTracks() {
    return [
      // Enter Sandman - Metallica
      BackingTrack(
        id: 'enter_sandman_main',
        name: 'Enter Sandman - Main Riff',
        artist: 'Metallica',
        genre: 'metal',
        bpm: 116,
        duration: const Duration(minutes: 3, seconds: 30),
        audioPath: '', // Demo - ready for real backing track
        albumImagePath: 'assets/images/metallica_black_album.jpg',
        techniques: ['palm-muting', 'alternate-picking', 'downstrokes'],
        difficulty: 'medium',
      ),
      
      // Hells Bells - AC/DC
      BackingTrack(
        id: 'hells_bells_main',
        name: 'Hells Bells - Main Riff',
        artist: 'AC/DC',
        genre: 'rock',
        bpm: 108,
        duration: const Duration(minutes: 4, seconds: 0),
        audioPath: '', // No audio yet
        albumImagePath: 'assets/images/acdc_back_in_black.jpg',
        techniques: ['power-chords', 'palm-muting'],
        difficulty: 'medium',
      ),
      
      // Crazy Train - Ozzy Osbourne
      BackingTrack(
        id: 'crazy_train_main',
        name: 'Crazy Train - Main Riff',
        artist: 'Ozzy Osbourne',
        genre: 'metal',
        bpm: 144,
        duration: const Duration(minutes: 3, seconds: 45),
        audioPath: '', // No audio yet
        albumImagePath: 'assets/images/ozzy_blizzard.jpg',
        techniques: ['alternate-picking', 'bending', 'vibrato'],
        difficulty: 'hard',
      ),
      
      // Smoke on the Water - Deep Purple
      BackingTrack(
        id: 'smoke_on_the_water_main',
        name: 'Smoke on the Water - Main Riff',
        artist: 'Deep Purple',
        genre: 'rock',
        bpm: 112,
        duration: const Duration(minutes: 3, seconds: 20),
        audioPath: '', // No audio yet
        albumImagePath: 'assets/images/deep_purple_machine_head.jpg',
        techniques: ['power-chords', 'palm-muting'],
        difficulty: 'easy',
      ),
      
      // Paranoid - Black Sabbath
      BackingTrack(
        id: 'paranoid_main',
        name: 'Paranoid - Main Riff',
        artist: 'Black Sabbath',
        genre: 'metal',
        bpm: 164,
        duration: const Duration(minutes: 2, seconds: 50),
        audioPath: '', // No audio yet
        albumImagePath: 'assets/images/black_sabbath_paranoid.jpg',
        techniques: ['power-chords', 'fast-picking', 'palm-muting'],
        difficulty: 'medium',
      ),
      
      // Back in Black - AC/DC
      BackingTrack(
        id: 'back_in_black_main',
        name: 'Back in Black - Main Riff',
        artist: 'AC/DC',
        genre: 'rock',
        bpm: 94,
        duration: const Duration(minutes: 3, seconds: 55),
        audioPath: '', // No audio yet
        albumImagePath: 'assets/images/acdc_back_in_black.jpg',
        techniques: ['power-chords', 'palm-muting', 'ghost-notes'],
        difficulty: 'medium',
      ),
    ];
  }
  
  /// Get backing track by ID
  BackingTrack? getBackingTrackById(String id) {
    try {
      return getAllBackingTracks().firstWhere((track) => track.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Get backing tracks by genre
  List<BackingTrack> getBackingTracksByGenre(String genre) {
    return getAllBackingTracks()
        .where((track) => track.genre.toLowerCase() == genre.toLowerCase())
        .toList();
  }
  
  /// Get backing tracks by difficulty
  List<BackingTrack> getBackingTracksByDifficulty(String difficulty) {
    return getAllBackingTracks()
        .where((track) => track.difficulty.toLowerCase() == difficulty.toLowerCase())
        .toList();
  }
  
  /// Search backing tracks by name or artist
  List<BackingTrack> searchBackingTracks(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllBackingTracks()
        .where((track) => 
            track.name.toLowerCase().contains(lowerQuery) ||
            track.artist.toLowerCase().contains(lowerQuery))
        .toList();
  }
}

/// Riverpod provider for BackingTrackService
final backingTrackServiceProvider = Provider<BackingTrackService>((ref) {
  return BackingTrackService();
});

/// Provider for all backing tracks
final allBackingTracksProvider = Provider<List<BackingTrack>>((ref) {
  final service = ref.read(backingTrackServiceProvider);
  return service.getAllBackingTracks();
});

/// Provider for backing track by ID
final backingTrackByIdProvider = Provider.family<BackingTrack?, String>((ref, id) {
  final service = ref.read(backingTrackServiceProvider);
  return service.getBackingTrackById(id);
});

/// Provider for backing tracks by genre
final backingTracksByGenreProvider = Provider.family<List<BackingTrack>, String>((ref, genre) {
  final service = ref.read(backingTrackServiceProvider);
  return service.getBackingTracksByGenre(genre);
});

/// Provider for backing tracks by difficulty
final backingTracksByDifficultyProvider = Provider.family<List<BackingTrack>, String>((ref, difficulty) {
  final service = ref.read(backingTrackServiceProvider);
  return service.getBackingTracksByDifficulty(difficulty);
});