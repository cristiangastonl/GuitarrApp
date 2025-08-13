class SongRiff {
  final String id;
  final String name;
  final String artistName;
  final String genre;
  final String difficulty; // 'easy', 'medium', 'hard'
  final int targetBpm;
  final int startingBpm;
  final List<String> techniques; // ['palm-muting', 'bending', 'vibrato', etc.]
  final String tabNotation;
  final String audioPath;
  final String? videoPath;
  final String description;
  final int durationSeconds;
  final bool hasGhostNotes;
  final DateTime createdAt;

  const SongRiff({
    required this.id,
    required this.name,
    required this.artistName,
    required this.genre,
    required this.difficulty,
    required this.targetBpm,
    required this.startingBpm,
    required this.techniques,
    required this.tabNotation,
    required this.audioPath,
    this.videoPath,
    required this.description,
    required this.durationSeconds,
    this.hasGhostNotes = false,
    required this.createdAt,
  });

  factory SongRiff.fromJson(Map<String, dynamic> json) {
    return SongRiff(
      id: json['id'] as String,
      name: json['name'] as String,
      artistName: json['artistName'] as String,
      genre: json['genre'] as String,
      difficulty: json['difficulty'] as String,
      targetBpm: json['targetBpm'] as int,
      startingBpm: json['startingBpm'] as int,
      techniques: List<String>.from(json['techniques'] as List),
      tabNotation: json['tabNotation'] as String,
      audioPath: json['audioPath'] as String,
      videoPath: json['videoPath'] as String?,
      description: json['description'] as String,
      durationSeconds: json['durationSeconds'] as int,
      hasGhostNotes: json['hasGhostNotes'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artistName': artistName,
      'genre': genre,
      'difficulty': difficulty,
      'targetBpm': targetBpm,
      'startingBpm': startingBpm,
      'techniques': techniques,
      'tabNotation': tabNotation,
      'audioPath': audioPath,
      'videoPath': videoPath,
      'description': description,
      'durationSeconds': durationSeconds,
      'hasGhostNotes': hasGhostNotes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  SongRiff copyWith({
    String? id,
    String? name,
    String? artistName,
    String? genre,
    String? difficulty,
    int? targetBpm,
    int? startingBpm,
    List<String>? techniques,
    String? tabNotation,
    String? audioPath,
    String? videoPath,
    String? description,
    int? durationSeconds,
    bool? hasGhostNotes,
    DateTime? createdAt,
  }) {
    return SongRiff(
      id: id ?? this.id,
      name: name ?? this.name,
      artistName: artistName ?? this.artistName,
      genre: genre ?? this.genre,
      difficulty: difficulty ?? this.difficulty,
      targetBpm: targetBpm ?? this.targetBpm,
      startingBpm: startingBpm ?? this.startingBpm,
      techniques: techniques ?? this.techniques,
      tabNotation: tabNotation ?? this.tabNotation,
      audioPath: audioPath ?? this.audioPath,
      videoPath: videoPath ?? this.videoPath,
      description: description ?? this.description,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      hasGhostNotes: hasGhostNotes ?? this.hasGhostNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SongRiff &&
        other.id == id &&
        other.name == name &&
        other.artistName == artistName &&
        other.genre == genre &&
        other.difficulty == difficulty &&
        other.targetBpm == targetBpm &&
        other.startingBpm == startingBpm &&
        other.techniques.toString() == techniques.toString() &&
        other.tabNotation == tabNotation &&
        other.audioPath == audioPath &&
        other.videoPath == videoPath &&
        other.description == description &&
        other.durationSeconds == durationSeconds &&
        other.hasGhostNotes == hasGhostNotes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      artistName,
      genre,
      difficulty,
      targetBpm,
      startingBpm,
      techniques,
      tabNotation,
      audioPath,
      videoPath,
      description,
      durationSeconds,
      hasGhostNotes,
      createdAt,
    );
  }
}