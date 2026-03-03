import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../widgets/arcade_button.dart';
import '../providers/tutorial_provider.dart';
import 'tutorial_welcome_page.dart';
import 'tutorial_fingers_page.dart';
import 'tutorial_strings_page.dart';
import 'tutorial_fretboard_page.dart';
import 'tutorial_chord_page.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  late PageController _pageController;

  final _pages = const [
    TutorialWelcomePage(),
    TutorialFingersPage(),
    TutorialStringsPage(),
    TutorialFretboardPage(),
    TutorialChordPage(),
  ];

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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    ref.read(tutorialProvider.notifier).goToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorialProvider);

    return Scaffold(
      backgroundColor: ArcadeColors.background,
      appBar: AppBar(
        backgroundColor: ArcadeColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ArcadeColors.neonCyan),
          onPressed: () {
            if (state.currentPage > 0) {
              _goToPage(state.currentPage - 1);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'TUTORIAL ${state.currentPage + 1}/${state.totalPages}',
          style: const TextStyle(
            fontSize: 14,
            color: ArcadeColors.neonPink,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'SALIR',
              style: TextStyle(
                color: ArcadeColors.textMuted,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  ref.read(tutorialProvider.notifier).goToPage(page);
                },
                children: _pages,
              ),
            ),

            // Dots + navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(state.totalPages, (i) {
                      final isActive = i == state.currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? ArcadeColors.neonPink
                              : ArcadeColors.textMuted,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isActive
                              ? NeonEffects.glow(ArcadeColors.neonPink, intensity: 0.3)
                              : [],
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Navigation buttons
                  Row(
                    children: [
                      if (state.currentPage > 0)
                        Expanded(
                          child: ArcadeButton.outline(
                            text: 'ANTERIOR',
                            onPressed: () => _goToPage(state.currentPage - 1),
                            height: 44,
                          ),
                        )
                      else
                        const Spacer(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: state.currentPage < state.totalPages - 1
                            ? ArcadeButton(
                                text: 'SIGUIENTE',
                                icon: Icons.arrow_forward,
                                onPressed: () => _goToPage(state.currentPage + 1),
                                height: 44,
                              )
                            : ArcadeButton(
                                text: 'LISTO!',
                                icon: Icons.check,
                                onPressed: () => Navigator.of(context).pop(),
                                height: 44,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
