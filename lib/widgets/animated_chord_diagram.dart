import 'package:flutter/material.dart';
import '../core/theme/arcade_theme.dart';
import '../core/data/chords_data.dart';
import 'hand_diagram.dart';

/// An enhanced chord diagram where each finger dot uses the finger's color,
/// supports per-finger highlighting, and a step-by-step reveal mode.
class AnimatedChordDiagram extends StatefulWidget {
  final ChordData chord;
  final double width;
  final double height;

  /// null = all fingers shown, 1-4 = only that finger highlighted (rest dimmed).
  final int? highlightedFinger;

  /// 0 = all visible, 1..n = show the first n unique fingers (with fade-in).
  final int stepIndex;

  const AnimatedChordDiagram({
    super.key,
    required this.chord,
    this.width = 200,
    this.height = 240,
    this.highlightedFinger,
    this.stepIndex = 0,
  });

  @override
  State<AnimatedChordDiagram> createState() => _AnimatedChordDiagramState();
}

class _AnimatedChordDiagramState extends State<AnimatedChordDiagram>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _previousStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _previousStepIndex = widget.stepIndex;
    _fadeController.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedChordDiagram old) {
    super.didUpdateWidget(old);
    if (old.stepIndex != widget.stepIndex && widget.stepIndex > _previousStepIndex) {
      _fadeController.forward(from: 0);
    }
    _previousStepIndex = widget.stepIndex;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Get the ordered list of unique finger numbers used in this chord.
  List<int> get _uniqueFingers {
    final seen = <int>{};
    final result = <int>[];
    for (final f in widget.chord.fingers) {
      if (f > 0 && seen.add(f)) {
        result.add(f);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: NeonEffects.neonContainer(
        ArcadeColors.neonCyan,
        backgroundColor: ArcadeColors.background,
        borderRadius: 12,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Chord name
          Text(
            widget.chord.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ArcadeColors.neonPink,
              shadows: NeonEffects.textGlow(ArcadeColors.neonPink),
            ),
          ),
          const SizedBox(height: 8),
          // Fretboard
          Expanded(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _AnimatedChordPainter(
                    chord: widget.chord,
                    highlightedFinger: widget.highlightedFinger,
                    stepIndex: widget.stepIndex,
                    uniqueFingers: _uniqueFingers,
                    fadeValue: _fadeAnimation.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedChordPainter extends CustomPainter {
  final ChordData chord;
  final int? highlightedFinger;
  final int stepIndex;
  final List<int> uniqueFingers;
  final double fadeValue;

  _AnimatedChordPainter({
    required this.chord,
    required this.highlightedFinger,
    required this.stepIndex,
    required this.uniqueFingers,
    required this.fadeValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int numStrings = 6;
    const int numFrets = 4;

    final double stringSpacing = size.width / (numStrings - 1);
    final double fretSpacing = (size.height - 30) / numFrets;
    final double topMargin = 30.0;

    final stringPaint = Paint()
      ..color = ArcadeColors.textSecondary
      ..strokeWidth = 1.5;

    final fretPaint = Paint()
      ..color = ArcadeColors.textSecondary
      ..strokeWidth = 1.0;

    final nutPaint = Paint()
      ..color = ArcadeColors.textPrimary
      ..strokeWidth = 4.0;

    // Find start fret
    final playedFrets = chord.frets.where((f) => f > 0).toList();
    final minFret = playedFrets.isEmpty ? 1 : playedFrets.reduce((a, b) => a < b ? a : b);
    final startFret = minFret > 3 ? minFret : 1;

    // Nut or fret number
    if (startFret == 1) {
      canvas.drawLine(Offset(0, topMargin), Offset(size.width, topMargin), nutPaint);
    } else {
      final tp = TextPainter(
        text: TextSpan(
          text: '$startFret',
          style: const TextStyle(color: ArcadeColors.textSecondary, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(-20, topMargin + fretSpacing / 2 - 6));
    }

    // Frets
    for (int i = 0; i <= numFrets; i++) {
      final y = topMargin + (i * fretSpacing);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), fretPaint);
    }

    // Strings
    for (int i = 0; i < numStrings; i++) {
      final x = i * stringSpacing;
      canvas.drawLine(Offset(x, topMargin), Offset(x, size.height), stringPaint);
    }

    // Visible fingers based on stepIndex
    final Set<int> visibleFingers;
    if (stepIndex <= 0) {
      visibleFingers = uniqueFingers.toSet();
    } else {
      visibleFingers = uniqueFingers.take(stepIndex).toSet();
    }

    // The newest finger (for fade animation)
    final int? newestFinger =
        stepIndex > 0 && stepIndex <= uniqueFingers.length ? uniqueFingers[stepIndex - 1] : null;

    // String labels and markers
    final stringNames = ['E', 'A', 'D', 'G', 'B', 'e'];
    for (int i = 0; i < numStrings; i++) {
      final x = i * stringSpacing;
      final fret = chord.frets[i];
      final finger = chord.fingers[i];

      // String name
      final tp = TextPainter(
        text: TextSpan(
          text: stringNames[i],
          style: const TextStyle(color: ArcadeColors.textMuted, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - 4, size.height + 4));

      // Muted / open markers
      if (fret == -1) {
        _drawX(canvas, Offset(x, topMargin - 15), ArcadeColors.neonRed);
      } else if (fret == 0) {
        _drawOpenCircle(canvas, Offset(x, topMargin - 15), ArcadeColors.neonGreen);
      }

      // Finger positions
      if (fret > 0 && finger > 0) {
        if (!visibleFingers.contains(finger)) continue;

        final adjustedFret = fret - startFret + 1;
        if (adjustedFret < 1 || adjustedFret > numFrets) continue;

        final y = topMargin + ((adjustedFret - 0.5) * fretSpacing);
        final fingerColor = FingerColors.fromFinger(finger);

        // Determine opacity
        double opacity = 1.0;
        if (highlightedFinger != null && finger != highlightedFinger) {
          opacity = 0.25;
        }
        if (newestFinger != null && finger == newestFinger) {
          opacity *= fadeValue;
        }

        _drawColoredFinger(canvas, Offset(x, y), finger, fingerColor, opacity);
      }
    }
  }

  void _drawX(Canvas canvas, Offset center, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const s = 8.0;
    canvas.drawLine(
      Offset(center.dx - s / 2, center.dy - s / 2),
      Offset(center.dx + s / 2, center.dy + s / 2),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + s / 2, center.dy - s / 2),
      Offset(center.dx - s / 2, center.dy + s / 2),
      paint,
    );
  }

  void _drawOpenCircle(Canvas canvas, Offset center, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 6, paint);
  }

  void _drawColoredFinger(
    Canvas canvas,
    Offset center,
    int finger,
    Color color,
    double opacity,
  ) {
    final effectiveColor = color.withValues(alpha: opacity);

    // Glow
    if (opacity > 0.5) {
      final glowPaint = Paint()
        ..color = effectiveColor.withValues(alpha: 0.3 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(center, 12, glowPaint);
    }

    // Main circle
    final fillPaint = Paint()
      ..color = effectiveColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10, fillPaint);

    // Finger number
    final tp = TextPainter(
      text: TextSpan(
        text: '$finger',
        style: TextStyle(
          color: ArcadeColors.background.withValues(alpha: opacity),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _AnimatedChordPainter old) {
    return old.chord != chord ||
        old.highlightedFinger != highlightedFinger ||
        old.stepIndex != stepIndex ||
        old.fadeValue != fadeValue;
  }
}
