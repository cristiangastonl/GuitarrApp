import 'package:flutter/material.dart';
import '../core/theme/arcade_theme.dart';

/// Displays the current score with neon styling
class ScoreDisplay extends StatelessWidget {
  final int score;
  final String label;

  const ScoreDisplay({
    super.key,
    required this.score,
    this.label = 'SCORE',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: ArcadeColors.textSecondary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatScore(score),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: ArcadeColors.neonYellow,
            letterSpacing: 2,
            shadows: NeonEffects.textGlow(ArcadeColors.neonYellow),
          ),
        ),
      ],
    );
  }

  String _formatScore(int score) {
    return score.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }
}

/// Animated score that counts up
class AnimatedScoreDisplay extends StatefulWidget {
  final int score;
  final String label;
  final Duration duration;

  const AnimatedScoreDisplay({
    super.key,
    required this.score,
    this.label = 'SCORE',
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedScoreDisplay> createState() => _AnimatedScoreDisplayState();
}

class _AnimatedScoreDisplayState extends State<AnimatedScoreDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  int _previousScore = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = IntTween(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedScoreDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _previousScore = oldWidget.score;
      _animation = IntTween(begin: _previousScore, end: widget.score).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ScoreDisplay(
          score: _animation.value,
          label: widget.label,
        );
      },
    );
  }
}

/// Star rating display
class StarRating extends StatelessWidget {
  final int stars; // 0-3
  final int maxStars;
  final double size;
  final bool animated;

  const StarRating({
    super.key,
    required this.stars,
    this.maxStars = 3,
    this.size = 32,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        final isFilled = index < stars;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.1),
          child: animated && isFilled
              ? _AnimatedStar(size: size, delay: index * 200)
              : _Star(isFilled: isFilled, size: size),
        );
      }),
    );
  }
}

class _Star extends StatelessWidget {
  final bool isFilled;
  final double size;

  const _Star({required this.isFilled, required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      isFilled ? Icons.star_rounded : Icons.star_border_rounded,
      size: size,
      color: isFilled ? ArcadeColors.starFilled : ArcadeColors.starEmpty,
      shadows: isFilled ? NeonEffects.textGlow(ArcadeColors.starFilled) : null,
    );
  }
}

class _AnimatedStar extends StatefulWidget {
  final double size;
  final int delay;

  const _AnimatedStar({required this.size, required this.delay});

  @override
  State<_AnimatedStar> createState() => _AnimatedStarState();
}

class _AnimatedStarState extends State<_AnimatedStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.3),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0),
        weight: 40,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        setState(() => _show = true);
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) {
      return _Star(isFilled: false, size: widget.size);
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _Star(isFilled: true, size: widget.size),
        );
      },
    );
  }
}

/// Progress bar for level completion
class LevelProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final double height;

  const LevelProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$current/$total',
          style: const TextStyle(
            fontSize: 12,
            color: ArcadeColors.textSecondary,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: ArcadeColors.backgroundLight,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: ArcadeColors.neonCyan.withOpacity(0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: Stack(
              children: [
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 300),
                  widthFactor: progress,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ArcadeColors.neonGreen,
                          ArcadeColors.neonCyan,
                        ],
                      ),
                      boxShadow: NeonEffects.glow(
                        ArcadeColors.neonGreen,
                        intensity: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
