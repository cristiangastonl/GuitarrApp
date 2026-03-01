import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../core/audio/mobile_audio_capture.dart';
import '../../../../widgets/neon_text.dart';
import '../../../../widgets/arcade_button.dart';
import '../../../../widgets/chord_diagram.dart';
import '../../../../widgets/score_display.dart';
import '../../../lessons/presentation/providers/game_provider.dart';
import '../../../lessons/presentation/screens/lesson_list_screen.dart';

class LevelTestScreen extends ConsumerStatefulWidget {
  const LevelTestScreen({super.key});

  @override
  ConsumerState<LevelTestScreen> createState() => _LevelTestScreenState();
}

class _LevelTestScreenState extends ConsumerState<LevelTestScreen> {
  final _audioService = MobileAudioCaptureService();
  StreamSubscription<AudioCaptureData>? _audioSubscription;
  Timer? _timeout;
  bool _showResult = false;
  bool _lastResult = false;

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
    _timeout?.cancel();
    _audioService.stopCapture();
    super.dispose();
  }

  void _startListening() {
    final notifier = ref.read(levelTestProvider.notifier);
    notifier.startListening();

    _audioService.startCapture();

    // Listen for audio data
    _audioSubscription = _audioService.audioDataStream.listen((data) {
      if (data.hasPitch) {
        _processAudioData(data);
      }
    });

    // Timeout after 5 seconds
    _timeout = Timer(const Duration(seconds: 5), () {
      final state = ref.read(levelTestProvider);
      if (state.isListening) {
        _processAttempt(false); // Miss if nothing detected
      }
    });
  }

  void _processAudioData(AudioCaptureData data) {
    final state = ref.read(levelTestProvider);
    if (!state.isListening) return;

    final chord = state.currentChord;
    final detectedNote = data.noteName;

    if (detectedNote != null && data.confidence > 0.6) {
      // Check if detected note is in chord
      final isCorrectNote = chord.notes.contains(detectedNote);

      if (isCorrectNote) {
        _processAttempt(true);
      }
    }
  }

  void _processAttempt(bool correct) {
    _audioSubscription?.cancel();
    _timeout?.cancel();
    _audioService.stopCapture();

    final notifier = ref.read(levelTestProvider.notifier);
    notifier.processAttempt(correct);

    // Show result briefly
    setState(() {
      _showResult = true;
      _lastResult = correct;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showResult = false);

        final state = ref.read(levelTestProvider);
        if (state.isComplete) {
          _showTestComplete();
        }
      }
    });
  }

  void _showTestComplete() {
    final state = ref.read(levelTestProvider);

    // Unlock levels based on test result
    ref.read(gameProgressProvider.notifier).unlockFromTest(state.correctCount);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TestCompleteDialog(
        correctCount: state.correctCount,
        totalCount: state.totalChords,
        results: state.results,
        onContinue: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const LessonListScreen(),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(levelTestProvider);

    return Scaffold(
      backgroundColor: ArcadeColors.background,
      appBar: AppBar(
        backgroundColor: ArcadeColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ArcadeColors.neonCyan),
          onPressed: () {
            ref.read(levelTestProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
        title: const NeonText(
          text: 'TEST DE NIVEL',
          fontSize: 18,
          color: ArcadeColors.neonPink,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Instructions
                  const Text(
                    'Tocá el acorde:',
                    style: TextStyle(
                      color: ArcadeColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Chord name
                  NeonText(
                    text: state.currentChord.name,
                    fontSize: 48,
                    color: ArcadeColors.neonPink,
                  ),

                  const SizedBox(height: 24),

                  // Chord diagram
                  Expanded(
                    child: Center(
                      child: ChordDiagram(
                        chord: state.currentChord,
                        width: 220,
                        height: 280,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress
                  LevelProgressBar(
                    current: state.currentChordIndex,
                    total: state.totalChords,
                  ),

                  const SizedBox(height: 16),

                  // Results so far
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(state.totalChords, (index) {
                      Color color;
                      IconData icon;

                      if (index < state.results.length) {
                        color = state.results[index]
                            ? ArcadeColors.neonGreen
                            : ArcadeColors.neonRed;
                        icon = state.results[index]
                            ? Icons.check_circle
                            : Icons.cancel;
                      } else if (index == state.currentChordIndex) {
                        color = ArcadeColors.neonCyan;
                        icon = Icons.radio_button_unchecked;
                      } else {
                        color = ArcadeColors.textMuted;
                        icon = Icons.radio_button_unchecked;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(icon, color: color, size: 24),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Listen button
                  if (!state.isComplete)
                    ArcadeButton(
                      text: state.isListening ? 'ESCUCHANDO...' : 'ESCUCHAR',
                      icon: state.isListening ? Icons.mic : Icons.hearing,
                      color: state.isListening
                          ? ArcadeColors.neonCyan
                          : ArcadeColors.neonGreen,
                      onPressed: state.isListening ? null : _startListening,
                      enabled: !state.isListening,
                    ),
                ],
              ),
            ),

            // Result overlay
            if (_showResult)
              Positioned.fill(
                child: Container(
                  color: (_lastResult ? ArcadeColors.neonGreen : ArcadeColors.neonRed)
                      .withValues(alpha: 0.3),
                  child: Center(
                    child: Icon(
                      _lastResult ? Icons.check_circle : Icons.cancel,
                      size: 120,
                      color: _lastResult
                          ? ArcadeColors.neonGreen
                          : ArcadeColors.neonRed,
                      shadows: NeonEffects.textGlow(
                        _lastResult
                            ? ArcadeColors.neonGreen
                            : ArcadeColors.neonRed,
                        intensity: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

            // Listening waves
            if (state.isListening)
              Positioned(
                bottom: 150,
                left: 0,
                right: 0,
                child: Center(
                  child: _ListeningIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ListeningIndicator extends StatefulWidget {
  @override
  State<_ListeningIndicator> createState() => _ListeningIndicatorState();
}

class _ListeningIndicatorState extends State<_ListeningIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
            for (int i = 0; i < 3; i++)
              Container(
                width: 8,
                height: 8 + 20 * (((_controller.value * 3 + i * 0.33) % 1)),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: ArcadeColors.neonCyan,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: NeonEffects.glow(
                    ArcadeColors.neonCyan,
                    intensity: 0.5,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TestCompleteDialog extends StatelessWidget {
  final int correctCount;
  final int totalCount;
  final List<bool> results;
  final VoidCallback onContinue;

  const _TestCompleteDialog({
    required this.correctCount,
    required this.totalCount,
    required this.results,
    required this.onContinue,
  });

  String get _levelMessage {
    if (correctCount <= 1) {
      return 'Empezarás desde el\nNivel 1 (Em)';
    } else if (correctCount <= 3) {
      return 'Desbloqueaste hasta el\nNivel 3 (E)';
    } else {
      return 'Desbloqueaste hasta el\nNivel 5 (D)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ArcadeColors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ArcadeColors.neonCyan, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: NeonEffects.glow(ArcadeColors.neonCyan, intensity: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NeonText(
              text: 'TEST COMPLETO',
              fontSize: 20,
              color: ArcadeColors.neonPink,
            ),

            const SizedBox(height: 24),

            // Score
            Text(
              '$correctCount / $totalCount',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: ArcadeColors.neonYellow,
                shadows: NeonEffects.textGlow(ArcadeColors.neonYellow),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'acordes correctos',
              style: TextStyle(
                color: ArcadeColors.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            // Results
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: results.map((correct) {
                return Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: correct
                        ? ArcadeColors.neonGreen.withValues(alpha: 0.2)
                        : ArcadeColors.neonRed.withValues(alpha: 0.2),
                    border: Border.all(
                      color: correct
                          ? ArcadeColors.neonGreen
                          : ArcadeColors.neonRed,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    correct ? Icons.check : Icons.close,
                    size: 18,
                    color: correct
                        ? ArcadeColors.neonGreen
                        : ArcadeColors.neonRed,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Level unlock message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ArcadeColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ArcadeColors.neonGreen.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                _levelMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ArcadeColors.neonGreen,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Continue button
            ArcadeButton(
              text: 'CONTINUAR',
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
