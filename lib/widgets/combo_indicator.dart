import 'package:flutter/material.dart';
import '../core/theme/arcade_theme.dart';

/// Displays the current combo multiplier with animations
class ComboIndicator extends StatefulWidget {
  final int combo;
  final bool animate;

  const ComboIndicator({
    super.key,
    required this.combo,
    this.animate = true,
  });

  @override
  State<ComboIndicator> createState() => _ComboIndicatorState();
}

class _ComboIndicatorState extends State<ComboIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(ComboIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.combo > oldWidget.combo && widget.animate) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getComboColor() {
    if (widget.combo >= 10) return ArcadeColors.neonPink;
    if (widget.combo >= 5) return ArcadeColors.neonOrange;
    return ArcadeColors.neonYellow;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.combo <= 1) {
      return const SizedBox.shrink();
    }

    final color = _getComboColor();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animate ? _scaleAnimation.value : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'COMBO',
                style: TextStyle(
                  fontSize: 12,
                  color: ArcadeColors.textSecondary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'x',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '${widget.combo}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: color,
                      shadows: NeonEffects.textGlow(color),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Full-screen combo celebration overlay
class ComboCelebration extends StatefulWidget {
  final int combo;
  final VoidCallback? onComplete;

  const ComboCelebration({
    super.key,
    required this.combo,
    this.onComplete,
  });

  @override
  State<ComboCelebration> createState() => _ComboCelebrationState();
}

class _ComboCelebrationState extends State<ComboCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0),
        weight: 30,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getComboColor() {
    if (widget.combo >= 10) return ArcadeColors.neonPink;
    if (widget.combo >= 5) return ArcadeColors.neonOrange;
    return ArcadeColors.neonYellow;
  }

  String _getComboMessage() {
    if (widget.combo >= 15) return 'UNSTOPPABLE!';
    if (widget.combo >= 10) return 'ON FIRE!';
    if (widget.combo >= 7) return 'AMAZING!';
    if (widget.combo >= 5) return 'GREAT!';
    return 'COMBO!';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getComboColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getComboMessage(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 2,
                    shadows: NeonEffects.textGlow(color),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'x',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '${widget.combo}',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: color,
                        shadows: NeonEffects.textGlow(color, intensity: 1.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Streak indicator (consecutive days/sessions)
class StreakIndicator extends StatelessWidget {
  final int streak;
  final String label;

  const StreakIndicator({
    super.key,
    required this.streak,
    this.label = 'STREAK',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ArcadeColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ArcadeColors.neonOrange.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: ArcadeColors.neonOrange,
            size: 24,
            shadows: NeonEffects.textGlow(ArcadeColors.neonOrange, intensity: 0.5),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: ArcadeColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '$streak',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ArcadeColors.neonOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
