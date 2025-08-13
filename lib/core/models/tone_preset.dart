class TonePreset {
  final String id;
  final String name;
  final String description;
  final String genre;
  final String ampModel;
  final Map<String, double> eqSettings; // 'bass', 'mid', 'treble', 'presence'
  final Map<String, double> effects; // 'distortion', 'reverb', 'delay', 'chorus'
  final double gain;
  final double volume;
  final bool isDefault;
  final bool isCustom;
  final DateTime createdAt;
  final DateTime lastUsed;

  const TonePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.genre,
    required this.ampModel,
    required this.eqSettings,
    required this.effects,
    required this.gain,
    required this.volume,
    this.isDefault = false,
    this.isCustom = true,
    required this.createdAt,
    required this.lastUsed,
  });

  factory TonePreset.fromJson(Map<String, dynamic> json) {
    return TonePreset(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      genre: json['genre'] as String,
      ampModel: json['ampModel'] as String,
      eqSettings: Map<String, double>.from(
        (json['eqSettings'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
      effects: Map<String, double>.from(
        (json['effects'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
      gain: (json['gain'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'genre': genre,
      'ampModel': ampModel,
      'eqSettings': eqSettings,
      'effects': effects,
      'gain': gain,
      'volume': volume,
      'isDefault': isDefault,
      'isCustom': isCustom,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  TonePreset copyWith({
    String? id,
    String? name,
    String? description,
    String? genre,
    String? ampModel,
    Map<String, double>? eqSettings,
    Map<String, double>? effects,
    double? gain,
    double? volume,
    bool? isDefault,
    bool? isCustom,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return TonePreset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      genre: genre ?? this.genre,
      ampModel: ampModel ?? this.ampModel,
      eqSettings: eqSettings ?? this.eqSettings,
      effects: effects ?? this.effects,
      gain: gain ?? this.gain,
      volume: volume ?? this.volume,
      isDefault: isDefault ?? this.isDefault,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TonePreset &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.genre == genre &&
        other.ampModel == ampModel &&
        other.eqSettings.toString() == eqSettings.toString() &&
        other.effects.toString() == effects.toString() &&
        other.gain == gain &&
        other.volume == volume &&
        other.isDefault == isDefault &&
        other.isCustom == isCustom &&
        other.createdAt == createdAt &&
        other.lastUsed == lastUsed;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      genre,
      ampModel,
      eqSettings,
      effects,
      gain,
      volume,
      isDefault,
      isCustom,
      createdAt,
      lastUsed,
    );
  }

  static TonePreset createCleanPreset() {
    final now = DateTime.now();
    return TonePreset(
      id: 'clean_default',
      name: 'Clean',
      description: 'Sonido limpio clásico',
      genre: 'jazz',
      ampModel: 'clean_twin',
      eqSettings: {
        'bass': 0.5,
        'mid': 0.5,
        'treble': 0.6,
        'presence': 0.4,
      },
      effects: {
        'distortion': 0.0,
        'reverb': 0.3,
        'delay': 0.0,
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

  static TonePreset createRockPreset() {
    final now = DateTime.now();
    return TonePreset(
      id: 'rock_default',
      name: 'Rock',
      description: 'Sonido rock clásico con distorsión',
      genre: 'rock',
      ampModel: 'marshall_plexi',
      eqSettings: {
        'bass': 0.6,
        'mid': 0.7,
        'treble': 0.8,
        'presence': 0.6,
      },
      effects: {
        'distortion': 0.6,
        'reverb': 0.2,
        'delay': 0.1,
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

  static TonePreset createMetalPreset() {
    final now = DateTime.now();
    return TonePreset(
      id: 'metal_default',
      name: 'Metal',
      description: 'Sonido metal con alta ganancia',
      genre: 'metal',
      ampModel: 'high_gain',
      eqSettings: {
        'bass': 0.7,
        'mid': 0.4,
        'treble': 0.9,
        'presence': 0.8,
      },
      effects: {
        'distortion': 0.9,
        'reverb': 0.1,
        'delay': 0.0,
        'chorus': 0.0,
      },
      gain: 0.9,
      volume: 0.8,
      isDefault: true,
      isCustom: false,
      createdAt: now,
      lastUsed: now,
    );
  }
}