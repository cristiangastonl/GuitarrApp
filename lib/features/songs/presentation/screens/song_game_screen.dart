import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../core/data/chords_data.dart';
import '../../../../core/data/songs_data.dart';
import '../../../../core/audio/mobile_audio_capture.dart';
import '../../../../core/services/gemini_coach_service.dart';
import '../../../../widgets/neon_text.dart';
import '../../../../widgets/arcade_button.dart';
import '../../../../widgets/chord_diagram.dart';
import '../../../../widgets/score_display.dart';
import '../../../../widgets/combo_indicator.dart';
import '../../../../widgets/reference_panel.dart';
import '../../../lessons/presentation/providers/game_provider.dart';
import '../providers/song_game_provider.dart';

class SongGameScreen extends ConsumerStatefulWidget {
  final String songId;

  const SongGameScreen({super.key, required this.songId});

  @override
  ConsumerState<SongGameScreen> createState() => _SongGameScreenState();
}

class _SongGameScreenState extends ConsumerState<SongGameScreen>
    with TickerProviderStateMixin {
  final _audioService = MobileAudioCaptureService();
  final _geminiCoach = GeminiCoachService();
  StreamSubscription<AudioCaptureData>? _audioSubscription;
  Timer? _attemptTimer;

  // Inline feedback state
  bool _showInlineFeedback = false;
  String _inlineFeedbackText = '';
  Color _inlineFeedbackColor = ArcadeColors.neonGreen;
  int _inlineFeedbackPoints = 0;

  // Metronome state
  int _metronomeBeat = 0;

  // Countdown animation
  late AnimationController _countdownAnimController;
  late Animation<double> _countdownScale;

  @override
  void initState() {
    super.initState();
    _initServices();
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

  Future<void> _initServices() async {
    await _audioService.initialize();
    _geminiCoach.initialize();
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
    final notifier = ref.read(songGameProvider(widget.songId).notifier);
    notifier.setPhase(RoundPhase.countdown);

    for (int i = 3; i >= 1; i--) {
      notifier.setCountdown(i);
      _countdownAnimController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
    }

    notifier.setCountdown(0);
    _countdownAnimController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    _audioService.startCapture();
    _audioSubscription = _audioService.audioDataStream.listen((data) {
      if (data.hasPitch) {
        _processAudioData(data);
      }
    });

    _startAttempt();
  }

  void _startAttempt() {
    final notifier = ref.read(songGameProvider(widget.songId).notifier);
    notifier.setPhase(RoundPhase.playing);
    notifier.startListening();

    _attemptTimer?.cancel();
    _attemptTimer = Timer(const Duration(seconds: 4), () {
      final state = ref.read(songGameProvider(widget.songId));
      if (state.isListening && state.roundPhase == RoundPhase.playing) {
        _resolveAttempt(0.0);
      }
    });
  }

  void _processAudioData(AudioCaptureData data) {
    final state = ref.read(songGameProvider(widget.songId));
    if (!state.isListening || state.roundPhase != RoundPhase.playing) return;

    final chord = state.currentChord;
    if (chord == null) return;
    final accuracy = _matchFrequencyToChord(data.frequency, chord);
    if (accuracy > 0) {
      _resolveAttempt(accuracy);
    }
  }

  double _matchFrequencyToChord(double freq, ChordData chord) {
    if (freq <= 0) return 0.0;

    double bestAccuracy = 0.0;
    for (final chordFreq in chord.frequencies) {
      final cents = (1200 * math.log(freq / chordFreq) / math.ln2).abs();
      if (cents <= 50) {
        final accuracy = 1.0 - (cents / 50.0) * 0.5;
        if (accuracy > bestAccuracy) {
          bestAccuracy = accuracy;
        }
      }
    }
    return bestAccuracy;
  }

  void _resolveAttempt(double accuracy) {
    _attemptTimer?.cancel();

    final notifier = ref.read(songGameProvider(widget.songId).notifier);
    notifier.processAttempt(accuracy);
    notifier.setPhase(RoundPhase.feedback);

    final state = ref.read(songGameProvider(widget.songId));

    setState(() {
      _showInlineFeedback = true;
      _inlineFeedbackText = state.lastFeedback ?? '';
      _inlineFeedbackColor = FeedbackColors.fromAccuracy(accuracy);
      _inlineFeedbackPoints = FeedbackColors.pointsFromAccuracy(accuracy) *
          (state.combo > 0 ? state.combo : 1);
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _showInlineFeedback = false);

      final currentState = ref.read(songGameProvider(widget.songId));
      if (currentState.isComplete) {
        _audioSubscription?.cancel();
        _audioService.stopCapture();
        notifier.setPhase(RoundPhase.complete);
        _showSongComplete();
      } else {
        _playMetronome();
      }
    });
  }

  Future<void> _playMetronome() async {
    for (int beat = 1; beat <= 3; beat++) {
      if (!mounted) return;
      setState(() => _metronomeBeat = beat);
      _countdownAnimController.forward(from: 0);
      final delay = beat < 3 ? 500 : 400;
      await Future.delayed(Duration(milliseconds: delay));
    }
    if (!mounted) return;
    setState(() => _metronomeBeat = 0);
    _startAttempt();
  }

  void _showSongComplete() {
    final state = ref.read(songGameProvider(widget.songId));

    // Save song progress
    ref.read(songProgressProvider.notifier).completeSong(
          widget.songId,
          state.score,
          state.stars,
        );

    // Request AI summary
    _geminiCoach
        .getSummaryFeedback(
      chordName: state.song.title,
      accuracies: state.accuracies,
      score: state.score,
      maxCombo: state.maxCombo,
      averageAccuracy: state.averageAccuracy,
    )
        .then((summary) {
      if (summary != null) {
        ref
            .read(songGameProvider(widget.songId).notifier)
            .setAiFeedback(summary);
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SongCompleteDialog(
        song: state.song,
        score: state.score,
        maxCombo: state.maxCombo,
        accuracy: (state.averageAccuracy * 100).round(),
        stars: state.stars,
        gameProvider: songGameProvider(widget.songId),
        onRetry: () {
          Navigator.of(context).pop();
          ref.read(songGameProvider(widget.songId).notifier).reset();
        },
        onBack: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildMetronomeBeat() {
    final sizes = [24.0, 36.0, 48.0];
    final alphas = [0.4, 0.7, 1.0];
    final size = sizes[_metronomeBeat - 1];
    final alpha = alphas[_metronomeBeat - 1];
    final isLastBeat = _metronomeBeat == 3;
    final color = isLastBeat ? ArcadeColors.neonGreen : ArcadeColors.neonCyan;

    return AnimatedBuilder(
      animation: _countdownScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _countdownScale.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: alpha * 0.3),
                  border: Border.all(
                      color: color.withValues(alpha: alpha), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: alpha * 0.5),
                      blurRadius: size * 0.5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              if (isLastBeat) ...[
                const SizedBox(width: 12),
                Text(
                  '¡TOCÁ!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ArcadeColors.neonGreen,
                    shadows: NeonEffects.textGlow(
                      ArcadeColors.neonGreen,
                      intensity: 0.8,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(songGameProvider(widget.songId));
    final chord = state.currentChord;
    final nextChord = state.nextChord;
    final isIdle = state.roundPhase == RoundPhase.idle;
    final isCountdown = state.roundPhase == RoundPhase.countdown;
    final isPlaying = state.roundPhase == RoundPhase.playing ||
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
            Navigator.of(context).pop();
          },
        ),
        title: NeonText(
          text: state.song.title.toUpperCase(),
          fontSize: 16,
          color: ArcadeColors.neonPink,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                Expanded(
                  child: Padding(
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

                        const SizedBox(height: 16),

                        // Current chord name with AnimatedSwitcher
                        if (chord != null)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: NeonText(
                              key: ValueKey(chord.name),
                              text: 'ACORDE ${chord.name}',
                              fontSize: 24,
                              color: ArcadeColors.neonCyan,
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Chord diagram with AnimatedSwitcher for smooth transitions
                        Expanded(
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _showInlineFeedback
                                    ? [
                                        BoxShadow(
                                          color: _inlineFeedbackColor
                                              .withValues(alpha: 0.6),
                                          blurRadius: 24,
                                          spreadRadius: 4,
                                        ),
                                        BoxShadow(
                                          color: _inlineFeedbackColor
                                              .withValues(alpha: 0.3),
                                          blurRadius: 48,
                                          spreadRadius: 8,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: chord != null
                                  ? AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: ChordDiagram(
                                        key: ValueKey(chord.name),
                                        chord: chord,
                                        width: 220,
                                        height: 280,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ),

                        // Next chord preview
                        SizedBox(
                          height: 24,
                          child: nextChord != null
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'SIGUIENTE: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ArcadeColors.textMuted,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: Text(
                                        nextChord.name,
                                        key: ValueKey(nextChord.name),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: ArcadeColors.neonYellow,
                                          shadows: NeonEffects.textGlow(
                                            ArcadeColors.neonYellow,
                                            intensity: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 8),

                        // Progress bar
                        LevelProgressBar(
                          current: state.currentAttempt,
                          total: state.totalAttempts,
                        ),

                        const SizedBox(height: 8),

                        // Inline feedback / metronome area
                        SizedBox(
                          height: 40,
                          child: _metronomeBeat > 0
                              ? _buildMetronomeBeat()
                              : AnimatedOpacity(
                                  opacity: _showInlineFeedback ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _inlineFeedbackPoints > 0
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: _inlineFeedbackColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _inlineFeedbackText,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _inlineFeedbackColor,
                                          shadows: NeonEffects.textGlow(
                                            _inlineFeedbackColor,
                                            intensity: 0.5,
                                          ),
                                        ),
                                      ),
                                      if (_inlineFeedbackPoints > 0) ...[
                                        const SizedBox(width: 12),
                                        Text(
                                          '+$_inlineFeedbackPoints pts',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: ArcadeColors.neonYellow,
                                            shadows: NeonEffects.textGlow(
                                              ArcadeColors.neonYellow,
                                              intensity: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                        ),

                        const SizedBox(height: 16),

                        // START button (only in idle)
                        if (isIdle && !state.isComplete)
                          ArcadeButton(
                            text: 'TOCAR',
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
                                'Escuchando... ${state.currentAttempt}/${state.totalAttempts}',
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
                ),
                const ReferencePanel(),
              ],
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

class _SongCompleteDialog extends ConsumerWidget {
  final SongData song;
  final int score;
  final int maxCombo;
  final int accuracy;
  final int stars;
  final StateNotifierProvider<SongGameNotifier, SongGameState> gameProvider;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _SongCompleteDialog({
    required this.song,
    required this.score,
    required this.maxCombo,
    required this.accuracy,
    required this.stars,
    required this.gameProvider,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiFeedback = ref.watch(gameProvider).aiFeedback;

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
              text: 'CANCIÓN COMPLETA!',
              fontSize: 20,
              color: ArcadeColors.neonGreen,
            ),

            const SizedBox(height: 8),

            Text(
              '${song.title} - ${song.artist}',
              style: const TextStyle(
                color: ArcadeColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ArcadeColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: ArcadeColors.neonCyan.withValues(alpha: 0.3)),
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

            const SizedBox(height: 16),

            // AI Summary
            if (aiFeedback != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ArcadeColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: ArcadeColors.neonPurple.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: ArcadeColors.neonPurple, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        aiFeedback,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              ArcadeColors.textPrimary.withValues(alpha: 0.9),
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ArcadeColors.neonPurple.withValues(alpha: 0.5),
                  ),
                ),
              ),

            const SizedBox(height: 16),

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
                    text: 'CANCIONES',
                    onPressed: onBack,
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
            shadows:
                NeonEffects.textGlow(ArcadeColors.neonYellow, intensity: 0.5),
          ),
        ),
      ],
    );
  }
}
