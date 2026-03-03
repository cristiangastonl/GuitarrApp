import 'package:flutter_riverpod/flutter_riverpod.dart';

class TutorialState {
  final int currentPage;
  final int totalPages;

  const TutorialState({
    this.currentPage = 0,
    this.totalPages = 5,
  });

  TutorialState copyWith({int? currentPage}) {
    return TutorialState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages,
    );
  }
}

class TutorialNotifier extends StateNotifier<TutorialState> {
  TutorialNotifier() : super(const TutorialState());

  void goToPage(int page) {
    if (page >= 0 && page < state.totalPages) {
      state = state.copyWith(currentPage: page);
    }
  }

  void nextPage() {
    if (state.currentPage < state.totalPages - 1) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void reset() {
    state = const TutorialState();
  }
}

final tutorialProvider =
    StateNotifierProvider.autoDispose<TutorialNotifier, TutorialState>(
  (ref) => TutorialNotifier(),
);
