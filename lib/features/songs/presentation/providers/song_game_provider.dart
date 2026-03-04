import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/data/songs_data.dart';
import '../../../../core/data/chords_data.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../lessons/presentation/providers/game_provider.dart';

/// Game state for a single song
class SongGameState {
  final SongData song;
  final int currentAttempt;
  final int score;
  final int combo;
  final int maxCombo;
  final List<double> accuracies;
  final bool isListening;
  final bool isComplete;
  final String? lastFeedback;
  final double? lastAccuracy;
  final String? aiFeedback;
  final RoundPhase roundPhase;
  final int countdownValue;

  const SongGameState({
    required this.song,
    this.currentAttempt = 0,
    this.score = 0,
    this.combo = 0,
    this.maxCombo = 0,
    this.accuracies = const [],
    this.isListening = false,
    this.isComplete = false,
    this.lastFeedback,
    this.lastAccuracy,
    this.aiFeedback,
    this.roundPhase = RoundPhase.idle,
    this.countdownValue = 3,
  });

  int get totalAttempts => song.totalAttempts;

  /// Current chord changes per attempt based on the song's chord sequence
  ChordData? get currentChord => song.getChordAt(currentAttempt);

  /// Preview of the next chord (null if last attempt)
  ChordData? get nextChord {
    if (currentAttempt + 1 >= totalAttempts) return null;
    return song.getChordAt(currentAttempt + 1);
  }

  double get averageAccuracy {
    if (accuracies.isEmpty) return 0;
    return accuracies.reduce((a, b) => a + b) / accuracies.length;
  }

  int get stars {
    final accuracy = averageAccuracy;
    if (accuracy >= 0.95) return 3;
    if (accuracy >= 0.85) return 2;
    if (accuracy >= 0.70) return 1;
    return 0;
  }

  SongGameState copyWith({
    SongData? song,
    int? currentAttempt,
    int? score,
    int? combo,
    int? maxCombo,
    List<double>? accuracies,
    bool? isListening,
    bool? isComplete,
    String? lastFeedback,
    double? lastAccuracy,
    String? aiFeedback,
    RoundPhase? roundPhase,
    int? countdownValue,
  }) {
    return SongGameState(
      song: song ?? this.song,
      currentAttempt: currentAttempt ?? this.currentAttempt,
      score: score ?? this.score,
      combo: combo ?? this.combo,
      maxCombo: maxCombo ?? this.maxCombo,
      accuracies: accuracies ?? this.accuracies,
      isListening: isListening ?? this.isListening,
      isComplete: isComplete ?? this.isComplete,
      lastFeedback: lastFeedback,
      lastAccuracy: lastAccuracy,
      aiFeedback: aiFeedback,
      roundPhase: roundPhase ?? this.roundPhase,
      countdownValue: countdownValue ?? this.countdownValue,
    );
  }
}

/// Song game state notifier
class SongGameNotifier extends StateNotifier<SongGameState> {
  SongGameNotifier(SongData song) : super(SongGameState(song: song));

  void startListening() {
    state = state.copyWith(isListening: true);
  }

  void stopListening() {
    state = state.copyWith(isListening: false);
  }

  /// Process an attempt with the detected accuracy
  void processAttempt(double accuracy) {
    if (state.isComplete) return;

    final points = FeedbackColors.pointsFromAccuracy(accuracy);
    final feedback = FeedbackColors.labelFromAccuracy(accuracy);

    // Update combo
    int newCombo = state.combo;
    if (points > 0) {
      newCombo = state.combo + 1;
    } else {
      newCombo = 0;
    }

    // Calculate score with combo multiplier
    final multiplier = newCombo > 0 ? newCombo : 1;
    final finalPoints = points * multiplier;

    // Update state — currentAttempt increments, so currentChord getter auto-advances
    final newAttempt = state.currentAttempt + 1;
    final newAccuracies = [...state.accuracies, accuracy];
    final isComplete = newAttempt >= state.totalAttempts;

    state = state.copyWith(
      currentAttempt: newAttempt,
      score: state.score + finalPoints,
      combo: newCombo,
      maxCombo: newCombo > state.maxCombo ? newCombo : state.maxCombo,
      accuracies: newAccuracies,
      isListening: false,
      isComplete: isComplete,
      lastFeedback: feedback,
      lastAccuracy: accuracy,
    );
  }

  void setPhase(RoundPhase phase) {
    state = state.copyWith(roundPhase: phase);
  }

  void setCountdown(int value) {
    state = state.copyWith(countdownValue: value);
  }

  void setAiFeedback(String feedback) {
    state = state.copyWith(aiFeedback: feedback);
  }

  void reset() {
    state = SongGameState(song: state.song);
  }
}

/// Provider factory for song games (keyed by songId)
final songGameProvider =
    StateNotifierProvider.family<SongGameNotifier, SongGameState, String>(
  (ref, songId) {
    final song = SongsData.getSongById(songId);
    return SongGameNotifier(song ?? SongsData.allSongs.first);
  },
);

/// Song progress state
class SongProgress {
  final Map<String, int> songStars; // songId -> stars (0-3)
  final Map<String, int> songHighScores; // songId -> high score
  final String? preferredGenre;

  const SongProgress({
    this.songStars = const {},
    this.songHighScores = const {},
    this.preferredGenre,
  });

  int getStars(String songId) => songStars[songId] ?? 0;
  int getHighScore(String songId) => songHighScores[songId] ?? 0;

  SongProgress copyWith({
    Map<String, int>? songStars,
    Map<String, int>? songHighScores,
    String? preferredGenre,
  }) {
    return SongProgress(
      songStars: songStars ?? this.songStars,
      songHighScores: songHighScores ?? this.songHighScores,
      preferredGenre: preferredGenre ?? this.preferredGenre,
    );
  }
}

/// Song progress notifier with SharedPreferences persistence
class SongProgressNotifier extends StateNotifier<SongProgress> {
  static const String _starsKey = 'song_stars';
  static const String _scoresKey = 'song_high_scores';
  static const String _genreKey = 'song_preferred_genre';

  SongProgressNotifier() : super(const SongProgress()) {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load stars
      final starsStr = prefs.getString(_starsKey);
      final stars = <String, int>{};
      if (starsStr != null && starsStr.isNotEmpty) {
        final parts = starsStr.split(',');
        for (final part in parts) {
          final kv = part.split(':');
          if (kv.length == 2) {
            stars[kv[0]] = int.parse(kv[1]);
          }
        }
      }

      // Load high scores
      final scoresStr = prefs.getString(_scoresKey);
      final scores = <String, int>{};
      if (scoresStr != null && scoresStr.isNotEmpty) {
        final parts = scoresStr.split(',');
        for (final part in parts) {
          final kv = part.split(':');
          if (kv.length == 2) {
            scores[kv[0]] = int.parse(kv[1]);
          }
        }
      }

      // Load preferred genre
      final genre = prefs.getString(_genreKey);

      state = SongProgress(
        songStars: stars,
        songHighScores: scores,
        preferredGenre: genre,
      );
    } catch (e) {
      // Keep default state on error
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final starsStr = state.songStars.entries
          .map((e) => '${e.key}:${e.value}')
          .join(',');
      await prefs.setString(_starsKey, starsStr);

      final scoresStr = state.songHighScores.entries
          .map((e) => '${e.key}:${e.value}')
          .join(',');
      await prefs.setString(_scoresKey, scoresStr);

      if (state.preferredGenre != null) {
        await prefs.setString(_genreKey, state.preferredGenre!);
      }
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Complete a song with the given score and stars
  Future<void> completeSong(String songId, int score, int stars) async {
    final newStars = Map<String, int>.from(state.songStars);
    final newScores = Map<String, int>.from(state.songHighScores);

    final currentStars = newStars[songId] ?? 0;
    if (stars > currentStars) {
      newStars[songId] = stars;
    }

    final currentScore = newScores[songId] ?? 0;
    if (score > currentScore) {
      newScores[songId] = score;
    }

    state = state.copyWith(
      songStars: newStars,
      songHighScores: newScores,
    );

    await _saveProgress();
  }

  /// Set the user's preferred genre
  Future<void> setPreferredGenre(String genre) async {
    state = state.copyWith(preferredGenre: genre);
    await _saveProgress();
  }
}

/// Global song progress provider
final songProgressProvider =
    StateNotifierProvider<SongProgressNotifier, SongProgress>(
  (ref) => SongProgressNotifier(),
);
