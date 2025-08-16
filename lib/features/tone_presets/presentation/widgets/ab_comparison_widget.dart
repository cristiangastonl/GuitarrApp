import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/tone_preset.dart';
import '../providers/tone_preset_providers.dart';
import 'preset_selector.dart';

class ABComparisonWidget extends ConsumerWidget {
  final Function(TonePreset)? onPresetSelected;

  const ABComparisonWidget({
    super.key,
    this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abState = ref.watch(abComparisonProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref),
          const SizedBox(height: 16),
          _buildComparisonCards(context, ref, abState),
          const SizedBox(height: 16),
          _buildControls(context, ref, abState),
          if (abState.comparison != null) ...[
            const SizedBox(height: 16),
            _buildComparisonResults(context, abState.comparison!),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Icon(
          Icons.compare,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Comparación A/B',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            ref.read(abComparisonProvider.notifier).clearPresets();
          },
          icon: const Icon(Icons.clear),
          tooltip: 'Limpiar comparación',
        ),
      ],
    );
  }

  Widget _buildComparisonCards(BuildContext context, WidgetRef ref, ABComparisonState state) {
    return Row(
      children: [
        Expanded(
          child: _buildPresetCard(
            context,
            ref,
            'A',
            state.presetA,
            state.activePreset == 'A',
            () => _selectPresetForSlot(context, ref, 'A'),
            () => ref.read(abComparisonProvider.notifier).setActivePreset('A'),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          children: [
            IconButton(
              onPressed: state.presetA != null && state.presetB != null
                  ? () => ref.read(abComparisonProvider.notifier).swapPresets()
                  : null,
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Intercambiar presets',
            ),
            Text(
              'VS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPresetCard(
            context,
            ref,
            'B',
            state.presetB,
            state.activePreset == 'B',
            () => _selectPresetForSlot(context, ref, 'B'),
            () => ref.read(abComparisonProvider.notifier).setActivePreset('B'),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetCard(
    BuildContext context,
    WidgetRef ref,
    String slot,
    TonePreset? preset,
    bool isActive,
    VoidCallback onSelect,
    VoidCallback onActivate,
  ) {
    return InkWell(
      onTap: preset != null ? onActivate : onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor.withOpacity(0.3),
            width: isActive ? 2 : 1,
          ),
          color: isActive
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Theme.of(context).scaffoldBackgroundColor,
        ),
        child: preset != null
            ? _buildPresetInfo(context, slot, preset, isActive, onSelect)
            : _buildEmptySlot(context, slot),
      ),
    );
  }

  Widget _buildPresetInfo(
    BuildContext context,
    String slot,
    TonePreset preset,
    bool isActive,
    VoidCallback onChangePreset,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with slot and change button
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).dividerColor,
                ),
                child: Center(
                  child: Text(
                    slot,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onChangePreset,
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Cambiar preset',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),

          // Preset name
          Text(
            preset.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Genre and amp
          Text(
            '${preset.genre.toUpperCase()} • ${preset.ampModel}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Key parameters
          _buildParameterRow(
            context,
            'Gain',
            preset.gain,
            'Dist',
            preset.effects['distortion'] ?? 0.0,
          ),
          const SizedBox(height: 4),
          _buildParameterRow(
            context,
            'Bass',
            preset.eqSettings['bass'] ?? 0.5,
            'Treb',
            preset.eqSettings['treble'] ?? 0.5,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot(BuildContext context, String slot) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Text(
              slot,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Seleccionar Preset',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Icon(
          Icons.add,
          color: Theme.of(context).textTheme.bodySmall?.color,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildParameterRow(
    BuildContext context,
    String label1,
    double value1,
    String label2,
    double value2,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildParameterIndicator(context, label1, value1),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildParameterIndicator(context, label2, value2),
        ),
      ],
    );
  }

  Widget _buildParameterIndicator(BuildContext context, String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            _getValueColor(value),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, WidgetRef ref, ABComparisonState state) {
    final hasPresets = state.presetA != null && state.presetB != null;

    return Row(
      children: [
        // A/B Toggle buttons
        if (hasPresets) ...[
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.activePreset != 'A'
                        ? () => ref.read(abComparisonProvider.notifier).setActivePreset('A')
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.activePreset == 'A'
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).cardColor,
                      foregroundColor: state.activePreset == 'A'
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    child: const Text('Escuchar A'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.activePreset != 'B'
                        ? () => ref.read(abComparisonProvider.notifier).setActivePreset('B')
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.activePreset == 'B'
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).cardColor,
                      foregroundColor: state.activePreset == 'B'
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    child: const Text('Escuchar B'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],

        // Use preset button
        if (hasPresets && state.activePreset != null) ...[
          ElevatedButton.icon(
            onPressed: () {
              final activePreset = state.activePreset == 'A' ? state.presetA! : state.presetB!;
              if (onPresetSelected != null) {
                onPresetSelected!(activePreset);
              }
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Usar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildComparisonResults(BuildContext context, Map<String, dynamic> comparison) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Análisis de Diferencias',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // EQ differences
          if ((comparison['differences']['eq'] as Map).isNotEmpty) ...[
            Text(
              'Ecualizador:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ..._buildDifferencesList(context, comparison['differences']['eq'] as Map<String, dynamic>),
            const SizedBox(height: 8),
          ],

          // Effects differences
          if ((comparison['differences']['effects'] as Map).isNotEmpty) ...[
            Text(
              'Efectos:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ..._buildDifferencesList(context, comparison['differences']['effects'] as Map<String, dynamic>),
            const SizedBox(height: 8),
          ],

          // Gain/Volume differences
          if (comparison['differences']['gain'] > 0.1 || comparison['differences']['volume'] > 0.1) ...[
            Text(
              'Niveles:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            if (comparison['differences']['gain'] > 0.1)
              Text(
                '• Ganancia: ${(comparison['differences']['gain'] * 100).round()}% diferencia',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (comparison['differences']['volume'] > 0.1)
              Text(
                '• Volumen: ${(comparison['differences']['volume'] * 100).round()}% diferencia',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDifferencesList(BuildContext context, Map<String, dynamic> differences) {
    return differences.entries.map((entry) {
      final percentage = (entry.value * 100).round();
      return Text(
        '• ${_getParameterDisplayName(entry.key)}: ${percentage}% diferencia',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }).toList();
  }

  String _getParameterDisplayName(String parameter) {
    switch (parameter) {
      case 'bass': return 'Graves';
      case 'mid': return 'Medios';
      case 'treble': return 'Agudos';
      case 'presence': return 'Presencia';
      case 'distortion': return 'Distorsión';
      case 'reverb': return 'Reverb';
      case 'delay': return 'Delay';
      case 'chorus': return 'Chorus';
      default: return parameter;
    }
  }

  Color _getValueColor(double value) {
    if (value < 0.3) return Colors.green;
    if (value < 0.7) return Colors.orange;
    return Colors.red;
  }

  void _selectPresetForSlot(BuildContext context, WidgetRef ref, String slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PresetSelector(
        onPresetSelected: (preset) {
          if (slot == 'A') {
            ref.read(abComparisonProvider.notifier).setPresetA(preset);
          } else {
            ref.read(abComparisonProvider.notifier).setPresetB(preset);
          }
        },
      ),
    );
  }
}