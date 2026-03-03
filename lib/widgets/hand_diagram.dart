import 'package:flutter/material.dart';
import '../core/theme/arcade_theme.dart';

/// Maps finger numbers to neon colors
class FingerColors {
  FingerColors._();

  static const Color index = ArcadeColors.neonCyan; // 1
  static const Color middle = ArcadeColors.neonPink; // 2
  static const Color ring = ArcadeColors.neonGreen; // 3
  static const Color pinky = ArcadeColors.neonYellow; // 4
  static const Color thumb = ArcadeColors.neonPurple;

  static Color fromFinger(int finger) {
    switch (finger) {
      case 1:
        return index;
      case 2:
        return middle;
      case 3:
        return ring;
      case 4:
        return pinky;
      default:
        return thumb;
    }
  }

  static String nameFromFinger(int finger) {
    switch (finger) {
      case 1:
        return 'Índice';
      case 2:
        return 'Medio';
      case 3:
        return 'Anular';
      case 4:
        return 'Meñique';
      default:
        return 'Pulgar';
    }
  }
}

/// Displays a left hand diagram with 4 numbered, colored fingers.
class HandDiagram extends StatelessWidget {
  /// Which fingers to highlight (1-4). Empty or null = all highlighted.
  final Set<int> highlightedFingers;

  /// Whether to show finger name labels below the hand.
  final bool showLabels;

  const HandDiagram({
    super.key,
    this.highlightedFingers = const {},
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HandPainter(
        highlightedFingers: highlightedFingers,
        showLabels: showLabels,
      ),
    );
  }
}

class _HandPainter extends CustomPainter {
  final Set<int> highlightedFingers;
  final bool showLabels;

  _HandPainter({
    required this.highlightedFingers,
    required this.showLabels,
  });

  bool _isHighlighted(int finger) {
    if (highlightedFingers.isEmpty) return true;
    return highlightedFingers.contains(finger);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- Palm ---
    final palmRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.45, w * 0.60, h * 0.45),
      const Radius.circular(16),
    );
    final palmPaint = Paint()
      ..color = ArcadeColors.backgroundLight
      ..style = PaintingStyle.fill;
    final palmBorder = Paint()
      ..color = ArcadeColors.textMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(palmRect, palmPaint);
    canvas.drawRRect(palmRect, palmBorder);

    // --- Thumb (left side, pointing left-up) ---
    final thumbColor = _isHighlighted(0)
        ? FingerColors.thumb
        : FingerColors.thumb.withValues(alpha: 0.3);
    _drawThumb(canvas, w, h, thumbColor);

    // --- Fingers ---
    // Positions: index(1), middle(2), ring(3), pinky(4) from left to right
    // when viewed from the front (left hand, palm facing you)
    final fingerData = [
      _FingerData(1, 0.22, 0.07, w * 0.11, h * 0.38),
      _FingerData(2, 0.39, 0.03, w * 0.11, h * 0.42),
      _FingerData(3, 0.56, 0.05, w * 0.11, h * 0.40),
      _FingerData(4, 0.73, 0.11, w * 0.10, h * 0.34),
    ];

    for (final fd in fingerData) {
      final color = _isHighlighted(fd.finger)
          ? FingerColors.fromFinger(fd.finger)
          : FingerColors.fromFinger(fd.finger).withValues(alpha: 0.3);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          w * fd.xFrac - fd.width / 2,
          h * fd.yFrac,
          fd.width,
          fd.height,
        ),
        const Radius.circular(8),
      );

      // Glow
      if (_isHighlighted(fd.finger)) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawRRect(rect, glowPaint);
      }

      // Finger body
      final fillPaint = Paint()
        ..color = ArcadeColors.backgroundLight
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(rect, fillPaint);
      canvas.drawRRect(rect, borderPaint);

      // Numbered circle at fingertip
      final tipCenter = Offset(
        w * fd.xFrac,
        h * fd.yFrac + fd.width * 0.6,
      );
      final circlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tipCenter, fd.width * 0.35, circlePaint);

      // Number text
      final tp = TextPainter(
        text: TextSpan(
          text: '${fd.finger}',
          style: TextStyle(
            color: ArcadeColors.background,
            fontSize: fd.width * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(tipCenter.dx - tp.width / 2, tipCenter.dy - tp.height / 2));
    }

    // --- Labels ---
    if (showLabels) {
      final labels = [
        _LabelData(1, 0.22),
        _LabelData(2, 0.39),
        _LabelData(3, 0.56),
        _LabelData(4, 0.73),
      ];
      for (final ld in labels) {
        final color = _isHighlighted(ld.finger)
            ? FingerColors.fromFinger(ld.finger)
            : ArcadeColors.textMuted;
        final tp = TextPainter(
          text: TextSpan(
            text: FingerColors.nameFromFinger(ld.finger),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(w * ld.xFrac - tp.width / 2, h * 0.93));
      }
    }
  }

  void _drawThumb(Canvas canvas, double w, double h, Color color) {
    final thumbPath = Path()
      ..moveTo(w * 0.20, h * 0.50)
      ..quadraticBezierTo(w * 0.05, h * 0.45, w * 0.08, h * 0.32)
      ..quadraticBezierTo(w * 0.10, h * 0.22, w * 0.16, h * 0.28)
      ..quadraticBezierTo(w * 0.20, h * 0.33, w * 0.20, h * 0.45);

    final fillPaint = Paint()
      ..color = ArcadeColors.backgroundLight
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(thumbPath, fillPaint);
    canvas.drawPath(thumbPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _HandPainter old) {
    return old.highlightedFingers != highlightedFingers ||
        old.showLabels != showLabels;
  }
}

class _FingerData {
  final int finger;
  final double xFrac;
  final double yFrac;
  final double width;
  final double height;

  _FingerData(this.finger, this.xFrac, this.yFrac, this.width, this.height);
}

class _LabelData {
  final int finger;
  final double xFrac;

  _LabelData(this.finger, this.xFrac);
}
