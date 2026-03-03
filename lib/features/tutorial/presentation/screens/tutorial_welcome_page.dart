import 'package:flutter/material.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../widgets/neon_text.dart';

class TutorialWelcomePage extends StatelessWidget {
  const TutorialWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          const Text('🎸', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),

          const NeonText(
            text: 'TUTORIAL',
            fontSize: 28,
            color: ArcadeColors.neonPink,
          ),
          const SizedBox(height: 8),
          const NeonText(
            text: 'GUITARRA BÁSICA',
            fontSize: 16,
            color: ArcadeColors.neonCyan,
          ),

          const SizedBox(height: 32),

          Text(
            '4 pasos, menos de un minuto',
            style: TextStyle(
              fontSize: 16,
              color: ArcadeColors.textSecondary,
            ),
          ),

          const SizedBox(height: 32),

          // Preview chips
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: const [
              _PreviewChip(icon: Icons.back_hand, label: 'Dedos', color: ArcadeColors.neonCyan),
              _PreviewChip(icon: Icons.straighten, label: 'Cuerdas', color: ArcadeColors.neonPink),
              _PreviewChip(icon: Icons.grid_on, label: 'Trastes', color: ArcadeColors.neonGreen),
              _PreviewChip(icon: Icons.music_note, label: 'Acorde', color: ArcadeColors.neonYellow),
            ],
          ),

          const Spacer(flex: 2),

          Text(
            'Desliza o toca SIGUIENTE →',
            style: TextStyle(
              fontSize: 12,
              color: ArcadeColors.textMuted,
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PreviewChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
