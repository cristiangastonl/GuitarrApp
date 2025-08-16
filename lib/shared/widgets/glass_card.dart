import 'package:flutter/material.dart';
import 'dart:ui';

import '../theme/colors.dart';
import 'audio_preview_controls.dart';

/// Modern glassmorphic card with blur effects and subtle transparency
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurStrength;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.all(8),
    this.borderRadius = 20,
    double blurStrength = 15,
    double? blurIntensity, // Legacy parameter for compatibility
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.shadows,
    this.onTap,
  }) : blurStrength = blurIntensity ?? blurStrength;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? GuitarrColors.glassOverlay;
    final effectiveBorderColor = borderColor ?? GuitarrColors.glassBorder;
    final effectiveShadows = shadows ?? [
      BoxShadow(
        color: GuitarrColors.shadowMedium,
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      ),
    ];
    
    Widget content = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        boxShadow: effectiveShadows,
      ),
      child: child,
    );
    
    // Apply backdrop filter for glass effect
    content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
        child: content,
      ),
    );
    
    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    
    return content;
  }
}

/// Specialized glass card for music-related content
class MusicGlassCard extends StatelessWidget {
  final Widget child;
  final String? genre;
  final bool isActive;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  
  const MusicGlassCard({
    super.key,
    required this.child,
    this.genre,
    this.isActive = false,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor = genre != null 
        ? GuitarrColors.getGenreColor(genre!)
        : GuitarrColors.ampOrange;
    
    return GlassCard(
      onTap: onTap,
      padding: padding,
      margin: margin,
      backgroundColor: isActive 
          ? accentColor.withOpacity(0.15)
          : GuitarrColors.glassOverlay,
      borderColor: isActive 
          ? accentColor.withOpacity(0.5)
          : GuitarrColors.glassBorder,
      borderWidth: isActive ? 2 : 1,
      shadows: isActive ? [
        BoxShadow(
          color: accentColor.withOpacity(0.2),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 2,
        ),
      ] : null,
      child: child,
    );
  }
}

/// Glass card specifically designed for riff/song items
class RiffGlassCard extends StatefulWidget {
  final String name;
  final String artist;
  final String genre;
  final String difficulty;
  final int targetBpm;
  final int currentBpm;
  final double progress;
  final List<String> techniques;
  final VoidCallback? onTap;
  final bool showAudioControls;
  final String? riffId;
  final String? audioPreviewUrl;
  final Duration? animationDelay;
  
  const RiffGlassCard({
    super.key,
    required this.name,
    required this.artist,
    required this.genre,
    required this.difficulty,
    required this.targetBpm,
    required this.currentBpm,
    required this.progress,
    required this.techniques,
    this.onTap,
    this.showAudioControls = true,
    this.riffId,
    this.audioPreviewUrl,
    this.animationDelay,
  });

  @override
  State<RiffGlassCard> createState() => _RiffGlassCardState();
}

class _RiffGlassCardState extends State<RiffGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    // Start animation with optional delay
    Future.delayed(widget.animationDelay ?? Duration.zero, () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: MusicGlassCard(
                genre: widget.genre,
                onTap: widget.onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with title and difficulty
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name,
                                style: Theme.of(context).textTheme.headlineMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.artist,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: GuitarrColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _DifficultyChip(difficulty: widget.difficulty),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // BPM Progress
                    _AnimatedBpmProgressBar(
                      currentBpm: widget.currentBpm,
                      targetBpm: widget.targetBpm,
                      progress: widget.progress,
                      animationController: _animationController,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Techniques chips
                    _TechniquesRow(techniques: widget.techniques),
                    
                    const SizedBox(height: 12),
                    
                    // Genre tag
                    _GenreTag(genre: widget.genre),
                    
                    // Audio controls (if enabled and riff ID provided)
                    if (widget.showAudioControls && widget.riffId != null) ...[
                      const SizedBox(height: 16),
                      AudioPreviewControls(
                        trackId: widget.riffId!,
                        artist: widget.artist,
                        trackName: widget.name,
                        previewUrl: widget.audioPreviewUrl,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Chip showing difficulty level
class _DifficultyChip extends StatelessWidget {
  final String difficulty;
  
  const _DifficultyChip({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        chipColor = GuitarrColors.success;
        break;
      case 'medium':
        chipColor = GuitarrColors.warning;
        break;
      case 'hard':
        chipColor = GuitarrColors.error;
        break;
      default:
        chipColor = GuitarrColors.guitarTeal;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: chipColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// BPM progress visualization
class _BpmProgressBar extends StatelessWidget {
  final int currentBpm;
  final int targetBpm;
  final double progress;
  
  const _BpmProgressBar({
    required this.currentBpm,
    required this.targetBpm,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  flex: 2,
                  child: Text(
                    '$currentBpm BPM',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: GuitarrColors.ampOrange,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 3,
                  child: Text(
                    'Meta: $targetBpm BPM',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: GuitarrColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: GuitarrColors.metronomeInactive,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: GuitarrColors.bpmProgressGradient,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).round()}% completado',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: GuitarrColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }
}

/// Animated BPM progress visualization
class _AnimatedBpmProgressBar extends StatelessWidget {
  final int currentBpm;
  final int targetBpm;
  final double progress;
  final AnimationController animationController;
  
  const _AnimatedBpmProgressBar({
    required this.currentBpm,
    required this.targetBpm,
    required this.progress,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final progressAnimation = Tween<double>(
      begin: 0.0,
      end: progress,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  flex: 2,
                  child: TweenAnimationBuilder<int>(
                    duration: const Duration(milliseconds: 800),
                    tween: IntTween(begin: 0, end: currentBpm),
                    builder: (context, value, child) {
                      return Text(
                        '$value BPM',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: GuitarrColors.ampOrange,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 3,
                  child: Text(
                    'Meta: $targetBpm BPM',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: GuitarrColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: GuitarrColors.metronomeInactive,
              ),
              child: AnimatedBuilder(
                animation: progressAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressAnimation.value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: GuitarrColors.bpmProgressGradient,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: progressAnimation,
              builder: (context, child) {
                final animatedProgress = (progressAnimation.value * 100).round();
                return Text(
                  '$animatedProgress% completado',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: GuitarrColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Row of technique chips
class _TechniquesRow extends StatelessWidget {
  final List<String> techniques;
  
  const _TechniquesRow({required this.techniques});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: techniques.take(4).map((technique) {
            return Container(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.45, // Max 45% of available width
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: GuitarrColors.surface3,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: GuitarrColors.glassBorderSubtle,
                  width: 1,
                ),
              ),
              child: Text(
                technique.replaceAll('-', ' '),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: GuitarrColors.textSecondary,
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Genre identification tag
class _GenreTag extends StatelessWidget {
  final String genre;
  
  const _GenreTag({required this.genre});

  @override
  Widget build(BuildContext context) {
    final genreColor = GuitarrColors.getGenreColor(genre);
    
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: genreColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          genre.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: genreColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}