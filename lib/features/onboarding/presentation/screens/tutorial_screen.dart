import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;
  bool isCompleting = false;

  final List<Map<String, dynamic>> tutorialSteps = [
    {
      'title': '🎸 Bienvenido a tu Estudio',
      'description': 'GuitarrApp es tu coach personal de guitarra que te ayuda a mejorar tocando, no estudiando teoría.',
      'icon': Icons.music_note,
      'features': [
        '🎯 Práctica dirigida con objetivos claros',
        '📊 Feedback inteligente en tiempo real',
        '📈 Seguimiento de tu progreso',
      ],
    },
    {
      'title': '🎙️ Cómo Funciona la Práctica',
      'description': 'Practica con riffs reales mientras recibiendo feedback sobre tu timing y técnica.',
      'icon': Icons.record_voice_over,
      'features': [
        '🎵 Selecciona un riff o ejercicio',
        '⏱️ Ajusta el BPM a tu nivel',
        '🎙️ Graba tu interpretación',
        '📊 Recibe feedback detallado',
      ],
    },
    {
      'title': '🎛️ Metrónomo Inteligente',
      'description': 'Nuestro metrónomo se sincroniza perfectamente con tu práctica para ayudarte a mantener el tiempo.',
      'icon': Icons.timer,
      'features': [
        '⚡ Sincronización automática',
        '🔊 Volumen ajustable',
        '📊 Análisis de timing',
        '✨ Visual y auditivo',
      ],
    },
    {
      'title': '🧠 Feedback Inteligente',
      'description': 'Análisis avanzado de tu performance con tips personalizados para mejorar.',
      'icon': Icons.analytics,
      'features': [
        '📊 Score detallado (timing, consistencia)',
        '💡 Tips específicos para mejorar',
        '📈 Tracking de progreso histórico',
        '🎯 Recomendaciones personalizadas',
      ],
    },
    {
      'title': '🚀 ¡Empezemos a Tocar!',
      'description': 'Todo está listo. Es hora de conectar tu guitarra y empezar tu primera sesión de práctica.',
      'icon': Icons.play_circle,
      'features': [
        '🎸 Conecta tu guitarra o usa micrófono',
        '🎵 Elige tu primer riff',
        '📱 Sigue las instrucciones en pantalla',
        '🎉 ¡Disfruta practicando!',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      ref.read(onboardingProvider.notifier).previousStep();
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    'Tutorial Interactivo',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (currentPage < tutorialSteps.length - 1)
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          tutorialSteps.length - 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Saltar'),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Page indicator
            _buildPageIndicator(),
            
            // Tutorial content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemCount: tutorialSteps.length,
                itemBuilder: (context, index) {
                  return _buildTutorialPage(tutorialSteps[index]);
                },
              ),
            ),

            // Navigation
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(tutorialSteps.length, (index) {
          final isActive = index == currentPage;
          final isCompleted = index < currentPage;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isCompleted || isActive
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColor.withOpacity(0.2),
              boxShadow: isActive ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: isCompleted ? Center(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 6,
                    ),
                  );
                },
              ),
            ) : null,
          );
        }),
      ),
    );
  }

  Widget _buildTutorialPage(Map<String, dynamic> step) {
    final isLastPage = currentPage == tutorialSteps.length - 1;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
                  const SizedBox(height: 32),
                  
                  // Icon
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.5 + (0.5 * value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor.withOpacity(0.1 * value),
                            boxShadow: value > 0.5 ? [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.2),
                                blurRadius: 20 * value,
                                offset: const Offset(0, 8),
                              ),
                            ] : null,
                          ),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, iconValue, child) {
                              return Transform.rotate(
                                angle: iconValue * 0.5,
                                child: Icon(
                                  step['icon'] as IconData,
                                  size: 50,
                                  color: Theme.of(context).primaryColor.withOpacity(iconValue),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    step['title'] as String,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    step['description'] as String,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  
                  // Features
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).cardColor,
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: (step['features'] as List<String>).map((feature) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  if (isLastPage) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '¡Tip! Empieza con un BPM bajo y ve aumentando gradualmente conforme mejores.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                ],
              ),
    );
  }

  Widget _buildNavigationButtons() {
    final isFirstPage = currentPage == 0;
    final isLastPage = currentPage == tutorialSteps.length - 1;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (!isFirstPage)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Anterior'),
              ),
            ),
          
          if (!isFirstPage) const SizedBox(width: 16),
          
          Expanded(
            child: ElevatedButton(
              onPressed: isCompleting ? null : () async {
                if (isLastPage) {
                  setState(() {
                    isCompleting = true;
                  });
                  
                  try {
                    await ref.read(onboardingProvider.notifier).completeOnboarding();
                    
                    if (mounted) {
                      // Navigate to main app
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        isCompleting = false;
                      });
                    }
                  }
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isCompleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isLastPage ? '¡Empezar a Tocar!' : 'Siguiente',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}