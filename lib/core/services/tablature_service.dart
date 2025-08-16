import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';

/// Tablature Service
/// Manages interactive guitar tablature with synchronized audio playback
/// Supports multi-track tabs, auto-scroll, and real-time practice feedback
class TablatureService {
  // Playback state
  bool _isPlaying = false;
  double _currentPosition = 0.0; // Position in seconds
  double _playbackSpeed = 1.0; // 0.5x to 2.0x speed
  Timer? _playbackTimer;
  
  // Tab data
  final Map<String, TablatureScore> _loadedTabs = {};
  TablatureScore? _currentTab;
  
  // Auto-scroll settings
  bool _autoScrollEnabled = true;
  double _scrollLeadTime = 2.0; // Seconds to look ahead
  
  // Practice mode settings
  bool _practiceMode = false;
  bool _loopEnabled = false;
  int _loopStart = 0;
  int _loopEnd = 0;
  
  // Event streams
  final StreamController<PlaybackEvent> _playbackController = StreamController.broadcast();
  final StreamController<TabPosition> _positionController = StreamController.broadcast();
  final StreamController<PracticeEvent> _practiceController = StreamController.broadcast();
  
  /// Stream of playback events
  Stream<PlaybackEvent> get playbackEvents => _playbackController.stream;
  
  /// Stream of current tab position
  Stream<TabPosition> get positionEvents => _positionController.stream;
  
  /// Stream of practice events
  Stream<PracticeEvent> get practiceEvents => _practiceController.stream;
  
  // Getters
  bool get isPlaying => _isPlaying;
  double get currentPosition => _currentPosition;
  double get playbackSpeed => _playbackSpeed;
  TablatureScore? get currentTab => _currentTab;
  bool get autoScrollEnabled => _autoScrollEnabled;
  bool get practiceMode => _practiceMode;
  
  /// Load tablature from various sources
  Future<TablatureScore> loadTablature({
    required String id,
    required String title,
    required String artist,
    String? filePath,
    String? gp5Data,
    List<TabTrack>? customTracks,
  }) async {
    try {
      TablatureScore tab;
      
      if (filePath != null) {
        tab = await _loadFromFile(filePath);
      } else if (gp5Data != null) {
        tab = await _parseGP5Data(gp5Data);
      } else if (customTracks != null) {
        tab = TablatureScore(
          id: id,
          title: title,
          artist: artist,
          tracks: customTracks,
          bpm: 120,
          timeSignature: TimeSignature.fourFour,
          difficulty: TabDifficulty.intermediate,
        );
      } else {
        throw TablatureException('No valid tablature source provided');
      }
      
      // Store the loaded tab
      _loadedTabs[id] = tab;
      
      return tab;
    } catch (e) {
      throw TablatureException('Failed to load tablature: $e');
    }
  }
  
  /// Set the current active tablature
  Future<void> setCurrentTab(String tabId) async {
    final tab = _loadedTabs[tabId];
    if (tab == null) {
      throw TablatureException('Tablature with ID $tabId not found');
    }
    
    // Stop current playback
    await stopPlayback();
    
    _currentTab = tab;
    _currentPosition = 0.0;
    
    _positionController.add(TabPosition(
      tabId: tabId,
      position: _currentPosition,
      measure: 1,
      beat: 1,
      notes: _getNotesAtPosition(_currentPosition),
    ));
  }
  
  /// Start playback from current position
  Future<void> startPlayback() async {
    if (_currentTab == null) {
      throw TablatureException('No tablature loaded');
    }
    
    _isPlaying = true;
    
    _playbackController.add(PlaybackEvent(
      type: PlaybackEventType.started,
      position: _currentPosition,
      timestamp: DateTime.now(),
    ));
    
    // Start playback timer
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _updatePlaybackPosition();
    });
  }
  
  /// Pause playback
  Future<void> pausePlayback() async {
    _isPlaying = false;
    _playbackTimer?.cancel();
    
    _playbackController.add(PlaybackEvent(
      type: PlaybackEventType.paused,
      position: _currentPosition,
      timestamp: DateTime.now(),
    ));
  }
  
  /// Stop playback and reset position
  Future<void> stopPlayback() async {
    _isPlaying = false;
    _playbackTimer?.cancel();
    _currentPosition = 0.0;
    
    _playbackController.add(PlaybackEvent(
      type: PlaybackEventType.stopped,
      position: _currentPosition,
      timestamp: DateTime.now(),
    ));
    
    if (_currentTab != null) {
      _positionController.add(TabPosition(
        tabId: _currentTab!.id,
        position: _currentPosition,
        measure: 1,
        beat: 1,
        notes: _getNotesAtPosition(_currentPosition),
      ));
    }
  }
  
  /// Set playback speed (0.5x to 2.0x)
  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed.clamp(0.25, 2.0);
    
    _playbackController.add(PlaybackEvent(
      type: PlaybackEventType.speedChanged,
      position: _currentPosition,
      timestamp: DateTime.now(),
      metadata: {'speed': _playbackSpeed},
    ));
  }
  
  /// Seek to specific position in seconds
  Future<void> seekToPosition(double position) async {
    if (_currentTab == null) return;
    
    _currentPosition = position.clamp(0.0, _currentTab!.duration);
    
    final tabPosition = _calculateTabPosition(position);
    _positionController.add(tabPosition);
    
    _playbackController.add(PlaybackEvent(
      type: PlaybackEventType.seeked,
      position: _currentPosition,
      timestamp: DateTime.now(),
    ));
  }
  
  /// Seek to specific measure
  Future<void> seekToMeasure(int measure) async {
    if (_currentTab == null) return;
    
    final position = _calculatePositionFromMeasure(measure);
    await seekToPosition(position);
  }
  
  /// Enable/disable auto-scroll
  void setAutoScroll(bool enabled) {
    _autoScrollEnabled = enabled;
  }
  
  /// Set auto-scroll lead time
  void setScrollLeadTime(double seconds) {
    _scrollLeadTime = seconds.clamp(0.5, 5.0);
  }
  
  /// Enter practice mode with loop settings
  void enterPracticeMode({
    required int startMeasure,
    required int endMeasure,
    bool enableLoop = true,
  }) {
    _practiceMode = true;
    _loopEnabled = enableLoop;
    _loopStart = startMeasure;
    _loopEnd = endMeasure;
    
    _practiceController.add(PracticeEvent(
      type: PracticeEventType.modeEntered,
      startMeasure: startMeasure,
      endMeasure: endMeasure,
      timestamp: DateTime.now(),
    ));
  }
  
  /// Exit practice mode
  void exitPracticeMode() {
    _practiceMode = false;
    _loopEnabled = false;
    
    _practiceController.add(PracticeEvent(
      type: PracticeEventType.modeExited,
      timestamp: DateTime.now(),
    ));
  }
  
  /// Toggle loop in practice mode
  void toggleLoop() {
    _loopEnabled = !_loopEnabled;
    
    _practiceController.add(PracticeEvent(
      type: _loopEnabled ? PracticeEventType.loopEnabled : PracticeEventType.loopDisabled,
      startMeasure: _loopStart,
      endMeasure: _loopEnd,
      timestamp: DateTime.now(),
    ));
  }
  
  /// Get notes at specific position
  List<TabNote> getNotesAtPosition(double position) {
    return _getNotesAtPosition(position);
  }
  
  /// Get upcoming notes for auto-scroll
  List<TabNote> getUpcomingNotes({double? fromPosition, double? lookAheadSeconds}) {
    if (_currentTab == null) return [];
    
    final position = fromPosition ?? _currentPosition;
    final lookAhead = lookAheadSeconds ?? _scrollLeadTime;
    
    final notes = <TabNote>[];
    
    for (final track in _currentTab!.tracks) {
      for (final measure in track.measures) {
        for (final note in measure.notes) {
          if (note.position >= position && note.position <= position + lookAhead) {
            notes.add(note);
          }
        }
      }
    }
    
    // Sort by position
    notes.sort((a, b) => a.position.compareTo(b.position));
    
    return notes;
  }
  
  /// Analyze difficulty of current tablature
  TabDifficultyAnalysis analyzeDifficulty() {
    if (_currentTab == null) {
      return TabDifficultyAnalysis.empty();
    }
    
    int totalNotes = 0;
    int bends = 0;
    int slides = 0;
    int hammerOns = 0;
    int pullOffs = 0;
    int vibratos = 0;
    double maxTempo = 0;
    Set<int> uniqueFrets = {};
    Set<int> uniqueStrings = {};
    
    for (final track in _currentTab!.tracks) {
      for (final measure in track.measures) {
        maxTempo = math.max(maxTempo, measure.bpm.toDouble());
        
        for (final note in measure.notes) {
          totalNotes++;
          uniqueFrets.add(note.fret);
          uniqueStrings.add(note.string);
          
          if (note.techniques.contains(TabTechnique.bend)) bends++;
          if (note.techniques.contains(TabTechnique.slide)) slides++;
          if (note.techniques.contains(TabTechnique.hammerOn)) hammerOns++;
          if (note.techniques.contains(TabTechnique.pullOff)) pullOffs++;
          if (note.techniques.contains(TabTechnique.vibrato)) vibratos++;
        }
      }
    }
    
    return TabDifficultyAnalysis(
      difficulty: _currentTab!.difficulty,
      totalNotes: totalNotes,
      techniqueCount: bends + slides + hammerOns + pullOffs + vibratos,
      maxFretUsed: uniqueFrets.isEmpty ? 0 : uniqueFrets.reduce(math.max),
      stringsUsed: uniqueStrings.length,
      maxTempo: maxTempo,
      bendCount: bends,
      slideCount: slides,
      hammerOnCount: hammerOns,
      pullOffCount: pullOffs,
      vibratoCount: vibratos,
    );
  }
  
  /// Generate practice exercises from current tab
  List<PracticeExercise> generatePracticeExercises() {
    if (_currentTab == null) return [];
    
    final exercises = <PracticeExercise>[];
    
    // Chord progression exercise
    final chords = _extractChordProgression();
    if (chords.isNotEmpty) {
      exercises.add(PracticeExercise(
        id: 'chord_progression',
        title: 'Chord Progression',
        description: 'Practice the chord changes in this song',
        type: ExerciseType.chordProgression,
        targetChords: chords,
        recommendedBpm: _currentTab!.bpm ~/ 2,
        difficulty: TabDifficulty.beginner,
      ));
    }
    
    // Technique-specific exercises
    final techniques = _extractUniqueTechniques();
    for (final technique in techniques) {
      exercises.add(PracticeExercise(
        id: 'technique_${technique.name}',
        title: '${technique.name.split('.').last} Practice',
        description: 'Focus on ${technique.name.split('.').last} technique',
        type: ExerciseType.technique,
        technique: technique,
        recommendedBpm: (_currentTab!.bpm * 0.7).round(),
        difficulty: _getTechniqueDifficulty(technique),
      ));
    }
    
    // Scale exercises based on key
    if (_currentTab!.key != null) {
      exercises.add(PracticeExercise(
        id: 'scale_practice',
        title: 'Scale Practice',
        description: 'Practice the scale used in this song',
        type: ExerciseType.scale,
        key: _currentTab!.key,
        recommendedBpm: _currentTab!.bpm,
        difficulty: TabDifficulty.intermediate,
      ));
    }
    
    return exercises;
  }
  
  /// Export tablature to different formats
  Future<String> exportTablature({
    required String tabId,
    required ExportFormat format,
  }) async {
    final tab = _loadedTabs[tabId];
    if (tab == null) {
      throw TablatureException('Tablature not found');
    }
    
    switch (format) {
      case ExportFormat.ascii:
        return _exportToASCII(tab);
      case ExportFormat.musicXml:
        return _exportToMusicXML(tab);
      case ExportFormat.gp5:
        return _exportToGP5(tab);
      case ExportFormat.json:
        return _exportToJSON(tab);
    }
  }
  
  // Private methods
  void _updatePlaybackPosition() {
    if (!_isPlaying || _currentTab == null) return;
    
    // Update position based on speed
    _currentPosition += 0.05 * _playbackSpeed; // 50ms * speed
    
    // Check for loop in practice mode
    if (_practiceMode && _loopEnabled) {
      final loopEndPosition = _calculatePositionFromMeasure(_loopEnd);
      if (_currentPosition >= loopEndPosition) {
        _currentPosition = _calculatePositionFromMeasure(_loopStart);
        
        _practiceController.add(PracticeEvent(
          type: PracticeEventType.loopRestarted,
          startMeasure: _loopStart,
          endMeasure: _loopEnd,
          timestamp: DateTime.now(),
        ));
      }
    }
    
    // Check for end of tab
    if (_currentPosition >= _currentTab!.duration) {
      stopPlayback();
      return;
    }
    
    // Update position
    final tabPosition = _calculateTabPosition(_currentPosition);
    _positionController.add(tabPosition);
    
    // Check for auto-scroll
    if (_autoScrollEnabled) {
      _playbackController.add(PlaybackEvent(
        type: PlaybackEventType.positionUpdate,
        position: _currentPosition,
        timestamp: DateTime.now(),
        metadata: {
          'measure': tabPosition.measure,
          'beat': tabPosition.beat,
          'upcomingNotes': getUpcomingNotes(),
        },
      ));
    }
  }
  
  TabPosition _calculateTabPosition(double position) {
    if (_currentTab == null) {
      return TabPosition(
        tabId: '',
        position: position,
        measure: 1,
        beat: 1,
        notes: [],
      );
    }
    
    // Calculate measure and beat from position
    final beatsPerSecond = _currentTab!.bpm / 60.0;
    final totalBeats = position * beatsPerSecond;
    final beatsPerMeasure = _currentTab!.timeSignature.numerator;
    
    final measure = (totalBeats / beatsPerMeasure).floor() + 1;
    final beat = (totalBeats % beatsPerMeasure).floor() + 1;
    
    return TabPosition(
      tabId: _currentTab!.id,
      position: position,
      measure: measure,
      beat: beat,
      notes: _getNotesAtPosition(position),
    );
  }
  
  double _calculatePositionFromMeasure(int measure) {
    if (_currentTab == null) return 0.0;
    
    final beatsPerMeasure = _currentTab!.timeSignature.numerator;
    final beatsPerSecond = _currentTab!.bpm / 60.0;
    
    final totalBeats = (measure - 1) * beatsPerMeasure;
    return totalBeats / beatsPerSecond;
  }
  
  List<TabNote> _getNotesAtPosition(double position) {
    if (_currentTab == null) return [];
    
    const tolerance = 0.1; // 100ms tolerance
    final notes = <TabNote>[];
    
    for (final track in _currentTab!.tracks) {
      for (final measure in track.measures) {
        for (final note in measure.notes) {
          if ((note.position - position).abs() <= tolerance) {
            notes.add(note);
          }
        }
      }
    }
    
    return notes;
  }
  
  Future<TablatureScore> _loadFromFile(String filePath) async {
    // Mock implementation - in production, parse actual tab files
    return TablatureScore(
      id: 'file_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Loaded Tab',
      artist: 'Unknown Artist',
      tracks: [_createSampleTrack()],
      bpm: 120,
      timeSignature: TimeSignature.fourFour,
      difficulty: TabDifficulty.intermediate,
    );
  }
  
  Future<TablatureScore> _parseGP5Data(String gp5Data) async {
    // Mock implementation - in production, parse GP5 format
    return TablatureScore(
      id: 'gp5_${DateTime.now().millisecondsSinceEpoch}',
      title: 'GP5 Tab',
      artist: 'Unknown Artist',
      tracks: [_createSampleTrack()],
      bpm: 120,
      timeSignature: TimeSignature.fourFour,
      difficulty: TabDifficulty.intermediate,
    );
  }
  
  TabTrack _createSampleTrack() {
    return TabTrack(
      id: 'track_1',
      name: 'Guitar',
      instrument: 'Electric Guitar',
      tuning: ['E', 'A', 'D', 'G', 'B', 'E'],
      measures: [
        TabMeasure(
          number: 1,
          bpm: 120,
          timeSignature: TimeSignature.fourFour,
          notes: [
            TabNote(
              position: 0.0,
              string: 6,
              fret: 0,
              duration: NoteDuration.quarter,
              techniques: [],
            ),
            TabNote(
              position: 0.5,
              string: 5,
              fret: 2,
              duration: NoteDuration.quarter,
              techniques: [],
            ),
            TabNote(
              position: 1.0,
              string: 4,
              fret: 2,
              duration: NoteDuration.quarter,
              techniques: [],
            ),
            TabNote(
              position: 1.5,
              string: 3,
              fret: 1,
              duration: NoteDuration.quarter,
              techniques: [],
            ),
          ],
        ),
      ],
    );
  }
  
  List<String> _extractChordProgression() {
    // Simplified chord extraction - in production, analyze harmonic content
    return ['C', 'Am', 'F', 'G'];
  }
  
  Set<TabTechnique> _extractUniqueTechniques() {
    if (_currentTab == null) return {};
    
    final techniques = <TabTechnique>{};
    
    for (final track in _currentTab!.tracks) {
      for (final measure in track.measures) {
        for (final note in measure.notes) {
          techniques.addAll(note.techniques);
        }
      }
    }
    
    return techniques;
  }
  
  TabDifficulty _getTechniqueDifficulty(TabTechnique technique) {
    switch (technique) {
      case TabTechnique.bend:
      case TabTechnique.vibrato:
        return TabDifficulty.intermediate;
      case TabTechnique.slide:
      case TabTechnique.hammerOn:
      case TabTechnique.pullOff:
        return TabDifficulty.intermediate;
      case TabTechnique.tapping:
      case TabTechnique.sweep:
        return TabDifficulty.advanced;
      default:
        return TabDifficulty.beginner;
    }
  }
  
  String _exportToASCII(TablatureScore tab) {
    final buffer = StringBuffer();
    buffer.writeln('${tab.title} - ${tab.artist}');
    buffer.writeln('BPM: ${tab.bpm}');
    buffer.writeln('');
    
    for (final track in tab.tracks) {
      buffer.writeln('${track.name} (${track.instrument})');
      buffer.writeln('Tuning: ${track.tuning.join(' ')}');
      buffer.writeln('');
      
      // ASCII tab format
      for (int string = 0; string < 6; string++) {
        buffer.write('${track.tuning[string]}|');
        for (final measure in track.measures) {
          for (final note in measure.notes.where((n) => n.string == string + 1)) {
            buffer.write('${note.fret}-');
          }
        }
        buffer.writeln('|');
      }
      buffer.writeln('');
    }
    
    return buffer.toString();
  }
  
  String _exportToMusicXML(TablatureScore tab) {
    // Simplified MusicXML export
    return '''<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <work>
    <work-title>${tab.title}</work-title>
  </work>
  <identification>
    <creator type="composer">${tab.artist}</creator>
  </identification>
  <!-- ... rest of MusicXML structure ... -->
</score-partwise>''';
  }
  
  String _exportToGP5(TablatureScore tab) {
    // Mock GP5 export - in production, generate binary GP5 format
    return 'GP5 Binary Data for ${tab.title}';
  }
  
  String _exportToJSON(TablatureScore tab) {
    // JSON representation of the tab
    return '''
{
  "id": "${tab.id}",
  "title": "${tab.title}",
  "artist": "${tab.artist}",
  "bpm": ${tab.bpm},
  "timeSignature": "${tab.timeSignature.numerator}/${tab.timeSignature.denominator}",
  "difficulty": "${tab.difficulty.name}",
  "tracks": [
    ${tab.tracks.map((track) => '''
    {
      "id": "${track.id}",
      "name": "${track.name}",
      "instrument": "${track.instrument}",
      "tuning": ${track.tuning},
      "measures": [
        ${track.measures.map((measure) => '''
        {
          "number": ${measure.number},
          "bpm": ${measure.bpm},
          "notes": [
            ${measure.notes.map((note) => '''
            {
              "position": ${note.position},
              "string": ${note.string},
              "fret": ${note.fret},
              "duration": "${note.duration.name}",
              "techniques": ${note.techniques.map((t) => '"${t.name}"').toList()}
            }''').join(',\n            ')}
          ]
        }''').join(',\n        ')}
      ]
    }''').join(',\n    ')}
  ]
}''';
  }
  
  void dispose() {
    _playbackTimer?.cancel();
    _playbackController.close();
    _positionController.close();
    _practiceController.close();
  }
}

// Data Models
class TablatureScore {
  final String id;
  final String title;
  final String artist;
  final List<TabTrack> tracks;
  final int bpm;
  final TimeSignature timeSignature;
  final TabDifficulty difficulty;
  final String? key;
  final double duration; // in seconds
  
  const TablatureScore({
    required this.id,
    required this.title,
    required this.artist,
    required this.tracks,
    required this.bpm,
    required this.timeSignature,
    required this.difficulty,
    this.key,
    this.duration = 120.0, // default 2 minutes
  });
}

class TabTrack {
  final String id;
  final String name;
  final String instrument;
  final List<String> tuning;
  final List<TabMeasure> measures;
  
  const TabTrack({
    required this.id,
    required this.name,
    required this.instrument,
    required this.tuning,
    required this.measures,
  });
}

class TabMeasure {
  final int number;
  final int bpm;
  final TimeSignature timeSignature;
  final List<TabNote> notes;
  
  const TabMeasure({
    required this.number,
    required this.bpm,
    required this.timeSignature,
    required this.notes,
  });
}

class TabNote {
  final double position; // Position in seconds
  final int string; // 1-6 (high E to low E)
  final int fret; // 0-24
  final NoteDuration duration;
  final List<TabTechnique> techniques;
  
  const TabNote({
    required this.position,
    required this.string,
    required this.fret,
    required this.duration,
    required this.techniques,
  });
}

class TimeSignature {
  final int numerator;
  final int denominator;
  
  const TimeSignature(this.numerator, this.denominator);
  
  static const fourFour = TimeSignature(4, 4);
  static const threeFour = TimeSignature(3, 4);
  static const sixEight = TimeSignature(6, 8);
}

class TabPosition {
  final String tabId;
  final double position;
  final int measure;
  final int beat;
  final List<TabNote> notes;
  
  const TabPosition({
    required this.tabId,
    required this.position,
    required this.measure,
    required this.beat,
    required this.notes,
  });
}

class PlaybackEvent {
  final PlaybackEventType type;
  final double position;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  
  const PlaybackEvent({
    required this.type,
    required this.position,
    required this.timestamp,
    this.metadata = const {},
  });
}

class PracticeEvent {
  final PracticeEventType type;
  final int? startMeasure;
  final int? endMeasure;
  final DateTime timestamp;
  
  const PracticeEvent({
    required this.type,
    this.startMeasure,
    this.endMeasure,
    required this.timestamp,
  });
}

class PracticeExercise {
  final String id;
  final String title;
  final String description;
  final ExerciseType type;
  final List<String>? targetChords;
  final TabTechnique? technique;
  final String? key;
  final int recommendedBpm;
  final TabDifficulty difficulty;
  
  const PracticeExercise({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.targetChords,
    this.technique,
    this.key,
    required this.recommendedBpm,
    required this.difficulty,
  });
}

class TabDifficultyAnalysis {
  final TabDifficulty difficulty;
  final int totalNotes;
  final int techniqueCount;
  final int maxFretUsed;
  final int stringsUsed;
  final double maxTempo;
  final int bendCount;
  final int slideCount;
  final int hammerOnCount;
  final int pullOffCount;
  final int vibratoCount;
  
  const TabDifficultyAnalysis({
    required this.difficulty,
    required this.totalNotes,
    required this.techniqueCount,
    required this.maxFretUsed,
    required this.stringsUsed,
    required this.maxTempo,
    required this.bendCount,
    required this.slideCount,
    required this.hammerOnCount,
    required this.pullOffCount,
    required this.vibratoCount,
  });
  
  factory TabDifficultyAnalysis.empty() {
    return const TabDifficultyAnalysis(
      difficulty: TabDifficulty.beginner,
      totalNotes: 0,
      techniqueCount: 0,
      maxFretUsed: 0,
      stringsUsed: 0,
      maxTempo: 0,
      bendCount: 0,
      slideCount: 0,
      hammerOnCount: 0,
      pullOffCount: 0,
      vibratoCount: 0,
    );
  }
  
  double get techniqueRatio => totalNotes > 0 ? techniqueCount / totalNotes : 0.0;
  
  double get fretSpread => maxFretUsed.toDouble();
  
  TabDifficulty get calculatedDifficulty {
    int score = 0;
    
    // Tempo scoring
    if (maxTempo > 140) score += 2;
    else if (maxTempo > 100) score += 1;
    
    // Fret usage scoring
    if (maxFretUsed > 12) score += 2;
    else if (maxFretUsed > 7) score += 1;
    
    // Technique scoring
    if (techniqueRatio > 0.3) score += 2;
    else if (techniqueRatio > 0.1) score += 1;
    
    // String usage scoring
    if (stringsUsed >= 6) score += 1;
    
    if (score >= 5) return TabDifficulty.advanced;
    if (score >= 3) return TabDifficulty.intermediate;
    return TabDifficulty.beginner;
  }
}

// Enums
enum TabDifficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

enum NoteDuration {
  whole,
  half,
  quarter,
  eighth,
  sixteenth,
  thirtysecond,
}

enum TabTechnique {
  bend,
  slide,
  hammerOn,
  pullOff,
  vibrato,
  palmMute,
  tapping,
  sweep,
  tremolo,
  harmonics,
}

enum PlaybackEventType {
  started,
  paused,
  stopped,
  seeked,
  speedChanged,
  positionUpdate,
}

enum PracticeEventType {
  modeEntered,
  modeExited,
  loopEnabled,
  loopDisabled,
  loopRestarted,
}

enum ExerciseType {
  chordProgression,
  technique,
  scale,
  rhythm,
  melody,
}

enum ExportFormat {
  ascii,
  musicXml,
  gp5,
  json,
}

class TablatureException implements Exception {
  final String message;
  
  const TablatureException(this.message);
  
  @override
  String toString() => 'TablatureException: $message';
}

// Riverpod providers
final tablatureServiceProvider = Provider<TablatureService>((ref) {
  return TablatureService();
});

final currentTabProvider = Provider<TablatureScore?>((ref) {
  final service = ref.read(tablatureServiceProvider);
  return service.currentTab;
});

final playbackStateProvider = StreamProvider<PlaybackEvent>((ref) {
  final service = ref.read(tablatureServiceProvider);
  return service.playbackEvents;
});

final tabPositionProvider = StreamProvider<TabPosition>((ref) {
  final service = ref.read(tablatureServiceProvider);
  return service.positionEvents;
});

final practiceEventsProvider = StreamProvider<PracticeEvent>((ref) {
  final service = ref.read(tablatureServiceProvider);
  return service.practiceEvents;
});

final tabDifficultyAnalysisProvider = Provider<TabDifficultyAnalysis>((ref) {
  final service = ref.read(tablatureServiceProvider);
  return service.analyzeDifficulty();
});

final practiceExercisesProvider = Provider<List<PracticeExercise>>((ref) {
  final service = ref.read(tablatureServiceProvider);
  return service.generatePracticeExercises();
});