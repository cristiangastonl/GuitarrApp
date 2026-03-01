import 'package:flutter/material.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../widgets/neon_text.dart';
import '../../../../widgets/arcade_button.dart';

class ReadyPage extends StatefulWidget {
  final String? skillLevel;
  final bool micTested;
  final VoidCallback onStart;

  const ReadyPage({
    super.key,
    this.skillLevel,
    this.micTested = false,
    required this.onStart,
  });

  @override
  State<ReadyPage> createState() => _ReadyPageState();
}

class _ReadyPageState extends State<ReadyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _skillLabel(String? level) {
    switch (level) {
      case 'principiante':
        return 'Principiante';
      case 'intermedio':
        return 'Intermedio';
      case 'avanzado':
        return 'Avanzado';
      default:
        return 'No seleccionado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Animated checkmark
          ScaleTransition(
            scale: _checkScale,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ArcadeColors.neonGreen,
                  width: 3,
                ),
                boxShadow: NeonEffects.glow(ArcadeColors.neonGreen),
              ),
              child: const Icon(
                Icons.check,
                size: 64,
                color: ArcadeColors.neonGreen,
              ),
            ),
          ),

          const SizedBox(height: 32),
          const NeonText(
            text: 'TODO LISTO!',
            fontSize: 32,
            color: ArcadeColors.neonGreen,
          ),
          const SizedBox(height: 32),

          // Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ArcadeColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ArcadeColors.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.person,
                  label: 'Nivel',
                  value: _skillLabel(widget.skillLevel),
                  color: ArcadeColors.neonPink,
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  icon: Icons.mic,
                  label: 'Microfono',
                  value: widget.micTested ? 'Verificado' : 'No probado',
                  color: widget.micTested
                      ? ArcadeColors.neonGreen
                      : ArcadeColors.neonYellow,
                ),
              ],
            ),
          ),

          const Spacer(),
          ArcadeButton(
            text: 'EMPEZAR A TOCAR',
            icon: Icons.play_arrow,
            onPressed: widget.onStart,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: ArcadeColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
