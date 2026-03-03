import 'package:flutter/material.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../widgets/hand_diagram.dart';
import '../../../../widgets/neon_text.dart';

class TutorialFingersPage extends StatefulWidget {
  const TutorialFingersPage({super.key});

  @override
  State<TutorialFingersPage> createState() => _TutorialFingersPageState();
}

class _TutorialFingersPageState extends State<TutorialFingersPage> {
  Set<int> _highlighted = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          const NeonText(
            text: 'TUS DEDOS',
            fontSize: 22,
            color: ArcadeColors.neonCyan,
          ),
          const SizedBox(height: 8),
          Text(
            'Cada dedo tiene un número y color',
            style: TextStyle(
              fontSize: 14,
              color: ArcadeColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // Hand diagram
          Expanded(
            child: Center(
              child: SizedBox(
                width: 220,
                height: 280,
                child: HandDiagram(
                  highlightedFingers: _highlighted,
                  showLabels: true,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Finger buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [1, 2, 3, 4].map((finger) {
              final isActive = _highlighted.contains(finger);
              final color = FingerColors.fromFinger(finger);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isActive) {
                      _highlighted = {};
                    } else {
                      _highlighted = {finger};
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isActive
                        ? color.withValues(alpha: 0.2)
                        : ArcadeColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? color : ArcadeColors.textMuted,
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: isActive ? NeonEffects.glow(color, intensity: 0.3) : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$finger',
                            style: const TextStyle(
                              color: ArcadeColors.background,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FingerColors.nameFromFinger(finger),
                        style: TextStyle(
                          fontSize: 9,
                          color: isActive ? color : ArcadeColors.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          Text(
            'Toca un botón para resaltar el dedo',
            style: TextStyle(fontSize: 12, color: ArcadeColors.textMuted),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
