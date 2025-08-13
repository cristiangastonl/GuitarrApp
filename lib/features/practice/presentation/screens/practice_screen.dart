import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/metronome_service.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Práctica'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Riff Selection
              _RiffSelectionSection(),
              
              SizedBox(height: 24),
              
              // Metronome Section
              _MetronomeSection(),
              
              SizedBox(height: 24),
              
              // Recording Controls
              _RecordingControlsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiffSelectionSection extends StatelessWidget {
  const _RiffSelectionSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona un Riff',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Riff a practicar',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'enter_sandman',
                  child: Text('Metallica - Enter Sandman'),
                ),
                DropdownMenuItem(
                  value: 'paranoid',
                  child: Text('Black Sabbath - Paranoid'),
                ),
                DropdownMenuItem(
                  value: 'back_in_black',
                  child: Text('AC/DC - Back in Black'),
                ),
              ],
              onChanged: (value) {},
            ),
            
            const SizedBox(height: 12),
            
            // Roadmap Progress
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Roadmap: Enter Sandman',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _RoadmapStep(
                    step: 1,
                    bpm: 72,
                    description: 'Skeleton (sin fills)',
                    isCompleted: true,
                  ),
                  _RoadmapStep(
                    step: 2,
                    bpm: 88,
                    description: 'Con palm mute marcado',
                    isCompleted: true,
                  ),
                  _RoadmapStep(
                    step: 3,
                    bpm: 96,
                    description: 'Añadir acentos correctos',
                    isCompleted: false,
                    isCurrent: true,
                  ),
                  _RoadmapStep(
                    step: 4,
                    bpm: 108,
                    description: 'Clic solo en 1 y 3',
                    isCompleted: false,
                  ),
                  _RoadmapStep(
                    step: 5,
                    bpm: 116,
                    description: 'Target final',
                    isCompleted: false,
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

class _RoadmapStep extends StatelessWidget {
  final int step;
  final int bpm;
  final String description;
  final bool isCompleted;
  final bool isCurrent;

  const _RoadmapStep({
    required this.step,
    required this.bpm,
    required this.description,
    this.isCompleted = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted 
        ? Colors.green 
        : isCurrent 
            ? Theme.of(context).colorScheme.primary
            : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? Colors.green : Colors.transparent,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      step.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$bpm BPM - $description',
              style: TextStyle(
                color: color,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetronomeSection extends ConsumerWidget {
  const _MetronomeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metronomeState = ref.watch(metronomeStateProvider);
    final metronomeNotifier = ref.read(metronomeStateProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Metrónomo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // BPM Display
            Text(
              '${metronomeState.bpm}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: metronomeState.isPlaying 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
            
            const Text(
              'BPM',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // BPM Slider
            Slider(
              value: metronomeState.bpm.toDouble(),
              min: 60,
              max: 180,
              divisions: 120,
              onChanged: metronomeState.isPlaying 
                  ? null 
                  : (value) => metronomeNotifier.setBpm(value.round()),
            ),
            
            const SizedBox(height: 16),
            
            // Metronome Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: metronomeState.isPlaying 
                      ? null 
                      : () => metronomeNotifier.setBpm(metronomeState.bpm - 5),
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                
                IconButton(
                  onPressed: () => metronomeNotifier.togglePlay(),
                  icon: Icon(
                    metronomeState.isPlaying ? Icons.stop : Icons.play_arrow, 
                    size: 48,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: metronomeState.isPlaying 
                        ? Colors.red 
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                IconButton(
                  onPressed: metronomeState.isPlaying 
                      ? null 
                      : () => metronomeNotifier.setBpm(metronomeState.bpm + 5),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Beat Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                metronomeState.timeSignature,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: metronomeState.isPlaying && 
                           metronomeState.currentBeat == index
                        ? Theme.of(context).colorScheme.primary
                        : metronomeState.accents[index] && metronomeState.accents.length > index
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                            : Colors.grey[300],
                    border: metronomeState.accents.length > index && 
                           metronomeState.accents[index]
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: metronomeState.isPlaying && 
                               metronomeState.currentBeat == index
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
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

class _RecordingControlsSection extends StatelessWidget {
  const _RecordingControlsSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Grabación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recording Button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_manual_record),
                  SizedBox(width: 8),
                  Text(
                    'Grabar (30s)',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              'Presiona grabar y toca el riff\ndurante 30 segundos',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}