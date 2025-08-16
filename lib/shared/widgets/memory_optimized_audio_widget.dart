import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'glass_card.dart';

/// Memory-optimized audio widget with automatic resource cleanup
class MemoryOptimizedAudioWidget extends StatefulWidget {
  final String audioPath;
  final VoidCallback? onPlayComplete;
  final bool autoDispose;
  final Duration maxDuration;

  const MemoryOptimizedAudioWidget({
    super.key,
    required this.audioPath,
    this.onPlayComplete,
    this.autoDispose = true,
    this.maxDuration = const Duration(minutes: 10),
  });

  @override
  State<MemoryOptimizedAudioWidget> createState() => _MemoryOptimizedAudioWidgetState();
}

class _MemoryOptimizedAudioWidgetState extends State<MemoryOptimizedAudioWidget>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  // Audio player instance (would be actual audio player in production)
  Timer? _playbackTimer;
  Timer? _inactivityTimer;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isDisposed = false;
  
  static const Duration _inactivityTimeout = Duration(minutes: 5);
  static const Duration _positionUpdateInterval = Duration(milliseconds: 100);

  @override
  bool get wantKeepAlive => _isPlaying && !_isDisposed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAudio();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeResources();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _pauseAudio();
        break;
      case AppLifecycleState.resumed:
        // Resume only if user was playing before
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        _pauseAudio();
        break;
    }
  }

  Future<void> _loadAudio() async {
    if (_isDisposed) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate loading audio file
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!_isDisposed) {
        setState(() {
          _totalDuration = const Duration(minutes: 3); // Mock duration
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _togglePlayback() {
    if (_isDisposed) return;
    
    if (_isPlaying) {
      _pauseAudio();
    } else {
      _playAudio();
    }
  }

  void _playAudio() {
    if (_isDisposed) return;
    
    setState(() {
      _isPlaying = true;
    });

    _playbackTimer = Timer.periodic(_positionUpdateInterval, (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentPosition = _currentPosition + _positionUpdateInterval;
        
        if (_currentPosition >= _totalDuration) {
          _stopAudio();
          widget.onPlayComplete?.call();
        }
      });
    });

    _resetInactivityTimer();
    updateKeepAlive();
  }

  void _pauseAudio() {
    if (_isDisposed) return;
    
    setState(() {
      _isPlaying = false;
    });

    _playbackTimer?.cancel();
    _playbackTimer = null;
    _resetInactivityTimer();
    updateKeepAlive();
  }

  void _stopAudio() {
    if (_isDisposed) return;
    
    _pauseAudio();
    setState(() {
      _currentPosition = Duration.zero;
    });
  }

  void _seekTo(Duration position) {
    if (_isDisposed) return;
    
    setState(() {
      _currentPosition = position.clamp(Duration.zero, _totalDuration);
    });
    _resetInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer = Timer(_inactivityTimeout, () {
      if (widget.autoDispose && !_isPlaying) {
        _disposeResources();
      }
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _startInactivityTimer();
  }

  void _disposeResources() {
    if (_isDisposed) return;
    _isDisposed = true;
    
    _playbackTimer?.cancel();
    _inactivityTimer?.cancel();
    _playbackTimer = null;
    _inactivityTimer = null;
    
    // Clean up audio resources here in production
    debugPrint('Audio resources disposed for: ${widget.audioPath}');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isDisposed) {
      return _buildDisposedState();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    return RepaintBoundary(
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Glassmorphic play button
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        GuitarrColors.ampOrange,
                        GuitarrColors.ampOrangeDark,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GuitarrColors.ampOrange.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _togglePlayback,
                      borderRadius: BorderRadius.circular(28),
                      child: Center(
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressBar(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_currentPosition),
                            style: GuitarrTypography.timerDisplay.copyWith(
                              color: GuitarrColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(_totalDuration),
                            style: GuitarrTypography.timerDisplay.copyWith(
                              color: GuitarrColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isPlaying) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: GuitarrColors.ampOrange.withOpacity(0.15),
                  border: Border.all(
                    color: GuitarrColors.ampOrange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up,
                      size: 16,
                      color: GuitarrColors.ampOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reproduciendo',
                      style: GuitarrTypography.labelMedium.copyWith(
                        color: GuitarrColors.ampOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final tapPosition = details.localPosition.dx / box.size.width;
        final seekPosition = Duration(
          milliseconds: (_totalDuration.inMilliseconds * tapPosition).round(),
        );
        _seekTo(seekPosition);
      },
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: GuitarrColors.metronomeInactive,
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                colors: [
                  GuitarrColors.ampOrange,
                  GuitarrColors.ampOrangeDark,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: GuitarrColors.ampOrange,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando audio...',
            style: GuitarrTypography.bodyMedium.copyWith(
              color: GuitarrColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisposedState() {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      backgroundColor: GuitarrColors.surface1.withOpacity(0.3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_off,
            size: 48,
            color: GuitarrColors.textTertiary.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Audio liberado de memoria',
            style: GuitarrTypography.bodyMedium.copyWith(
              color: GuitarrColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Optimización de memoria activa',
            style: GuitarrTypography.labelSmall.copyWith(
              color: GuitarrColors.textTertiary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}