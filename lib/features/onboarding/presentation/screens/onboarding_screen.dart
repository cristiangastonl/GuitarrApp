import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../home/presentation/screens/arcade_home_screen.dart';
import '../providers/onboarding_provider.dart';
import 'welcome_page.dart';
import 'mic_permission_page.dart';
import 'mic_test_page.dart';
import 'skill_level_page.dart';
import 'ready_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;

  // On web, skip mic permission page (pages: 0,1,2,3 instead of 0,1,2,3,4)
  int get _totalPages => kIsWeb ? 4 : 5;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    ref.read(onboardingProvider.notifier).goToPage(page);
  }

  void _nextPage() {
    final current = _pageController.page?.round() ?? 0;
    if (current < _totalPages - 1) {
      _goToPage(current + 1);
    }
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ArcadeHomeScreen()),
      );
    }
  }

  List<Widget> _buildPages() {
    final pages = <Widget>[
      WelcomePage(onNext: _nextPage),
    ];

    if (!kIsWeb) {
      pages.add(
        MicPermissionPage(
          onNext: _nextPage,
          onPermissionResult: (granted) {
            ref
                .read(onboardingProvider.notifier)
                .setMicPermissionGranted(granted);
          },
        ),
      );
    }

    pages.addAll([
      MicTestPage(
        onNext: _nextPage,
        onTestResult: (tested) {
          ref.read(onboardingProvider.notifier).setMicTested(tested);
        },
      ),
      SkillLevelPage(
        onNext: _nextPage,
        onSkillSelected: (level) {
          ref.read(onboardingProvider.notifier).setSkillLevel(level);
        },
      ),
    ]);

    // Ready page needs to read current state
    pages.add(
      Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(onboardingProvider);
          return ReadyPage(
            skillLevel: state.skillLevel,
            micTested: state.micTested,
            onStart: _completeOnboarding,
          );
        },
      ),
    );

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: ArcadeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  ref.read(onboardingProvider.notifier).goToPage(page);
                },
                children: _buildPages(),
              ),
            ),

            // Dot indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => _DotIndicator(
                    active: index == state.currentPage,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final bool active;

  const _DotIndicator({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: active ? ArcadeColors.neonPink : ArcadeColors.textMuted,
        boxShadow: active
            ? NeonEffects.glow(ArcadeColors.neonPink, intensity: 0.5)
            : null,
      ),
    );
  }
}
