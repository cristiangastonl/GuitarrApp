import 'package:flutter/material.dart';

/// A widget that creates a pulsing animation effect
/// Perfect for recording indicators, metronome beats, and visual feedback
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool animate;
  final Color? pulseColor;
  final double? pulseOpacity;
  final int? pulseCount;
  final Curve curve;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.8,
    this.maxScale = 1.2,
    this.animate = true,
    this.pulseColor,
    this.pulseOpacity = 0.3,
    this.pulseCount,
    this.curve = Curves.easeInOut,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: widget.curve,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: widget.curve,
    ));

    if (widget.animate) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (widget.pulseCount != null) {
      _animateWithCount();
    } else {
      _animateInfinite();
    }
  }

  void _animateInfinite() {
    _scaleController.repeat(reverse: true);
    _pulseController.repeat();
  }

  void _animateWithCount() async {
    for (int i = 0; i < widget.pulseCount!; i++) {
      await _scaleController.forward();
      await _scaleController.reverse();
      _pulseController.forward().then((_) => _pulseController.reset());
    }
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _startAnimation();
      } else {
        _scaleController.stop();
        _pulseController.stop();
        _scaleController.reset();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _pulseController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse effect
            if (widget.pulseColor != null)
              Transform.scale(
                scale: 1.0 + (_pulseAnimation.value * 0.5),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.pulseColor!.withOpacity(
                      (widget.pulseOpacity ?? 0.3) * (1.0 - _pulseAnimation.value),
                    ),
                  ),
                ),
              ),
            
            // Main content with scale animation
            Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.child,
            ),
          ],
        );
      },
    );
  }
}

/// A specialized pulse animation for recording indicators
class RecordingPulse extends StatelessWidget {
  final bool isRecording;
  final double size;
  final Color? recordingColor;

  const RecordingPulse({
    super.key,
    required this.isRecording,
    this.size = 16,
    this.recordingColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = recordingColor ?? Colors.red;
    
    return PulseAnimation(
      animate: isRecording,
      duration: const Duration(milliseconds: 800),
      minScale: 0.9,
      maxScale: 1.1,
      pulseColor: color,
      pulseOpacity: 0.4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording ? color : color.withOpacity(0.3),
          boxShadow: isRecording ? [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
      ),
    );
  }
}

/// A metronome beat indicator with pulse animation
class MetronomePulse extends StatelessWidget {
  final bool isActive;
  final int? bpm;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const MetronomePulse({
    super.key,
    required this.isActive,
    this.bpm,
    this.size = 20,
    this.activeColor,
    this.inactiveColor,
  });

  Duration get _pulseDuration {
    if (bpm != null && bpm! > 0) {
      // Convert BPM to milliseconds per beat
      return Duration(milliseconds: (60000 / bpm!).round());
    }
    return const Duration(milliseconds: 500);
  }

  @override
  Widget build(BuildContext context) {
    final activeCol = activeColor ?? Theme.of(context).primaryColor;
    final inactiveCol = inactiveColor ?? Theme.of(context).disabledColor;
    
    return PulseAnimation(
      animate: isActive,
      duration: _pulseDuration,
      minScale: 0.8,
      maxScale: 1.2,
      pulseColor: activeCol,
      pulseOpacity: 0.3,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? activeCol : inactiveCol,
          border: Border.all(
            color: isActive ? activeCol : inactiveCol,
            width: 2,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: activeCol.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Center(
          child: Container(
            width: size * 0.4,
            height: size * 0.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// A loading spinner with pulse effect
class LoadingPulse extends StatelessWidget {
  final Color? color;
  final double size;
  final double strokeWidth;

  const LoadingPulse({
    super.key,
    this.color,
    this.size = 40,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    final loaderColor = color ?? Theme.of(context).primaryColor;
    
    return PulseAnimation(
      animate: true,
      duration: const Duration(milliseconds: 1200),
      minScale: 0.9,
      maxScale: 1.1,
      pulseColor: loaderColor,
      pulseOpacity: 0.2,
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: loaderColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}