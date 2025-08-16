import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/tone_preset_service.dart';
import '../../../../core/models/tone_preset.dart';
import '../../../../core/models/song_riff.dart';

// Service provider
final tonePresetServiceProvider = Provider<TonePresetService>((ref) => TonePresetService());

// All presets
final allPresetsProvider = FutureProvider<List<TonePreset>>((ref) async {
  final service = ref.read(tonePresetServiceProvider);
  return await service.getAllPresets();
});

// Default presets only
final defaultPresetsProvider = FutureProvider<List<TonePreset>>((ref) async {
  final service = ref.read(tonePresetServiceProvider);
  return service.getDefaultPresets();
});

// Custom presets only
final customPresetsProvider = FutureProvider<List<TonePreset>>((ref) async {
  final allPresets = await ref.read(allPresetsProvider.future);
  return allPresets.where((preset) => preset.isCustom).toList();
});

// Presets by genre
final presetsByGenreProvider = FutureProvider.family<List<TonePreset>, String>((ref, genre) async {
  final service = ref.read(tonePresetServiceProvider);
  return await service.getPresetsByGenre(genre);
});

// Recommendations for specific riff
final riffRecommendationsProvider = FutureProvider.family<List<TonePreset>, SongRiff>((ref, riff) async {
  final service = ref.read(tonePresetServiceProvider);
  return await service.getRecommendationsForRiff(riff);
});

// Equipment-based recommendations
typedef EquipmentParams = ({String guitarType, String ampType, String? genre});
final equipmentRecommendationsProvider = FutureProvider.family<List<TonePreset>, EquipmentParams>((ref, params) async {
  final service = ref.read(tonePresetServiceProvider);
  return await service.getPresetsForEquipment(
    guitarType: params.guitarType,
    ampType: params.ampType,
    genre: params.genre,
  );
});

// Preset analytics
final presetAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(tonePresetServiceProvider);
  return await service.getPresetAnalytics();
});

// Currently selected preset (for practice session)
final selectedPresetProvider = StateProvider<TonePreset?>((ref) => null);

// A/B comparison state
class ABComparisonState {
  final TonePreset? presetA;
  final TonePreset? presetB;
  final Map<String, dynamic>? comparison;
  final String? activePreset; // 'A' or 'B'

  const ABComparisonState({
    this.presetA,
    this.presetB,
    this.comparison,
    this.activePreset,
  });

  ABComparisonState copyWith({
    TonePreset? presetA,
    TonePreset? presetB,
    Map<String, dynamic>? comparison,
    String? activePreset,
  }) {
    return ABComparisonState(
      presetA: presetA ?? this.presetA,
      presetB: presetB ?? this.presetB,
      comparison: comparison ?? this.comparison,
      activePreset: activePreset ?? this.activePreset,
    );
  }
}

class ABComparisonNotifier extends StateNotifier<ABComparisonState> {
  final TonePresetService _service;

  ABComparisonNotifier(this._service) : super(const ABComparisonState());

  void setPresetA(TonePreset preset) {
    state = state.copyWith(presetA: preset);
    _updateComparison();
  }

  void setPresetB(TonePreset preset) {
    state = state.copyWith(presetB: preset);
    _updateComparison();
  }

  void setActivePreset(String preset) {
    if (preset == 'A' || preset == 'B') {
      state = state.copyWith(activePreset: preset);
    }
  }

  void swapPresets() {
    state = state.copyWith(
      presetA: state.presetB,
      presetB: state.presetA,
    );
    _updateComparison();
  }

  void clearPresets() {
    state = const ABComparisonState();
  }

  void _updateComparison() {
    if (state.presetA != null && state.presetB != null) {
      final comparison = _service.comparePresets(state.presetA!, state.presetB!);
      state = state.copyWith(comparison: comparison);
    }
  }
}

final abComparisonProvider = StateNotifierProvider<ABComparisonNotifier, ABComparisonState>((ref) {
  final service = ref.read(tonePresetServiceProvider);
  return ABComparisonNotifier(service);
});

// Preset creation state
class PresetCreationState {
  final String name;
  final String description;
  final String genre;
  final String ampModel;
  final Map<String, double> eqSettings;
  final Map<String, double> effects;
  final double gain;
  final double volume;
  final bool isValid;

  const PresetCreationState({
    this.name = '',
    this.description = '',
    this.genre = 'rock',
    this.ampModel = 'marshall_plexi',
    this.eqSettings = const {
      'bass': 0.5,
      'mid': 0.5,
      'treble': 0.5,
      'presence': 0.5,
    },
    this.effects = const {
      'distortion': 0.0,
      'reverb': 0.0,
      'delay': 0.0,
      'chorus': 0.0,
    },
    this.gain = 0.5,
    this.volume = 0.7,
    this.isValid = false,
  });

  PresetCreationState copyWith({
    String? name,
    String? description,
    String? genre,
    String? ampModel,
    Map<String, double>? eqSettings,
    Map<String, double>? effects,
    double? gain,
    double? volume,
    bool? isValid,
  }) {
    return PresetCreationState(
      name: name ?? this.name,
      description: description ?? this.description,
      genre: genre ?? this.genre,
      ampModel: ampModel ?? this.ampModel,
      eqSettings: eqSettings ?? this.eqSettings,
      effects: effects ?? this.effects,
      gain: gain ?? this.gain,
      volume: volume ?? this.volume,
      isValid: isValid ?? this.isValid,
    );
  }
}

class PresetCreationNotifier extends StateNotifier<PresetCreationState> {
  final TonePresetService _service;

  PresetCreationNotifier(this._service) : super(const PresetCreationState());

  void updateName(String name) {
    state = state.copyWith(name: name);
    _validateState();
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updateGenre(String genre) {
    state = state.copyWith(genre: genre);
  }

  void updateAmpModel(String ampModel) {
    state = state.copyWith(ampModel: ampModel);
  }

  void updateEqSetting(String parameter, double value) {
    final newEqSettings = Map<String, double>.from(state.eqSettings);
    newEqSettings[parameter] = value.clamp(0.0, 1.0);
    state = state.copyWith(eqSettings: newEqSettings);
  }

  void updateEffect(String effect, double value) {
    final newEffects = Map<String, double>.from(state.effects);
    newEffects[effect] = value.clamp(0.0, 1.0);
    state = state.copyWith(effects: newEffects);
  }

  void updateGain(double gain) {
    state = state.copyWith(gain: gain.clamp(0.0, 1.0));
  }

  void updateVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
  }

  void loadFromPreset(TonePreset preset) {
    state = PresetCreationState(
      name: '${preset.name} (Copia)',
      description: preset.description,
      genre: preset.genre,
      ampModel: preset.ampModel,
      eqSettings: Map.from(preset.eqSettings),
      effects: Map.from(preset.effects),
      gain: preset.gain,
      volume: preset.volume,
      isValid: true,
    );
  }

  Future<TonePreset?> createPreset() async {
    if (!state.isValid) return null;

    try {
      final preset = await _service.createCustomPreset(
        name: state.name,
        description: state.description,
        genre: state.genre,
        ampModel: state.ampModel,
        eqSettings: state.eqSettings,
        effects: state.effects,
        gain: state.gain,
        volume: state.volume,
      );
      
      // Reset state after creation
      state = const PresetCreationState();
      return preset;
    } catch (e) {
      return null;
    }
  }

  void reset() {
    state = const PresetCreationState();
  }

  void _validateState() {
    final isValid = state.name.trim().isNotEmpty && state.name.trim().length >= 3;
    state = state.copyWith(isValid: isValid);
  }
}

final presetCreationProvider = StateNotifierProvider<PresetCreationNotifier, PresetCreationState>((ref) {
  final service = ref.read(tonePresetServiceProvider);
  return PresetCreationNotifier(service);
});

// Recent presets (most recently used)
final recentPresetsProvider = FutureProvider<List<TonePreset>>((ref) async {
  final allPresets = await ref.read(allPresetsProvider.future);
  final customPresets = allPresets.where((preset) => preset.isCustom).toList();
  
  // Sort by last used date
  customPresets.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
  
  return customPresets.take(5).toList();
});

// Preset search
final presetSearchProvider = StateProvider<String>((ref) => '');

final filteredPresetsProvider = FutureProvider<List<TonePreset>>((ref) async {
  final allPresets = await ref.read(allPresetsProvider.future);
  final searchQuery = ref.watch(presetSearchProvider).toLowerCase().trim();
  
  if (searchQuery.isEmpty) return allPresets;
  
  return allPresets.where((preset) {
    return preset.name.toLowerCase().contains(searchQuery) ||
           preset.description.toLowerCase().contains(searchQuery) ||
           preset.genre.toLowerCase().contains(searchQuery) ||
           preset.ampModel.toLowerCase().contains(searchQuery);
  }).toList();
});

// Helper function to refresh all preset providers
void refreshPresetProviders(WidgetRef ref) {
  ref.invalidate(allPresetsProvider);
  ref.invalidate(customPresetsProvider);
  ref.invalidate(presetAnalyticsProvider);
  ref.invalidate(recentPresetsProvider);
}