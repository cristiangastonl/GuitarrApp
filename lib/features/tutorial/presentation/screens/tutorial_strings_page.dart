import 'package:flutter/material.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../widgets/neon_text.dart';

class TutorialStringsPage extends StatefulWidget {
  const TutorialStringsPage({super.key});

  @override
  State<TutorialStringsPage> createState() => _TutorialStringsPageState();
}

class _TutorialStringsPageState extends State<TutorialStringsPage> {
  int? _selectedString;

  static const _stringData = [
    (number: 6, name: 'E', fullName: 'Mi grave', thickness: 5.0),
    (number: 5, name: 'A', fullName: 'La', thickness: 4.0),
    (number: 4, name: 'D', fullName: 'Re', thickness: 3.2),
    (number: 3, name: 'G', fullName: 'Sol', thickness: 2.4),
    (number: 2, name: 'B', fullName: 'Si', thickness: 1.6),
    (number: 1, name: 'e', fullName: 'Mi agudo', thickness: 1.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          const NeonText(
            text: 'LAS CUERDAS',
            fontSize: 22,
            color: ArcadeColors.neonPink,
          ),
          const SizedBox(height: 8),
          Text(
            'La guitarra tiene 6 cuerdas',
            style: TextStyle(fontSize: 14, color: ArcadeColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'De gruesa (grave) a fina (agudo)',
            style: TextStyle(fontSize: 12, color: ArcadeColors.textMuted),
          ),

          const SizedBox(height: 32),

          // Strings
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _stringData.map((s) {
                final isSelected = _selectedString == s.number;
                final color = isSelected ? ArcadeColors.neonCyan : ArcadeColors.textSecondary;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedString = isSelected ? null : s.number;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ArcadeColors.neonCyan.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // String number
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${s.number}ª',
                            style: TextStyle(
                              color: ArcadeColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Note name
                        SizedBox(
                          width: 28,
                          child: Text(
                            s.name,
                            style: TextStyle(
                              color: color,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Visual string
                        Expanded(
                          child: Container(
                            height: s.thickness,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(s.thickness / 2),
                              boxShadow: isSelected
                                  ? NeonEffects.glow(ArcadeColors.neonCyan, intensity: 0.3)
                                  : [],
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Full name
                        SizedBox(
                          width: 70,
                          child: Text(
                            s.fullName,
                            style: TextStyle(
                              color: isSelected ? ArcadeColors.neonCyan : ArcadeColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ArcadeColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ArcadeColors.neonPink.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, size: 16, color: ArcadeColors.neonYellow),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Se cuentan de abajo (1ª) a arriba (6ª). Toca una para resaltarla.',
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
