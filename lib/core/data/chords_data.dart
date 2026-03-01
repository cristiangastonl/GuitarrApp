// Chord data for GuitarrApp MVP Arcade
// Contains the 10 chord lessons with all necessary information

/// Represents a single chord in the app
class ChordData {
  final int level;
  final String name;
  final String displayName;
  final int difficulty; // 1-3 stars
  final List<int> frets; // -1 = muted, 0 = open, 1-4 = fret number (strings low E to high e)
  final List<int> fingers; // 0 = open/muted, 1-4 = finger number
  final List<String> notes; // Note names for each string (low to high)
  final List<double> frequencies; // Fundamental frequencies for chord detection
  final String description;

  const ChordData({
    required this.level,
    required this.name,
    required this.displayName,
    required this.difficulty,
    required this.frets,
    required this.fingers,
    required this.notes,
    required this.frequencies,
    required this.description,
  });

  /// Whether a string should be played
  bool isStringPlayed(int stringIndex) => frets[stringIndex] != -1;

  /// Get the fret position for display (-1 = muted, 0 = open, >0 = fret)
  int getFretDisplay(int stringIndex) {
    return frets[stringIndex];
  }
}

/// All 10 chords for the MVP
class ChordsData {
  static const List<ChordData> allChords = [
    // Level 1: Em (E minor) - Easiest chord
    ChordData(
      level: 1,
      name: 'Em',
      displayName: 'E minor',
      difficulty: 1,
      frets: [0, 2, 2, 0, 0, 0], // E A D G B e
      fingers: [0, 2, 3, 0, 0, 0],
      notes: ['E', 'B', 'E', 'G', 'B', 'E'],
      frequencies: [82.41, 123.47, 164.81, 196.00, 246.94, 329.63],
      description: 'El acorde más fácil. Solo 2 dedos.',
    ),

    // Level 2: Am (A minor)
    ChordData(
      level: 2,
      name: 'Am',
      displayName: 'A minor',
      difficulty: 1,
      frets: [-1, 0, 2, 2, 1, 0], // X A D G B e
      fingers: [0, 0, 2, 3, 1, 0],
      notes: ['X', 'A', 'E', 'A', 'C', 'E'],
      frequencies: [110.00, 164.81, 220.00, 261.63, 329.63],
      description: 'Similar a Em pero en las cuerdas del medio.',
    ),

    // Level 3: E (E major)
    ChordData(
      level: 3,
      name: 'E',
      displayName: 'E major',
      difficulty: 1,
      frets: [0, 2, 2, 1, 0, 0],
      fingers: [0, 2, 3, 1, 0, 0],
      notes: ['E', 'B', 'E', 'G#', 'B', 'E'],
      frequencies: [82.41, 123.47, 164.81, 207.65, 246.94, 329.63],
      description: 'Como Em pero con un dedo más en la 3ra cuerda.',
    ),

    // Level 4: A (A major)
    ChordData(
      level: 4,
      name: 'A',
      displayName: 'A major',
      difficulty: 1,
      frets: [-1, 0, 2, 2, 2, 0],
      fingers: [0, 0, 1, 2, 3, 0], // Or [0, 0, 2, 3, 4, 0] or bar with index
      notes: ['X', 'A', 'E', 'A', 'C#', 'E'],
      frequencies: [110.00, 164.81, 220.00, 277.18, 329.63],
      description: 'Tres dedos en línea en el 2do traste.',
    ),

    // Level 5: D (D major)
    ChordData(
      level: 5,
      name: 'D',
      displayName: 'D major',
      difficulty: 1,
      frets: [-1, -1, 0, 2, 3, 2],
      fingers: [0, 0, 0, 1, 3, 2],
      notes: ['X', 'X', 'D', 'A', 'D', 'F#'],
      frequencies: [146.83, 220.00, 293.66, 369.99],
      description: 'Solo las 4 cuerdas más agudas. Forma de triángulo.',
    ),

    // Level 6: G (G major) - Intermediate
    ChordData(
      level: 6,
      name: 'G',
      displayName: 'G major',
      difficulty: 2,
      frets: [3, 2, 0, 0, 0, 3],
      fingers: [2, 1, 0, 0, 0, 3], // Alternative: [3, 2, 0, 0, 0, 4]
      notes: ['G', 'B', 'D', 'G', 'B', 'G'],
      frequencies: [98.00, 123.47, 146.83, 196.00, 246.94, 392.00],
      description: 'Acorde amplio. Usa dedos en ambos extremos.',
    ),

    // Level 7: C (C major)
    ChordData(
      level: 7,
      name: 'C',
      displayName: 'C major',
      difficulty: 2,
      frets: [-1, 3, 2, 0, 1, 0],
      fingers: [0, 3, 2, 0, 1, 0],
      notes: ['X', 'C', 'E', 'G', 'C', 'E'],
      frequencies: [130.81, 164.81, 196.00, 261.63, 329.63],
      description: 'Forma de escalera diagonal.',
    ),

    // Level 8: Dm (D minor)
    ChordData(
      level: 8,
      name: 'Dm',
      displayName: 'D minor',
      difficulty: 2,
      frets: [-1, -1, 0, 2, 3, 1],
      fingers: [0, 0, 0, 2, 3, 1],
      notes: ['X', 'X', 'D', 'A', 'D', 'F'],
      frequencies: [146.83, 220.00, 293.66, 349.23],
      description: 'Similar a D pero con el dedo 1 en la 1ra cuerda.',
    ),

    // Level 9: F (F major) - Advanced (barre chord)
    ChordData(
      level: 9,
      name: 'F',
      displayName: 'F major',
      difficulty: 3,
      frets: [1, 3, 3, 2, 1, 1],
      fingers: [1, 3, 4, 2, 1, 1], // Barre with index
      notes: ['F', 'C', 'F', 'A', 'C', 'F'],
      frequencies: [87.31, 130.81, 174.61, 220.00, 261.63, 349.23],
      description: 'Cejilla completa. El más difícil para principiantes.',
    ),

    // Level 10: Bm (B minor) - Advanced (barre chord)
    ChordData(
      level: 10,
      name: 'Bm',
      displayName: 'B minor',
      difficulty: 3,
      frets: [-1, 2, 4, 4, 3, 2],
      fingers: [0, 1, 3, 4, 2, 1], // Partial barre
      notes: ['X', 'B', 'F#', 'B', 'D', 'F#'],
      frequencies: [123.47, 185.00, 246.94, 293.66, 369.99],
      description: 'Cejilla parcial en el 2do traste.',
    ),
  ];

  /// Get chord by level (1-10)
  static ChordData? getChordByLevel(int level) {
    if (level < 1 || level > allChords.length) return null;
    return allChords[level - 1];
  }

  /// Get chord by name (e.g., "Em", "Am")
  static ChordData? getChordByName(String name) {
    return allChords.cast<ChordData?>().firstWhere(
          (chord) => chord?.name.toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );
  }

  /// Get all chords up to a certain difficulty
  static List<ChordData> getChordsByMaxDifficulty(int maxDifficulty) {
    return allChords.where((chord) => chord.difficulty <= maxDifficulty).toList();
  }

  /// Get the test chords (first 5 for level assessment)
  static List<ChordData> get testChords => allChords.sublist(0, 5);
}
