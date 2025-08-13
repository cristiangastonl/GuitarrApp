class UserSetup {
  final String id;
  final String playerName;
  final String skillLevel; // 'beginner', 'intermediate', 'advanced'
  final List<String> preferredGenres;
  final int practiceTimeMinutes;
  final bool metronomeEnabled;
  final double metronomeVolume;
  final DateTime createdAt;
  final DateTime lastPracticeDate;

  const UserSetup({
    required this.id,
    required this.playerName,
    required this.skillLevel,
    required this.preferredGenres,
    required this.practiceTimeMinutes,
    this.metronomeEnabled = true,
    this.metronomeVolume = 0.7,
    required this.createdAt,
    required this.lastPracticeDate,
  });

  factory UserSetup.fromJson(Map<String, dynamic> json) {
    return UserSetup(
      id: json['id'] as String,
      playerName: json['playerName'] as String,
      skillLevel: json['skillLevel'] as String,
      preferredGenres: List<String>.from(json['preferredGenres'] as List),
      practiceTimeMinutes: json['practiceTimeMinutes'] as int,
      metronomeEnabled: json['metronomeEnabled'] as bool? ?? true,
      metronomeVolume: (json['metronomeVolume'] as num?)?.toDouble() ?? 0.7,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastPracticeDate: DateTime.parse(json['lastPracticeDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerName': playerName,
      'skillLevel': skillLevel,
      'preferredGenres': preferredGenres,
      'practiceTimeMinutes': practiceTimeMinutes,
      'metronomeEnabled': metronomeEnabled,
      'metronomeVolume': metronomeVolume,
      'createdAt': createdAt.toIso8601String(),
      'lastPracticeDate': lastPracticeDate.toIso8601String(),
    };
  }

  UserSetup copyWith({
    String? id,
    String? playerName,
    String? skillLevel,
    List<String>? preferredGenres,
    int? practiceTimeMinutes,
    bool? metronomeEnabled,
    double? metronomeVolume,
    DateTime? createdAt,
    DateTime? lastPracticeDate,
  }) {
    return UserSetup(
      id: id ?? this.id,
      playerName: playerName ?? this.playerName,
      skillLevel: skillLevel ?? this.skillLevel,
      preferredGenres: preferredGenres ?? this.preferredGenres,
      practiceTimeMinutes: practiceTimeMinutes ?? this.practiceTimeMinutes,
      metronomeEnabled: metronomeEnabled ?? this.metronomeEnabled,
      metronomeVolume: metronomeVolume ?? this.metronomeVolume,
      createdAt: createdAt ?? this.createdAt,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSetup &&
        other.id == id &&
        other.playerName == playerName &&
        other.skillLevel == skillLevel &&
        other.preferredGenres.toString() == preferredGenres.toString() &&
        other.practiceTimeMinutes == practiceTimeMinutes &&
        other.metronomeEnabled == metronomeEnabled &&
        other.metronomeVolume == metronomeVolume &&
        other.createdAt == createdAt &&
        other.lastPracticeDate == lastPracticeDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      playerName,
      skillLevel,
      preferredGenres,
      practiceTimeMinutes,
      metronomeEnabled,
      metronomeVolume,
      createdAt,
      lastPracticeDate,
    );
  }
}