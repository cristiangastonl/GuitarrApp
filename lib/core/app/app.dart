import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/arcade_theme.dart';
import '../storage/preferences_helper.dart';
import '../../features/home/presentation/screens/arcade_home_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';

class GuitarrApp extends ConsumerWidget {
  const GuitarrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'GuitarrApp',
      theme: ArcadeTheme.theme,
      home: FutureBuilder<bool>(
        future: PreferencesHelper.isOnboardingCompleted(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              backgroundColor: ArcadeColors.background,
              body: Center(
                child: CircularProgressIndicator(
                  color: ArcadeColors.neonPink,
                ),
              ),
            );
          }

          if (snapshot.data == true) {
            return const ArcadeHomeScreen();
          }

          return const OnboardingScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
