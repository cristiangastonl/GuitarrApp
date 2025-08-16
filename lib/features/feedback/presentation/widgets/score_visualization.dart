import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/services/feedback_analysis_service.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Main score visualization widget with animated circular progress
class ScoreVisualization extends StatefulWidget {
  final SessionAnalysis analysis;
  
  const ScoreVisualization({
    super.key,
    required this.analysis,
  });

  @override
  State<ScoreVisualization> createState() => _ScoreVisualizationState();
}

class _ScoreVisualizationState extends State<ScoreVisualization>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Main score animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0,
      end: widget.analysis.overallScore / 100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    // Pulse animation for emphasis
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _controller.forward();
    
    // Start pulse after main animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Puntuación General',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Main circular score display
            AnimatedBuilder(
              animation: Listenable.merge([_animation, _pulseAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: _CircularScoreWidget(
                    score: widget.analysis.overallScore,
                    progress: _animation.value,
                    performanceLevel: widget.analysis.performanceLevel,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Performance level indicator
            _PerformanceLevelIndicator(
              level: widget.analysis.performanceLevel,
            ),
            
            const SizedBox(height: 20),
            
            // Score components breakdown
            _ScoreComponentsRow(analysis: widget.analysis),
          ],
        ),
      ),
    );
  }
}

/// Circular score widget with animated progress
class _CircularScoreWidget extends StatelessWidget {
  final double score;
  final double progress;
  final PerformanceLevel performanceLevel;
  
  const _CircularScoreWidget({
    required this.score,
    required this.progress,
    required this.performanceLevel,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: _CircularScorePainter(
          progress: progress,
          color: color,
          backgroundColor: Colors.grey[300]!,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${score.round()}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'puntos',
                style: TextStyle(
                  fontSize: 16,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                performanceLevel.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green[600]!;
    if (score >= 80) return Colors.green[500]!;
    if (score >= 70) return Colors.orange[500]!;
    if (score >= 60) return Colors.orange[600]!;
    return Colors.red[500]!;
  }
}

/// Custom painter for the circular score indicator
class _CircularScorePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  
  const _CircularScorePainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    
    final startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
    
    // Add gradient effect
    if (progress > 0) {
      final gradientPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 2),
        startAngle,
        sweepAngle,
        false,
        gradientPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularScorePainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.color != color;
  }
}

/// Performance level indicator with styled badge
class _PerformanceLevelIndicator extends StatelessWidget {
  final PerformanceLevel level;
  
  const _PerformanceLevelIndicator({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor(level);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        level.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
  
  Color _getLevelColor(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return Colors.green[600]!;
      case PerformanceLevel.great:
        return Colors.green[500]!;
      case PerformanceLevel.good:
        return Colors.orange[500]!;
      case PerformanceLevel.fair:
        return Colors.orange[600]!;
      case PerformanceLevel.needsWork:
        return Colors.red[500]!;
    }
  }
}

/// Row showing individual score components
class _ScoreComponentsRow extends StatelessWidget {
  final SessionAnalysis analysis;
  
  const _ScoreComponentsRow({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ScoreComponent(
          label: 'Timing',
          score: analysis.timingScore,
          icon: Icons.timer,
        ),
        _ScoreComponent(
          label: 'Progreso',
          score: analysis.progressScore,
          icon: Icons.trending_up,
        ),
        _ScoreComponent(
          label: 'Consistencia',
          score: analysis.consistencyScore,
          icon: Icons.show_chart,
        ),
        _ScoreComponent(
          label: 'Frecuencia',
          score: analysis.frequencyScore,
          icon: Icons.event_repeat,
        ),
      ],
    );
  }
}

/// Individual score component display
class _ScoreComponent extends StatefulWidget {
  final String label;
  final double score;
  final IconData icon;
  
  const _ScoreComponent({
    required this.label,
    required this.score,
    required this.icon,
  });

  @override
  State<_ScoreComponent> createState() => _ScoreComponentState();
}

class _ScoreComponentState extends State<_ScoreComponent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0,
      end: widget.score,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));
    
    // Delay animation based on position
    Future.delayed(Duration(milliseconds: 200 * widget.label.length % 4), () {
      if (mounted) {
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
    final color = _getScoreColor(widget.score);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_animation.value.round()}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
  
  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

/// Mini score display for use in other widgets
class MiniScoreDisplay extends StatelessWidget {
  final double score;
  final String label;
  final IconData? icon;
  final double size;
  
  const MiniScoreDisplay({
    super.key,
    required this.score,
    required this.label,
    this.icon,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, color: color, size: size * 0.4)
                : Text(
                    '${score.round()}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 0.25,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: size * 0.2,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}