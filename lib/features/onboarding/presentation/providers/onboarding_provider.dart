import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/preferences_helper.dart';

class OnboardingState {
  final int currentPage;
  final bool micPermissionGranted;
  final bool micTested;
  final String? skillLevel;

  const OnboardingState({
    this.currentPage = 0,
    this.micPermissionGranted = false,
    this.micTested = false,
    this.skillLevel,
  });

  OnboardingState copyWith({
    int? currentPage,
    bool? micPermissionGranted,
    bool? micTested,
    String? skillLevel,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      micPermissionGranted: micPermissionGranted ?? this.micPermissionGranted,
      micTested: micTested ?? this.micTested,
      skillLevel: skillLevel ?? this.skillLevel,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void nextPage() {
    state = state.copyWith(currentPage: state.currentPage + 1);
  }

  void setMicPermissionGranted(bool granted) {
    state = state.copyWith(micPermissionGranted: granted);
  }

  void setMicTested(bool tested) {
    state = state.copyWith(micTested: tested);
  }

  void setSkillLevel(String level) {
    state = state.copyWith(skillLevel: level);
  }

  Future<void> completeOnboarding() async {
    if (state.skillLevel != null) {
      await PreferencesHelper.setSkillLevel(state.skillLevel!);
    }
    await PreferencesHelper.setOnboardingCompleted();
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(),
);
