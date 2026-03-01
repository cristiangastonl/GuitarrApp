import 'package:flutter/material.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../widgets/neon_text.dart';
import '../../../../widgets/arcade_button.dart';

class SkillLevelPage extends StatefulWidget {
  final VoidCallback onNext;
  final ValueChanged<String> onSkillSelected;

  const SkillLevelPage({
    super.key,
    required this.onNext,
    required this.onSkillSelected,
  });

  @override
  State<SkillLevelPage> createState() => _SkillLevelPageState();
}

class _SkillLevelPageState extends State<SkillLevelPage> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const NeonText(
            text: 'TU NIVEL',
            fontSize: 28,
            color: ArcadeColors.neonPink,
          ),
          const SizedBox(height: 12),
          const Text(
            'Cual es tu experiencia con la guitarra?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ArcadeColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),

          _SkillCard(
            title: 'PRINCIPIANTE',
            subtitle: 'Nunca toque o recien empiezo',
            icon: Icons.child_care,
            color: ArcadeColors.neonGreen,
            selected: _selected == 'principiante',
            onTap: () => setState(() => _selected = 'principiante'),
          ),
          const SizedBox(height: 16),
          _SkillCard(
            title: 'INTERMEDIO',
            subtitle: 'Conozco algunos acordes basicos',
            icon: Icons.trending_up,
            color: ArcadeColors.neonCyan,
            selected: _selected == 'intermedio',
            onTap: () => setState(() => _selected = 'intermedio'),
          ),
          const SizedBox(height: 16),
          _SkillCard(
            title: 'AVANZADO',
            subtitle: 'Toco hace tiempo, quiero mejorar',
            icon: Icons.star,
            color: ArcadeColors.neonPink,
            selected: _selected == 'avanzado',
            onTap: () => setState(() => _selected = 'avanzado'),
          ),

          const Spacer(),
          ArcadeButton(
            text: 'CONTINUAR',
            icon: Icons.arrow_forward,
            enabled: _selected != null,
            onPressed: _selected == null
                ? null
                : () {
                    widget.onSkillSelected(_selected!);
                    widget.onNext();
                  },
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SkillCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : ArcadeColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : ArcadeColors.textMuted,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? NeonEffects.glow(color, intensity: 0.3) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? color : ArcadeColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ArcadeColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
