import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/chords_data.dart';

class ChordExplorerState {
  final ChordData selectedChord;
  final int? highlightedFinger;
  final int stepIndex;
  final bool stepMode;

  const ChordExplorerState({
    required this.selectedChord,
    this.highlightedFinger,
    this.stepIndex = 0,
    this.stepMode = false,
  });

  ChordExplorerState copyWith({
    ChordData? selectedChord,
    int? Function()? highlightedFinger,
    int? stepIndex,
    bool? stepMode,
  }) {
    return ChordExplorerState(
      selectedChord: selectedChord ?? this.selectedChord,
      highlightedFinger: highlightedFinger != null
          ? highlightedFinger()
          : this.highlightedFinger,
      stepIndex: stepIndex ?? this.stepIndex,
      stepMode: stepMode ?? this.stepMode,
    );
  }

  /// Unique fingers used in the selected chord (ordered by appearance).
  List<int> get uniqueFingers {
    final seen = <int>{};
    final result = <int>[];
    for (final f in selectedChord.fingers) {
      if (f > 0 && seen.add(f)) result.add(f);
    }
    return result;
  }
}

class ChordExplorerNotifier extends StateNotifier<ChordExplorerState> {
  ChordExplorerNotifier()
      : super(ChordExplorerState(selectedChord: ChordsData.allChords[0]));

  void selectChord(ChordData chord) {
    state = ChordExplorerState(selectedChord: chord);
  }

  void highlightFinger(int? finger) {
    state = state.copyWith(highlightedFinger: () => finger);
  }

  void toggleStepMode() {
    if (state.stepMode) {
      state = state.copyWith(stepMode: false, stepIndex: 0);
    } else {
      state = state.copyWith(stepMode: true, stepIndex: 0);
    }
  }

  void nextStep() {
    final max = state.uniqueFingers.length;
    if (state.stepIndex < max) {
      state = state.copyWith(stepIndex: state.stepIndex + 1);
    } else {
      state = state.copyWith(stepMode: false, stepIndex: 0);
    }
  }

  void resetSteps() {
    state = state.copyWith(stepIndex: 0, stepMode: true);
  }
}

final chordExplorerProvider =
    StateNotifierProvider.autoDispose<ChordExplorerNotifier, ChordExplorerState>(
  (ref) => ChordExplorerNotifier(),
);
