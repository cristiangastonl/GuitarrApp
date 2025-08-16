import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/services/backing_track_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Audio preview controls widget with glassmorphic design
class AudioPreviewControls extends ConsumerWidget {
  final String trackId;
  final String artist;
  final String trackName;
  final String? previewUrl;
  final VoidCallback? onPlayingChanged;
  
  const AudioPreviewControls({
    super.key,
    required this.trackId,
    required this.artist,
    required this.trackName,
    this.previewUrl,
    this.onPlayingChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerServiceProvider);
    final audioService = ref.read(audioPlayerServiceProvider.notifier);
    final backingTrack = ref.watch(backingTrackByIdProvider(trackId));
    final isThisTrackPlaying = audioState.isTrackPlaying(trackId);
    final isLoading = audioState.isLoading && audioState.currentTrackId == trackId;
    
    // Use backing track info if available, otherwise fallback to provided values
    final displayName = backingTrack?.name ?? trackName;
    final displayArtist = backingTrack?.artist ?? artist;
    final hasBackingTrack = backingTrack?.hasAudio ?? false;
    
    return Container(
      decoration: BoxDecoration(
        color: GuitarrColors.glassOverlay,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: GuitarrColors.glassBorderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button and Track Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Play/Pause Button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        GuitarrColors.ampOrange,
                        GuitarrColors.ampOrange.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: GuitarrColors.ampOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: isLoading ? null : () async {
                        if (hasBackingTrack) {
                          await audioService.playBackingTrack(trackId);
                        } else if (previewUrl != null) {
                          await audioService.playPreviewUrl(previewUrl!, trackId);
                        } else {
                          await audioService.playTrackPreview(artist, trackName, trackId);
                        }
                        onPlayingChanged?.call();
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Center(
                          key: ValueKey(isLoading ? 'loading' : isThisTrackPlaying ? 'pause' : 'play'),
                          child: isLoading
                              ? TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 1200),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Transform.rotate(
                                      angle: value * 2 * 3.14159,
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : AnimatedScale(
                                  scale: isThisTrackPlaying ? 1.1 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: Icon(
                                    isThisTrackPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Track Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GuitarrTypography.labelLarge.copyWith(
                          color: GuitarrColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        displayArtist,
                        style: GuitarrTypography.labelMedium.copyWith(
                          color: GuitarrColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: GuitarrColors.ampOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: GuitarrColors.ampOrange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          hasBackingTrack ? 'Backing Track' : backingTrack != null ? 'Coming Soon' : '30s Preview',
                          style: GuitarrTypography.labelSmall.copyWith(
                            color: hasBackingTrack ? GuitarrColors.guitarTeal : 
                                   backingTrack != null ? GuitarrColors.warning : GuitarrColors.ampOrange,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Volume/More Button
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: GuitarrColors.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: GuitarrColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        // TODO: Show volume control or more options
                      },
                      child: Icon(
                        Icons.volume_up,
                        color: GuitarrColors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Progress Bar (only show when playing this track)
          if (isThisTrackPlaying || (audioState.currentTrackId == trackId && audioState.position.inSeconds > 0))
            _ProgressBar(
              position: audioState.position,
              duration: audioState.duration ?? const Duration(seconds: 30),
              onSeek: (position) => audioService.seek(position),
            ),
        ],
      ),
    );
  }
}

/// Progress bar for audio preview
class _ProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  
  const _ProgressBar({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds > 0 
        ? position.inMilliseconds / duration.inMilliseconds 
        : 0.0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // Progress slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: GuitarrColors.ampOrange,
              inactiveTrackColor: GuitarrColors.metronomeInactive,
              thumbColor: GuitarrColors.ampOrange,
              overlayColor: GuitarrColors.ampOrange.withOpacity(0.2),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (value * duration.inMilliseconds).round(),
                );
                onSeek(newPosition);
              },
            ),
          ),
          
          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: GuitarrTypography.labelSmall.copyWith(
                    color: GuitarrColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: GuitarrTypography.labelSmall.copyWith(
                    color: GuitarrColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
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

/// Compact audio preview controls for smaller spaces
class CompactAudioPreviewControls extends ConsumerWidget {
  final String trackId;
  final String artist;
  final String trackName;
  final String? previewUrl;
  
  const CompactAudioPreviewControls({
    super.key,
    required this.trackId,
    required this.artist,
    required this.trackName,
    this.previewUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerServiceProvider);
    final audioService = ref.read(audioPlayerServiceProvider.notifier);
    final isThisTrackPlaying = audioState.isTrackPlaying(trackId);
    final isLoading = audioState.isLoading && audioState.currentTrackId == trackId;
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GuitarrColors.ampOrange,
            GuitarrColors.ampOrange.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: GuitarrColors.ampOrange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isLoading ? null : () async {
            if (previewUrl != null) {
              await audioService.playPreviewUrl(previewUrl!, trackId);
            } else {
              await audioService.playTrackPreview(artist, trackName, trackId);
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Center(
              key: ValueKey(isLoading ? 'loading' : isThisTrackPlaying ? 'pause' : 'play'),
              child: isLoading
                  ? TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 2 * 3.14159,
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    )
                  : AnimatedScale(
                      scale: isThisTrackPlaying ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        isThisTrackPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}