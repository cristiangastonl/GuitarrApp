import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_setup.dart';
import '../storage/database_helper.dart';

class OnboardingService {
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _userSetupIdKey = 'user_setup_id';

  /// Check if user has completed onboarding
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding(String userSetupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
    await prefs.setString(_userSetupIdKey, userSetupId);
  }

  /// Get current user setup
  Future<UserSetup?> getCurrentUserSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final userSetupId = prefs.getString(_userSetupIdKey);
    
    if (userSetupId == null) return null;
    
    try {
      return await DatabaseHelper.getUserSetupById(userSetupId);
    } catch (e) {
      // If user setup not found, reset onboarding
      await resetOnboarding();
      return null;
    }
  }

  /// Save user setup from onboarding data
  Future<String> saveUserSetupFromOnboarding(Map<String, dynamic> onboardingData) async {
    final userSetup = UserSetup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      playerName: onboardingData['playerName'] ?? 'Guitarist',
      skillLevel: onboardingData['skillLevel'] ?? 'beginner',
      preferredGenres: List<String>.from(onboardingData['genres'] ?? ['rock']),
      practiceTimeMinutes: onboardingData['practiceTime'] ?? 30,
      metronomeEnabled: true,
      metronomeVolume: 0.7,
      createdAt: DateTime.now(),
      lastPracticeDate: DateTime.now(),
    );

    await DatabaseHelper.insertUserSetup(userSetup);
    return userSetup.id;
  }

  /// Reset onboarding (for testing or user reset)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompleteKey);
    await prefs.remove(_userSetupIdKey);
  }

  /// Update user's last practice date
  Future<void> updateLastPracticeDate(String userSetupId) async {
    try {
      final userSetup = await DatabaseHelper.getUserSetupById(userSetupId);
      if (userSetup != null) {
        final updatedSetup = userSetup.copyWith(
          lastPracticeDate: DateTime.now(),
        );
        await DatabaseHelper.updateUserSetup(updatedSetup);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Generate recommended practice plan based on user setup
  Map<String, dynamic> generatePracticePlan(UserSetup userSetup) {
    final plans = {
      'beginner': {
        'dailyMinutes': 15,
        'recommendedBPM': 60,
        'focusAreas': ['Basic timing', 'Simple riffs', 'Chord changes'],
        'suggestedRiffs': ['Seven Nation Army', 'Smoke on the Water'],
      },
      'novice': {
        'dailyMinutes': 25,
        'recommendedBPM': 80,
        'focusAreas': ['Rhythm consistency', 'Technique refinement', 'Speed building'],
        'suggestedRiffs': ['Enter Sandman', 'Come As You Are', 'Iron Man'],
      },
      'intermediate': {
        'dailyMinutes': 35,
        'recommendedBPM': 100,
        'focusAreas': ['Advanced techniques', 'Complex rhythms', 'Solo preparation'],
        'suggestedRiffs': ['Master of Puppets', 'Back in Black', 'Paranoid'],
      },
      'advanced': {
        'dailyMinutes': 45,
        'recommendedBPM': 120,
        'focusAreas': ['Precision improvement', 'Advanced solos', 'Creative variations'],
        'suggestedRiffs': ['Sweet Child O\' Mine', 'Thunderstruck', 'Master of Puppets'],
      },
    };

    return plans[userSetup.skillLevel] ?? plans['beginner']!;
  }

  /// Get onboarding statistics for analytics
  Future<Map<String, dynamic>> getOnboardingStats() async {
    final prefs = await SharedPreferences.getInstance();
    final isComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
    
    if (!isComplete) {
      return {
        'completed': false,
        'userSetup': null,
        'daysSinceCompletion': 0,
      };
    }

    final userSetup = await getCurrentUserSetup();
    final daysSinceCompletion = userSetup != null 
        ? DateTime.now().difference(userSetup.createdAt).inDays
        : 0;

    return {
      'completed': true,
      'userSetup': userSetup?.toJson(),
      'daysSinceCompletion': daysSinceCompletion,
    };
  }
}