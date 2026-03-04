// Song data for GuitarrApp - Songs by Genre mode
// Contains song catalog organized by genre with chord sequences

import 'chords_data.dart';

/// Available song genres
enum SongGenre { rock, pop, blues }

/// Represents a single song with its chord progression
class SongData {
  final String id;
  final String title;
  final String artist;
  final SongGenre genre;
  final int difficulty; // 1-3
  final List<String> chordSequence; // Each entry = 1 attempt
  final List<String> requiredChords; // Unique chords needed
  final String description;

  const SongData({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.difficulty,
    required this.chordSequence,
    required this.requiredChords,
    required this.description,
  });

  int get totalAttempts => chordSequence.length;

  /// Get the ChordData for a specific attempt index
  ChordData? getChordAt(int index) {
    if (index < 0 || index >= chordSequence.length) return null;
    return ChordsData.getChordByName(chordSequence[index]);
  }
}

/// Song catalog for the MVP
class SongsData {
  static const List<SongData> allSongs = [
    // === ROCK ===
    SongData(
      id: 'about_a_girl',
      title: 'About a Girl',
      artist: 'Nirvana',
      genre: SongGenre.rock,
      difficulty: 1,
      chordSequence: ['Em', 'G', 'Em', 'G', 'Em', 'G', 'Em', 'G', 'Em', 'G'],
      requiredChords: ['Em', 'G'],
      description: 'Dos acordes que se alternan. Clásico grunge.',
    ),
    SongData(
      id: 'polly',
      title: 'Polly',
      artist: 'Nirvana',
      genre: SongGenre.rock,
      difficulty: 1,
      chordSequence: ['Em', 'G', 'D', 'C', 'Em', 'G', 'D', 'C', 'Em', 'G'],
      requiredChords: ['Em', 'G', 'D', 'C'],
      description: 'Tema acústico de Nirvana. Acordes simples y lentos.',
    ),
    SongData(
      id: 'knockin_on_heavens_door',
      title: "Knockin' on Heaven's Door",
      artist: 'Bob Dylan',
      genre: SongGenre.rock,
      difficulty: 2,
      chordSequence: ['G', 'D', 'Am', 'Am', 'G', 'D', 'C', 'C', 'G', 'D'],
      requiredChords: ['G', 'D', 'Am', 'C'],
      description: 'Progresión clásica de folk-rock.',
    ),
    SongData(
      id: 'boulevard_of_broken_dreams',
      title: 'Boulevard of Broken Dreams',
      artist: 'Green Day',
      genre: SongGenre.rock,
      difficulty: 2,
      chordSequence: ['Em', 'G', 'D', 'A', 'Em', 'G', 'D', 'A', 'Em', 'G'],
      requiredChords: ['Em', 'G', 'D', 'A'],
      description: 'Himno punk rock con 4 acordes.',
    ),

    // === POP ===
    SongData(
      id: 'riptide',
      title: 'Riptide',
      artist: 'Vance Joy',
      genre: SongGenre.pop,
      difficulty: 1,
      chordSequence: ['Am', 'G', 'C', 'Am', 'G', 'C', 'Am', 'G', 'C', 'Am'],
      requiredChords: ['Am', 'G', 'C'],
      description: 'Hit pop con 3 acordes en loop.',
    ),
    SongData(
      id: 'stand_by_me',
      title: 'Stand By Me',
      artist: 'Ben E. King',
      genre: SongGenre.pop,
      difficulty: 2,
      chordSequence: ['G', 'G', 'Em', 'Em', 'C', 'D', 'G', 'G', 'C', 'D'],
      requiredChords: ['G', 'Em', 'C', 'D'],
      description: 'Clásico atemporal con progresión I-vi-IV-V.',
    ),
    SongData(
      id: 'let_her_go',
      title: 'Let Her Go',
      artist: 'Passenger',
      genre: SongGenre.pop,
      difficulty: 2,
      chordSequence: ['C', 'D', 'Em', 'C', 'D', 'G', 'Em', 'C', 'D', 'Em'],
      requiredChords: ['C', 'D', 'Em', 'G'],
      description: 'Balada folk-pop con arpegios.',
    ),

    // === BLUES ===
    SongData(
      id: '12_bar_blues_e',
      title: '12-Bar Blues en E',
      artist: 'Tradicional',
      genre: SongGenre.blues,
      difficulty: 1,
      chordSequence: ['E', 'E', 'E', 'E', 'A', 'A', 'E', 'E', 'D', 'A'],
      requiredChords: ['E', 'A', 'D'],
      description: 'La base del blues. 3 acordes, infinitas posibilidades.',
    ),
    SongData(
      id: 'hound_dog',
      title: 'Hound Dog',
      artist: 'Elvis Presley',
      genre: SongGenre.blues,
      difficulty: 1,
      chordSequence: ['A', 'A', 'A', 'A', 'D', 'D', 'A', 'A', 'E', 'D'],
      requiredChords: ['A', 'D', 'E'],
      description: 'Rock and roll clásico con estructura blues.',
    ),
  ];

  /// Get a song by its ID
  static SongData? getSongById(String id) {
    return allSongs.cast<SongData?>().firstWhere(
          (song) => song?.id == id,
          orElse: () => null,
        );
  }

  /// Get all songs for a given genre
  static List<SongData> getSongsByGenre(SongGenre genre) {
    return allSongs.where((song) => song.genre == genre).toList();
  }

  /// Check if a player can play a song based on their chord progress.
  /// Each required chord must have ≥1 star in its corresponding level.
  static bool canPlaySong(SongData song, Map<int, int> levelStars) {
    for (final chordName in song.requiredChords) {
      final chord = ChordsData.getChordByName(chordName);
      if (chord == null) return false;
      if ((levelStars[chord.level] ?? 0) < 1) return false;
    }
    return true;
  }

  /// Get the genre display name
  static String genreDisplayName(SongGenre genre) {
    switch (genre) {
      case SongGenre.rock:
        return 'ROCK';
      case SongGenre.pop:
        return 'POP';
      case SongGenre.blues:
        return 'BLUES';
    }
  }
}
