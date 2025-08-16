import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';

class GoalSelectionScreen extends ConsumerStatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  ConsumerState<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends ConsumerState<GoalSelectionScreen> {
  final Set<String> selectedGoals = {};
  final TextEditingController nameController = TextEditingController();

  final List<Map<String, dynamic>> practiceGoals = [
    {
      'id': 'timing',
      'title': 'Mejorar el Timing',
      'description': 'Tocar en tiempo con el metrónomo',
      'icon': Icons.timer,
    },
    {
      'id': 'technique',
      'title': 'Técnica Guitarra',
      'description': 'Perfeccionar técnicas específicas',
      'icon': Icons.music_note,
    },
    {
      'id': 'riffs',
      'title': 'Aprender Riffs Icónicos',
      'description': 'Dominar riffs clásicos del rock',
      'icon': Icons.album,
    },
    {
      'id': 'consistency',
      'title': 'Consistencia',
      'description': 'Tocar de forma más uniforme',
      'icon': Icons.trending_up,
    },
    {
      'id': 'speed',
      'title': 'Velocidad',
      'description': 'Aumentar BPM gradualmente',
      'icon': Icons.fast_forward,
    },
    {
      'id': 'creativity',
      'title': 'Creatividad',
      'description': 'Improvisar y crear variaciones',
      'icon': Icons.lightbulb,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '¡Bienvenido a GuitarrApp! 🎸',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Empezemos conociendo tus objetivos musicales',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 32),

          // Name input
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: '¿Cómo te llamas?',
              hintText: 'Tu nombre de guitarrista',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              ref.read(onboardingProvider.notifier).updateUserData('playerName', value);
            },
          ),
          const SizedBox(height: 32),

          // Goals section
          Text(
            '¿Qué quieres lograr? (Selecciona todo lo que aplique)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Goals grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: practiceGoals.length,
              itemBuilder: (context, index) {
                final goal = practiceGoals[index];
                final isSelected = selectedGoals.contains(goal['id']);
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedGoals.remove(goal['id']);
                      } else {
                        selectedGoals.add(goal['id']);
                      }
                    });
                    ref.read(onboardingProvider.notifier).setGoals(selectedGoals.toList());
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
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
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(
                          goal['icon'] as IconData,
                          size: 32,
                          color: isSelected 
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).iconTheme.color,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          goal['title'] as String,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          goal['description'] as String,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Next button
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedGoals.isNotEmpty && nameController.text.isNotEmpty
                  ? () {
                      ref.read(onboardingProvider.notifier).nextStep();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continuar',
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
    nameController.dispose();
    super.dispose();
  }
}