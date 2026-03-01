import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../core/data/chords_data.dart';
import '../../../../widgets/neon_text.dart';
import '../../../../widgets/arcade_button.dart';
import '../../../lessons/presentation/providers/game_provider.dart';
import '../../../lessons/presentation/screens/lesson_list_screen.dart';
import '../../../level_test/presentation/screens/level_test_screen.dart';

class ArcadeHomeScreen extends ConsumerWidget {
  const ArcadeHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);

    return Scaffold(
      backgroundColor: ArcadeColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Title
              const NeonText(
                text: 'GUITARR',
                fontSize: 36,
                color: ArcadeColors.neonPink,
                animate: true,
                blinkDuration: Duration(milliseconds: 2000),
              ),
              const NeonText(
                text: 'APP',
                fontSize: 36,
                color: ArcadeColors.neonCyan,
              ),

              const SizedBox(height: 16),

              // Guitar emoji
              const Text(
                '🎸',
                style: TextStyle(fontSize: 64),
              ),

              const Spacer(),

              // Menu buttons
              ArcadeButton(
                text: 'NUEVO JUEGO',
                icon: Icons.play_arrow,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LevelTestScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              ArcadeButton.secondary(
                text: 'CONTINUAR',
                icon: Icons.sports_esports,
                onPressed: progress.unlockedLevel > 0
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LessonListScreen(),
                          ),
                        );
                      }
                    : null,
                enabled: progress.unlockedLevel > 0,
              ),

              const SizedBox(height: 16),

              ArcadeButton.outline(
                text: 'HIGH SCORES',
                icon: Icons.leaderboard,
                onPressed: () {
                  _showHighScores(context, progress);
                },
              ),

              const Spacer(),

              // High score display
              if (progress.totalHighScore > 0) ...[
                Text(
                  'HIGH SCORE',
                  style: TextStyle(
                    fontSize: 12,
                    color: ArcadeColors.textSecondary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatScore(progress.totalHighScore),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: ArcadeColors.neonYellow,
                    shadows: NeonEffects.textGlow(ArcadeColors.neonYellow),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Insert coin text
              const NeonText(
                text: 'INSERT COIN',
                fontSize: 14,
                color: ArcadeColors.textSecondary,
                animate: true,
                blinkDuration: Duration(milliseconds: 1000),
              ),

              const Spacer(),
            ],
          ),
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

  void _showHighScores(BuildContext context, GameProgress progress) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArcadeColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NeonText(
              text: 'HIGH SCORES',
              fontSize: 24,
              color: ArcadeColors.neonPink,
            ),
            const SizedBox(height: 24),
            if (progress.highScores.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No hay puntajes aún.\n¡Empieza a jugar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ArcadeColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: progress.highScores.length,
                itemBuilder: (context, index) {
                  final level = progress.highScores.keys.elementAt(index);
                  final score = progress.highScores[level]!;
                  final stars = progress.getStars(level);
                  final chord = ChordsData.getChordByLevel(level);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: ArcadeColors.neonCyan.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ArcadeColors.neonCyan.withOpacity(0.5),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$level',
                              style: const TextStyle(
                                color: ArcadeColors.neonCyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chord?.name ?? 'Nivel $level',
                                style: const TextStyle(
                                  color: ArcadeColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  3,
                                  (i) => Icon(
                                    i < stars
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    size: 16,
                                    color: i < stars
                                        ? ArcadeColors.starFilled
                                        : ArcadeColors.starEmpty,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatScore(score),
                          style: TextStyle(
                            color: ArcadeColors.neonYellow,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            shadows: NeonEffects.textGlow(
                              ArcadeColors.neonYellow,
                              intensity: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            Divider(color: ArcadeColors.textMuted),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    color: ArcadeColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  _formatScore(progress.totalHighScore),
                  style: TextStyle(
                    fontSize: 20,
                    color: ArcadeColors.neonYellow,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    shadows: NeonEffects.textGlow(ArcadeColors.neonYellow),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
