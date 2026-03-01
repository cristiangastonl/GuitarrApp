import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../core/data/chords_data.dart';
import '../../../../core/audio/mobile_audio_capture.dart';
import '../../../../widgets/neon_text.dart';
import '../../../../widgets/arcade_button.dart';
import '../../../../widgets/chord_diagram.dart';
import '../../../../widgets/score_display.dart';
import '../../../../widgets/combo_indicator.dart';
import '../providers/game_provider.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final int level;

  const LessonScreen({super.key, required this.level});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen>
    with SingleTickerProviderStateMixin {
  final _audioService = MobileAudioCaptureService();
  StreamSubscription<AudioCaptureData>? _audioSubscription;
  bool _showFeedback = false;
  String _feedbackText = '';
  Color _feedbackColor = ArcadeColors.neonGreen;
  int _feedbackPoints = 0;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _audioService.initialize();
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _audioService.stopCapture();
    super.dispose();
  }

  void _startListening() {
    final notifier = ref.read(lessonGameProvider(widget.level).notifier);
    notifier.startListening();

    _audioService.startCapture();

    // Listen for audio data
    _audioSubscription = _audioService.audioDataStream.listen((data) {
      if (data.hasPitch) {
        _processAudioData(data);
      }
    });

    // Timeout after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      final state = ref.read(lessonGameProvider(widget.level));
      if (state.isListening) {
        _processAttempt(0.0); // Miss if nothing detected
      }
    });
  }

  void _processAudioData(AudioCaptureData data) {
    final state = ref.read(lessonGameProvider(widget.level));
    if (!state.isListening) return;

    // Check if the detected note matches any chord note
    final chord = state.chord;
    final detectedNote = data.noteName;

    if (detectedNote != null) {
      // Simple chord detection: check if detected note is in chord
      final isCorrectNote = chord.notes.contains(detectedNote);

      if (isCorrectNote) {
        // Calculate accuracy based on confidence
        final accuracy = data.confidence.clamp(0.0, 1.0);
        _processAttempt(accuracy);
      }
    }
  }

  void _processAttempt(double accuracy) {
    _audioSubscription?.cancel();
    _audioService.stopCapture();

    final notifier = ref.read(lessonGameProvider(widget.level).notifier);
    notifier.processAttempt(accuracy);

    final state = ref.read(lessonGameProvider(widget.level));

    // Show feedback
    setState(() {
      _showFeedback = true;
      _feedbackText = state.lastFeedback ?? '';
      _feedbackColor = FeedbackColors.fromAccuracy(accuracy);
      _feedbackPoints = FeedbackColors.pointsFromAccuracy(accuracy) *
          (state.combo > 0 ? state.combo : 1);
    });

    // Hide feedback after delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _showFeedback = false);

        // Check if level complete
        final currentState = ref.read(lessonGameProvider(widget.level));
        if (currentState.isComplete) {
          _showLevelComplete();
        }
      }
    });
  }

  void _showLevelComplete() {
    final state = ref.read(lessonGameProvider(widget.level));

    // Save progress
    ref.read(gameProgressProvider.notifier).completeLevel(
          widget.level,
          state.score,
          state.stars,
        );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LevelCompleteDialog(
        level: widget.level,
        chord: state.chord,
        score: state.score,
        maxCombo: state.maxCombo,
        accuracy: (state.averageAccuracy * 100).round(),
        stars: state.stars,
        onNext: () {
          Navigator.of(context).pop();
          if (widget.level < 10) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => LessonScreen(level: widget.level + 1),
              ),
            );
          } else {
            Navigator.of(context).pop(); // Back to list
          }
        },
        onRetry: () {
          Navigator.of(context).pop();
          ref.read(lessonGameProvider(widget.level).notifier).reset();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonGameProvider(widget.level));
    final chord = state.chord;

    return Scaffold(
      backgroundColor: ArcadeColors.background,
      appBar: AppBar(
        backgroundColor: ArcadeColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ArcadeColors.neonCyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: NeonText(
          text: 'NIVEL ${widget.level}',
          fontSize: 18,
          color: ArcadeColors.neonPink,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Score and combo row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedScoreDisplay(score: state.score),
                      ComboIndicator(combo: state.combo),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Chord name
                  NeonText(
                    text: 'ACORDE ${chord.name}',
                    fontSize: 24,
                    color: ArcadeColors.neonCyan,
                  ),

                  const SizedBox(height: 16),

                  // Chord diagram
                  Expanded(
                    child: Center(
                      child: ChordDiagram(
                        chord: chord,
                        width: 220,
                        height: 280,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress bar
                  LevelProgressBar(
                    current: state.currentAttempt,
                    total: state.totalAttempts,
                  ),

                  const SizedBox(height: 24),

                  // Play button
                  if (!state.isComplete)
                    ArcadeButton(
                      text: state.isListening ? 'ESCUCHANDO...' : 'TOCAR',
                      icon: state.isListening ? Icons.mic : Icons.play_arrow,
                      color: state.isListening
                          ? ArcadeColors.neonCyan
                          : ArcadeColors.neonGreen,
                      onPressed: state.isListening ? null : _startListening,
                      enabled: !state.isListening,
                    ),
                ],
              ),
            ),

            // Feedback overlay
            if (_showFeedback)
              Positioned.fill(
                child: Container(
                  color: _feedbackColor.withOpacity(0.2),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FeedbackText(
                          text: _feedbackText,
                          color: _feedbackColor,
                        ),
                        if (_feedbackPoints > 0) ...[
                          const SizedBox(height: 16),
                          Text(
                            '+$_feedbackPoints pts',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ArcadeColors.neonYellow,
                              shadows: NeonEffects.textGlow(
                                ArcadeColors.neonYellow,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            // Listening indicator
            if (state.isListening)
              Positioned(
                bottom: 150,
                left: 0,
                right: 0,
                child: Center(
                  child: _ListeningWaves(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ListeningWaves extends StatefulWidget {
  @override
  State<_ListeningWaves> createState() => _ListeningWavesState();
}

class _ListeningWavesState extends State<_ListeningWaves>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ')',
              style: TextStyle(
                fontSize: 24,
                color: ArcadeColors.neonCyan.withOpacity(
                  0.3 + 0.7 * (((_controller.value * 3) % 1) > 0.5 ? 1 : 0),
                ),
              ),
            ),
            Text(
              '))',
              style: TextStyle(
                fontSize: 24,
                color: ArcadeColors.neonCyan.withOpacity(
                  0.3 + 0.7 * (((_controller.value * 3 + 0.33) % 1) > 0.5 ? 1 : 0),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.mic, color: ArcadeColors.neonCyan, size: 32),
            const SizedBox(width: 8),
            Text(
              '((',
              style: TextStyle(
                fontSize: 24,
                color: ArcadeColors.neonCyan.withOpacity(
                  0.3 + 0.7 * (((_controller.value * 3 + 0.33) % 1) > 0.5 ? 1 : 0),
                ),
              ),
            ),
            Text(
              '(',
              style: TextStyle(
                fontSize: 24,
                color: ArcadeColors.neonCyan.withOpacity(
                  0.3 + 0.7 * (((_controller.value * 3) % 1) > 0.5 ? 1 : 0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LevelCompleteDialog extends StatelessWidget {
  final int level;
  final ChordData chord;
  final int score;
  final int maxCombo;
  final int accuracy;
  final int stars;
  final VoidCallback onNext;
  final VoidCallback onRetry;

  const _LevelCompleteDialog({
    required this.level,
    required this.chord,
    required this.score,
    required this.maxCombo,
    required this.accuracy,
    required this.stars,
    required this.onNext,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ArcadeColors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ArcadeColors.neonGreen, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: NeonEffects.glow(ArcadeColors.neonGreen, intensity: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NeonText(
              text: 'NIVEL COMPLETO!',
              fontSize: 20,
              color: ArcadeColors.neonGreen,
            ),

            const SizedBox(height: 8),

            Text(
              'Acorde: ${chord.name}',
              style: const TextStyle(
                color: ArcadeColors.textSecondary,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ArcadeColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ArcadeColors.neonCyan.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _StatRow(label: 'SCORE', value: _formatScore(score)),
                  const SizedBox(height: 8),
                  _StatRow(label: 'COMBO MAX', value: 'x$maxCombo'),
                  const SizedBox(height: 8),
                  _StatRow(label: 'PRECISION', value: '$accuracy%'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stars
            StarRating(stars: stars, size: 48, animated: true),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ArcadeButton.outline(
                    text: 'REPETIR',
                    onPressed: onRetry,
                    height: 48,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ArcadeButton(
                    text: level < 10 ? 'SIGUIENTE' : 'FIN',
                    onPressed: onNext,
                    height: 48,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatScore(int score) {
    return score.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ArcadeColors.textSecondary,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: ArcadeColors.neonYellow,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            shadows: NeonEffects.textGlow(ArcadeColors.neonYellow, intensity: 0.5),
          ),
        ),
      ],
    );
  }
}
