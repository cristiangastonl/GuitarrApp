import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'goal_selection_screen.dart';
import 'equipment_setup_screen.dart';
import 'skill_assessment_screen.dart';
import 'tutorial_screen.dart';
import '../providers/onboarding_provider.dart';

class OnboardingFlow extends ConsumerWidget {
  const OnboardingFlow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);
    
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation during onboarding
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(context, onboardingState.currentStep),
              
              // Current screen
              Expanded(
                child: _buildCurrentScreen(onboardingState.currentStep),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, int currentStep) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isCompleted || isCurrent
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColor.withOpacity(0.2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentScreen(int currentStep) {
    switch (currentStep) {
      case 0:
        return const GoalSelectionScreen();
      case 1:
        return const EquipmentSetupScreen();
      case 2:
        return const SkillAssessmentScreen();
      case 3:
        return const TutorialScreen();
      default:
        return const GoalSelectionScreen();
    }
  }
}