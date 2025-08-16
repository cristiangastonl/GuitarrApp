import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_setup.dart';
import '../../../../core/services/onboarding_service.dart';

class OnboardingState {
  final int currentStep;
  final Map<String, dynamic> userData;
  final bool isLoading;
  final String? error;

  const OnboardingState({
    this.currentStep = 0,
    this.userData = const {},
    this.isLoading = false,
    this.error,
  });

  OnboardingState copyWith({
    int? currentStep,
    Map<String, dynamic>? userData,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      userData: userData ?? this.userData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final OnboardingService _onboardingService;
  
  OnboardingNotifier(this._onboardingService) : super(const OnboardingState());

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void updateUserData(String key, dynamic value) {
    final updatedData = Map<String, dynamic>.from(state.userData);
    updatedData[key] = value;
    state = state.copyWith(userData: updatedData);
  }

  void setGoals(List<String> goals) {
    updateUserData('goals', goals);
  }

  void setEquipment(Map<String, dynamic> equipment) {
    updateUserData('equipment', equipment);
  }

  void setSkillLevel(String skillLevel, Map<String, dynamic> assessment) {
    updateUserData('skillLevel', skillLevel);
    updateUserData('assessment', assessment);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Save user setup from onboarding data
      final userSetupId = await _onboardingService.saveUserSetupFromOnboarding(state.userData);
      
      // Mark onboarding as complete
      await _onboardingService.completeOnboarding(userSetupId);
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error completing onboarding: $e',
      );
    }
  }

  void reset() {
    state = const OnboardingState();
  }
}

// Service providers
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) {
    final onboardingService = ref.read(onboardingServiceProvider);
    return OnboardingNotifier(onboardingService);
  },
);

// Check onboarding status provider
final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  final onboardingService = ref.read(onboardingServiceProvider);
  return await onboardingService.isOnboardingComplete();
});