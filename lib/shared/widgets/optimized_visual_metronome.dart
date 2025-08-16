import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'glass_card.dart';

/// Optimized visual metronome with efficient rendering and animations
class OptimizedVisualMetronome extends StatefulWidget {
  final int bpm;
  final bool isPlaying;
  final int currentBeat;
  final int timeSignature;
  final List<bool> accents;
  final Color primaryColor;
  final Color accentColor;

  const OptimizedVisualMetronome({
    super.key,
    required this.bpm,
    required this.isPlaying,
    this.currentBeat = 0,
    this.timeSignature = 4,
    this.accents = const [true, false, false, false],
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<OptimizedVisualMetronome> createState() => _OptimizedVisualMetronomeState();
}

class _OptimizedVisualMetronomeState extends State<OptimizedVisualMetronome>
    with TickerProviderStateMixin {
  
  late AnimationController _pendulumController;
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  
  late Animation<double> _pendulumAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;
  
  bool _isAnimating = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Pendulum animation
    _pendulumController = AnimationController(
      duration: Duration(milliseconds: (60000 / widget.bpm).round()),
      vsync: this,
    );
    
    _pendulumAnimation = Tween<double>(
      begin: -0.5,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _pendulumController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation for beat indication
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));

    // Ripple effect animation
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    _pendulumController.addStatusListener(_onPendulumStatusChanged);
  }

  void _onPendulumStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (widget.isPlaying && mounted) {
        _pendulumController.reverse();
        _triggerBeatEffects();
      }
    } else if (status == AnimationStatus.dismissed) {
      if (widget.isPlaying && mounted) {
        _pendulumController.forward();
        _triggerBeatEffects();
      }
    }
  }

  void _triggerBeatEffects() {
    if (!mounted) return;
    
    // Trigger pulse effect
    _pulseController.forward().then((_) {
      if (mounted) _pulseController.reset();
    });
    
    // Trigger ripple effect on accent beats
    if (widget.accents.length > widget.currentBeat && 
        widget.accents[widget.currentBeat]) {
      _rippleController.forward().then((_) {
        if (mounted) _rippleController.reset();
      });
    }
  }

  @override
  void didUpdateWidget(OptimizedVisualMetronome oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update BPM if changed
    if (oldWidget.bpm != widget.bpm) {
      _pendulumController.duration = Duration(
        milliseconds: (60000 / widget.bpm).round(),
      );
    }
    
    // Handle play/stop state changes
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  void _startAnimation() {
    if (!_isAnimating && mounted) {
      _isAnimating = true;
      _pendulumController.forward();
    }
  }

  void _stopAnimation() {
    if (_isAnimating) {
      _isAnimating = false;
      _pendulumController.stop();
      _pulseController.stop();
      _rippleController.stop();
    }
  }

  @override
  void dispose() {
    _pendulumController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          height: 280,
          child: Column(
            children: [
              _buildBPMDisplay(),
              const SizedBox(height: 20),
              Expanded(child: _buildMetronomeVisual()),
              const SizedBox(height: 20),
              _buildBeatIndicators(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBPMDisplay() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isPlaying ? _pulseAnimation.value : 1.0,
          child: Column(
            children: [
              Text(
                '${widget.bpm}',
                style: GuitarrTypography.bpmDisplay.copyWith(
                  color: GuitarrColors.ampOrange,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'BPM',
                style: GuitarrTypography.labelLarge.copyWith(
                  color: GuitarrColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetronomeVisual() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pendulumAnimation, _rippleAnimation]),
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 160),
          painter: MetronomePainter(
            pendulumAngle: _pendulumAnimation.value,
            rippleProgress: _rippleAnimation.value,
            primaryColor: GuitarrColors.ampOrange,
            accentColor: GuitarrColors.steelGold,
            isPlaying: widget.isPlaying,
          ),
        );
      },
    );
  }

  Widget _buildBeatIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.timeSignature, (index) {
        final isCurrentBeat = widget.isPlaying && widget.currentBeat == index;
        final isAccented = widget.accents.length > index && widget.accents[index];
        
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = isCurrentBeat ? _pulseAnimation.value : 1.0;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrentBeat
                        ? GuitarrColors.ampOrange
                        : isAccented
                            ? GuitarrColors.ampOrange.withOpacity(0.3)
                            : GuitarrColors.metronomeInactive,
                    border: isAccented
                        ? Border.all(
                            color: GuitarrColors.ampOrange,
                            width: 2,
                          )
                        : null,
                    boxShadow: isCurrentBeat
                        ? [
                            BoxShadow(
                              color: GuitarrColors.ampOrange.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GuitarrTypography.labelMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isCurrentBeat
                            ? Colors.white
                            : GuitarrColors.ampOrange,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class MetronomePainter extends CustomPainter {
  final double pendulumAngle;
  final double rippleProgress;
  final Color primaryColor;
  final Color accentColor;
  final bool isPlaying;

  MetronomePainter({
    required this.pendulumAngle,
    required this.rippleProgress,
    required this.primaryColor,
    required this.accentColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 3;
    
    // Draw ripple effect
    if (rippleProgress > 0 && isPlaying) {
      _drawRipple(canvas, center, baseRadius, rippleProgress);
    }
    
    // Draw metronome base
    _drawBase(canvas, center, baseRadius);
    
    // Draw pendulum
    _drawPendulum(canvas, center, baseRadius);
  }

  void _drawRipple(Canvas canvas, Offset center, double baseRadius, double progress) {
    final ripplePaint = Paint()
      ..color = accentColor.withOpacity((1 - progress) * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    final rippleRadius = baseRadius + (baseRadius * progress * 1.5);
    canvas.drawCircle(center, rippleRadius, ripplePaint);
  }

  void _drawBase(Canvas canvas, Offset center, double baseRadius) {
    // Draw outer circle (metronome body)
    final basePaint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, baseRadius, basePaint);
    canvas.drawCircle(center, baseRadius, borderPaint);
    
    // Draw center point
    final centerPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 6, centerPaint);
  }

  void _drawPendulum(Canvas canvas, Offset center, double baseRadius) {
    final pendulumPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    final pendulumLength = baseRadius * 1.2;
    final angle = pendulumAngle * (math.pi / 6); // Convert to radians, limit swing
    
    final endX = center.dx + math.sin(angle) * pendulumLength;
    final endY = center.dy - math.cos(angle) * pendulumLength;
    final endPoint = Offset(endX, endY);
    
    // Draw pendulum rod
    canvas.drawLine(center, endPoint, pendulumPaint);
    
    // Draw pendulum weight
    final weightPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(endPoint, 8, weightPaint);
    
    // Add highlight to weight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(endPoint.dx - 2, endPoint.dy - 2),
      3,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(MetronomePainter oldDelegate) {
    return oldDelegate.pendulumAngle != pendulumAngle ||
           oldDelegate.rippleProgress != rippleProgress ||
           oldDelegate.isPlaying != isPlaying;
  }
}