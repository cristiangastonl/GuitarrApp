import 'package:flutter/material.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../core/data/chords_data.dart';
import '../../../../widgets/neon_text.dart';
import '../../../../widgets/hand_diagram.dart';
import '../../../../widgets/animated_chord_diagram.dart';
import '../../../../widgets/arcade_button.dart';

class TutorialChordPage extends StatefulWidget {
  const TutorialChordPage({super.key});

  @override
  State<TutorialChordPage> createState() => _TutorialChordPageState();
}

class _TutorialChordPageState extends State<TutorialChordPage> {
  final ChordData _chord = ChordsData.allChords[0]; // Em
  int _stepIndex = 0;
  bool _stepMode = true;

  /// Unique fingers in Em: [2, 3]
  List<int> get _uniqueFingers {
    final seen = <int>{};
    final result = <int>[];
    for (final f in _chord.fingers) {
      if (f > 0 && seen.add(f)) result.add(f);
    }
    return result;
  }

  int? get _currentHighlightFinger {
    if (!_stepMode || _stepIndex <= 0) return null;
    if (_stepIndex <= _uniqueFingers.length) {
      return _uniqueFingers[_stepIndex - 1];
    }
    return null;
  }

  Set<int> get _handHighlight {
    if (!_stepMode || _stepIndex <= 0) return {};
    if (_stepIndex <= _uniqueFingers.length) {
      return {_uniqueFingers[_stepIndex - 1]};
    }
    return {};
  }

  void _nextStep() {
    setState(() {
      if (_stepIndex < _uniqueFingers.length) {
        _stepIndex++;
      } else {
        // Show all
        _stepMode = false;
        _stepIndex = 0;
      }
    });
  }

  void _resetSteps() {
    setState(() {
      _stepIndex = 0;
      _stepMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),

          const NeonText(
            text: 'TU PRIMER ACORDE',
            fontSize: 22,
            color: ArcadeColors.neonYellow,
          ),
          const SizedBox(height: 4),
          Text(
            '${_chord.name} — ${_chord.displayName}',
            style: TextStyle(fontSize: 14, color: ArcadeColors.textSecondary),
          ),

          const SizedBox(height: 16),

          // Hand + Chord side by side
          Expanded(
            child: Row(
              children: [
                // Hand diagram
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Mano',
                        style: TextStyle(
                          fontSize: 11,
                          color: ArcadeColors.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: HandDiagram(
                          highlightedFingers: _handHighlight,
                          showLabels: false,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Chord diagram
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Diagrama',
                        style: TextStyle(
                          fontSize: 11,
                          color: ArcadeColors.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth.clamp(120.0, 220.0);
                            final h = constraints.maxHeight.clamp(150.0, 280.0);
                            return AnimatedChordDiagram(
                              chord: _chord,
                              width: w,
                              height: h,
                              highlightedFinger: _currentHighlightFinger,
                              stepIndex: _stepMode ? _stepIndex : 0,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Step mode controls
          if (_stepMode) ...[
            Text(
              _stepIndex == 0
                  ? 'Modo dedo a dedo — toca SIGUIENTE DEDO'
                  : 'Dedo ${_uniqueFingers[_stepIndex - 1]} colocado (${_stepIndex}/${_uniqueFingers.length})',
              style: TextStyle(
                fontSize: 13,
                color: ArcadeColors.neonCyan,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ArcadeButton(
              text: _stepIndex < _uniqueFingers.length
                  ? 'SIGUIENTE DEDO'
                  : 'VER COMPLETO',
              icon: Icons.arrow_forward,
              onPressed: _nextStep,
              height: 44,
            ),
          ] else ...[
            Text(
              '¡Acorde completo! Así se ve ${_chord.name}',
              style: TextStyle(
                fontSize: 13,
                color: ArcadeColors.neonGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ArcadeButton.outline(
              text: 'REPETIR PASOS',
              icon: Icons.replay,
              onPressed: _resetSteps,
              height: 44,
            ),
          ],

          const SizedBox(height: 12),

          // Tip
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ArcadeColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ArcadeColors.neonYellow.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, size: 14, color: ArcadeColors.neonYellow),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Em es el acorde más fácil: solo usa 2 dedos.',
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
