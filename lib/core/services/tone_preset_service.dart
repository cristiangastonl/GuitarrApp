import '../models/tone_preset.dart';
import '../models/song_riff.dart';
import '../storage/database_helper.dart';

class TonePresetService {
  /// Get all presets (default + user custom)
  Future<List<TonePreset>> getAllPresets() async {
    try {
      final customPresets = await DatabaseHelper.getAllTonePresets();
      final defaultPresets = getDefaultPresets();
      
      return [...defaultPresets, ...customPresets];
    } catch (e) {
      return getDefaultPresets();
    }
  }

  /// Get default factory presets
  List<TonePreset> getDefaultPresets() {
    return [
      TonePreset.createCleanPreset(),
      TonePreset.createRockPreset(),
      TonePreset.createMetalPreset(),
      _createBluesPreset(),
      _createCountryPreset(),
      _createJazzPreset(),
      _createFunkPreset(),
      _createAcousticPreset(),
    ];
  }

  /// Get presets filtered by genre
  Future<List<TonePreset>> getPresetsByGenre(String genre) async {
    final allPresets = await getAllPresets();
    return allPresets.where((preset) => preset.genre.toLowerCase() == genre.toLowerCase()).toList();
  }

  /// Get smart recommendations for a specific riff
  Future<List<TonePreset>> getRecommendationsForRiff(SongRiff riff) async {
    final allPresets = await getAllPresets();
    final recommendations = <TonePreset>[];

    // 1. Exact genre match (highest priority)
    final genreMatches = allPresets
        .where((preset) => preset.genre.toLowerCase() == riff.genre.toLowerCase())
        .toList();
    recommendations.addAll(genreMatches);

    // 2. Artist/song specific presets
    final artistSpecific = await _getArtistSpecificPresets(riff.artistName);
    recommendations.addAll(artistSpecific);

    // 3. BPM and difficulty matching
    final bpmMatches = _getPresetsByBpmAndDifficulty(allPresets, riff.targetBpm, riff.difficulty);
    recommendations.addAll(bpmMatches);

    // 4. Remove duplicates and limit to top 6
    final uniqueRecommendations = <String, TonePreset>{};
    for (final preset in recommendations) {
      uniqueRecommendations[preset.id] = preset;
    }

    return uniqueRecommendations.values.take(6).toList();
  }

  /// Get equipment-specific preset recommendations
  Future<List<TonePreset>> getPresetsForEquipment({
    required String guitarType,
    required String ampType,
    String? genre,
  }) async {
    final allPresets = await getAllPresets();
    final recommendations = <TonePreset>[];

    // Match by amp type
    for (final preset in allPresets) {
      final score = _calculateEquipmentCompatibility(preset, guitarType, ampType);
      if (score > 0.6) {
        recommendations.add(preset);
      }
    }

    // Filter by genre if provided
    if (genre != null) {
      final genreFiltered = recommendations
          .where((preset) => preset.genre.toLowerCase() == genre.toLowerCase())
          .toList();
      if (genreFiltered.isNotEmpty) {
        return genreFiltered.take(6).toList();
      }
    }

    return recommendations.take(6).toList();
  }

  /// Create a custom preset
  Future<TonePreset> createCustomPreset({
    required String name,
    required String description,
    required String genre,
    required String ampModel,
    required Map<String, double> eqSettings,
    required Map<String, double> effects,
    required double gain,
    required double volume,
  }) async {
    final preset = TonePreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      genre: genre,
      ampModel: ampModel,
      eqSettings: eqSettings,
      effects: effects,
      gain: gain,
      volume: volume,
      isDefault: false,
      isCustom: true,
      createdAt: DateTime.now(),
      lastUsed: DateTime.now(),
    );

    await DatabaseHelper.insertTonePreset(preset);
    return preset;
  }

  /// Clone an existing preset with modifications
  Future<TonePreset> clonePreset(TonePreset original, {
    String? newName,
    Map<String, double>? eqOverrides,
    Map<String, double>? effectsOverrides,
    double? gainOverride,
    double? volumeOverride,
  }) async {
    final clonedPreset = TonePreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: newName ?? '${original.name} (Copia)',
      description: '${original.description} - Personalizado',
      genre: original.genre,
      ampModel: original.ampModel,
      eqSettings: eqOverrides ?? Map.from(original.eqSettings),
      effects: effectsOverrides ?? Map.from(original.effects),
      gain: gainOverride ?? original.gain,
      volume: volumeOverride ?? original.volume,
      isDefault: false,
      isCustom: true,
      createdAt: DateTime.now(),
      lastUsed: DateTime.now(),
    );

    await DatabaseHelper.insertTonePreset(clonedPreset);
    return clonedPreset;
  }

  /// Update preset usage
  Future<void> updatePresetUsage(String presetId) async {
    try {
      final preset = await DatabaseHelper.getTonePresetById(presetId);
      if (preset != null && preset.isCustom) {
        final updatedPreset = preset.copyWith(lastUsed: DateTime.now());
        await DatabaseHelper.updateTonePreset(updatedPreset);
      }
    } catch (e) {
      // Silently handle error for default presets
    }
  }

  /// A/B compare two presets
  Map<String, dynamic> comparePresets(TonePreset presetA, TonePreset presetB) {
    return {
      'preset_a': {
        'name': presetA.name,
        'genre': presetA.genre,
        'amp': presetA.ampModel,
        'gain': presetA.gain,
        'eq': presetA.eqSettings,
        'effects': presetA.effects,
      },
      'preset_b': {
        'name': presetB.name,
        'genre': presetB.genre,
        'amp': presetB.ampModel,
        'gain': presetB.gain,
        'eq': presetB.eqSettings,
        'effects': presetB.effects,
      },
      'differences': _calculateDifferences(presetA, presetB),
    };
  }

  /// Get preset analytics
  Future<Map<String, dynamic>> getPresetAnalytics() async {
    final customPresets = await DatabaseHelper.getAllTonePresets();
    final defaultPresets = getDefaultPresets();

    final genreDistribution = <String, int>{};
    final ampModelUsage = <String, int>{};

    for (final preset in [...defaultPresets, ...customPresets]) {
      genreDistribution[preset.genre] = (genreDistribution[preset.genre] ?? 0) + 1;
      ampModelUsage[preset.ampModel] = (ampModelUsage[preset.ampModel] ?? 0) + 1;
    }

    final mostUsedPresets = customPresets
        .where((p) => p.isCustom)
        .toList()
      ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));

    return {
      'totalPresets': defaultPresets.length + customPresets.length,
      'customPresets': customPresets.length,
      'defaultPresets': defaultPresets.length,
      'genreDistribution': genreDistribution,
      'ampModelUsage': ampModelUsage,
      'mostUsedPresets': mostUsedPresets.take(5).map((p) => p.name).toList(),
    };
  }

  /// Private helper methods

  Future<List<TonePreset>> _getArtistSpecificPresets(String artistName) async {
    // This would ideally be a curated database of artist-specific presets
    final artistPresets = <TonePreset>[];
    
    switch (artistName.toLowerCase()) {
      case 'metallica':
        artistPresets.add(_createMetallicaPreset());
        break;
      case 'led zeppelin':
        artistPresets.add(_createLedZeppelinPreset());
        break;
      case 'black sabbath':
        artistPresets.add(_createBlackSabbathPreset());
        break;
      case 'ac/dc':
        artistPresets.add(_createACDCPreset());
        break;
    }

    return artistPresets;
  }

  List<TonePreset> _getPresetsByBpmAndDifficulty(List<TonePreset> presets, int bpm, String difficulty) {
    final filtered = <TonePreset>[];

    for (final preset in presets) {
      double score = 0.0;

      // BPM considerations
      if (bpm < 80) {
        // Slow songs might benefit from cleaner tones or blues
        if (preset.genre == 'blues' || preset.genre == 'jazz') score += 0.3;
      } else if (bpm > 140) {
        // Fast songs might benefit from tighter, more aggressive tones
        if (preset.genre == 'metal' || preset.genre == 'rock') score += 0.3;
      }

      // Difficulty considerations
      switch (difficulty.toLowerCase()) {
        case 'beginner':
          if (preset.genre == 'clean' || preset.effects['distortion']! < 0.5) score += 0.2;
          break;
        case 'intermediate':
          if (preset.genre == 'rock') score += 0.2;
          break;
        case 'advanced':
          if (preset.genre == 'metal' || preset.effects['distortion']! > 0.7) score += 0.2;
          break;
      }

      if (score > 0.3) {
        filtered.add(preset);
      }
    }

    return filtered;
  }

  double _calculateEquipmentCompatibility(TonePreset preset, String guitarType, String ampType) {
    double score = 0.5; // Base compatibility

    // Guitar type matching
    switch (guitarType.toLowerCase()) {
      case 'electric':
        score += 0.3;
        break;
      case 'acoustic':
        if (preset.genre == 'country' || preset.genre == 'folk') score += 0.2;
        if (preset.effects['distortion']! < 0.3) score += 0.1;
        break;
      case 'classical':
        if (preset.genre == 'jazz' || preset.genre == 'classical') score += 0.2;
        break;
    }

    // Amp type matching
    switch (ampType.toLowerCase()) {
      case 'tube':
        if (preset.ampModel.contains('marshall') || preset.ampModel.contains('fender')) score += 0.2;
        break;
      case 'solid_state':
        if (preset.ampModel.contains('roland') || preset.ampModel.contains('vox')) score += 0.2;
        break;
      case 'modeling':
        score += 0.1; // Modeling amps are generally compatible
        break;
    }

    return score.clamp(0.0, 1.0);
  }

  Map<String, dynamic> _calculateDifferences(TonePreset presetA, TonePreset presetB) {
    final differences = <String, dynamic>{};

    // EQ differences
    final eqDiffs = <String, double>{};
    for (final key in presetA.eqSettings.keys) {
      final diff = (presetA.eqSettings[key]! - presetB.eqSettings[key]!).abs();
      if (diff > 0.1) {
        eqDiffs[key] = diff;
      }
    }
    differences['eq'] = eqDiffs;

    // Effects differences
    final effectsDiffs = <String, double>{};
    for (final key in presetA.effects.keys) {
      final diff = (presetA.effects[key]! - presetB.effects[key]!).abs();
      if (diff > 0.1) {
        effectsDiffs[key] = diff;
      }
    }
    differences['effects'] = effectsDiffs;

    // Gain and volume differences
    differences['gain'] = (presetA.gain - presetB.gain).abs();
    differences['volume'] = (presetA.volume - presetB.volume).abs();

    return differences;
  }

  // Factory methods for additional presets

  TonePreset _createBluesPreset() {
    final now = DateTime.now();
    return TonePreset(
      id: 'blues_default',
      name: 'Blues',
      description: 'Sonido blues con overdrive cálido',
      genre: 'blues',
      ampModel: 'fender_blues',
      eqSettings: {
        'bass': 0.6,
        'mid': 0.6,
        'treble': 0.5,
        'presence': 0.4,
      },
      effects: {
        'distortion': 0.4,
        'reverb': 0.4,
        'delay': 0.2,
        'chorus': 0.0,
      },
      gain: 0.5,
      volume: 0.7,
      isDefault: true,
      isCustom: false,
      createdAt: now,
      lastUsed: now,
    );
  }

  TonePreset _createCountryPreset() {
    final now = DateTime.now();
    return TonePreset(
      id: 'country_default',
      name: 'Country',
      description: 'Sonido country brillante y limpio',
      genre: 'country',
      ampModel: 'fender_twin',
      eqSettings: {
        'bass': 0.4,
        'mid': 0.5,
        'treble': 0.8,
        'presence': 0.7,
      },
      effects: {
        'distortion': 0.2,
        'reverb': 0.3,
        'delay': 0.3,
        'chorus': 0.2,
      },
      gain: 0.4,
      volume: 0.8,
      isDefault: true,
      isCustom: false,
      createdAt: now,
      lastUsed: now,
    );
  }

  TonePreset _createJazzPreset() {
    final now = DateTime.now();
    return TonePreset(
      id: 'jazz_default',
      name: 'Jazz',
      description: 'Sonido jazz limpio y cálido',
      genre: 'jazz',
      ampModel: 'fender_twin',
      eqSettings: {
        'bass': 0.6,
        'mid': 0.5,
        'treble': 0.4,
        'presence': 0.3,
      },
      effects: {
        'distortion': 0.0,
        'reverb': 0.4,
        'delay': 0.1,
        'chorus': 0.2,
      },
      gain: 0.3,
      volume: 0.6,
      isDefault: true,
      isCustom: false,
      createdAt: now,
      lastUsed: now,
    );
  }

  TonePreset _createFunkPreset() {
    final now = DateTime.now();
    return TonePreset(
      id: 'funk_default',
      name: 'Funk',
      description: 'Sonido funk con punch y claridad',
      genre: 'funk',
      ampModel: 'fender_twin',
      eqSettings: {
        'bass': 0.5,
        'mid': 0.7,
        'treble': 0.6,
        'presence': 0.5,
      },
      effects: {
        'distortion': 0.1,
        'reverb': 0.2,
        'delay': 0.0,
        'chorus': 0.1,
      },
      gain: 0.4,
      volume: 0.7,
      isDefault: true,
      isCustom: false,
      createdAt: now,
      lastUsed: now,
    );
  }

  TonePreset _createAcousticPreset() {
    final now = DateTime.now();
    return TonePreset(
      id: 'acoustic_default',
      name: 'Acoustic',
      description: 'Sonido acústico natural',
      genre: 'acoustic',
      ampModel: 'acoustic_amp',
      eqSettings: {
        'bass': 0.5,
        'mid': 0.5,
        'treble': 0.6,
        'presence': 0.4,
      },
      effects: {
        'distortion': 0.0,
        'reverb': 0.3,
        'delay': 0.1,
        'chorus': 0.1,
      },
      gain: 0.3,
      volume: 0.7,
      isDefault: true,
      isCustom: false,
      createdAt: now,
      lastUsed: now,
    );
  }

  // Artist-specific presets

  TonePreset _createMetallicaPreset() {
    final now = DateTime.now();
    return TonePreset(
      id: 'metallica_preset',
      name: 'Metallica',
      description: 'Sonido inspirado en Metallica',
      genre: 'metal',
      ampModel: 'mesa_boogie',
      eqSettings: {
        'bass': 0.6,
        'mid': 0.3,
        'treble': 0.8,
        'presence': 0.7,
      },
      effects: {
        'distortion': 0.8,
        'reverb': 0.1,
        'delay': 0.0,
        'chorus': 0.0,
      },
      gain: 0.8,
      volume: 0.8,
      isDefault: true,
      isCustom: false,
      createdAt: now,
      lastUsed: now,
    );
  }

  TonePreset _createLedZeppelinPreset() {
    final now = DateTime.now();
    return TonePreset(
      id: 'ledzeppelin_preset',
      name: 'Led Zeppelin',
      description: 'Sonido inspirado en Led Zeppelin',
      genre: 'rock',
      ampModel: 'marshall_plexi',
      eqSettings: {
        'bass': 0.7,
        'mid': 0.6,
        'treble': 0.7,
        'presence': 0.5,
      },
      effects: {
        'distortion': 0.5,
        'reverb': 0.3,
        'delay': 0.2,
        'chorus': 0.0,
      },
      gain: 0.6,
      volume: 0.8,
      isDefault: true,
      isCustom: false,
      createdAt: now,
      lastUsed: now,
    );
  }

  TonePreset _createBlackSabbathPreset() {
    final now = DateTime.now();
    return TonePreset(
      id: 'blacksabbath_preset',
      name: 'Black Sabbath',
      description: 'Sonido inspirado en Black Sabbath',
      genre: 'metal',
      ampModel: 'laney_supergroup',
      eqSettings: {
        'bass': 0.8,
        'mid': 0.7,
        'treble': 0.6,
        'presence': 0.5,
      },
      effects: {
        'distortion': 0.7,
        'reverb': 0.2,
        'delay': 0.0,
        'chorus': 0.0,
      },
      gain: 0.7,
      volume: 0.8,
      isDefault: true,
      isCustom: false,
      createdAt: now,
      lastUsed: now,
    );
  }

  TonePreset _createACDCPreset() {
    final now = DateTime.now();
    return TonePreset(
      id: 'acdc_preset',
      name: 'AC/DC',
      description: 'Sonido inspirado en AC/DC',
      genre: 'rock',
      ampModel: 'marshall_jcm800',
      eqSettings: {
        'bass': 0.6,
        'mid': 0.8,
        'treble': 0.9,
        'presence': 0.8,
      },
      effects: {
        'distortion': 0.6,
        'reverb': 0.1,
        'delay': 0.0,
        'chorus': 0.0,
      },
      gain: 0.7,
      volume: 0.9,
      isDefault: true,
      isCustom: false,
      createdAt: now,
      lastUsed: now,
    );
  }
}