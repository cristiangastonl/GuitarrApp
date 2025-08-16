import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';

/// Chord Recognition Service
/// Uses ML-based audio processing to detect guitar chords in real-time
/// Provides visual feedback and accuracy scoring for practice sessions
class ChordRecognitionService {
  // Chord templates for pattern matching
  static const Map<String, ChordTemplate> _chordTemplates = {
    // Major chords
    'C': ChordTemplate(
      name: 'C Major',
      frequencies: [261.63, 329.63, 392.00, 523.25, 659.25], // C E G C E
      fingerPattern: [0, 1, 0, 2, 3, 0], // Fret positions
      difficulty: ChordDifficulty.beginner,
      type: ChordType.major,
    ),
    'G': ChordTemplate(
      name: 'G Major',
      frequencies: [196.00, 246.94, 293.66, 392.00, 493.88, 587.33], // G B D G B G
      fingerPattern: [3, 2, 0, 0, 3, 3],
      difficulty: ChordDifficulty.beginner,
      type: ChordType.major,
    ),
    'D': ChordTemplate(
      name: 'D Major',
      frequencies: [146.83, 220.00, 293.66, 369.99], // D A D F#
      fingerPattern: [-1, -1, 0, 2, 3, 2], // -1 = muted string
      difficulty: ChordDifficulty.beginner,
      type: ChordType.major,
    ),
    'A': ChordTemplate(
      name: 'A Major',
      frequencies: [110.00, 164.81, 220.00, 277.18, 329.63], // A C# E A C#
      fingerPattern: [-1, 0, 2, 2, 2, 0],
      difficulty: ChordDifficulty.beginner,
      type: ChordType.major,
    ),
    'E': ChordTemplate(
      name: 'E Major',
      frequencies: [82.41, 123.47, 164.81, 207.65, 246.94, 329.63], // E B E G# B E
      fingerPattern: [0, 2, 2, 1, 0, 0],
      difficulty: ChordDifficulty.beginner,
      type: ChordType.major,
    ),
    
    // Minor chords
    'Am': ChordTemplate(
      name: 'A Minor',
      frequencies: [110.00, 164.81, 220.00, 261.63, 329.63], // A C E A C
      fingerPattern: [-1, 0, 2, 2, 1, 0],
      difficulty: ChordDifficulty.beginner,
      type: ChordType.minor,
    ),
    'Em': ChordTemplate(
      name: 'E Minor',
      frequencies: [82.41, 123.47, 164.81, 196.00, 246.94, 329.63], // E B E G B E
      fingerPattern: [0, 2, 2, 0, 0, 0],
      difficulty: ChordDifficulty.beginner,
      type: ChordType.minor,
    ),
    'Dm': ChordTemplate(
      name: 'D Minor',
      frequencies: [146.83, 220.00, 293.66, 349.23], // D A D F
      fingerPattern: [-1, -1, 0, 2, 3, 1],
      difficulty: ChordDifficulty.beginner,
      type: ChordType.minor,
    ),
    
    // Seventh chords
    'G7': ChordTemplate(
      name: 'G7 Dominant',
      frequencies: [196.00, 246.94, 293.66, 349.23, 493.88], // G B D F B
      fingerPattern: [3, 2, 0, 0, 0, 1],
      difficulty: ChordDifficulty.intermediate,
      type: ChordType.dominant7,
    ),
    'C7': ChordTemplate(
      name: 'C7 Dominant',
      frequencies: [261.63, 329.63, 392.00, 466.16, 659.25], // C E G Bb E
      fingerPattern: [0, 1, 3, 2, 3, 1],
      difficulty: ChordDifficulty.intermediate,
      type: ChordType.dominant7,
    ),
    
    // Barre chords
    'F': ChordTemplate(
      name: 'F Major (Barre)',
      frequencies: [174.61, 220.00, 261.63, 349.23, 440.00, 523.25], // F A C F A F
      fingerPattern: [1, 1, 3, 3, 2, 1],
      difficulty: ChordDifficulty.advanced,
      type: ChordType.major,
      isBarre: true,
    ),
    'Bm': ChordTemplate(
      name: 'B Minor (Barre)',
      frequencies: [123.47, 184.99, 246.94, 293.66, 369.99, 440.00], // B F# B D F# B
      fingerPattern: [2, 2, 4, 4, 3, 2],
      difficulty: ChordDifficulty.advanced,
      type: ChordType.minor,
      isBarre: true,
    ),
  };
  
  // Audio analysis parameters
  static const int _sampleRate = 44100;
  static const int _fftSize = 2048;
  static const double _minConfidence = 0.6;
  static const double _frequencyTolerance = 10.0; // Hz
  
  // Recognition state
  ChordRecognitionResult? _lastRecognition;
  final List<ChordRecognitionResult> _recognitionHistory = [];
  DateTime? _lastAnalysisTime;
  
  /// Analyze audio buffer and detect chord
  Future<ChordRecognitionResult> recognizeChord(Float32List audioBuffer) async {
    try {
      _lastAnalysisTime = DateTime.now();
      
      // Perform FFT analysis
      final frequencies = await _performFFT(audioBuffer);
      
      // Extract fundamental frequencies
      final fundamentals = _extractFundamentalFrequencies(frequencies);
      
      // Match against chord templates
      final matches = _matchChordTemplates(fundamentals);
      
      // Select best match
      final bestMatch = _selectBestMatch(matches);
      
      final result = ChordRecognitionResult(
        detectedChord: bestMatch?.chordName,
        confidence: bestMatch?.confidence ?? 0.0,
        fundamentalFrequencies: fundamentals,
        timestamp: DateTime.now(),
        accuracy: _calculateAccuracy(bestMatch),
        suggestions: _generateSuggestions(bestMatch, fundamentals),
      );
      
      _lastRecognition = result;
      _recognitionHistory.add(result);
      
      // Keep only last 100 recognitions
      if (_recognitionHistory.length > 100) {
        _recognitionHistory.removeAt(0);
      }
      
      return result;
    } catch (e) {
      throw ChordRecognitionException('Failed to recognize chord: $e');
    }
  }
  
  /// Get chord template by name
  ChordTemplate? getChordTemplate(String chordName) {
    return _chordTemplates[chordName];
  }
  
  /// Get all available chord templates
  Map<String, ChordTemplate> getAllChordTemplates() {
    return Map.from(_chordTemplates);
  }
  
  /// Get chords by difficulty level
  List<ChordTemplate> getChordsByDifficulty(ChordDifficulty difficulty) {
    return _chordTemplates.values
        .where((template) => template.difficulty == difficulty)
        .toList();
  }
  
  /// Get chord progression suggestions
  List<String> getChordProgressionSuggestions(String currentChord) {
    final progressions = {
      'C': ['Am', 'F', 'G', 'Dm'],
      'G': ['Em', 'C', 'D', 'Am'],
      'D': ['Bm', 'G', 'A', 'Em'],
      'A': ['F#m', 'D', 'E', 'Bm'],
      'E': ['C#m', 'A', 'B', 'F#m'],
      'Am': ['F', 'C', 'G', 'Dm'],
      'Em': ['C', 'G', 'D', 'Am'],
      'Dm': ['Bb', 'F', 'C', 'Gm'],
    };
    
    return progressions[currentChord] ?? [];
  }
  
  /// Calculate chord transition accuracy
  Future<double> analyzeChordTransition({
    required String fromChord,
    required String toChord,
    required Duration transitionTime,
  }) async {
    final fromTemplate = _chordTemplates[fromChord];
    final toTemplate = _chordTemplates[toChord];
    
    if (fromTemplate == null || toTemplate == null) return 0.0;
    
    // Calculate finger movement difficulty
    final fingerMovement = _calculateFingerMovement(fromTemplate, toTemplate);
    
    // Calculate timing accuracy (ideal transition time vs actual)
    final idealTime = _calculateIdealTransitionTime(fromTemplate, toTemplate);
    final timingAccuracy = 1.0 - (transitionTime.inMilliseconds - idealTime.inMilliseconds).abs() / idealTime.inMilliseconds;
    
    // Combined score
    return (fingerMovement * 0.3 + timingAccuracy * 0.7).clamp(0.0, 1.0);
  }
  
  /// Get practice recommendations based on recognition history
  List<PracticeRecommendation> getPracticeRecommendations() {
    if (_recognitionHistory.length < 10) {
      return [
        PracticeRecommendation(
          type: RecommendationType.general,
          message: 'Practice more chords to get personalized recommendations',
          targetChords: ['C', 'G', 'Am', 'Em'],
          difficulty: ChordDifficulty.beginner,
        ),
      ];
    }
    
    final recommendations = <PracticeRecommendation>[];
    
    // Analyze accuracy patterns
    final lowAccuracyChords = _findLowAccuracyChords();
    if (lowAccuracyChords.isNotEmpty) {
      recommendations.add(PracticeRecommendation(
        type: RecommendationType.accuracy,
        message: 'Focus on improving chord clarity',
        targetChords: lowAccuracyChords,
        difficulty: ChordDifficulty.beginner,
      ));
    }
    
    // Suggest progression practice
    final commonChords = _findMostPracticedChords();
    if (commonChords.isNotEmpty) {
      recommendations.add(PracticeRecommendation(
        type: RecommendationType.progression,
        message: 'Try practicing chord progressions',
        targetChords: getChordProgressionSuggestions(commonChords.first),
        difficulty: ChordDifficulty.intermediate,
      ));
    }
    
    // Suggest new chord challenges
    final masteredChords = _findMasteredChords();
    final nextLevelChords = _suggestNextLevelChords(masteredChords);
    if (nextLevelChords.isNotEmpty) {
      recommendations.add(PracticeRecommendation(
        type: RecommendationType.challenge,
        message: 'Ready for more challenging chords!',
        targetChords: nextLevelChords,
        difficulty: ChordDifficulty.advanced,
      ));
    }
    
    return recommendations;
  }
  
  /// Get recognition statistics
  ChordRecognitionStats getRecognitionStats() {
    if (_recognitionHistory.isEmpty) {
      return ChordRecognitionStats.empty();
    }
    
    final totalRecognitions = _recognitionHistory.length;
    final successfulRecognitions = _recognitionHistory
        .where((r) => r.confidence >= _minConfidence)
        .length;
    
    final averageAccuracy = _recognitionHistory
        .map((r) => r.accuracy)
        .reduce((a, b) => a + b) / totalRecognitions;
    
    final averageConfidence = _recognitionHistory
        .map((r) => r.confidence)
        .reduce((a, b) => a + b) / totalRecognitions;
    
    final uniqueChords = _recognitionHistory
        .where((r) => r.detectedChord != null)
        .map((r) => r.detectedChord!)
        .toSet()
        .length;
    
    return ChordRecognitionStats(
      totalRecognitions: totalRecognitions,
      successfulRecognitions: successfulRecognitions,
      averageAccuracy: averageAccuracy,
      averageConfidence: averageConfidence,
      uniqueChordsDetected: uniqueChords,
      sessionStartTime: _recognitionHistory.first.timestamp,
      lastRecognitionTime: _recognitionHistory.last.timestamp,
    );
  }
  
  // Private methods
  Future<List<double>> _performFFT(Float32List audioBuffer) async {
    // Simplified FFT implementation
    // In production, use a proper FFT library like `fft` package
    final frequencies = <double>[];
    
    for (int k = 0; k < _fftSize ~/ 2; k++) {
      double real = 0.0;
      double imag = 0.0;
      
      for (int n = 0; n < audioBuffer.length && n < _fftSize; n++) {
        final angle = -2.0 * math.pi * k * n / _fftSize;
        real += audioBuffer[n] * math.cos(angle);
        imag += audioBuffer[n] * math.sin(angle);
      }
      
      final magnitude = math.sqrt(real * real + imag * imag);
      frequencies.add(magnitude);
    }
    
    return frequencies;
  }
  
  List<double> _extractFundamentalFrequencies(List<double> fftMagnitudes) {
    final fundamentals = <double>[];
    
    // Find peaks in the frequency spectrum
    for (int i = 1; i < fftMagnitudes.length - 1; i++) {
      if (fftMagnitudes[i] > fftMagnitudes[i - 1] &&
          fftMagnitudes[i] > fftMagnitudes[i + 1] &&
          fftMagnitudes[i] > 0.01) { // Threshold for noise
        
        final frequency = i * _sampleRate / _fftSize;
        
        // Filter to guitar frequency range (80Hz - 1200Hz)
        if (frequency >= 80 && frequency <= 1200) {
          fundamentals.add(frequency);
        }
      }
    }
    
    // Sort by magnitude (strongest frequencies first)
    fundamentals.sort((a, b) {
      final aIndex = (a * _fftSize / _sampleRate).round();
      final bIndex = (b * _fftSize / _sampleRate).round();
      return fftMagnitudes[bIndex].compareTo(fftMagnitudes[aIndex]);
    });
    
    // Return top 6 frequencies (for 6 strings)
    return fundamentals.take(6).toList();
  }
  
  List<ChordMatch> _matchChordTemplates(List<double> detectedFrequencies) {
    final matches = <ChordMatch>[];
    
    for (final entry in _chordTemplates.entries) {
      final template = entry.value;
      final confidence = _calculateChordConfidence(detectedFrequencies, template);
      
      if (confidence >= _minConfidence) {
        matches.add(ChordMatch(
          chordName: entry.key,
          template: template,
          confidence: confidence,
          matchedFrequencies: detectedFrequencies,
        ));
      }
    }
    
    // Sort by confidence (best matches first)
    matches.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return matches;
  }
  
  double _calculateChordConfidence(List<double> detectedFreqs, ChordTemplate template) {
    if (detectedFreqs.isEmpty) return 0.0;
    
    int matchedFreqs = 0;
    int totalExpectedFreqs = template.frequencies.length;
    
    for (final expectedFreq in template.frequencies) {
      for (final detectedFreq in detectedFreqs) {
        if ((detectedFreq - expectedFreq).abs() <= _frequencyTolerance) {
          matchedFreqs++;
          break;
        }
      }
    }
    
    // Bonus for detecting all expected frequencies
    double baseConfidence = matchedFreqs / totalExpectedFreqs;
    
    // Penalty for extra unexpected frequencies
    int extraFreqs = (detectedFreqs.length - matchedFreqs).clamp(0, detectedFreqs.length);
    double penalty = extraFreqs * 0.1;
    
    return (baseConfidence - penalty).clamp(0.0, 1.0);
  }
  
  ChordMatch? _selectBestMatch(List<ChordMatch> matches) {
    if (matches.isEmpty) return null;
    
    // Additional scoring based on recent recognition history
    for (final match in matches) {
      if (_recognitionHistory.length >= 3) {
        final recentChords = _recognitionHistory
            .skip(_recognitionHistory.length - 3)
            .map((r) => r.detectedChord)
            .where((chord) => chord != null)
            .toList();
        
        // Boost confidence for contextually likely chords
        if (recentChords.contains(match.chordName)) {
          match.confidence *= 1.1;
        }
      }
    }
    
    // Re-sort after confidence adjustment
    matches.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return matches.first;
  }
  
  double _calculateAccuracy(ChordMatch? match) {
    if (match == null) return 0.0;
    
    // Base accuracy from confidence
    double accuracy = match.confidence;
    
    // Adjust based on chord difficulty
    switch (match.template.difficulty) {
      case ChordDifficulty.beginner:
        accuracy *= 1.0;
        break;
      case ChordDifficulty.intermediate:
        accuracy *= 1.1;
        break;
      case ChordDifficulty.advanced:
        accuracy *= 1.2;
        break;
    }
    
    return accuracy.clamp(0.0, 1.0);
  }
  
  List<String> _generateSuggestions(ChordMatch? match, List<double> detectedFreqs) {
    final suggestions = <String>[];
    
    if (match == null) {
      suggestions.add('Try pressing strings more firmly');
      suggestions.add('Check your finger placement');
      suggestions.add('Make sure all strings are sounding clearly');
      return suggestions;
    }
    
    if (match.confidence < 0.8) {
      suggestions.add('Clean up muted strings');
      suggestions.add('Check finger arch to avoid touching other strings');
    }
    
    if (match.template.isBarre) {
      suggestions.add('Apply even pressure across the barre');
      suggestions.add('Keep your thumb positioned behind the neck');
    }
    
    return suggestions;
  }
  
  double _calculateFingerMovement(ChordTemplate from, ChordTemplate to) {
    double totalMovement = 0.0;
    int activeFingers = 0;
    
    for (int i = 0; i < math.min(from.fingerPattern.length, to.fingerPattern.length); i++) {
      final fromFret = from.fingerPattern[i];
      final toFret = to.fingerPattern[i];
      
      if (fromFret >= 0 || toFret >= 0) {
        activeFingers++;
        totalMovement += (fromFret - toFret).abs();
      }
    }
    
    if (activeFingers == 0) return 1.0;
    
    final averageMovement = totalMovement / activeFingers;
    return (1.0 - (averageMovement / 12.0)).clamp(0.0, 1.0); // 12 frets = maximum movement
  }
  
  Duration _calculateIdealTransitionTime(ChordTemplate from, ChordTemplate to) {
    final movement = _calculateFingerMovement(from, to);
    
    // Base time + adjustment based on complexity
    int baseMs = 500; // 500ms base transition time
    
    if (from.difficulty == ChordDifficulty.advanced || to.difficulty == ChordDifficulty.advanced) {
      baseMs += 200;
    }
    
    if (from.isBarre || to.isBarre) {
      baseMs += 300;
    }
    
    final adjustedMs = (baseMs * (2.0 - movement)).round();
    return Duration(milliseconds: adjustedMs);
  }
  
  List<String> _findLowAccuracyChords() {
    final chordAccuracy = <String, List<double>>{};
    
    for (final recognition in _recognitionHistory) {
      if (recognition.detectedChord != null) {
        chordAccuracy[recognition.detectedChord!] ??= [];
        chordAccuracy[recognition.detectedChord!]!.add(recognition.accuracy);
      }
    }
    
    final lowAccuracyChords = <String>[];
    
    for (final entry in chordAccuracy.entries) {
      final avgAccuracy = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (avgAccuracy < 0.7) {
        lowAccuracyChords.add(entry.key);
      }
    }
    
    return lowAccuracyChords;
  }
  
  List<String> _findMostPracticedChords() {
    final chordCounts = <String, int>{};
    
    for (final recognition in _recognitionHistory) {
      if (recognition.detectedChord != null) {
        chordCounts[recognition.detectedChord!] = 
            (chordCounts[recognition.detectedChord!] ?? 0) + 1;
      }
    }
    
    final sortedChords = chordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedChords.take(3).map((e) => e.key).toList();
  }
  
  List<String> _findMasteredChords() {
    final chordAccuracy = <String, List<double>>{};
    
    for (final recognition in _recognitionHistory) {
      if (recognition.detectedChord != null) {
        chordAccuracy[recognition.detectedChord!] ??= [];
        chordAccuracy[recognition.detectedChord!]!.add(recognition.accuracy);
      }
    }
    
    final masteredChords = <String>[];
    
    for (final entry in chordAccuracy.entries) {
      if (entry.value.length >= 5) { // At least 5 attempts
        final avgAccuracy = entry.value.reduce((a, b) => a + b) / entry.value.length;
        if (avgAccuracy >= 0.85) {
          masteredChords.add(entry.key);
        }
      }
    }
    
    return masteredChords;
  }
  
  List<String> _suggestNextLevelChords(List<String> masteredChords) {
    final beginnerChords = {'C', 'G', 'Am', 'Em', 'D', 'A', 'E', 'Dm'};
    final intermediateChords = {'G7', 'C7', 'F7', 'Cm', 'Gm'};
    final advancedChords = {'F', 'Bm', 'B7', 'Bb', 'F#m'};
    
    final masteredSet = masteredChords.toSet();
    
    // If mastered most beginner chords, suggest intermediate
    if (masteredSet.intersection(beginnerChords).length >= 5) {
      return intermediateChords.difference(masteredSet).toList();
    }
    
    // If mastered some intermediate, suggest advanced
    if (masteredSet.intersection(intermediateChords).length >= 2) {
      return advancedChords.difference(masteredSet).take(3).toList();
    }
    
    // Otherwise suggest remaining beginner chords
    return beginnerChords.difference(masteredSet).toList();
  }
}

// Data Models
class ChordTemplate {
  final String name;
  final List<double> frequencies;
  final List<int> fingerPattern; // -1 = muted, 0 = open, 1-12 = fret
  final ChordDifficulty difficulty;
  final ChordType type;
  final bool isBarre;
  
  const ChordTemplate({
    required this.name,
    required this.frequencies,
    required this.fingerPattern,
    required this.difficulty,
    required this.type,
    this.isBarre = false,
  });
}

class ChordRecognitionResult {
  final String? detectedChord;
  final double confidence;
  final List<double> fundamentalFrequencies;
  final DateTime timestamp;
  final double accuracy;
  final List<String> suggestions;
  
  const ChordRecognitionResult({
    this.detectedChord,
    required this.confidence,
    required this.fundamentalFrequencies,
    required this.timestamp,
    required this.accuracy,
    required this.suggestions,
  });
}

class ChordMatch {
  final String chordName;
  final ChordTemplate template;
  double confidence;
  final List<double> matchedFrequencies;
  
  ChordMatch({
    required this.chordName,
    required this.template,
    required this.confidence,
    required this.matchedFrequencies,
  });
}

class PracticeRecommendation {
  final RecommendationType type;
  final String message;
  final List<String> targetChords;
  final ChordDifficulty difficulty;
  
  const PracticeRecommendation({
    required this.type,
    required this.message,
    required this.targetChords,
    required this.difficulty,
  });
}

class ChordRecognitionStats {
  final int totalRecognitions;
  final int successfulRecognitions;
  final double averageAccuracy;
  final double averageConfidence;
  final int uniqueChordsDetected;
  final DateTime sessionStartTime;
  final DateTime lastRecognitionTime;
  
  const ChordRecognitionStats({
    required this.totalRecognitions,
    required this.successfulRecognitions,
    required this.averageAccuracy,
    required this.averageConfidence,
    required this.uniqueChordsDetected,
    required this.sessionStartTime,
    required this.lastRecognitionTime,
  });
  
  factory ChordRecognitionStats.empty() {
    final now = DateTime.now();
    return ChordRecognitionStats(
      totalRecognitions: 0,
      successfulRecognitions: 0,
      averageAccuracy: 0.0,
      averageConfidence: 0.0,
      uniqueChordsDetected: 0,
      sessionStartTime: now,
      lastRecognitionTime: now,
    );
  }
  
  double get successRate => totalRecognitions > 0 ? successfulRecognitions / totalRecognitions : 0.0;
  
  Duration get sessionDuration => lastRecognitionTime.difference(sessionStartTime);
}

// Enums
enum ChordDifficulty {
  beginner,
  intermediate,
  advanced,
}

enum ChordType {
  major,
  minor,
  dominant7,
  major7,
  minor7,
  diminished,
  augmented,
  suspended,
}

enum RecommendationType {
  general,
  accuracy,
  progression,
  challenge,
  technique,
}

class ChordRecognitionException implements Exception {
  final String message;
  
  const ChordRecognitionException(this.message);
  
  @override
  String toString() => 'ChordRecognitionException: $message';
}

// Riverpod providers
final chordRecognitionServiceProvider = Provider<ChordRecognitionService>((ref) {
  return ChordRecognitionService();
});

final chordRecognitionStatsProvider = Provider<ChordRecognitionStats>((ref) {
  final service = ref.read(chordRecognitionServiceProvider);
  return service.getRecognitionStats();
});

final practiceRecommendationsProvider = Provider<List<PracticeRecommendation>>((ref) {
  final service = ref.read(chordRecognitionServiceProvider);
  return service.getPracticeRecommendations();
});

final chordTemplatesProvider = Provider<Map<String, ChordTemplate>>((ref) {
  final service = ref.read(chordRecognitionServiceProvider);
  return service.getAllChordTemplates();
});

final chordsByDifficultyProvider = Provider.family<List<ChordTemplate>, ChordDifficulty>((ref, difficulty) {
  final service = ref.read(chordRecognitionServiceProvider);
  return service.getChordsByDifficulty(difficulty);
});