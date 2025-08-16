import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../audio/metronome_service.dart';
import 'input_validation_service.dart';

/// Recording state model
class RecordingState {
  final bool isRecording;
  final bool isPlaying;
  final bool isLoading;
  final Duration recordingDuration;
  final Duration playbackPosition;
  final String? currentRecordingPath;
  final String? error;
  final List<RecordingFile> recordings;
  final int? recordingBpm;
  final bool isMetronomeSync;
  
  const RecordingState({
    this.isRecording = false,
    this.isPlaying = false,
    this.isLoading = false,
    this.recordingDuration = Duration.zero,
    this.playbackPosition = Duration.zero,
    this.currentRecordingPath,
    this.error,
    this.recordings = const [],
    this.recordingBpm,
    this.isMetronomeSync = false,
  });
  
  RecordingState copyWith({
    bool? isRecording,
    bool? isPlaying,
    bool? isLoading,
    Duration? recordingDuration,
    Duration? playbackPosition,
    String? currentRecordingPath,
    String? error,
    List<RecordingFile>? recordings,
    int? recordingBpm,
    bool? isMetronomeSync,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      currentRecordingPath: currentRecordingPath ?? this.currentRecordingPath,
      error: error,
      recordings: recordings ?? this.recordings,
      recordingBpm: recordingBpm ?? this.recordingBpm,
      isMetronomeSync: isMetronomeSync ?? this.isMetronomeSync,
    );
  }
}

/// Recording file model
class RecordingFile {
  final String path;
  final String name;
  final DateTime createdAt;
  final Duration duration;
  final int fileSize;
  final int? bpm;
  
  const RecordingFile({
    required this.path,
    required this.name,
    required this.createdAt,
    required this.duration,
    required this.fileSize,
    this.bpm,
  });
  
  String get formattedDuration {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  String get formattedSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// Recording service for practice sessions
class RecordingService extends StateNotifier<RecordingState> {
  final FlutterSoundRecorder _recorder;
  final FlutterSoundPlayer _player;
  final Ref _ref;
  
  RecordingService(this._ref) 
      : _recorder = FlutterSoundRecorder(),
        _player = FlutterSoundPlayer(),
        super(const RecordingState()) {
    _initializeRecorder();
  }
  
  Future<void> _initializeRecorder() async {
    try {
      // Request microphone permission
      final permission = await Permission.microphone.request();
      if (permission != PermissionStatus.granted) {
        state = state.copyWith(error: 'Microphone permission required');
        return;
      }
      
      // Initialize recorder
      await _recorder.openRecorder();
      await _player.openPlayer();
      
      // Load existing recordings
      await _loadRecordings();
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize recorder: $e');
    }
  }
  
  /// Start recording a practice session
  Future<void> startRecording({String? sessionName, bool syncWithMetronome = false}) async {
    if (state.isRecording) return;
    
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Get current metronome state if syncing
      int? currentBpm;
      bool metronomeWasPlaying = false;
      
      if (syncWithMetronome) {
        final metronomeState = _ref.read(metronomeStateProvider);
        currentBpm = metronomeState.bpm;
        metronomeWasPlaying = metronomeState.isPlaying;
        
        // Auto-start metronome if not playing
        if (!metronomeWasPlaying) {
          _ref.read(metronomeStateProvider.notifier).start();
        }
      }
      
      String? filePath;
      
      if (kIsWeb) {
        // For web, record to a temporary blob (use default codec for web)
        await _recorder.startRecorder(
          codec: Codec.defaultCodec,
          bitRate: 96000,
          sampleRate: 44100,
        );
        filePath = 'web_recording_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // For mobile/desktop, use file system
        final directory = await _getRecordingsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        // Sanitize session name for security
        String sanitizedSessionName;
        if (sessionName != null) {
          sanitizedSessionName = ValidationUtils.sanitizeSessionName(sessionName);
        } else {
          sanitizedSessionName = 'practice_session_$timestamp';
        }
        
        filePath = '${directory.path}/$sanitizedSessionName.aac';
        
        await _recorder.startRecorder(
          toFile: filePath,
          codec: Codec.aacADTS,
          bitRate: 96000,
          sampleRate: 44100,
        );
      }
      
      state = state.copyWith(
        isRecording: true,
        isLoading: false,
        currentRecordingPath: filePath,
        recordingDuration: Duration.zero,
        recordingBpm: currentBpm,
        isMetronomeSync: syncWithMetronome,
      );
      
      // Start duration timer
      _startDurationTimer();
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start recording: $e',
      );
    }
  }
  
  /// Stop recording
  Future<void> stopRecording() async {
    if (!state.isRecording) return;
    
    try {
      state = state.copyWith(isLoading: true);
      
      await _recorder.stopRecorder();
      
      // If metronome was auto-started for this recording, optionally stop it
      // (User preference - for now we keep it running)
      
      state = state.copyWith(
        isRecording: false,
        isLoading: false,
        recordingBpm: null,
        isMetronomeSync: false,
      );
      
      // Reload recordings list
      await _loadRecordings();
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to stop recording: $e',
      );
    }
  }
  
  /// Play a recording
  Future<void> playRecording(String filePath) async {
    try {
      if (state.isPlaying) {
        await _player.stopPlayer();
      }
      
      state = state.copyWith(isLoading: true, error: null);
      
      await _player.startPlayer(
        fromURI: filePath,
        whenFinished: () {
          state = state.copyWith(
            isPlaying: false,
            playbackPosition: Duration.zero,
          );
        },
      );
      
      state = state.copyWith(
        isPlaying: true,
        isLoading: false,
        currentRecordingPath: filePath,
      );
      
      // Start playback position timer
      _startPlaybackTimer();
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to play recording: $e',
      );
    }
  }
  
  /// Stop playback
  Future<void> stopPlayback() async {
    try {
      await _player.stopPlayer();
      state = state.copyWith(
        isPlaying: false,
        playbackPosition: Duration.zero,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to stop playback: $e');
    }
  }
  
  /// Delete a recording
  Future<void> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Reload recordings list
      await _loadRecordings();
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete recording: $e');
    }
  }
  
  /// Load all recordings from storage
  Future<void> _loadRecordings() async {
    if (kIsWeb) {
      // For web, we don't persist recordings yet
      // In the future, could use IndexedDB or cloud storage
      state = state.copyWith(recordings: []);
      return;
    }
    
    try {
      final directory = await _getRecordingsDirectory();
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final files = directory.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.aac'))
          .toList();
      
      final recordings = <RecordingFile>[];
      
      for (final file in files) {
        final stat = await file.stat();
        final name = file.path.split('/').last.replaceAll('.aac', '');
        
        // Estimate duration (will be more accurate when we implement proper duration detection)
        final estimatedDuration = Duration(seconds: (stat.size / 12000).round());
        
        // Extract BPM from filename if available
        int? bpm;
        final bpmMatch = RegExp(r'(\d+)bpm').firstMatch(name);
        if (bpmMatch != null) {
          bpm = int.tryParse(bpmMatch.group(1)!);
        }
        
        recordings.add(RecordingFile(
          path: file.path,
          name: name,
          createdAt: stat.modified,
          duration: estimatedDuration,
          fileSize: stat.size,
          bpm: bpm,
        ));
      }
      
      // Sort by creation date (newest first)
      recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      state = state.copyWith(recordings: recordings);
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to load recordings: $e');
    }
  }
  
  /// Get recordings directory (Web compatible)
  Future<Directory> _getRecordingsDirectory() async {
    if (kIsWeb) {
      // For web, we'll use a temporary directory approach
      // Note: Web doesn't have persistent file storage like mobile
      throw UnsupportedError('File storage not available on web. Consider using IndexedDB or cloud storage.');
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      return Directory('${appDocDir.path}/recordings');
    }
  }
  
  /// Start recording duration timer
  void _startDurationTimer() {
    if (!state.isRecording) return;
    
    Future.delayed(const Duration(seconds: 1), () {
      if (state.isRecording) {
        state = state.copyWith(
          recordingDuration: Duration(seconds: state.recordingDuration.inSeconds + 1),
        );
        _startDurationTimer();
      }
    });
  }
  
  /// Start playback position timer
  void _startPlaybackTimer() {
    if (!state.isPlaying) return;
    
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (state.isPlaying) {
        try {
          // Use player state stream instead of getProgress for better compatibility
          _startPlaybackTimer();
        } catch (e) {
          // Ignore errors during position updates
        }
      }
    });
  }
  
  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }
}

/// Providers
final recordingServiceProvider = StateNotifierProvider<RecordingService, RecordingState>((ref) {
  return RecordingService(ref);
});

/// Provider for recordings list
final recordingsListProvider = Provider<List<RecordingFile>>((ref) {
  return ref.watch(recordingServiceProvider).recordings;
});

/// Provider for current recording state
final isRecordingProvider = Provider<bool>((ref) {
  return ref.watch(recordingServiceProvider).isRecording;
});

/// Provider for current playback state
final isPlayingRecordingProvider = Provider<bool>((ref) {
  return ref.watch(recordingServiceProvider).isPlaying;
});