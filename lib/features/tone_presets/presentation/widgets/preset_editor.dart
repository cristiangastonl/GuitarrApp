import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/tone_preset.dart';
import '../providers/tone_preset_providers.dart';

class PresetEditor extends ConsumerStatefulWidget {
  final TonePreset? basePreset;
  final Function(TonePreset)? onPresetCreated;

  const PresetEditor({
    super.key,
    this.basePreset,
    this.onPresetCreated,
  });

  @override
  ConsumerState<PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<PresetEditor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.basePreset != null) {
        ref.read(presetCreationProvider.notifier).loadFromPreset(widget.basePreset!);
        _nameController.text = '${widget.basePreset!.name} (Copia)';
        _descriptionController.text = widget.basePreset!.description;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creationState = ref.watch(presetCreationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.basePreset != null ? 'Editar Preset' : 'Crear Preset'),
        actions: [
          IconButton(
            onPressed: () => _showPreviewDialog(),
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Vista previa',
          ),
          IconButton(
            onPressed: creationState.isValid ? _savePreset : null,
            icon: const Icon(Icons.save),
            tooltip: 'Guardar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'General', icon: Icon(Icons.info)),
            Tab(text: 'EQ', icon: Icon(Icons.equalizer)),
            Tab(text: 'Efectos', icon: Icon(Icons.auto_fix_high)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(creationState),
          _buildEqTab(creationState),
          _buildEffectsTab(creationState),
        ],
      ),
    );
  }

  Widget _buildGeneralTab(PresetCreationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name input
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre del Preset *',
              hintText: 'Mi Preset Personalizado',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              errorText: _nameController.text.trim().length < 3 && _nameController.text.isNotEmpty
                  ? 'El nombre debe tener al menos 3 caracteres'
                  : null,
            ),
            onChanged: (value) {
              ref.read(presetCreationProvider.notifier).updateName(value);
            },
          ),
          const SizedBox(height: 16),

          // Description input
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Descripción',
              hintText: 'Describe el sonido de este preset...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
            onChanged: (value) {
              ref.read(presetCreationProvider.notifier).updateDescription(value);
            },
          ),
          const SizedBox(height: 24),

          // Genre selection
          Text(
            'Género',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildGenreSelector(state),
          const SizedBox(height: 24),

          // Amp model selection
          Text(
            'Modelo de Amplificador',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildAmpSelector(state),
          const SizedBox(height: 24),

          // Gain and Volume
          Text(
            'Nivel General',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildSliderControl(
            'Ganancia',
            state.gain,
            Icons.volume_up,
            (value) => ref.read(presetCreationProvider.notifier).updateGain(value),
          ),
          const SizedBox(height: 8),
          _buildSliderControl(
            'Volumen',
            state.volume,
            Icons.volume_down,
            (value) => ref.read(presetCreationProvider.notifier).updateVolume(value),
          ),
        ],
      ),
    );
  }

  Widget _buildEqTab(PresetCreationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ecualizador',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajusta la respuesta de frecuencia del amplificador',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),

          // EQ Visual representation
          _buildEqVisualizer(state),
          const SizedBox(height: 32),

          // EQ Controls
          _buildSliderControl(
            'Graves (Bass)',
            state.eqSettings['bass'] ?? 0.5,
            Icons.graphic_eq,
            (value) => ref.read(presetCreationProvider.notifier).updateEqSetting('bass', value),
            description: 'Frecuencias bajas (80-250 Hz)',
          ),
          const SizedBox(height: 16),
          _buildSliderControl(
            'Medios (Mid)',
            state.eqSettings['mid'] ?? 0.5,
            Icons.graphic_eq,
            (value) => ref.read(presetCreationProvider.notifier).updateEqSetting('mid', value),
            description: 'Frecuencias medias (250-4000 Hz)',
          ),
          const SizedBox(height: 16),
          _buildSliderControl(
            'Agudos (Treble)',
            state.eqSettings['treble'] ?? 0.5,
            Icons.graphic_eq,
            (value) => ref.read(presetCreationProvider.notifier).updateEqSetting('treble', value),
            description: 'Frecuencias altas (4000-20000 Hz)',
          ),
          const SizedBox(height: 16),
          _buildSliderControl(
            'Presencia',
            state.eqSettings['presence'] ?? 0.5,
            Icons.graphic_eq,
            (value) => ref.read(presetCreationProvider.notifier).updateEqSetting('presence', value),
            description: 'Claridad y definición en agudos',
          ),
        ],
      ),
    );
  }

  Widget _buildEffectsTab(PresetCreationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Efectos',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configura los efectos de audio',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),

          _buildSliderControl(
            'Distorsión',
            state.effects['distortion'] ?? 0.0,
            Icons.auto_fix_high,
            (value) => ref.read(presetCreationProvider.notifier).updateEffect('distortion', value),
            description: 'Saturación y overdrive',
          ),
          const SizedBox(height: 16),
          _buildSliderControl(
            'Reverb',
            state.effects['reverb'] ?? 0.0,
            Icons.waves,
            (value) => ref.read(presetCreationProvider.notifier).updateEffect('reverb', value),
            description: 'Espacialidad y ambiente',
          ),
          const SizedBox(height: 16),
          _buildSliderControl(
            'Delay',
            state.effects['delay'] ?? 0.0,
            Icons.repeat,
            (value) => ref.read(presetCreationProvider.notifier).updateEffect('delay', value),
            description: 'Eco y repeticiones',
          ),
          const SizedBox(height: 16),
          _buildSliderControl(
            'Chorus',
            state.effects['chorus'] ?? 0.0,
            Icons.music_note,
            (value) => ref.read(presetCreationProvider.notifier).updateEffect('chorus', value),
            description: 'Modulación y grosor',
          ),
        ],
      ),
    );
  }

  Widget _buildGenreSelector(PresetCreationState state) {
    final genres = [
      {'id': 'rock', 'name': 'Rock', 'color': Colors.orange},
      {'id': 'metal', 'name': 'Metal', 'color': Colors.red},
      {'id': 'blues', 'name': 'Blues', 'color': Colors.blue},
      {'id': 'jazz', 'name': 'Jazz', 'color': Colors.purple},
      {'id': 'country', 'name': 'Country', 'color': Colors.brown},
      {'id': 'acoustic', 'name': 'Acústico', 'color': Colors.green},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genres.map((genre) {
        final isSelected = state.genre == genre['id'];
        return InkWell(
          onTap: () {
            ref.read(presetCreationProvider.notifier).updateGenre(genre['id'] as String);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? (genre['color'] as Color)
                    : Theme.of(context).dividerColor,
              ),
              color: isSelected 
                  ? (genre['color'] as Color).withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Text(
              genre['name'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? (genre['color'] as Color) : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmpSelector(PresetCreationState state) {
    final amps = [
      {'id': 'marshall_plexi', 'name': 'Marshall Plexi'},
      {'id': 'fender_twin', 'name': 'Fender Twin'},
      {'id': 'mesa_boogie', 'name': 'Mesa Boogie'},
      {'id': 'vox_ac30', 'name': 'Vox AC30'},
      {'id': 'fender_blues', 'name': 'Fender Blues'},
      {'id': 'marshall_jcm800', 'name': 'Marshall JCM800'},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: state.ampModel,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: amps.map((amp) {
          return DropdownMenuItem(
            value: amp['id'],
            child: Text(amp['name']!),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            ref.read(presetCreationProvider.notifier).updateAmpModel(value);
          }
        },
      ),
    );
  }

  Widget _buildSliderControl(
    String label,
    double value,
    IconData icon,
    Function(double) onChanged, {
    String? description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                child: Text(
                  '${(value * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            onChanged: onChanged,
            divisions: 20,
            label: '${(value * 100).round()}%',
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEqVisualizer(PresetCreationState state) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 88),
        painter: EqVisualizerPainter(
          bassLevel: state.eqSettings['bass'] ?? 0.5,
          midLevel: state.eqSettings['mid'] ?? 0.5,
          trebleLevel: state.eqSettings['treble'] ?? 0.5,
          presenceLevel: state.eqSettings['presence'] ?? 0.5,
          primaryColor: Theme.of(context).primaryColor,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
      ),
    );
  }

  void _showPreviewDialog() {
    final state = ref.read(presetCreationProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vista Previa del Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${state.name.isEmpty ? "Sin nombre" : state.name}'),
            Text('Género: ${state.genre}'),
            Text('Amplificador: ${state.ampModel}'),
            const SizedBox(height: 16),
            Text('EQ:', style: Theme.of(context).textTheme.titleSmall),
            Text('• Graves: ${(state.eqSettings["bass"]! * 100).round()}%'),
            Text('• Medios: ${(state.eqSettings["mid"]! * 100).round()}%'),
            Text('• Agudos: ${(state.eqSettings["treble"]! * 100).round()}%'),
            const SizedBox(height: 8),
            Text('Efectos:', style: Theme.of(context).textTheme.titleSmall),
            Text('• Distorsión: ${(state.effects["distortion"]! * 100).round()}%'),
            Text('• Reverb: ${(state.effects["reverb"]! * 100).round()}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement actual audio preview
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vista previa de audio (próximamente)')),
              );
            },
            child: const Text('Escuchar'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePreset() async {
    final notifier = ref.read(presetCreationProvider.notifier);
    final preset = await notifier.createPreset();
    
    if (preset != null) {
      if (widget.onPresetCreated != null) {
        widget.onPresetCreated!(preset);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preset "${preset.name}" guardado correctamente')),
        );
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar el preset'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Custom painter for EQ visualization
class EqVisualizerPainter extends CustomPainter {
  final double bassLevel;
  final double midLevel;
  final double trebleLevel;
  final double presenceLevel;
  final Color primaryColor;
  final Color backgroundColor;

  EqVisualizerPainter({
    required this.bassLevel,
    required this.midLevel,
    required this.trebleLevel,
    required this.presenceLevel,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Draw frequency response curve
    final path = Path();
    final fillPath = Path();
    
    final width = size.width;
    final height = size.height;
    
    // Create points for the EQ curve
    final points = [
      Offset(0, height - (bassLevel * height)),
      Offset(width * 0.25, height - (bassLevel * height)),
      Offset(width * 0.5, height - (midLevel * height)),
      Offset(width * 0.75, height - (trebleLevel * height)),
      Offset(width, height - (presenceLevel * height)),
    ];

    // Draw the curve
    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
      fillPath.lineTo(points[i].dx, points[i].dy);
    }

    fillPath.lineTo(width, height);
    fillPath.close();

    // Fill under the curve
    canvas.drawPath(fillPath, fillPaint);
    
    // Draw the curve line
    canvas.drawPath(path, paint);

    // Draw frequency labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final labels = ['Bass', 'Mid', 'Treble', 'Presence'];
    final positions = [0.125, 0.375, 0.625, 0.875];

    for (int i = 0; i < labels.length; i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: primaryColor.withOpacity(0.7),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(width * positions[i] - textPainter.width / 2, height + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}