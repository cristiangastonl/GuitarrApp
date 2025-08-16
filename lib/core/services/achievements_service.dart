import '../models/session.dart';
import '../storage/database_helper.dart';

enum AchievementType {
  practice,
  score,
  streak,
  speed,
  consistency,
  milestone,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final AchievementType type;
  final int requirement;
  final bool isUnlocked;
  final DateTime? unlockedDate;
  final String badgeColor;
  final int points;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.type,
    required this.requirement,
    this.isUnlocked = false,
    this.unlockedDate,
    this.badgeColor = 'blue',
    this.points = 10,
  });

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedDate,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      iconName: iconName,
      type: type,
      requirement: requirement,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      badgeColor: badgeColor,
      points: points,
    );
  }
}

class AchievementsService {
  static final List<Achievement> _allAchievements = [
    // Practice achievements
    Achievement(
      id: 'first_session',
      title: 'Primera Sesión',
      description: 'Completa tu primera sesión de práctica',
      iconName: 'play_circle',
      type: AchievementType.practice,
      requirement: 1,
      badgeColor: 'green',
      points: 5,
    ),
    Achievement(
      id: 'practice_10',
      title: 'Principiante Dedicado',
      description: 'Completa 10 sesiones de práctica',
      iconName: 'music_note',
      type: AchievementType.practice,
      requirement: 10,
      badgeColor: 'blue',
      points: 15,
    ),
    Achievement(
      id: 'practice_50',
      title: 'Guitarrista Comprometido',
      description: 'Completa 50 sesiones de práctica',
      iconName: 'star',
      type: AchievementType.practice,
      requirement: 50,
      badgeColor: 'purple',
      points: 25,
    ),
    Achievement(
      id: 'practice_100',
      title: 'Maestro Persistente',
      description: 'Completa 100 sesiones de práctica',
      iconName: 'emoji_events',
      type: AchievementType.practice,
      requirement: 100,
      badgeColor: 'gold',
      points: 50,
    ),

    // Score achievements
    Achievement(
      id: 'score_80',
      title: 'Buen Ritmo',
      description: 'Obtén un score de 80 o más',
      iconName: 'trending_up',
      type: AchievementType.score,
      requirement: 80,
      badgeColor: 'orange',
      points: 10,
    ),
    Achievement(
      id: 'score_90',
      title: 'Excelente Timing',
      description: 'Obtén un score de 90 o más',
      iconName: 'timer',
      type: AchievementType.score,
      requirement: 90,
      badgeColor: 'red',
      points: 20,
    ),
    Achievement(
      id: 'score_95',
      title: 'Casi Perfecto',
      description: 'Obtén un score de 95 o más',
      iconName: 'auto_awesome',
      type: AchievementType.score,
      requirement: 95,
      badgeColor: 'gold',
      points: 30,
    ),

    // Streak achievements
    Achievement(
      id: 'streak_3',
      title: 'En Racha',
      description: 'Practica 3 días consecutivos',
      iconName: 'local_fire_department',
      type: AchievementType.streak,
      requirement: 3,
      badgeColor: 'orange',
      points: 15,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Una Semana Completa',
      description: 'Practica 7 días consecutivos',
      iconName: 'whatshot',
      type: AchievementType.streak,
      requirement: 7,
      badgeColor: 'red',
      points: 25,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Mes de Dedicación',
      description: 'Practica 30 días consecutivos',
      iconName: 'local_fire_department',
      type: AchievementType.streak,
      requirement: 30,
      badgeColor: 'gold',
      points: 50,
    ),

    // Speed achievements
    Achievement(
      id: 'speed_100',
      title: 'Velocidad Moderada',
      description: 'Toca a 100 BPM o más',
      iconName: 'speed',
      type: AchievementType.speed,
      requirement: 100,
      badgeColor: 'blue',
      points: 10,
    ),
    Achievement(
      id: 'speed_150',
      title: 'Dedos Rápidos',
      description: 'Toca a 150 BPM o más',
      iconName: 'fast_forward',
      type: AchievementType.speed,
      requirement: 150,
      badgeColor: 'purple',
      points: 20,
    ),
    Achievement(
      id: 'speed_200',
      title: 'Lightning Fingers',
      description: 'Toca a 200 BPM o más',
      iconName: 'flash_on',
      type: AchievementType.speed,
      requirement: 200,
      badgeColor: 'gold',
      points: 40,
    ),

    // Consistency achievements
    Achievement(
      id: 'consistency_80',
      title: 'Ritmo Estable',
      description: 'Mantén 80% de consistencia en timing',
      iconName: 'balance',
      type: AchievementType.consistency,
      requirement: 80,
      badgeColor: 'green',
      points: 15,
    ),
    Achievement(
      id: 'consistency_90',
      title: 'Como un Metrónomo',
      description: 'Mantén 90% de consistencia en timing',
      iconName: 'adjust',
      type: AchievementType.consistency,
      requirement: 90,
      badgeColor: 'purple',
      points: 25,
    ),

    // Milestone achievements
    Achievement(
      id: 'hour_10',
      title: '10 Horas de Práctica',
      description: 'Acumula 10 horas de práctica total',
      iconName: 'schedule',
      type: AchievementType.milestone,
      requirement: 600, // minutes
      badgeColor: 'blue',
      points: 20,
    ),
    Achievement(
      id: 'hour_50',
      title: '50 Horas de Práctica',
      description: 'Acumula 50 horas de práctica total',
      iconName: 'access_time',
      type: AchievementType.milestone,
      requirement: 3000, // minutes
      badgeColor: 'purple',
      points: 50,
    ),
    Achievement(
      id: 'hour_100',
      title: '100 Horas de Práctica',
      description: 'Acumula 100 horas de práctica total',
      iconName: 'timer',
      type: AchievementType.milestone,
      requirement: 6000, // minutes
      badgeColor: 'gold',
      points: 100,
    ),
  ];

  /// Get all achievements with their unlock status
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final sessions = await DatabaseHelper.getAllSessions();
      final unlockedAchievements = await _getUnlockedAchievements();
      
      return _allAchievements.map((achievement) {
        final isUnlocked = _checkAchievementUnlocked(achievement, sessions);
        final existingUnlock = unlockedAchievements[achievement.id];
        
        return achievement.copyWith(
          isUnlocked: isUnlocked,
          unlockedDate: existingUnlock,
        );
      }).toList();
    } catch (e) {
      return _allAchievements;
    }
  }

  /// Check for newly unlocked achievements
  Future<List<Achievement>> checkNewAchievements(List<Session> sessions) async {
    final newlyUnlocked = <Achievement>[];
    final previouslyUnlocked = await _getUnlockedAchievements();
    
    for (final achievement in _allAchievements) {
      if (!previouslyUnlocked.containsKey(achievement.id) && 
          _checkAchievementUnlocked(achievement, sessions)) {
        newlyUnlocked.add(achievement.copyWith(
          isUnlocked: true,
          unlockedDate: DateTime.now(),
        ));
        await _saveUnlockedAchievement(achievement.id);
      }
    }
    
    return newlyUnlocked;
  }

  /// Get user's total achievement points
  Future<int> getTotalPoints() async {
    final unlocked = await _getUnlockedAchievements();
    return _allAchievements
        .where((a) => unlocked.containsKey(a.id))
        .fold<int>(0, (total, achievement) => total + achievement.points);
  }

  /// Get achievement stats
  Future<Map<String, dynamic>> getAchievementStats() async {
    final unlocked = await _getUnlockedAchievements();
    final totalPoints = await getTotalPoints();
    
    return {
      'unlockedCount': unlocked.length,
      'totalCount': _allAchievements.length,
      'totalPoints': totalPoints,
      'completionPercentage': (unlocked.length / _allAchievements.length * 100).round(),
    };
  }

  /// Check if specific achievement should be unlocked
  bool _checkAchievementUnlocked(Achievement achievement, List<Session> sessions) {
    switch (achievement.type) {
      case AchievementType.practice:
        return sessions.length >= achievement.requirement;
        
      case AchievementType.score:
        return sessions.any((s) => s.overallScore >= achievement.requirement);
        
      case AchievementType.streak:
        final streak = _calculateCurrentStreak(sessions);
        return streak >= achievement.requirement;
        
      case AchievementType.speed:
        return sessions.any((s) => s.targetBpm >= achievement.requirement);
        
      case AchievementType.consistency:
        return sessions.any((s) => s.consistencyScore >= achievement.requirement);
        
      case AchievementType.milestone:
        final totalMinutes = sessions.fold<int>(0, (total, s) => total + s.durationMinutes);
        return totalMinutes >= achievement.requirement;
    }
  }

  /// Calculate current practice streak
  int _calculateCurrentStreak(List<Session> sessions) {
    if (sessions.isEmpty) return 0;
    
    final sortedSessions = List<Session>.from(sessions)
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    
    final Set<String> practiceDays = {};
    for (final session in sortedSessions) {
      final dayKey = '${session.sessionDate.year}-${session.sessionDate.month}-${session.sessionDate.day}';
      practiceDays.add(dayKey);
    }
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    for (int i = 0; i < 365; i++) {
      final dayKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (practiceDays.contains(dayKey)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        if (i == 0) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }
    
    return streak;
  }

  /// Save unlocked achievement to preferences
  Future<void> _saveUnlockedAchievement(String achievementId) async {
    // TODO: Implement with SharedPreferences
    // For now, this is a placeholder
  }

  /// Get previously unlocked achievements
  Future<Map<String, DateTime>> _getUnlockedAchievements() async {
    // TODO: Implement with SharedPreferences
    // For now, return empty map
    return {};
  }
}