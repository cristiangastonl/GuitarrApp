import 'package:flutter/material.dart';
import '../core/theme/arcade_theme.dart';

/// Animated neon text with glow effect
class NeonText extends StatefulWidget {
  final String text;
  final double fontSize;
  final Color color;
  final bool animate;
  final Duration blinkDuration;
  final FontWeight fontWeight;
  final TextAlign textAlign;

  const NeonText({
    super.key,
    required this.text,
    this.fontSize = 24,
    this.color = ArcadeColors.neonPink,
    this.animate = false,
    this.blinkDuration = const Duration(milliseconds: 1000),
    this.fontWeight = FontWeight.bold,
    this.textAlign = TextAlign.center,
  });

  @override
  State<NeonText> createState() => _NeonTextState();
}

class _NeonTextState extends State<NeonText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.blinkDuration,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(NeonText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return _buildText(1.0);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _buildText(_animation.value);
      },
    );
  }

  Widget _buildText(double intensity) {
    return Text(
      widget.text,
      textAlign: widget.textAlign,
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: widget.fontWeight,
        color: widget.color.withOpacity(intensity),
        letterSpacing: 2,
        shadows: NeonEffects.textGlow(widget.color, intensity: intensity),
      ),
    );
  }
}

/// Large score display with neon effect
class ScoreText extends StatelessWidget {
  final int score;
  final double fontSize;
  final Color color;

  const ScoreText({
    super.key,
    required this.score,
    this.fontSize = 32,
    this.color = ArcadeColors.neonYellow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      score.toString().padLeft(6, '0'),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
        fontFamily: 'monospace',
        letterSpacing: 4,
        shadows: NeonEffects.textGlow(color),
      ),
    );
  }
}

/// Feedback text that appears briefly (PERFECT!, GOOD, etc.)
class FeedbackText extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback? onComplete;

  const FeedbackText({
    super.key,
    required this.text,
    required this.color,
    this.onComplete,
  });

  @override
  State<FeedbackText> createState() => _FeedbackTextState();
}

class _FeedbackTextState extends State<FeedbackText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0),
        weight: 40,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 30,
      ),
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: widget.color,
                letterSpacing: 4,
                shadows: NeonEffects.textGlow(widget.color, intensity: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
