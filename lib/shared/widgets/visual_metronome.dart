import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../theme/colors.dart';
import '../theme/typography.dart';
import '../../core/audio/metronome_service.dart';

/// Modern visual metronome with pulsating circles and beat indicators
class VisualMetronome extends ConsumerWidget {
  const VisualMetronome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metronomeState = ref.watch(metronomeStateProvider);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GuitarrColors.surface2,
            GuitarrColors.backgroundTertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: GuitarrColors.glassBorderSubtle,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: GuitarrColors.shadowMedium,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // BPM Display with modern styling
          _BpmDisplay(bpm: metronomeState.bpm),
          
          const SizedBox(height: 32),
          
          // Visual Beat Indicators
          _BeatIndicators(
            timeSignature: metronomeState.timeSignature,
            currentBeat: metronomeState.currentBeat,
            isPlaying: metronomeState.isPlaying,
            accents: metronomeState.accents,
          ),
          
          const SizedBox(height: 32),
          
          // Main Pulse Circle
          _MainPulseCircle(
            isPlaying: metronomeState.isPlaying,
            bpm: metronomeState.bpm,
            isAccent: metronomeState.currentBeat < metronomeState.accents.length 
                && metronomeState.accents[metronomeState.currentBeat],
          ),
          
          const SizedBox(height: 32),
          
          // Controls Row
          _MetronomeControls(),
        ],
      ),
    );
  }
}

/// Large BPM display with gradient text
class _BpmDisplay extends StatelessWidget {
  final int bpm;
  
  const _BpmDisplay({required this.bpm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              GuitarrColors.ampOrange,
              GuitarrColors.steelGold,
            ],
          ).createShader(bounds),
          child: Text(
            bpm.toString(),
            style: GuitarrTypography.bpmDisplay.copyWith(
              color: Colors.white,
            ),
          ),
        ),
        Text(
          'BPM',
          style: GuitarrTypography.labelLarge.copyWith(
            color: GuitarrColors.textTertiary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

/// Beat indicators showing current position in measure
class _BeatIndicators extends StatelessWidget {
  final int timeSignature;
  final int currentBeat;
  final bool isPlaying;
  final List<bool> accents;
  
  const _BeatIndicators({
    required this.timeSignature,
    required this.currentBeat,
    required this.isPlaying,
    required this.accents,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(timeSignature, (index) {
        final isCurrentBeat = isPlaying && (currentBeat % timeSignature) == index;
        final isAccent = index < accents.length && accents[index];
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrentBeat 
                ? (isAccent ? GuitarrColors.metronomeAccent : GuitarrColors.metronomeBeat)
                : GuitarrColors.metronomeInactive,
            border: isAccent && !isCurrentBeat
                ? Border.all(color: GuitarrColors.metronomeAccent, width: 2)
                : null,
            boxShadow: isCurrentBeat ? [
              BoxShadow(
                color: (isAccent ? GuitarrColors.metronomeAccent : GuitarrColors.metronomeBeat).withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ] : null,
          ),
        );
      }),
    );
  }
}

/// Main pulsating circle that responds to beats
class _MainPulseCircle extends StatefulWidget {
  final bool isPlaying;
  final int bpm;
  final bool isAccent;
  
  const _MainPulseCircle({
    required this.isPlaying,
    required this.bpm,
    required this.isAccent,
  });

  @override
  State<_MainPulseCircle> createState() => _MainPulseCircleState();
}

class _MainPulseCircleState extends State<_MainPulseCircle>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    if (widget.isPlaying) {
      _rotationController.repeat();
    }
  }
  
  @override
  void didUpdateWidget(_MainPulseCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    }
    
    // Trigger pulse animation on beat change
    if (widget.isPlaying && widget.isAccent != oldWidget.isAccent) {
      _pulseController.forward().then((_) {
        if (mounted) {
          _pulseController.reverse();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _rotationController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (widget.isAccent ? GuitarrColors.metronomeAccent : GuitarrColors.metronomeBeat)
                        .withOpacity(_opacityAnimation.value),
                    (widget.isAccent ? GuitarrColors.metronomeAccent : GuitarrColors.metronomeBeat)
                        .withOpacity(_opacityAnimation.value * 0.1),
                  ],
                ),
                border: Border.all(
                  color: widget.isAccent 
                      ? GuitarrColors.metronomeAccent 
                      : GuitarrColors.metronomeBeat,
                  width: 3,
                ),
                boxShadow: widget.isPlaying ? [
                  BoxShadow(
                    color: (widget.isAccent 
                        ? GuitarrColors.metronomeAccent 
                        : GuitarrColors.metronomeBeat).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ] : null,
              ),
              child: Center(
                child: Icon(
                  widget.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 48,
                  color: GuitarrColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Control buttons for the metronome
class _MetronomeControls extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metronomeState = ref.watch(metronomeStateProvider);
    final metronomeNotifier = ref.read(metronomeStateProvider.notifier);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Decrease BPM
        _ControlButton(
          icon: Icons.remove,
          onPressed: () => metronomeNotifier.setBpm(metronomeState.bpm - 1),
          tooltip: 'Disminuir BPM',
        ),
        
        // Play/Pause
        _PlayPauseButton(
          isPlaying: metronomeState.isPlaying,
          onPressed: () => metronomeNotifier.togglePlay(),
        ),
        
        // Increase BPM
        _ControlButton(
          icon: Icons.add,
          onPressed: () => metronomeNotifier.setBpm(metronomeState.bpm + 1),
          tooltip: 'Aumentar BPM',
        ),
      ],
    );
  }
}

/// Styled control button
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  
  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: GuitarrColors.surface3,
          border: Border.all(
            color: GuitarrColors.glassBorderSubtle,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: GuitarrColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: GuitarrColors.textSecondary,
          iconSize: 24,
        ),
      ),
    );
  }
}

/// Special play/pause button with enhanced styling
class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  
  const _PlayPauseButton({
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GuitarrColors.ampOrange,
              GuitarrColors.ampOrangeDark,
            ],
          ),
          border: Border.all(
            color: GuitarrColors.glassBorder,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: GuitarrColors.ampOrange.withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          size: 32,
          color: GuitarrColors.textPrimary,
        ),
      ),
    );
  }
}