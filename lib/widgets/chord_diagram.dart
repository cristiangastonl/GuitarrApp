import 'package:flutter/material.dart';
import '../core/theme/arcade_theme.dart';
import '../core/data/chords_data.dart';

/// Displays a guitar chord diagram
class ChordDiagram extends StatelessWidget {
  final ChordData chord;
  final double width;
  final double height;
  final bool showFingers;
  final bool animated;

  const ChordDiagram({
    super.key,
    required this.chord,
    this.width = 200,
    this.height = 240,
    this.showFingers = true,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
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
            chord.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ArcadeColors.neonPink,
              shadows: NeonEffects.textGlow(ArcadeColors.neonPink),
            ),
          ),
          const SizedBox(height: 8),
          // Fretboard diagram
          Expanded(
            child: CustomPaint(
              painter: _ChordDiagramPainter(
                chord: chord,
                showFingers: showFingers,
              ),
              size: Size(width - 32, height - 80),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChordDiagramPainter extends CustomPainter {
  final ChordData chord;
  final bool showFingers;

  _ChordDiagramPainter({
    required this.chord,
    required this.showFingers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int numStrings = 6;
    const int numFrets = 4;

    final double stringSpacing = size.width / (numStrings - 1);
    final double fretSpacing = (size.height - 30) / numFrets;
    final double topMargin = 30.0;

    // Paint objects
    final stringPaint = Paint()
      ..color = ArcadeColors.textSecondary
      ..strokeWidth = 1.5;

    final fretPaint = Paint()
      ..color = ArcadeColors.textSecondary
      ..strokeWidth = 1.0;

    final nutPaint = Paint()
      ..color = ArcadeColors.textPrimary
      ..strokeWidth = 4.0;

    // Find min fret to determine if we need to show fret position
    final playedFrets = chord.frets.where((f) => f > 0).toList();
    final minFret = playedFrets.isEmpty ? 1 : playedFrets.reduce((a, b) => a < b ? a : b);
    final startFret = minFret > 3 ? minFret : 1;

    // Draw nut (thick line at top) or fret position
    if (startFret == 1) {
      canvas.drawLine(
        Offset(0, topMargin),
        Offset(size.width, topMargin),
        nutPaint,
      );
    } else {
      // Show fret number
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$startFret',
          style: const TextStyle(
            color: ArcadeColors.textSecondary,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-20, topMargin + fretSpacing / 2 - 6));
    }

    // Draw frets (horizontal lines)
    for (int i = 0; i <= numFrets; i++) {
      final y = topMargin + (i * fretSpacing);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        fretPaint,
      );
    }

    // Draw strings (vertical lines)
    for (int i = 0; i < numStrings; i++) {
      final x = i * stringSpacing;
      canvas.drawLine(
        Offset(x, topMargin),
        Offset(x, size.height),
        stringPaint,
      );
    }

    // Draw string labels and markers at top
    final stringNames = ['E', 'A', 'D', 'G', 'B', 'e'];
    for (int i = 0; i < numStrings; i++) {
      final x = i * stringSpacing;
      final fret = chord.frets[i];

      // Draw string name
      final textPainter = TextPainter(
        text: TextSpan(
          text: stringNames[i],
          style: const TextStyle(
            color: ArcadeColors.textMuted,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 4, size.height + 4));

      // Draw marker at top (open, muted, or nothing)
      if (fret == -1) {
        // Muted string - X
        _drawX(canvas, Offset(x, topMargin - 15), ArcadeColors.neonRed);
      } else if (fret == 0) {
        // Open string - O
        _drawOpenCircle(canvas, Offset(x, topMargin - 15), ArcadeColors.neonGreen);
      }

      // Draw finger position
      if (fret > 0) {
        final adjustedFret = fret - startFret + 1;
        if (adjustedFret >= 1 && adjustedFret <= numFrets) {
          final y = topMargin + ((adjustedFret - 0.5) * fretSpacing);
          _drawFinger(
            canvas,
            Offset(x, y),
            showFingers ? chord.fingers[i] : null,
          );
        }
      }
    }
  }

  void _drawX(Canvas canvas, Offset center, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const size = 8.0;
    canvas.drawLine(
      Offset(center.dx - size / 2, center.dy - size / 2),
      Offset(center.dx + size / 2, center.dy + size / 2),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + size / 2, center.dy - size / 2),
      Offset(center.dx - size / 2, center.dy + size / 2),
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

  void _drawFinger(Canvas canvas, Offset center, int? finger) {
    // Draw filled circle
    final fillPaint = Paint()
      ..color = ArcadeColors.neonGreen
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = ArcadeColors.neonGreen.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Glow effect
    canvas.drawCircle(center, 12, glowPaint);
    // Main circle
    canvas.drawCircle(center, 10, fillPaint);

    // Draw finger number if provided
    if (finger != null && finger > 0) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$finger',
          style: const TextStyle(
            color: ArcadeColors.background,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChordDiagramPainter oldDelegate) {
    return oldDelegate.chord != chord || oldDelegate.showFingers != showFingers;
  }
}

/// Compact chord diagram for level selection
class ChordDiagramMini extends StatelessWidget {
  final ChordData chord;
  final double size;

  const ChordDiagramMini({
    super.key,
    required this.chord,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ArcadeColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ArcadeColors.neonCyan.withOpacity(0.5)),
      ),
      child: Center(
        child: Text(
          chord.name,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            color: ArcadeColors.neonPink,
            shadows: NeonEffects.textGlow(ArcadeColors.neonPink, intensity: 0.5),
          ),
        ),
      ),
    );
  }
}
