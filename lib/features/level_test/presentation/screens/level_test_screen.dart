import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../core/data/chords_data.dart';
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

class _LevelTestScreenState extends ConsumerState<LevelTestScreen>
    with TickerProviderStateMixin {
  final _audioService = MobileAudioCaptureService();
  StreamSubscription<AudioCaptureData>? _audioSubscription;
  Timer? _attemptTimer;

  bool _showResult = false;
  bool _lastResult = false;

  late AnimationController _countdownAnimController;
  late Animation<double> _countdownScale;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _countdownAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _countdownScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _countdownAnimController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _initAudio() async {
    await _audioService.initialize();
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _attemptTimer?.cancel();
    _audioService.stopCapture();
    _countdownAnimController.dispose();
    super.dispose();
  }

  Future<void> _startRound() async {
    final notifier = ref.read(levelTestProvider.notifier);
    notifier.setPhase(RoundPhase.countdown);

    // Countdown 3 → 2 → 1
    for (int i = 3; i >= 1; i--) {
      notifier.setCountdown(i);
      _countdownAnimController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
    }

    // "¡TOCÁ!" flash
    notifier.setCountdown(0);
    _countdownAnimController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Open mic once
    _audioService.startCapture();
    _audioSubscription = _audioService.audioDataStream.listen((data) {
      if (data.hasPitch) {
        _processAudioData(data);
      }
    });

    _startAttempt();
  }

  void _startAttempt() {
    final notifier = ref.read(levelTestProvider.notifier);
    notifier.setPhase(RoundPhase.playing);
    notifier.startListening();

    _attemptTimer?.cancel();
    _attemptTimer = Timer(const Duration(seconds: 4), () {
      final state = ref.read(levelTestProvider);
      if (state.isListening && state.roundPhase == RoundPhase.playing) {
        _resolveAttempt(false);
      }
    });
  }

  void _processAudioData(AudioCaptureData data) {
    final state = ref.read(levelTestProvider);
    if (!state.isListening || state.roundPhase != RoundPhase.playing) return;

    final chord = state.currentChord;
    final accuracy = _matchFrequencyToChord(data.frequency, chord);
    if (accuracy > 0) {
      _resolveAttempt(true);
    }
  }

  /// Match detected frequency against chord frequencies using cents tolerance.
  /// Returns accuracy 0.0-1.0 (0 = no match). Tolerance: 50 cents.
  double _matchFrequencyToChord(double freq, ChordData chord) {
    if (freq <= 0) return 0.0;

    for (final chordFreq in chord.frequencies) {
      final cents = (1200 * math.log(freq / chordFreq) / math.ln2).abs();
      if (cents <= 50) return 1.0;
    }
    return 0.0;
  }

  void _resolveAttempt(bool correct) {
    _attemptTimer?.cancel();

    final notifier = ref.read(levelTestProvider.notifier);
    notifier.processAttempt(correct);
    notifier.setPhase(RoundPhase.feedback);

    setState(() {
      _showResult = true;
      _lastResult = correct;
    });

    // Feedback 0.8s → pause 0.5s → next or complete
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _showResult = false);

      final currentState = ref.read(levelTestProvider);
      if (currentState.isComplete) {
        _audioSubscription?.cancel();
        _audioService.stopCapture();
        notifier.setPhase(RoundPhase.complete);
        _showTestComplete();
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          _startAttempt();
        });
      }
    });
  }

  void _showTestComplete() {
    final state = ref.read(levelTestProvider);

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
    final isIdle = state.roundPhase == RoundPhase.idle;
    final isCountdown = state.roundPhase == RoundPhase.countdown;
    final isPlaying =
        state.roundPhase == RoundPhase.playing ||
        state.roundPhase == RoundPhase.feedback;

    return Scaffold(
      backgroundColor: ArcadeColors.background,
      appBar: AppBar(
        backgroundColor: ArcadeColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ArcadeColors.neonCyan),
          onPressed: () {
            _audioSubscription?.cancel();
            _attemptTimer?.cancel();
            _audioService.stopCapture();
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

                  // Chord diagram with glow on feedback
                  Expanded(
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _showResult
                              ? [
                                  BoxShadow(
                                    color: (_lastResult
                                            ? ArcadeColors.neonGreen
                                            : ArcadeColors.neonRed)
                                        .withValues(alpha: 0.6),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ]
                              : [],
                        ),
                        child: ChordDiagram(
                          chord: state.currentChord,
                          width: 220,
                          height: 280,
                        ),
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

                  const SizedBox(height: 8),

                  // Inline feedback
                  SizedBox(
                    height: 32,
                    child: AnimatedOpacity(
                      opacity: _showResult ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _lastResult ? Icons.check_circle : Icons.cancel,
                            color: _lastResult
                                ? ArcadeColors.neonGreen
                                : ArcadeColors.neonRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _lastResult ? 'OK' : 'MISS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _lastResult
                                  ? ArcadeColors.neonGreen
                                  : ArcadeColors.neonRed,
                              shadows: NeonEffects.textGlow(
                                _lastResult
                                    ? ArcadeColors.neonGreen
                                    : ArcadeColors.neonRed,
                                intensity: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // START button (only in idle)
                  if (isIdle && !state.isComplete)
                    ArcadeButton(
                      text: 'EMPEZAR',
                      icon: Icons.play_arrow,
                      color: ArcadeColors.neonGreen,
                      onPressed: _startRound,
                    ),

                  // Playing indicator
                  if (isPlaying)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.mic,
                            color: ArcadeColors.neonCyan, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Escuchando... ${state.currentChordIndex + (state.isListening ? 0 : 0)}/${state.totalChords}',
                          style: const TextStyle(
                            color: ArcadeColors.neonCyan,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Countdown overlay
            if (isCountdown)
              Positioned.fill(
                child: Container(
                  color: ArcadeColors.background.withValues(alpha: 0.85),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _countdownScale,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _countdownScale.value,
                          child: state.countdownValue > 0
                              ? Text(
                                  '${state.countdownValue}',
                                  style: TextStyle(
                                    fontSize: 120,
                                    fontWeight: FontWeight.bold,
                                    color: ArcadeColors.neonPink,
                                    shadows: [
                                      Shadow(
                                        color: ArcadeColors.neonPink
                                            .withValues(alpha: 0.8),
                                        blurRadius: 40,
                                      ),
                                      Shadow(
                                        color: ArcadeColors.neonPink
                                            .withValues(alpha: 0.4),
                                        blurRadius: 80,
                                      ),
                                    ],
                                  ),
                                )
                              : Text(
                                  '¡TOCÁ!',
                                  style: TextStyle(
                                    fontSize: 72,
                                    fontWeight: FontWeight.bold,
                                    color: ArcadeColors.neonGreen,
                                    shadows: [
                                      Shadow(
                                        color: ArcadeColors.neonGreen
                                            .withValues(alpha: 0.8),
                                        blurRadius: 40,
                                      ),
                                      Shadow(
                                        color: ArcadeColors.neonGreen
                                            .withValues(alpha: 0.4),
                                        blurRadius: 80,
                                      ),
                                    ],
                                  ),
                                ),
                        );
                      },
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
