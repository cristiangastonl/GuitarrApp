import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';

class SkillAssessmentScreen extends ConsumerStatefulWidget {
  const SkillAssessmentScreen({super.key});

  @override
  ConsumerState<SkillAssessmentScreen> createState() => _SkillAssessmentScreenState();
}

class _SkillAssessmentScreenState extends ConsumerState<SkillAssessmentScreen> {
  int currentQuestionIndex = 0;
  Map<String, dynamic> answers = {};
  String finalSkillLevel = '';

  final List<Map<String, dynamic>> assessmentQuestions = [
    {
      'id': 'experience',
      'question': '¿Cuánto tiempo llevas tocando guitarra?',
      'type': 'single_choice',
      'options': [
        {'value': 'beginner', 'text': 'Menos de 1 año', 'points': 1},
        {'value': 'novice', 'text': '1-2 años', 'points': 2},
        {'value': 'intermediate', 'text': '3-5 años', 'points': 3},
        {'value': 'advanced', 'text': 'Más de 5 años', 'points': 4},
      ],
    },
    {
      'id': 'chords',
      'question': '¿Qué acordes dominas?',
      'type': 'multiple_choice',
      'options': [
        {'value': 'basic_open', 'text': 'Acordes abiertos básicos (G, C, D, Em)', 'points': 1},
        {'value': 'barre', 'text': 'Acordes con cejilla (F, Bm)', 'points': 2},
        {'value': 'seventh', 'text': 'Acordes de séptima (G7, C7)', 'points': 2},
        {'value': 'extended', 'text': 'Acordes extendidos (add9, sus4)', 'points': 3},
        {'value': 'jazz', 'text': 'Acordes de jazz complejos', 'points': 4},
      ],
    },
    {
      'id': 'techniques',
      'question': '¿Qué técnicas puedes tocar?',
      'type': 'multiple_choice',
      'options': [
        {'value': 'strumming', 'text': 'Rasgueo básico', 'points': 1},
        {'value': 'fingerpicking', 'text': 'Fingerpicking', 'points': 2},
        {'value': 'palm_muting', 'text': 'Palm muting', 'points': 2},
        {'value': 'alternate_picking', 'text': 'Alternate picking', 'points': 3},
        {'value': 'sweep_picking', 'text': 'Sweep picking', 'points': 4},
        {'value': 'tapping', 'text': 'Tapping', 'points': 4},
      ],
    },
    {
      'id': 'rhythm',
      'question': '¿Cómo es tu sentido del ritmo?',
      'type': 'single_choice',
      'options': [
        {'value': 'struggle', 'text': 'Me cuesta mantener el tiempo', 'points': 1},
        {'value': 'basic', 'text': 'Puedo tocar ritmos simples', 'points': 2},
        {'value': 'good', 'text': 'Mantengo bien el tiempo', 'points': 3},
        {'value': 'excellent', 'text': 'Tengo muy buen timing natural', 'points': 4},
      ],
    },
    {
      'id': 'reading',
      'question': '¿Qué puedes leer?',
      'type': 'multiple_choice',
      'options': [
        {'value': 'none', 'text': 'Solo toco de oído', 'points': 1},
        {'value': 'tabs', 'text': 'Tablaturas', 'points': 2},
        {'value': 'chord_charts', 'text': 'Diagramas de acordes', 'points': 2},
        {'value': 'sheet_music', 'text': 'Partitura tradicional', 'points': 4},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (finalSkillLevel.isNotEmpty) {
      return _buildResultsScreen();
    }

    final currentQuestion = assessmentQuestions[currentQuestionIndex];
    final isLastQuestion = currentQuestionIndex == assessmentQuestions.length - 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (currentQuestionIndex > 0) {
                    setState(() {
                      currentQuestionIndex--;
                    });
                  } else {
                    ref.read(onboardingProvider.notifier).previousStep();
                  }
                },
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Evaluación de Habilidades',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pregunta ${currentQuestionIndex + 1} de ${assessmentQuestions.length}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Progress indicator
          LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / assessmentQuestions.length,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 32),

          // Question
          Text(
            currentQuestion['question'],
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          if (currentQuestion['type'] == 'multiple_choice')
            Text(
              'Selecciona todas las que apliquen',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          const SizedBox(height: 24),

          // Options
          Expanded(
            child: ListView.builder(
              itemCount: currentQuestion['options'].length,
              itemBuilder: (context, index) {
                final option = currentQuestion['options'][index];
                final questionId = currentQuestion['id'];
                final isMultiple = currentQuestion['type'] == 'multiple_choice';
                
                bool isSelected;
                if (isMultiple) {
                  final selectedOptions = answers[questionId] as List<String>? ?? [];
                  isSelected = selectedOptions.contains(option['value']);
                } else {
                  isSelected = answers[questionId] == option['value'];
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isMultiple) {
                          final selectedOptions = answers[questionId] as List<String>? ?? [];
                          if (isSelected) {
                            selectedOptions.remove(option['value']);
                          } else {
                            selectedOptions.add(option['value']);
                          }
                          answers[questionId] = selectedOptions;
                        } else {
                          answers[questionId] = option['value'];
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                        color: isSelected 
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Theme.of(context).cardColor,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isMultiple 
                                ? (isSelected ? Icons.check_box : Icons.check_box_outline_blank)
                                : (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                            color: isSelected 
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).iconTheme.color,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              option['text'],
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Navigation
          const SizedBox(height: 24),
          Row(
            children: [
              if (currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        currentQuestionIndex--;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Atrás'),
                  ),
                ),
              
              if (currentQuestionIndex > 0) const SizedBox(width: 16),
              
              Expanded(
                child: ElevatedButton(
                  onPressed: _canContinue()
                      ? () {
                          if (isLastQuestion) {
                            _calculateSkillLevel();
                          } else {
                            setState(() {
                              currentQuestionIndex++;
                            });
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isLastQuestion ? 'Finalizar' : 'Siguiente',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    final skillInfo = _getSkillLevelInfo(finalSkillLevel);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          
          // Result icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 3,
              ),
            ),
            child: Icon(
              skillInfo['icon'],
              size: 60,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            '¡Evaluación Completada!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Tu nivel: ${skillInfo['title']}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          Text(
            skillInfo['description'],
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).cardColor,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(height: 12),
                Text(
                  'Recomendación',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  skillInfo['recommendation'],
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(onboardingProvider.notifier).nextStep();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continuar al Tutorial',
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

  bool _canContinue() {
    final currentQuestion = assessmentQuestions[currentQuestionIndex];
    final questionId = currentQuestion['id'];
    
    if (currentQuestion['type'] == 'multiple_choice') {
      final selectedOptions = answers[questionId] as List<String>? ?? [];
      return selectedOptions.isNotEmpty;
    } else {
      return answers[questionId] != null;
    }
  }

  void _calculateSkillLevel() {
    int totalPoints = 0;
    int maxPoints = 0;

    for (final question in assessmentQuestions) {
      final questionId = question['id'];
      final questionMaxPoints = (question['options'] as List)
          .map((option) => option['points'] as int)
          .reduce((a, b) => a > b ? a : b);
      
      if (question['type'] == 'multiple_choice') {
        final selectedOptions = answers[questionId] as List<String>? ?? [];
        for (final selectedValue in selectedOptions) {
          final option = (question['options'] as List)
              .firstWhere((opt) => opt['value'] == selectedValue);
          totalPoints += option['points'] as int;
        }
        maxPoints += (question['options'] as List)
            .map((option) => option['points'] as int)
            .reduce((a, b) => a + b);
      } else {
        final selectedValue = answers[questionId];
        if (selectedValue != null) {
          final option = (question['options'] as List)
              .firstWhere((opt) => opt['value'] == selectedValue);
          totalPoints += option['points'] as int;
        }
        maxPoints += questionMaxPoints;
      }
    }

    final percentage = (totalPoints / maxPoints) * 100;
    
    if (percentage >= 80) {
      finalSkillLevel = 'advanced';
    } else if (percentage >= 60) {
      finalSkillLevel = 'intermediate';
    } else if (percentage >= 40) {
      finalSkillLevel = 'novice';
    } else {
      finalSkillLevel = 'beginner';
    }

    // Save results
    ref.read(onboardingProvider.notifier).setSkillLevel(
      finalSkillLevel,
      {
        'totalPoints': totalPoints,
        'maxPoints': maxPoints,
        'percentage': percentage,
        'answers': answers,
      },
    );

    setState(() {});
  }

  Map<String, dynamic> _getSkillLevelInfo(String level) {
    switch (level) {
      case 'advanced':
        return {
          'title': 'Avanzado',
          'description': 'Tienes excelente técnica y conocimiento musical',
          'icon': Icons.star,
          'recommendation': 'Te enfocaremos en perfeccionar detalles y técnicas avanzadas',
        };
      case 'intermediate':
        return {
          'title': 'Intermedio',
          'description': 'Tienes buenas bases y estás listo para nuevos desafíos',
          'icon': Icons.trending_up,
          'recommendation': 'Trabajaremos en expandir tu repertorio y mejorar tu precisión',
        };
      case 'novice':
        return {
          'title': 'Principiante Avanzado',
          'description': 'Conoces lo básico y estás progresando bien',
          'icon': Icons.psychology,
          'recommendation': 'Te ayudaremos a solidificar las bases y desarrollar consistencia',
        };
      default:
        return {
          'title': 'Principiante',
          'description': 'Estás comenzando tu viaje musical',
          'icon': Icons.school,
          'recommendation': 'Empezaremos con ejercicios fundamentales y riffs simples',
        };
    }
  }
}