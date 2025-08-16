import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/tone_preset.dart';
import '../../../../core/models/song_riff.dart';
import '../providers/tone_preset_providers.dart';

class PresetSelector extends ConsumerStatefulWidget {
  final Function(TonePreset) onPresetSelected;
  final SongRiff? targetRiff;
  final String? guitarType;
  final String? ampType;

  const PresetSelector({
    super.key,
    required this.onPresetSelected,
    this.targetRiff,
    this.guitarType,
    this.ampType,
  });

  @override
  ConsumerState<PresetSelector> createState() => _PresetSelectorState();
}

class _PresetSelectorState extends ConsumerState<PresetSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedCategory = 'all';
  TonePreset? selectedPreset;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecommendedTab(),
                _buildAllPresetsTab(),
                _buildCustomTab(),
              ],
            ),
          ),
          if (selectedPreset != null) _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Seleccionar Preset',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Recomendados', icon: Icon(Icons.recommend)),
        Tab(text: 'Todos', icon: Icon(Icons.library_music)),
        Tab(text: 'Personalizados', icon: Icon(Icons.tune)),
      ],
    );
  }

  Widget _buildRecommendedTab() {
    if (widget.targetRiff == null) {
      return _buildEquipmentRecommendations();
    }

    return Consumer(
      builder: (context, ref, child) {
        final recommendationsAsync = ref.watch(
          riffRecommendationsProvider(widget.targetRiff!),
        );

        return recommendationsAsync.when(
          data: (presets) => _buildPresetGrid(presets, showRecommendationBadge: true),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget('Error al cargar recomendaciones: $error'),
        );
      },
    );
  }

  Widget _buildEquipmentRecommendations() {
    if (widget.guitarType == null || widget.ampType == null) {
      return _buildEmptyRecommendations();
    }

    return Consumer(
      builder: (context, ref, child) {
        final recommendationsAsync = ref.watch(
          equipmentRecommendationsProvider((
            guitarType: widget.guitarType!,
            ampType: widget.ampType!,
            genre: null,
          )),
        );

        return recommendationsAsync.when(
          data: (presets) => _buildPresetGrid(presets, showCompatibilityBadge: true),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget('Error al cargar recomendaciones: $error'),
        );
      },
    );
  }

  Widget _buildAllPresetsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final presetsAsync = ref.watch(allPresetsProvider);

        return presetsAsync.when(
          data: (presets) => Column(
            children: [
              _buildCategoryFilter(),
              Expanded(
                child: _buildPresetGrid(_filterPresets(presets)),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget('Error al cargar presets: $error'),
        );
      },
    );
  }

  Widget _buildCustomTab() {
    return Consumer(
      builder: (context, ref, child) {
        final customPresetsAsync = ref.watch(customPresetsProvider);

        return customPresetsAsync.when(
          data: (presets) => presets.isEmpty
              ? _buildEmptyCustomPresets()
              : _buildPresetGrid(presets, allowEdit: true),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget('Error al cargar presets personalizados: $error'),
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      {'id': 'all', 'label': 'Todos'},
      {'id': 'rock', 'label': 'Rock'},
      {'id': 'metal', 'label': 'Metal'},
      {'id': 'blues', 'label': 'Blues'},
      {'id': 'jazz', 'label': 'Jazz'},
      {'id': 'country', 'label': 'Country'},
      {'id': 'acoustic', 'label': 'Acústico'},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['id'];

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = selected ? category['id']! : 'all';
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPresetGrid(
    List<TonePreset> presets, {
    bool showRecommendationBadge = false,
    bool showCompatibilityBadge = false,
    bool allowEdit = false,
  }) {
    if (presets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 64,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron presets',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        final isSelected = selectedPreset?.id == preset.id;

        return InkWell(
          onTap: () {
            setState(() {
              selectedPreset = preset;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).dividerColor.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Theme.of(context).cardColor,
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preset name and amp
                      Text(
                        preset.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset.ampModel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Genre badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _getGenreColor(preset.genre).withOpacity(0.2),
                        ),
                        child: Text(
                          preset.genre.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getGenreColor(preset.genre),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Gain and distortion indicators
                      Row(
                        children: [
                          _buildMeterIndicator('Gain', preset.gain),
                          const SizedBox(width: 8),
                          _buildMeterIndicator('Dist', preset.effects['distortion'] ?? 0.0),
                        ],
                      ),
                    ],
                  ),
                ),

                // Badges
                if (showRecommendationBadge || showCompatibilityBadge || allowEdit)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildBadge(
                      showRecommendationBadge,
                      showCompatibilityBadge,
                      allowEdit,
                      preset,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeterIndicator(String label, double value) {
    return Expanded(
      child: Column(
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
      ),
    );
  }

  Widget _buildBadge(
    bool isRecommended,
    bool isCompatible,
    bool isCustom,
    TonePreset preset,
  ) {
    if (isRecommended) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.orange,
        ),
        child: const Text(
          '⭐',
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    if (isCompatible) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.green,
        ),
        child: const Text(
          '✓',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    }

    if (isCustom) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 18),
        onSelected: (value) {
          switch (value) {
            case 'edit':
              _editPreset(preset);
              break;
            case 'clone':
              _clonePreset(preset);
              break;
            case 'delete':
              _deletePreset(preset);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('Editar')),
          const PopupMenuItem(value: 'clone', child: Text('Clonar')),
          const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Preview button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _previewPreset(selectedPreset!),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Vista Previa'),
            ),
          ),
          const SizedBox(width: 12),
          
          // Select button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onPresetSelected(selectedPreset!);
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Seleccionar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecommendations() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona un riff para ver\nrecomendaciones personalizadas',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCustomPresets() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tune,
            size: 64,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes presets personalizados',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _createNewPreset(),
            child: const Text('Crear Preset'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  List<TonePreset> _filterPresets(List<TonePreset> presets) {
    if (selectedCategory == 'all') return presets;
    return presets.where((preset) => preset.genre.toLowerCase() == selectedCategory).toList();
  }

  Color _getGenreColor(String genre) {
    switch (genre.toLowerCase()) {
      case 'rock':
        return Colors.orange;
      case 'metal':
        return Colors.red;
      case 'blues':
        return Colors.blue;
      case 'jazz':
        return Colors.purple;
      case 'country':
        return Colors.brown;
      case 'acoustic':
        return Colors.green;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  Color _getValueColor(double value) {
    if (value < 0.3) return Colors.green;
    if (value < 0.7) return Colors.orange;
    return Colors.red;
  }

  void _previewPreset(TonePreset preset) {
    // TODO: Implement preset preview
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Vista previa de ${preset.name}')),
    );
  }

  void _editPreset(TonePreset preset) {
    // TODO: Navigate to preset editor
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editando ${preset.name}')),
    );
  }

  void _clonePreset(TonePreset preset) {
    // TODO: Implement preset cloning
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Clonando ${preset.name}')),
    );
  }

  void _deletePreset(TonePreset preset) {
    // TODO: Implement preset deletion
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Eliminando ${preset.name}')),
    );
  }

  void _createNewPreset() {
    // TODO: Navigate to preset creator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Crear nuevo preset')),
    );
  }
}