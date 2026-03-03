import 'package:flutter/material.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../widgets/neon_text.dart';

class TutorialFretboardPage extends StatelessWidget {
  const TutorialFretboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          const NeonText(
            text: 'EL DIAPASÓN',
            fontSize: 22,
            color: ArcadeColors.neonGreen,
          ),
          const SizedBox(height: 8),
          Text(
            'Donde pones los dedos',
            style: TextStyle(fontSize: 14, color: ArcadeColors.textSecondary),
          ),

          const SizedBox(height: 24),

          // Horizontal fretboard
          Expanded(
            child: Center(
              child: SizedBox(
                width: double.infinity,
                height: 200,
                child: CustomPaint(
                  painter: _FretboardPainter(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ArcadeColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ArcadeColors.neonGreen.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                _LegendRow(
                  icon: 'O',
                  color: ArcadeColors.neonGreen,
                  text: 'Cuerda al aire (se toca sin pisar)',
                ),
                const SizedBox(height: 6),
                _LegendRow(
                  icon: 'X',
                  color: ArcadeColors.neonRed,
                  text: 'Cuerda que NO se toca',
                ),
                const SizedBox(height: 6),
                _LegendRow(
                  icon: '●',
                  color: ArcadeColors.neonCyan,
                  text: 'Dedo presionando en un traste',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ArcadeColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ArcadeColors.neonGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, size: 16, color: ArcadeColors.neonYellow),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Los trastes se numeran desde la cejilla (nut). El 1er traste es el más cercano a la cabeza.',
                    style: TextStyle(fontSize: 11, color: ArcadeColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String icon;
  final Color color;
  final String text;

  const _LegendRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            icon,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: ArcadeColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _FretboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const numStrings = 6;
    const numFrets = 5;

    final stringSpacing = h / (numStrings + 1);
    final fretSpacing = (w - 60) / numFrets; // 60px for head labels
    final leftMargin = 60.0;

    // --- Head label ---
    final headTp = TextPainter(
      text: const TextSpan(
        text: '← Cabeza',
        style: TextStyle(color: ArcadeColors.textMuted, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    headTp.layout();
    headTp.paint(canvas, Offset(2, h - 16));

    // --- Body label ---
    final bodyTp = TextPainter(
      text: const TextSpan(
        text: 'Cuerpo →',
        style: TextStyle(color: ArcadeColors.textMuted, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    bodyTp.layout();
    bodyTp.paint(canvas, Offset(w - bodyTp.width - 2, h - 16));

    // --- Nut (thick vertical line) ---
    final nutPaint = Paint()
      ..color = ArcadeColors.textPrimary
      ..strokeWidth = 4;
    canvas.drawLine(
      Offset(leftMargin, stringSpacing),
      Offset(leftMargin, stringSpacing * numStrings),
      nutPaint,
    );

    // --- "Nut" label ---
    final nutTp = TextPainter(
      text: const TextSpan(
        text: 'Nut',
        style: TextStyle(color: ArcadeColors.neonYellow, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    nutTp.layout();
    nutTp.paint(canvas, Offset(leftMargin - nutTp.width / 2, stringSpacing * numStrings + 8));

    // --- Frets (vertical lines) ---
    final fretPaint = Paint()
      ..color = ArcadeColors.textSecondary
      ..strokeWidth = 1.5;

    for (int i = 1; i <= numFrets; i++) {
      final x = leftMargin + i * fretSpacing;
      canvas.drawLine(
        Offset(x, stringSpacing),
        Offset(x, stringSpacing * numStrings),
        fretPaint,
      );

      // Fret number
      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: const TextStyle(
            color: ArcadeColors.neonGreen,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(leftMargin + (i - 0.5) * fretSpacing - tp.width / 2, 4));
    }

    // --- Strings (horizontal lines) ---
    final stringPaint = Paint()..style = PaintingStyle.stroke;
    final stringNames = ['e', 'B', 'G', 'D', 'A', 'E'];

    for (int i = 0; i < numStrings; i++) {
      final y = stringSpacing * (i + 1);
      final thickness = 0.8 + i * 0.5;

      stringPaint
        ..color = ArcadeColors.textSecondary
        ..strokeWidth = thickness;

      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(w - 10, y),
        stringPaint,
      );

      // String name label
      final tp = TextPainter(
        text: TextSpan(
          text: stringNames[i],
          style: const TextStyle(
            color: ArcadeColors.neonCyan,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(leftMargin - tp.width - 8, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
