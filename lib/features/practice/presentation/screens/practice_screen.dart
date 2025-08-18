import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/metronome_service.dart';
import '../../../../core/services/backing_track_service.dart';
import '../../../../core/services/recording_service.dart';
import '../../../../core/services/feedback_analysis_service.dart';
import '../../../../shared/widgets/visual_metronome.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/riff_glass_card.dart';
import '../../../../shared/widgets/intelligent_backing_tracks_widget.dart';
import '../widgets/recordings_list.dart';
import '../../../feedback/presentation/screens/feedback_screen.dart';
import '../../../tone_presets/presentation/widgets/preset_selector.dart';
import '../../../tone_presets/presentation/widgets/ab_comparison_widget.dart';
import '../../../tone_presets/presentation/providers/tone_preset_providers.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Práctica'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Riff Selection
              _RiffSelectionSection(),
              
              SizedBox(height: 24),
              
              // Tone Preset Section
              _TonePresetSection(),
              
              SizedBox(height: 24),
              
              // AI Backing Tracks Section
              IntelligentBackingTracksWidget(
                songRiffId: 'enter_sandman_main',
                userId: 'user_1', // TODO: Get from user session
                genre: 'metal',
              ),
              
              SizedBox(height: 24),
              
              // Visual Metronome Section
              VisualMetronome(),
              
              SizedBox(height: 24),
              
              // Recording Controls
              _RecordingControlsSection(),
              
              SizedBox(height: 24),
              
              // Recordings List
              RecordingsList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiffSelectionSection extends ConsumerWidget {
  const _RiffSelectionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backingTrack = ref.watch(backingTrackByIdProvider('enter_sandman_main'));
    
    if (backingTrack == null) {
      return const Center(child: Text('Backing track not found'));
    }
    
    return RiffGlassCard(
      name: backingTrack.name,
      artist: backingTrack.artist,
      genre: backingTrack.genre,
      difficulty: backingTrack.difficulty,
      targetBpm: backingTrack.bpm,
      currentBpm: (backingTrack.bpm * 0.7).round(), // 70% of target BPM as current
      progress: 0.6,
      techniques: backingTrack.techniques,
      riffId: backingTrack.id,
      showAudioControls: true,
    );
  }
}

class _TonePresetSection extends ConsumerWidget {
  const _TonePresetSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPreset = ref.watch(selectedPresetProvider);
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Preset de Sonido',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (selectedPreset != null)
                IconButton(
                  onPressed: () => _showABComparison(context),
                  icon: const Icon(Icons.compare, size: 18),
                  tooltip: 'Comparar presets',
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (selectedPreset != null) ...[
            // Current preset display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedPreset.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${selectedPreset.genre.toUpperCase()} • ${selectedPreset.ampModel}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        // Quick preview of key settings
                        Row(
                          children: [
                            _buildQuickMeter('Gain', selectedPreset.gain),
                            const SizedBox(width: 12),
                            _buildQuickMeter('Dist', selectedPreset.effects['distortion'] ?? 0.0),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: () => _showPresetSelector(context, ref),
                        icon: const Icon(Icons.swap_horiz),
                        tooltip: 'Cambiar preset',
                      ),
                      IconButton(
                        onPressed: () => _applyPreset(ref, selectedPreset),
                        icon: const Icon(Icons.volume_up),
                        tooltip: 'Aplicar preset',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // No preset selected
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).cardColor,
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.music_note_outlined,
                    size: 48,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Selecciona un preset de sonido',
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Optimiza tu sonido para el riff que vas a practicar',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showPresetSelector(context, ref),
                    icon: const Icon(Icons.library_music, color: Colors.white),
                    label: const Text(
                      'Explorar Presets',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickMeter(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.grey.withOpacity(0.3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _getValueColor(value),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getValueColor(double value) {
    if (value < 0.3) return Colors.green;
    if (value < 0.7) return Colors.orange;
    return Colors.red;
  }

  void _showPresetSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PresetSelector(
        onPresetSelected: (preset) {
          ref.read(selectedPresetProvider.notifier).state = preset;
          _applyPreset(ref, preset);
        },
        guitarType: 'electric', // Could be dynamic based on user setup
        ampType: 'tube', // Could be dynamic based on user setup
      ),
    );
  }

  void _showABComparison(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          color: Colors.white,
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: ABComparisonWidget(),
        ),
      ),
    );
  }

  void _applyPreset(WidgetRef ref, preset) {
    // TODO: Integrate with audio processing system
    ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(
        content: Text('Preset "${preset.name}" aplicado'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _RoadmapStep extends StatelessWidget {
  final int step;
  final int bpm;
  final String description;
  final bool isCompleted;
  final bool isCurrent;

  const _RoadmapStep({
    required this.step,
    required this.bpm,
    required this.description,
    this.isCompleted = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted 
        ? Colors.green 
        : isCurrent 
            ? Theme.of(context).colorScheme.primary
            : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? Colors.green : Colors.transparent,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      step.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$bpm BPM - $description',
              style: TextStyle(
                color: color,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetronomeSection extends ConsumerWidget {
  const _MetronomeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metronomeState = ref.watch(metronomeStateProvider);
    final metronomeNotifier = ref.read(metronomeStateProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Metrónomo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // BPM Display
            Text(
              '${metronomeState.bpm}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: metronomeState.isPlaying 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
            
            const Text(
              'BPM',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // BPM Slider
            Slider(
              value: metronomeState.bpm.toDouble(),
              min: 60,
              max: 180,
              divisions: 120,
              onChanged: metronomeState.isPlaying 
                  ? null 
                  : (value) => metronomeNotifier.setBpm(value.round()),
            ),
            
            const SizedBox(height: 16),
            
            // Metronome Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: metronomeState.isPlaying 
                      ? null 
                      : () => metronomeNotifier.setBpm(metronomeState.bpm - 5),
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                
                IconButton(
                  onPressed: () => metronomeNotifier.togglePlay(),
                  icon: Icon(
                    metronomeState.isPlaying ? Icons.stop : Icons.play_arrow, 
                    size: 48,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: metronomeState.isPlaying 
                        ? Colors.red 
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                IconButton(
                  onPressed: metronomeState.isPlaying 
                      ? null 
                      : () => metronomeNotifier.setBpm(metronomeState.bpm + 5),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Beat Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                metronomeState.timeSignature,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: metronomeState.isPlaying && 
                           metronomeState.currentBeat == index
                        ? Theme.of(context).colorScheme.primary
                        : metronomeState.accents[index] && metronomeState.accents.length > index
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                            : Colors.grey[300],
                    border: metronomeState.accents.length > index && 
                           metronomeState.accents[index]
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: metronomeState.isPlaying && 
                               metronomeState.currentBeat == index
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingControlsSection extends ConsumerWidget {
  const _RecordingControlsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingState = ref.watch(recordingServiceProvider);
    final recordingService = ref.read(recordingServiceProvider.notifier);
    final metronomeState = ref.watch(metronomeStateProvider);
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Sesión de Práctica',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          
          const SizedBox(height: 16),
          
          // Recording duration display (when recording)
          if (recordingState.isRecording) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        color: Theme.of(context).colorScheme.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Grabando: ${_formatDuration(recordingState.recordingDuration)}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (recordingState.isMetronomeSync && recordingState.recordingBpm != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sync,
                          color: Theme.of(context).colorScheme.primary,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sincronizado con ${recordingState.recordingBpm} BPM',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Recording Button with modern design
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: recordingState.isRecording
                    ? [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      ]
                    : [
                        Theme.of(context).colorScheme.error,
                        Theme.of(context).colorScheme.error.withOpacity(0.8),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: recordingState.isRecording
                      ? Theme.of(context).colorScheme.surface.withOpacity(0.3)
                      : Theme.of(context).colorScheme.error.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: recordingState.isLoading 
                    ? null 
                    : () async {
                        if (recordingState.isRecording) {
                          // Stop recording and navigate to feedback
                          await recordingService.stopRecording();
                          
                          // Wait a moment for the recording to be processed
                          await Future.delayed(const Duration(milliseconds: 500));
                          
                          // Get the latest recording
                          final recordings = ref.read(recordingsListProvider);
                          if (recordings.isNotEmpty && context.mounted) {
                            final latestRecording = recordings.first;
                            
                            // Generate analysis and navigate to feedback
                            await _showFeedback(context, ref, latestRecording, metronomeState.bpm);
                          }
                        } else {
                          // Generate session name with current BPM
                          final sessionName = 'practice_${metronomeState.bpm}bpm_${DateTime.now().millisecondsSinceEpoch}';
                          await recordingService.startRecording(
                            sessionName: sessionName,
                            syncWithMetronome: true,
                          );
                        }
                      },
                child: Center(
                  child: recordingState.isLoading
                      ? CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              recordingState.isRecording 
                                  ? Icons.stop 
                                  : Icons.fiber_manual_record,
                              color: recordingState.isRecording
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              recordingState.isRecording 
                                  ? 'Detener Grabación'
                                  : 'Iniciar Grabación',
                              style: TextStyle(
                                color: recordingState.isRecording
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Error display
          if (recordingState.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recordingState.error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Session info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BPM objetivo:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${metronomeState.bpm} BPM',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Grabaciones:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${recordingState.recordings.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            recordingState.isRecording 
                ? 'Grabando tu práctica con el metrónomo...'
                : 'Graba tu ejecución para recibir feedback detallado',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

/// Helper function to show feedback after recording
Future<void> _showFeedback(
  BuildContext context,
  WidgetRef ref,
  RecordingFile recording,
  int targetBpm,
) async {
  try {
    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analizando tu performance...'),
            ],
          ),
        ),
      );
    }

    // Get services
    final feedbackService = ref.read(feedbackAnalysisServiceProvider);
    
    // Analyze the session
    final analysis = await feedbackService.analyzeSession(
      recording: recording,
      riffId: 'enter_sandman_main', // For now, using the current riff
      targetBpm: targetBpm,
    );

    // Close loading dialog and navigate to feedback
    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FeedbackScreen(
            analysis: analysis,
            riffId: 'enter_sandman_main',
          ),
        ),
      );
    }
  } catch (e) {
    // Close loading dialog and show error
    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al analizar la sesión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}