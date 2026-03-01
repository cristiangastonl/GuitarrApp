import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../core/data/chords_data.dart';
import '../../../../widgets/neon_text.dart';
import '../../../../widgets/score_display.dart';
import '../providers/game_provider.dart';
import 'lesson_screen.dart';

class LessonListScreen extends ConsumerWidget {
  const LessonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);

    return Scaffold(
      backgroundColor: ArcadeColors.background,
      appBar: AppBar(
        backgroundColor: ArcadeColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ArcadeColors.neonCyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const NeonText(
          text: 'NIVELES',
          fontSize: 20,
          color: ArcadeColors.neonPink,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Grid of levels
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: ChordsData.allChords.length,
                  itemBuilder: (context, index) {
                    final level = index + 1;
                    final chord = ChordsData.allChords[index];
                    final isUnlocked = progress.isLevelUnlocked(level);
                    final stars = progress.getStars(level);
                    final highScore = progress.getHighScore(level);

                    return _LevelCard(
                      level: level,
                      chord: chord,
                      isUnlocked: isUnlocked,
                      stars: stars,
                      highScore: highScore,
                      onTap: isUnlocked
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LessonScreen(level: level),
                                ),
                              );
                            }
                          : null,
                    );
                  },
                ),
              ),
            ),

            // Total high score
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL HIGH SCORE',
                    style: TextStyle(
                      color: ArcadeColors.textSecondary,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  ScoreDisplay(score: progress.totalHighScore),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int level;
  final ChordData chord;
  final bool isUnlocked;
  final int stars;
  final int highScore;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.level,
    required this.chord,
    required this.isUnlocked,
    required this.stars,
    required this.highScore,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isUnlocked
        ? (stars > 0 ? ArcadeColors.neonGreen : ArcadeColors.neonCyan)
        : ArcadeColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: ArcadeColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          boxShadow: isUnlocked
              ? NeonEffects.glow(borderColor, intensity: 0.3)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Level number
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$level',
                style: TextStyle(
                  color: borderColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Chord name or lock
            if (isUnlocked)
              Text(
                chord.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ArcadeColors.neonPink,
                  shadows: NeonEffects.textGlow(
                    ArcadeColors.neonPink,
                    intensity: 0.5,
                  ),
                ),
              )
            else
              Icon(
                Icons.lock,
                color: ArcadeColors.textMuted,
                size: 32,
              ),

            const SizedBox(height: 8),

            // Stars or difficulty
            if (isUnlocked)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Icon(
                    i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 16,
                    color: i < stars
                        ? ArcadeColors.starFilled
                        : ArcadeColors.starEmpty,
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  chord.difficulty,
                  (_) => const Icon(
                    Icons.star_rounded,
                    size: 12,
                    color: ArcadeColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
