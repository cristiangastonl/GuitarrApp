import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../core/data/chords_data.dart';
import '../../../../widgets/neon_text.dart';
import '../../../../widgets/arcade_button.dart';
import '../../../../widgets/animated_chord_diagram.dart';
import '../../../../widgets/hand_diagram.dart';
import '../../../../widgets/reference_panel.dart';
import '../providers/chord_explorer_provider.dart';

class ChordExplorerScreen extends ConsumerWidget {
  const ChordExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chordExplorerProvider);
    final notifier = ref.read(chordExplorerProvider.notifier);

    return Scaffold(
      backgroundColor: ArcadeColors.background,
      appBar: AppBar(
        backgroundColor: ArcadeColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ArcadeColors.neonCyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const NeonText(
          text: 'EXPLORADOR',
          fontSize: 18,
          color: ArcadeColors.neonPink,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chord selector
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ChordsData.allChords.length,
                itemBuilder: (context, i) {
                  final chord = ChordsData.allChords[i];
                  final isSelected = chord.name == state.selectedChord.name;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => notifier.selectChord(chord),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ArcadeColors.neonPink.withValues(alpha: 0.2)
                              : ArcadeColors.backgroundLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? ArcadeColors.neonPink
                                : ArcadeColors.textMuted,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? NeonEffects.glow(ArcadeColors.neonPink, intensity: 0.3)
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            chord.name,
                            style: TextStyle(
                              color: isSelected
                                  ? ArcadeColors.neonPink
                                  : ArcadeColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Chord info
            Text(
              state.selectedChord.displayName,
              style: const TextStyle(
                color: ArcadeColors.textSecondary,
                fontSize: 13,
              ),
            ),
            Text(
              state.selectedChord.description,
              style: const TextStyle(
                color: ArcadeColors.textMuted,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 12),

            // Hand + Chord diagrams
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final diagramWidth = (constraints.maxWidth - 16) / 2;
                    final diagramHeight = constraints.maxHeight;
                    return Row(
                      children: [
                        // Hand
                        Expanded(
                          child: HandDiagram(
                            highlightedFingers: state.highlightedFinger != null
                                ? {state.highlightedFinger!}
                                : {},
                            showLabels: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Chord diagram - constrained to available space
                        SizedBox(
                          width: diagramWidth.clamp(140, 220),
                          height: diagramHeight.clamp(180, 280),
                          child: AnimatedChordDiagram(
                            chord: state.selectedChord,
                            width: diagramWidth.clamp(140, 220),
                            height: diagramHeight.clamp(180, 280),
                            highlightedFinger: state.highlightedFinger,
                            stepIndex: state.stepMode ? state.stepIndex : 0,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Finger highlight buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FingerChip(
                    label: 'TODOS',
                    color: ArcadeColors.textSecondary,
                    isActive: state.highlightedFinger == null,
                    onTap: () => notifier.highlightFinger(null),
                  ),
                  ...state.uniqueFingers.map((f) => _FingerChip(
                        label: '$f',
                        color: FingerColors.fromFinger(f),
                        isActive: state.highlightedFinger == f,
                        onTap: () => notifier.highlightFinger(
                          state.highlightedFinger == f ? null : f,
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Step mode controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ArcadeButton.outline(
                      text: state.stepMode ? 'MODO NORMAL' : 'PASO A PASO',
                      icon: state.stepMode ? Icons.visibility : Icons.slow_motion_video,
                      onPressed: () => notifier.toggleStepMode(),
                      height: 40,
                    ),
                  ),
                  if (state.stepMode) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ArcadeButton(
                        text: state.stepIndex < state.uniqueFingers.length
                            ? 'SIGUIENTE'
                            : 'COMPLETO',
                        icon: Icons.arrow_forward,
                        onPressed: () => notifier.nextStep(),
                        height: 40,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Reference panel
            const ReferencePanel(),
          ],
        ),
      ),
    );
  }
}

class _FingerChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _FingerChip({
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.2) : ArcadeColors.backgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? color : ArcadeColors.textMuted,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? color : ArcadeColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
