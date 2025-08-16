import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/stats_service.dart';
import '../../../../core/services/achievements_service.dart';
import '../../../../core/models/session.dart';
import '../../../../core/storage/database_helper.dart';

// Services
final statsServiceProvider = Provider<StatsService>((ref) => StatsService());
final achievementsServiceProvider = Provider<AchievementsService>((ref) => AchievementsService());

// User stats
final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final statsService = ref.read(statsServiceProvider);
  return await statsService.getUserStats();
});

// Historical data for charts
final historicalDataProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final statsService = ref.read(statsServiceProvider);
  return await statsService.getHistoricalData(days: days);
});

// All achievements
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final achievementsService = ref.read(achievementsServiceProvider);
  return await achievementsService.getAllAchievements();
});

// Achievement stats
final achievementStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final achievementsService = ref.read(achievementsServiceProvider);
  return await achievementsService.getAchievementStats();
});

// All sessions
final allSessionsProvider = FutureProvider<List<Session>>((ref) async {
  return await DatabaseHelper.getAllSessions();
});

// Best sessions (top 10 by score)
final bestSessionsProvider = FutureProvider<List<Session>>((ref) async {
  final sessions = await DatabaseHelper.getAllSessions();
  
  // Filter sessions with score >= 75 and sort by score descending
  final bestSessions = sessions
      .where((session) => session.overallScore >= 75)
      .toList()
    ..sort((a, b) => b.overallScore.compareTo(a.overallScore));
  
  // Return top 10
  return bestSessions.take(10).toList();
});

// Practice dates for streak calculation
final practiceDatesProvider = FutureProvider<List<DateTime>>((ref) async {
  final sessions = await DatabaseHelper.getAllSessions();
  
  // Get unique practice dates from last 30 days
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  final recentSessions = sessions
      .where((session) => session.sessionDate.isAfter(thirtyDaysAgo))
      .toList();
  
  final Set<String> uniqueDates = {};
  final List<DateTime> practiceDates = [];
  
  for (final session in recentSessions) {
    final dateKey = '${session.sessionDate.year}-${session.sessionDate.month.toString().padLeft(2, '0')}-${session.sessionDate.day.toString().padLeft(2, '0')}';
    if (!uniqueDates.contains(dateKey)) {
      uniqueDates.add(dateKey);
      practiceDates.add(DateTime(
        session.sessionDate.year,
        session.sessionDate.month,
        session.sessionDate.day,
      ));
    }
  }
  
  return practiceDates;
});

// Riff progress data
final riffProgressProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, riffId) async {
  final statsService = ref.read(statsServiceProvider);
  return await statsService.getRiffProgress(riffId);
});

// Recent sessions (last 20)
final recentSessionsProvider = FutureProvider<List<Session>>((ref) async {
  final sessions = await DatabaseHelper.getAllSessions();
  return sessions.take(20).toList();
});

// Weekly summary
final weeklySummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final sessions = await DatabaseHelper.getAllSessions();
  final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
  
  final weekSessions = sessions
      .where((session) => session.sessionDate.isAfter(oneWeekAgo))
      .toList();
  
  if (weekSessions.isEmpty) {
    return {
      'sessionsCount': 0,
      'totalMinutes': 0,
      'averageScore': 0.0,
      'averageBpm': 0,
      'improvement': 0.0,
      'topRiff': '',
    };
  }
  
  final totalMinutes = weekSessions.fold<int>(0, (sum, session) => sum + session.durationMinutes);
  final averageScore = weekSessions.map((s) => s.overallScore).reduce((a, b) => a + b) / weekSessions.length;
  final averageBpm = weekSessions.map((s) => s.targetBpm).reduce((a, b) => a + b) / weekSessions.length;
  
  // Calculate improvement compared to previous week
  final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
  final previousWeekSessions = sessions
      .where((session) => 
          session.sessionDate.isAfter(twoWeeksAgo) && 
          session.sessionDate.isBefore(oneWeekAgo))
      .toList();
  
  double improvement = 0.0;
  if (previousWeekSessions.isNotEmpty) {
    final previousAverage = previousWeekSessions.map((s) => s.overallScore).reduce((a, b) => a + b) / previousWeekSessions.length;
    improvement = averageScore - previousAverage;
  }
  
  // Find most practiced riff
  final riffCounts = <String, int>{};
  for (final session in weekSessions) {
    riffCounts[session.songRiffId] = (riffCounts[session.songRiffId] ?? 0) + 1;
  }
  
  String topRiff = '';
  int maxCount = 0;
  riffCounts.forEach((riff, count) {
    if (count > maxCount) {
      maxCount = count;
      topRiff = riff;
    }
  });
  
  return {
    'sessionsCount': weekSessions.length,
    'totalMinutes': totalMinutes,
    'averageScore': averageScore.round(),
    'averageBpm': averageBpm.round(),
    'improvement': improvement.round(),
    'topRiff': topRiff,
  };
});

// Monthly summary
final monthlySummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final sessions = await DatabaseHelper.getAllSessions();
  final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
  
  final monthSessions = sessions
      .where((session) => session.sessionDate.isAfter(oneMonthAgo))
      .toList();
  
  if (monthSessions.isEmpty) {
    return {
      'sessionsCount': 0,
      'totalMinutes': 0,
      'averageScore': 0.0,
      'uniqueRiffs': 0,
      'bestScore': 0,
      'totalPracticeHours': 0.0,
    };
  }
  
  final totalMinutes = monthSessions.fold<int>(0, (sum, session) => sum + session.durationMinutes);
  final averageScore = monthSessions.map((s) => s.overallScore).reduce((a, b) => a + b) / monthSessions.length;
  final bestScore = monthSessions.map((s) => s.overallScore).reduce((a, b) => a > b ? a : b);
  
  final uniqueRiffs = monthSessions.map((s) => s.songRiffId).toSet().length;
  
  return {
    'sessionsCount': monthSessions.length,
    'totalMinutes': totalMinutes,
    'averageScore': averageScore.round(),
    'uniqueRiffs': uniqueRiffs,
    'bestScore': bestScore.round(),
    'totalPracticeHours': (totalMinutes / 60).round(),
  };
});

// Check for new achievements
final newAchievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final achievementsService = ref.read(achievementsServiceProvider);
  final sessions = await DatabaseHelper.getAllSessions();
  return await achievementsService.checkNewAchievements(sessions);
});

// Refresh all providers
void refreshHistoryProviders(WidgetRef ref) {
  ref.invalidate(userStatsProvider);
  ref.invalidate(historicalDataProvider);
  ref.invalidate(achievementsProvider);
  ref.invalidate(achievementStatsProvider);
  ref.invalidate(allSessionsProvider);
  ref.invalidate(bestSessionsProvider);
  ref.invalidate(practiceDatesProvider);
  ref.invalidate(recentSessionsProvider);
  ref.invalidate(weeklySummaryProvider);
  ref.invalidate(monthlySummaryProvider);
  ref.invalidate(newAchievementsProvider);
}