import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/data/chords_data.dart';
import '../../../../core/theme/arcade_theme.dart';

/// Game state for a single lesson
class LessonGameState {
  final ChordData chord;
  final int currentAttempt;
  final int totalAttempts;
  final int score;
  final int combo;
  final int maxCombo;
  final List<double> accuracies;
  final bool isListening;
  final bool isComplete;
  final String? lastFeedback;
  final double? lastAccuracy;

  const LessonGameState({
    required this.chord,
    this.currentAttempt = 0,
    this.totalAttempts = 10,
    this.score = 0,
    this.combo = 0,
    this.maxCombo = 0,
    this.accuracies = const [],
    this.isListening = false,
    this.isComplete = false,
    this.lastFeedback,
    this.lastAccuracy,
  });

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

  LessonGameState copyWith({
    ChordData? chord,
    int? currentAttempt,
    int? totalAttempts,
    int? score,
    int? combo,
    int? maxCombo,
    List<double>? accuracies,
    bool? isListening,
    bool? isComplete,
    String? lastFeedback,
    double? lastAccuracy,
  }) {
    return LessonGameState(
      chord: chord ?? this.chord,
      currentAttempt: currentAttempt ?? this.currentAttempt,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      score: score ?? this.score,
      combo: combo ?? this.combo,
      maxCombo: maxCombo ?? this.maxCombo,
      accuracies: accuracies ?? this.accuracies,
      isListening: isListening ?? this.isListening,
      isComplete: isComplete ?? this.isComplete,
      lastFeedback: lastFeedback,
      lastAccuracy: lastAccuracy,
    );
  }
}

/// Game state notifier for a lesson
class LessonGameNotifier extends StateNotifier<LessonGameState> {
  LessonGameNotifier(ChordData chord)
      : super(LessonGameState(chord: chord));

  void startListening() {
    state = state.copyWith(isListening: true);
  }

  void stopListening() {
    state = state.copyWith(isListening: false);
  }

  /// Process an attempt with the detected accuracy
  void processAttempt(double accuracy) {
    if (state.isComplete) return;

    // Calculate points
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

    // Update state
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

  /// Reset the game
  void reset() {
    state = LessonGameState(chord: state.chord);
  }
}

/// Provider factory for lesson games
final lessonGameProvider = StateNotifierProvider.family<LessonGameNotifier, LessonGameState, int>(
  (ref, level) {
    final chord = ChordsData.getChordByLevel(level);
    return LessonGameNotifier(chord ?? ChordsData.allChords.first);
  },
);

/// Global game progress state
class GameProgress {
  final Map<int, int> levelStars; // level -> stars (0-3)
  final Map<int, int> highScores; // level -> high score
  final int unlockedLevel; // highest unlocked level
  final int totalHighScore;

  const GameProgress({
    this.levelStars = const {},
    this.highScores = const {},
    this.unlockedLevel = 1,
    this.totalHighScore = 0,
  });

  bool isLevelUnlocked(int level) => level <= unlockedLevel;

  int getStars(int level) => levelStars[level] ?? 0;

  int getHighScore(int level) => highScores[level] ?? 0;

  GameProgress copyWith({
    Map<int, int>? levelStars,
    Map<int, int>? highScores,
    int? unlockedLevel,
    int? totalHighScore,
  }) {
    return GameProgress(
      levelStars: levelStars ?? this.levelStars,
      highScores: highScores ?? this.highScores,
      unlockedLevel: unlockedLevel ?? this.unlockedLevel,
      totalHighScore: totalHighScore ?? this.totalHighScore,
    );
  }
}

/// Progress notifier that persists to SharedPreferences
class GameProgressNotifier extends StateNotifier<GameProgress> {
  static const String _starsKey = 'arcade_level_stars';
  static const String _scoresKey = 'arcade_high_scores';
  static const String _unlockedKey = 'arcade_unlocked_level';

  GameProgressNotifier() : super(const GameProgress()) {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load stars
      final starsStr = prefs.getString(_starsKey);
      final stars = <int, int>{};
      if (starsStr != null) {
        final parts = starsStr.split(',');
        for (final part in parts) {
          final kv = part.split(':');
          if (kv.length == 2) {
            stars[int.parse(kv[0])] = int.parse(kv[1]);
          }
        }
      }

      // Load high scores
      final scoresStr = prefs.getString(_scoresKey);
      final scores = <int, int>{};
      if (scoresStr != null) {
        final parts = scoresStr.split(',');
        for (final part in parts) {
          final kv = part.split(':');
          if (kv.length == 2) {
            scores[int.parse(kv[0])] = int.parse(kv[1]);
          }
        }
      }

      // Load unlocked level
      final unlocked = prefs.getInt(_unlockedKey) ?? 1;

      // Calculate total high score
      final total = scores.values.fold(0, (a, b) => a + b);

      state = GameProgress(
        levelStars: stars,
        highScores: scores,
        unlockedLevel: unlocked,
        totalHighScore: total,
      );
    } catch (e) {
      // Keep default state on error
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save stars
      final starsStr = state.levelStars.entries
          .map((e) => '${e.key}:${e.value}')
          .join(',');
      await prefs.setString(_starsKey, starsStr);

      // Save high scores
      final scoresStr = state.highScores.entries
          .map((e) => '${e.key}:${e.value}')
          .join(',');
      await prefs.setString(_scoresKey, scoresStr);

      // Save unlocked level
      await prefs.setInt(_unlockedKey, state.unlockedLevel);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Complete a level with the given score and stars
  Future<void> completeLevel(int level, int score, int stars) async {
    final newStars = Map<int, int>.from(state.levelStars);
    final newScores = Map<int, int>.from(state.highScores);

    // Update stars if better
    final currentStars = newStars[level] ?? 0;
    if (stars > currentStars) {
      newStars[level] = stars;
    }

    // Update high score if better
    final currentScore = newScores[level] ?? 0;
    if (score > currentScore) {
      newScores[level] = score;
    }

    // Unlock next level if passed (at least 1 star)
    int newUnlocked = state.unlockedLevel;
    if (stars >= 1 && level >= state.unlockedLevel && level < 10) {
      newUnlocked = level + 1;
    }

    // Calculate total
    final total = newScores.values.fold(0, (a, b) => a + b);

    state = state.copyWith(
      levelStars: newStars,
      highScores: newScores,
      unlockedLevel: newUnlocked,
      totalHighScore: total,
    );

    await _saveProgress();
  }

  /// Unlock levels based on test results
  Future<void> unlockFromTest(int correctCount) async {
    int unlockLevel;
    if (correctCount <= 1) {
      unlockLevel = 1;
    } else if (correctCount <= 3) {
      unlockLevel = 3;
    } else {
      unlockLevel = 5;
    }

    if (unlockLevel > state.unlockedLevel) {
      state = state.copyWith(unlockedLevel: unlockLevel);
      await _saveProgress();
    }
  }

  /// Reset all progress
  Future<void> resetProgress() async {
    state = const GameProgress();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_starsKey);
    await prefs.remove(_scoresKey);
    await prefs.remove(_unlockedKey);
  }
}

/// Global game progress provider
final gameProgressProvider =
    StateNotifierProvider<GameProgressNotifier, GameProgress>(
  (ref) => GameProgressNotifier(),
);

/// Level test state
class LevelTestState {
  final int currentChordIndex;
  final int correctCount;
  final bool isListening;
  final bool isComplete;
  final List<bool> results;

  const LevelTestState({
    this.currentChordIndex = 0,
    this.correctCount = 0,
    this.isListening = false,
    this.isComplete = false,
    this.results = const [],
  });

  ChordData get currentChord => ChordsData.testChords[currentChordIndex];

  int get totalChords => ChordsData.testChords.length;

  LevelTestState copyWith({
    int? currentChordIndex,
    int? correctCount,
    bool? isListening,
    bool? isComplete,
    List<bool>? results,
  }) {
    return LevelTestState(
      currentChordIndex: currentChordIndex ?? this.currentChordIndex,
      correctCount: correctCount ?? this.correctCount,
      isListening: isListening ?? this.isListening,
      isComplete: isComplete ?? this.isComplete,
      results: results ?? this.results,
    );
  }
}

/// Level test notifier
class LevelTestNotifier extends StateNotifier<LevelTestState> {
  LevelTestNotifier() : super(const LevelTestState());

  void startListening() {
    state = state.copyWith(isListening: true);
  }

  void stopListening() {
    state = state.copyWith(isListening: false);
  }

  void processAttempt(bool correct) {
    final newResults = [...state.results, correct];
    final newCorrectCount = state.correctCount + (correct ? 1 : 0);
    final nextIndex = state.currentChordIndex + 1;
    final isComplete = nextIndex >= state.totalChords;

    state = state.copyWith(
      currentChordIndex: isComplete ? state.currentChordIndex : nextIndex,
      correctCount: newCorrectCount,
      isListening: false,
      isComplete: isComplete,
      results: newResults,
    );
  }

  void reset() {
    state = const LevelTestState();
  }
}

/// Level test provider
final levelTestProvider =
    StateNotifierProvider<LevelTestNotifier, LevelTestState>(
  (ref) => LevelTestNotifier(),
);
