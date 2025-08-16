import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/intelligent_backing_tracks_service.dart';
import '../../core/services/audio_player_service.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'glass_card.dart';

class IntelligentBackingTracksWidget extends ConsumerStatefulWidget {
  final String songRiffId;
  final String userId;
  final String genre;
  
  const IntelligentBackingTracksWidget({
    super.key,
    required this.songRiffId,
    required this.userId,
    required this.genre,
  });

  @override
  ConsumerState<IntelligentBackingTracksWidget> createState() => _IntelligentBackingTracksWidgetState();
}

class _IntelligentBackingTracksWidgetState extends ConsumerState<IntelligentBackingTracksWidget> {
  BackingTrackStyle? _selectedStyle;
  int? _customBpm;
  BackingTrackComplexity? _selectedComplexity;
  bool _isCustomizing = false;
  BackingTrack? _currentTrack;
  
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildControls(),
          const SizedBox(height: 16),
          _buildBackingTrackSection(),
          if (_currentTrack != null) ...[
            const SizedBox(height: 16),
            _buildCustomizationPanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                GuitarrColors.accent,
                GuitarrColors.accent.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.queue_music,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Backing Tracks',
                style: GuitarrTypography.headlineSmall.copyWith(
                  color: GuitarrColors.textPrimary,
                ),
              ),
              Text(
                'Intelligent accompaniment for your practice',
                style: GuitarrTypography.bodySmall.copyWith(
                  color: GuitarrColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _showInfoDialog(),
          icon: Icon(
            Icons.info_outline,
            color: GuitarrColors.textSecondary,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    final availableStyles = ref.watch(availableStylesProvider(widget.genre));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStyleSelector(availableStyles),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildComplexitySelector(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBpmSelector(),
      ],
    );
  }

  Widget _buildStyleSelector(List<BackingTrackStyle> availableStyles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Style',
          style: GuitarrTypography.bodySmall.copyWith(
            color: GuitarrColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: GuitarrColors.cardBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GuitarrColors.primary.withOpacity(0.3)),
          ),
          child: DropdownButton<BackingTrackStyle>(
            value: _selectedStyle,
            hint: Text(
              'Auto Select',
              style: GuitarrTypography.bodySmall.copyWith(
                color: GuitarrColors.textSecondary,
              ),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: GuitarrColors.cardBackground,
            items: [
              DropdownMenuItem<BackingTrackStyle>(
                value: null,
                child: Text(
                  'Auto Select',
                  style: GuitarrTypography.bodySmall.copyWith(
                    color: GuitarrColors.textPrimary,
                  ),
                ),
              ),
              ...availableStyles.map((style) => DropdownMenuItem(
                value: style,
                child: Text(
                  style.displayName,
                  style: GuitarrTypography.bodySmall.copyWith(
                    color: GuitarrColors.textPrimary,
                  ),
                ),
              )),
            ],
            onChanged: (style) {
              setState(() {
                _selectedStyle = style;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComplexitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complexity',
          style: GuitarrTypography.bodySmall.copyWith(
            color: GuitarrColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: GuitarrColors.cardBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GuitarrColors.primary.withOpacity(0.3)),
          ),
          child: DropdownButton<BackingTrackComplexity>(
            value: _selectedComplexity,
            hint: Text(
              'Auto Select',
              style: GuitarrTypography.bodySmall.copyWith(
                color: GuitarrColors.textSecondary,
              ),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: GuitarrColors.cardBackground,
            items: [
              DropdownMenuItem<BackingTrackComplexity>(
                value: null,
                child: Text(
                  'Auto Select',
                  style: GuitarrTypography.bodySmall.copyWith(
                    color: GuitarrColors.textPrimary,
                  ),
                ),
              ),
              ...BackingTrackComplexity.values.map((complexity) => DropdownMenuItem(
                value: complexity,
                child: Text(
                  complexity.displayName,
                  style: GuitarrTypography.bodySmall.copyWith(
                    color: GuitarrColors.textPrimary,
                  ),
                ),
              )),
            ],
            onChanged: (complexity) {
              setState(() {
                _selectedComplexity = complexity;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBpmSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'BPM',
              style: GuitarrTypography.bodySmall.copyWith(
                color: GuitarrColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _customBpm?.toString() ?? 'Auto',
              style: GuitarrTypography.bodySmall.copyWith(
                color: GuitarrColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_customBpm != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _customBpm = null;
                  });
                },
                child: Text(
                  'Reset',
                  style: GuitarrTypography.bodySmall.copyWith(
                    color: GuitarrColors.secondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Slider(
          value: (_customBpm ?? 120).toDouble(),
          min: 60,
          max: 200,
          divisions: 140,
          activeColor: GuitarrColors.primary,
          inactiveColor: GuitarrColors.primary.withOpacity(0.3),
          onChanged: (value) {
            setState(() {
              _customBpm = value.round();
            });
          },
        ),
      ],
    );
  }

  Widget _buildBackingTrackSection() {
    final request = BackingTrackRequest(
      songRiffId: widget.songRiffId,
      userId: widget.userId,
      preferredStyle: _selectedStyle,
      customBpm: _customBpm,
      complexity: _selectedComplexity,
    );
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _generateBackingTrack(request),
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text('Generate AI Track'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GuitarrColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => _showTrackHistory(),
              icon: Icon(
                Icons.history,
                color: GuitarrColors.secondary,
              ),
              tooltip: 'Track History',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCurrentTrackDisplay(),
      ],
    );
  }

  Widget _buildCurrentTrackDisplay() {
    if (_currentTrack == null) {
      return _buildEmptyTrackState();
    }
    
    final audioPlayerService = ref.watch(audioPlayerServiceProvider.notifier);
    
    return GlassCard(
      blurIntensity: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentTrack!.name,
                        style: GuitarrTypography.bodyLarge.copyWith(
                          color: GuitarrColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildTrackDetails(_currentTrack!),
                    ],
                  ),
                ),
                _buildQualityBadge(_currentTrack!.quality),
              ],
            ),
            const SizedBox(height: 12),
            _buildTrackControls(_currentTrack!, audioPlayerService),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackDetails(BackingTrack track) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildDetailChip('${track.bpm} BPM', GuitarrColors.primary),
        _buildDetailChip(track.style.displayName, GuitarrColors.secondary),
        _buildDetailChip(track.complexity.displayName, GuitarrColors.accent),
        _buildDetailChip(track.keySignature, GuitarrColors.info),
        _buildDetailChip('${track.enabledInstruments.length} instruments', GuitarrColors.warning),
      ],
    );
  }

  Widget _buildDetailChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GuitarrTypography.bodySmall.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildQualityBadge(BackingTrackQuality quality) {
    final color = switch (quality) {
      BackingTrackQuality.professional => GuitarrColors.success,
      BackingTrackQuality.high => GuitarrColors.primary,
      BackingTrackQuality.medium => GuitarrColors.warning,
      BackingTrackQuality.basic => GuitarrColors.textSecondary,
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            quality.displayName,
            style: GuitarrTypography.bodySmall.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackControls(BackingTrack track, AudioPlayerService audioPlayer) {
    return Row(
        children: [
          StreamBuilder<bool>(
            stream: audioPlayer.isPlayingStream,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? false;
              final currentUrl = audioPlayer.currentUrl;
              final isThisTrack = currentUrl == track.audioPath;
              
              return ElevatedButton.icon(
                onPressed: () => _togglePlayback(audioPlayer, track.audioPath),
                icon: Icon(
                  (isPlaying && isThisTrack) ? Icons.pause : Icons.play_arrow,
                  size: 20,
                ),
                label: Text((isPlaying && isThisTrack) ? 'Pause' : 'Play'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GuitarrColors.primary,
                  foregroundColor: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isCustomizing = !_isCustomizing;
              });
            },
            icon: Icon(
              _isCustomizing ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 20,
            ),
            label: Text(_isCustomizing ? 'Hide Options' : 'Customize'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GuitarrColors.secondary,
              foregroundColor: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _downloadTrack(track),
            icon: Icon(
              Icons.download,
              color: GuitarrColors.accent,
            ),
            tooltip: 'Download',
          ),
          IconButton(
            onPressed: () => _shareTrack(track),
            icon: Icon(
              Icons.share,
              color: GuitarrColors.info,
            ),
            tooltip: 'Share',
          ),
        ],
      );
  }

  Widget _buildCustomizationPanel() {
    if (!_isCustomizing || _currentTrack == null) return const SizedBox();
    
    return GlassCard(
      blurIntensity: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customize Track',
              style: GuitarrTypography.bodyLarge.copyWith(
                color: GuitarrColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInstrumentControls(),
            const SizedBox(height: 16),
            _buildVolumeControls(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyCustomizations(),
                    child: const Text('Apply Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GuitarrColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _resetCustomizations(),
                  child: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GuitarrColors.textSecondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrumentControls() {
    if (_currentTrack == null) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instruments',
          style: GuitarrTypography.bodyMedium.copyWith(
            color: GuitarrColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _currentTrack!.enabledInstruments.map((instrument) {
            return FilterChip(
              label: Text(instrument.displayName),
              selected: true,
              onSelected: (selected) {
                // Handle instrument toggle
              },
              selectedColor: GuitarrColors.primary.withOpacity(0.3),
              labelStyle: GuitarrTypography.bodySmall.copyWith(
                color: GuitarrColors.textPrimary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVolumeControls() {
    if (_currentTrack == null) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Volume Mix',
          style: GuitarrTypography.bodyMedium.copyWith(
            color: GuitarrColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...(_currentTrack!.instrumentVolumes.entries.take(4).map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    entry.key.displayName,
                    style: GuitarrTypography.bodySmall.copyWith(
                      color: GuitarrColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: entry.value,
                    min: 0.0,
                    max: 1.0,
                    activeColor: GuitarrColors.primary,
                    inactiveColor: GuitarrColors.primary.withOpacity(0.3),
                    onChanged: (value) {
                      // Handle volume change
                    },
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(entry.value * 100).round()}%',
                    style: GuitarrTypography.bodySmall.copyWith(
                      color: GuitarrColors.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        })),
      ],
    );
  }

  Widget _buildEmptyTrackState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.queue_music,
            color: GuitarrColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No backing track generated',
            style: GuitarrTypography.bodyLarge.copyWith(
              color: GuitarrColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Generate AI Track" to create an intelligent backing track',
            style: GuitarrTypography.bodySmall.copyWith(
              color: GuitarrColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Actions
  void _generateBackingTrack(BackingTrackRequest request) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: GuitarrColors.cardBackground,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Generating AI backing track...',
                style: GuitarrTypography.bodyMedium.copyWith(
                  color: GuitarrColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
      
      final track = await ref.read(backingTrackProvider(request).future);
      
      Navigator.of(context).pop(); // Close loading dialog
      
      setState(() {
        _currentTrack = track;
        _isCustomizing = false;
      });
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog('Generation Error', e.toString());
    }
  }

  void _applyCustomizations() {
    // Implementation for applying customizations
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Customizations applied!'),
        backgroundColor: GuitarrColors.success,
      ),
    );
  }

  void _resetCustomizations() {
    setState(() {
      _isCustomizing = false;
    });
  }

  Future<void> _togglePlayback(AudioPlayerService audioPlayer, String audioPath) async {
    try {
      if (audioPlayer.currentUrl == audioPath && await audioPlayer.isPlaying) {
        await audioPlayer.pause();
      } else {
        await audioPlayer.playFromUrl(audioPath);
      }
    } catch (e) {
      _showErrorDialog('Playback Error', e.toString());
    }
  }

  void _downloadTrack(BackingTrack track) {
    // Implementation for downloading track
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Track downloaded!'),
        backgroundColor: GuitarrColors.success,
      ),
    );
  }

  void _shareTrack(BackingTrack track) {
    // Implementation for sharing track
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Track shared!'),
        backgroundColor: GuitarrColors.info,
      ),
    );
  }

  void _showTrackHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _BackingTracksHistoryScreen(userId: widget.userId),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GuitarrColors.cardBackground,
        title: Text(
          'AI Backing Tracks',
          style: GuitarrTypography.headlineSmall.copyWith(
            color: GuitarrColors.textPrimary,
          ),
        ),
        content: Text(
          'Our AI analyzes your practice progress and generates personalized backing tracks that match your skill level and musical preferences.',
          style: GuitarrTypography.bodyMedium.copyWith(
            color: GuitarrColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it!',
              style: TextStyle(color: GuitarrColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GuitarrColors.cardBackground,
        title: Text(
          title,
          style: GuitarrTypography.headlineSmall.copyWith(
            color: GuitarrColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: GuitarrTypography.bodyMedium.copyWith(
            color: GuitarrColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: GuitarrColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackingTracksHistoryScreen extends ConsumerWidget {
  final String userId;

  const _BackingTracksHistoryScreen({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(userBackingTracksHistoryProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backing Tracks History'),
        backgroundColor: GuitarrColors.cardBackground,
      ),
      backgroundColor: GuitarrColors.background,
      body: historyAsync.when(
        data: (tracks) => tracks.isEmpty
            ? const Center(
                child: Text('No backing tracks generated yet'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      blurIntensity: 3,
                      child: ListTile(
                        title: Text(
                          track.name,
                          style: GuitarrTypography.bodyMedium.copyWith(
                            color: GuitarrColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Created ${_formatDate(track.createdAt)} • ${track.style.displayName}',
                          style: GuitarrTypography.bodySmall.copyWith(
                            color: GuitarrColors.textSecondary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.play_arrow,
                          color: GuitarrColors.primary,
                        ),
                        onTap: () {
                          // Play or select this track
                        },
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading history: $error',
            style: GuitarrTypography.bodyMedium.copyWith(
              color: GuitarrColors.error,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}