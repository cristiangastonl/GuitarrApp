import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';

class EquipmentSetupScreen extends ConsumerStatefulWidget {
  const EquipmentSetupScreen({super.key});

  @override
  ConsumerState<EquipmentSetupScreen> createState() => _EquipmentSetupScreenState();
}

class _EquipmentSetupScreenState extends ConsumerState<EquipmentSetupScreen> {
  String selectedGuitarType = '';
  String selectedAmpType = '';
  String selectedGenre = '';
  int practiceTime = 30;

  final List<Map<String, dynamic>> guitarTypes = [
    {
      'id': 'electric',
      'title': 'Guitarra Eléctrica',
      'description': 'Para rock, metal, blues',
      'icon': '🎸',
    },
    {
      'id': 'acoustic',
      'title': 'Guitarra Acústica',
      'description': 'Para folk, pop, country',
      'icon': '🪕',
    },
    {
      'id': 'classical',
      'title': 'Guitarra Clásica',
      'description': 'Para música clásica, flamenca',
      'icon': '🎼',
    },
  ];

  final List<Map<String, dynamic>> ampTypes = [
    {
      'id': 'tube',
      'title': 'Amplificador a Válvulas',
      'description': 'Sonido cálido y natural',
      'icon': '🔥',
    },
    {
      'id': 'solid_state',
      'title': 'Amplificador Transistor',
      'description': 'Sonido limpio y consistente',
      'icon': '⚡',
    },
    {
      'id': 'modeling',
      'title': 'Amplificador Digital',
      'description': 'Múltiples simulaciones',
      'icon': '🖥️',
    },
    {
      'id': 'none',
      'title': 'Sin Amplificador',
      'description': 'Solo guitarra acústica',
      'icon': '🔇',
    },
  ];

  final List<Map<String, dynamic>> genres = [
    {'id': 'rock', 'title': 'Rock', 'icon': '🤘'},
    {'id': 'metal', 'title': 'Metal', 'icon': '⚡'},
    {'id': 'blues', 'title': 'Blues', 'icon': '🎺'},
    {'id': 'pop', 'title': 'Pop', 'icon': '✨'},
    {'id': 'country', 'title': 'Country', 'icon': '🤠'},
    {'id': 'jazz', 'title': 'Jazz', 'icon': '🎷'},
    {'id': 'classical', 'title': 'Clásica', 'icon': '🎼'},
    {'id': 'alternative', 'title': 'Alternativo', 'icon': '🎨'},
  ];

  @override
  Widget build(BuildContext context) {
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
                  ref.read(onboardingProvider.notifier).previousStep();
                },
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Text(
                'Configuración de Equipamiento',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ayúdanos a personalizar tu experiencia',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guitar Type Section
                  _buildSectionTitle('¿Qué tipo de guitarra tocas?'),
                  const SizedBox(height: 16),
                  _buildGuitarTypeSelection(),
                  const SizedBox(height: 32),

                  // Amp Type Section
                  if (selectedGuitarType == 'electric') ...[
                    _buildSectionTitle('¿Qué amplificador usas?'),
                    const SizedBox(height: 16),
                    _buildAmpTypeSelection(),
                    const SizedBox(height: 32),
                  ],

                  // Genre Section
                  _buildSectionTitle('¿Cuál es tu género favorito?'),
                  const SizedBox(height: 16),
                  _buildGenreSelection(),
                  const SizedBox(height: 32),

                  // Practice Time Section
                  _buildSectionTitle('¿Cuánto tiempo quieres practicar diariamente?'),
                  const SizedBox(height: 16),
                  _buildPracticeTimeSlider(),
                ],
              ),
            ),
          ),

          // Navigation buttons
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(onboardingProvider.notifier).previousStep();
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
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canContinue()
                      ? () {
                          _saveEquipmentData();
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
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildGuitarTypeSelection() {
    return Column(
      children: guitarTypes.map((guitar) {
        final isSelected = selectedGuitarType == guitar['id'];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                selectedGuitarType = guitar['id'];
                if (guitar['id'] != 'electric') {
                  selectedAmpType = 'none';
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
                  Text(
                    guitar['icon'],
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guitar['title'],
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          guitar['description'],
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) 
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmpTypeSelection() {
    return Column(
      children: ampTypes.where((amp) => amp['id'] != 'none').map((amp) {
        final isSelected = selectedAmpType == amp['id'];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                selectedAmpType = amp['id'];
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
                  Text(
                    amp['icon'],
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          amp['title'],
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          amp['description'],
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) 
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenreSelection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: genres.map((genre) {
        final isSelected = selectedGenre == genre['id'];
        return InkWell(
          onTap: () {
            setState(() {
              selectedGenre = genre['id'];
            });
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).dividerColor,
              ),
              color: isSelected 
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Theme.of(context).cardColor,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(genre['icon']),
                const SizedBox(width: 8),
                Text(
                  genre['title'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : null,
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPracticeTimeSlider() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiempo diario',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '$practiceTime minutos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: practiceTime.toDouble(),
            min: 10,
            max: 120,
            divisions: 11,
            onChanged: (value) {
              setState(() {
                practiceTime = value.round();
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10 min', style: Theme.of(context).textTheme.bodySmall),
              Text('120 min', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  bool _canContinue() {
    return selectedGuitarType.isNotEmpty && 
           selectedGenre.isNotEmpty &&
           (selectedGuitarType != 'electric' || selectedAmpType.isNotEmpty);
  }

  void _saveEquipmentData() {
    final equipmentData = {
      'guitarType': selectedGuitarType,
      'ampType': selectedAmpType,
      'genre': selectedGenre,
      'practiceTime': practiceTime,
    };
    
    ref.read(onboardingProvider.notifier).setEquipment(equipmentData);
    ref.read(onboardingProvider.notifier).updateUserData('genres', [selectedGenre]);
    ref.read(onboardingProvider.notifier).updateUserData('practiceTime', practiceTime);
  }
}