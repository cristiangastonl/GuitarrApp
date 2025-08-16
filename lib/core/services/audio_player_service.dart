import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'spotify_service.dart';
import 'backing_track_service.dart';
import 'secure_logging_service.dart';

/// Audio player state for track previews
class AudioPlayerState {
  final bool isPlaying;
  final bool isLoading;
  final Duration? duration;
  final Duration position;
  final String? currentTrackId;
  final String? error;
  final double volume;
  
  const AudioPlayerState({
    this.isPlaying = false,
    this.isLoading = false,
    this.duration,
    this.position = Duration.zero,
    this.currentTrackId,
    this.error,
    this.volume = 1.0,
  });
  
  AudioPlayerState copyWith({
    bool? isPlaying,
    bool? isLoading,
    Duration? duration,
    Duration? position,
    String? currentTrackId,
    String? error,
    double? volume,
  }) {
    return AudioPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      currentTrackId: currentTrackId ?? this.currentTrackId,
      error: error,
      volume: volume ?? this.volume,
    );
  }
  
  /// Get progress percentage (0.0 to 1.0)
  double get progress {
    if (duration == null || duration!.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration!.inMilliseconds;
  }
  
  /// Check if specific track is currently playing
  bool isTrackPlaying(String trackId) {
    return isPlaying && currentTrackId == trackId;
  }
}

/// Audio Player Service for handling track preview playback
class AudioPlayerService extends StateNotifier<AudioPlayerState> {
  final AudioPlayer _player;
  final SpotifyService _spotifyService;
  final BackingTrackService _backingTrackService;
  
  AudioPlayerService(this._spotifyService, this._backingTrackService) 
      : _player = AudioPlayer(), 
        super(const AudioPlayerState()) {
    _initializePlayer();
  }
  
  void _initializePlayer() {
    // Listen to player state changes
    _player.playerStateStream.listen((playerState) {
      state = state.copyWith(
        isPlaying: playerState.playing,
        isLoading: playerState.processingState == ProcessingState.loading ||
                   playerState.processingState == ProcessingState.buffering,
      );
    });
    
    // Listen to duration changes
    _player.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });
    
    // Listen to position changes
    _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });
    
    // Listen to playback completion
    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        state = state.copyWith(
          isPlaying: false,
          position: Duration.zero,
        );
      }
    });
  }
  
  /// Play backing track by track ID
  Future<void> playBackingTrack(String trackId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // If same track is playing, just toggle play/pause
      if (state.currentTrackId == trackId && state.isPlaying) {
        await pause();
        return;
      }
      
      // Get backing track info
      final backingTrack = _backingTrackService.getBackingTrackById(trackId);
      
      if (backingTrack == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Backing track not found',
        );
        return;
      }
      
      if (!backingTrack.hasAudio) {
        state = state.copyWith(
          isLoading: false,
          error: 'No audio available for this track',
        );
        return;
      }
      
      // Stop current playback if any
      await _player.stop();
      
      // Load and play backing track
      if (backingTrack.audioPath.startsWith('http')) {
        await _player.setUrl(backingTrack.fullAudioPath);
      } else {
        await _player.setAsset(backingTrack.fullAudioPath);
      }
      state = state.copyWith(
        currentTrackId: trackId,
        isLoading: false,
        error: null,
      );
      
      await _player.play();
      
    } catch (e) {
      SecureLoggingService.error('Error playing backing track', tag: LogTags.audio, error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to play backing track: ${e.toString()}',
      );
    }
  }

  /// Play track preview by searching Spotify (fallback)
  Future<void> playTrackPreview(String artist, String trackName, String trackId) async {
    // Try backing track first
    final backingTrack = _backingTrackService.getBackingTrackById(trackId);
    if (backingTrack != null && backingTrack.hasAudio) {
      await playBackingTrack(trackId);
      return;
    }
    
    // Fallback to Spotify if no backing track
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // If same track is playing, just toggle play/pause
      if (state.currentTrackId == trackId && state.isPlaying) {
        await pause();
        return;
      }
      
      // Search for track preview
      final preview = await _spotifyService.searchTrackPreview(artist, trackName);
      
      if (preview?.previewUrl == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No preview available for this track',
        );
        return;
      }
      
      // Stop current playback if any
      await _player.stop();
      
      // Load and play new track
      await _player.setUrl(preview!.previewUrl!);
      state = state.copyWith(
        currentTrackId: trackId,
        isLoading: false,
        error: null,
      );
      
      await _player.play();
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to play track: ${e.toString()}',
      );
    }
  }
  
  /// Play preview from direct URL (for local files or cached previews)
  Future<void> playPreviewUrl(String previewUrl, String trackId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // If same track is playing, just toggle play/pause
      if (state.currentTrackId == trackId && state.isPlaying) {
        await pause();
        return;
      }
      
      // Stop current playback if any
      await _player.stop();
      
      // Load and play track
      await _player.setUrl(previewUrl);
      state = state.copyWith(
        currentTrackId: trackId,
        isLoading: false,
        error: null,
      );
      
      await _player.play();
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to play preview: ${e.toString()}',
      );
    }
  }
  
  /// Pause playback
  Future<void> pause() async {
    await _player.pause();
  }
  
  /// Resume playback
  Future<void> resume() async {
    await _player.play();
  }
  
  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
    state = state.copyWith(
      isPlaying: false,
      position: Duration.zero,
      currentTrackId: null,
    );
  }
  
  /// Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
  
  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
    state = state.copyWith(volume: volume);
  }
  
  /// Toggle play/pause for current track
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }
  
  /// Check if currently playing
  bool get isPlaying => state.isPlaying;
  
  /// Get current track URL
  String? get currentUrl => _player.audioSource?.toString();
  
  /// Play from URL (alias for playPreviewUrl)
  Future<void> playFromUrl(String url) async {
    await playPreviewUrl(url, 'url_track_${DateTime.now().millisecondsSinceEpoch}');
  }
  
  /// Stream of playing state
  Stream<bool> get isPlayingStream => stream.map((state) => state.isPlaying);
  
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

/// Riverpod provider for AudioPlayerService
final audioPlayerServiceProvider = StateNotifierProvider<AudioPlayerService, AudioPlayerState>((ref) {
  final spotifyService = ref.read(spotifyServiceProvider);
  final backingTrackService = ref.read(backingTrackServiceProvider);
  return AudioPlayerService(spotifyService, backingTrackService);
});

/// Provider to check if a specific track is playing
final isTrackPlayingProvider = Provider.family<bool, String>((ref, trackId) {
  final audioState = ref.watch(audioPlayerServiceProvider);
  return audioState.isTrackPlaying(trackId);
});

/// Provider for current playing track info
final currentTrackProvider = Provider<String?>((ref) {
  final audioState = ref.watch(audioPlayerServiceProvider);
  return audioState.currentTrackId;
});

/// Provider for playback progress
final playbackProgressProvider = Provider<double>((ref) {
  final audioState = ref.watch(audioPlayerServiceProvider);
  return audioState.progress;
});