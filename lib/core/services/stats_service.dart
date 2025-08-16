import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../storage/database_helper.dart';

class StatsService {
  /// Get all sessions for a specific user
  Future<List<Session>> getUserSessions(String userId) async {
    try {
      final allSessions = await DatabaseHelper.getAllSessions();
      return allSessions.where((session) => session.userId == userId).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get user statistics for different time periods
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final sessions = await DatabaseHelper.getAllSessions();
      
      final now = DateTime.now();
      final thisWeek = now.subtract(const Duration(days: 7));
      final thisMonth = now.subtract(const Duration(days: 30));
      
      // Weekly stats
      final weekSessions = sessions.where((s) => s.sessionDate.isAfter(thisWeek)).toList();
      final weeklyScore = weekSessions.isEmpty ? 0.0 : 
          weekSessions.map((s) => s.overallScore).reduce((a, b) => a + b) / weekSessions.length;
      
      // Monthly stats  
      final monthSessions = sessions.where((s) => s.sessionDate.isAfter(thisMonth)).toList();
      final monthlyScore = monthSessions.isEmpty ? 0.0 :
          monthSessions.map((s) => s.overallScore).reduce((a, b) => a + b) / monthSessions.length;
      
      // All time stats
      final allTimeScore = sessions.isEmpty ? 0.0 :
          sessions.map((s) => s.overallScore).reduce((a, b) => a + b) / sessions.length;
      
      // Best performance
      final bestSession = sessions.isEmpty ? null :
          sessions.reduce((a, b) => a.overallScore > b.overallScore ? a : b);
      
      // Total practice time
      final totalPracticeMinutes = sessions.fold<int>(0, (total, session) => 
          total + session.durationMinutes);
      
      // Practice streak
      final streak = _calculatePracticeStreak(sessions);
      
      return {
        'totalSessions': sessions.length,
        'weekSessions': weekSessions.length,
        'monthSessions': monthSessions.length,
        'weeklyScore': weeklyScore.round(),
        'monthlyScore': monthlyScore.round(),
        'allTimeScore': allTimeScore.round(),
        'bestScore': bestSession?.overallScore ?? 0,
        'bestSessionRiff': bestSession?.songRiffId ?? '',
        'totalPracticeHours': (totalPracticeMinutes / 60).round(),
        'totalPracticeMinutes': totalPracticeMinutes,
        'currentStreak': streak['current'],
        'longestStreak': streak['longest'],
        'averageBpm': _calculateAverageBpm(sessions),
        'improvementTrend': _calculateImprovementTrend(sessions),
      };
    } catch (e) {
      return {
        'totalSessions': 0,
        'weekSessions': 0,
        'monthSessions': 0,
        'weeklyScore': 0,
        'monthlyScore': 0,
        'allTimeScore': 0,
        'bestScore': 0,
        'bestSessionRiff': '',
        'totalPracticeHours': 0,
        'totalPracticeMinutes': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'averageBpm': 0,
        'improvementTrend': 'stable',
      };
    }
  }

  /// Get historical data for charts
  Future<List<Map<String, dynamic>>> getHistoricalData({int days = 30}) async {
    try {
      final sessions = await DatabaseHelper.getAllSessions();
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final recentSessions = sessions
          .where((s) => s.sessionDate.isAfter(cutoffDate))
          .toList()
        ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));
      
      // Group by day
      final Map<String, List<Session>> sessionsByDay = {};
      
      for (final session in recentSessions) {
        final dayKey = '${session.sessionDate.year}-${session.sessionDate.month.toString().padLeft(2, '0')}-${session.sessionDate.day.toString().padLeft(2, '0')}';
        sessionsByDay[dayKey] ??= [];
        sessionsByDay[dayKey]!.add(session);
      }
      
      // Calculate daily averages
      final List<Map<String, dynamic>> chartData = [];
      
      for (final entry in sessionsByDay.entries) {
        final daySessions = entry.value;
        final avgScore = daySessions.map((s) => s.overallScore).reduce((a, b) => a + b) / daySessions.length;
        final avgBpm = daySessions.map((s) => s.targetBpm).reduce((a, b) => a + b) / daySessions.length;
        final totalMinutes = daySessions.fold<int>(0, (total, s) => total + s.durationMinutes);
        
        chartData.add({
          'date': entry.key,
          'avgScore': avgScore.round(),
          'avgBpm': avgBpm.round(),
          'sessions': daySessions.length,
          'totalMinutes': totalMinutes,
          'dateTime': daySessions.first.sessionDate,
        });
      }
      
      return chartData;
    } catch (e) {
      return [];
    }
  }

  /// Get progress data for specific riff
  Future<List<Map<String, dynamic>>> getRiffProgress(String riffId) async {
    try {
      final sessions = await DatabaseHelper.getSessionsByRiff(riffId);
      
      return sessions.map((session) => {
        'date': session.sessionDate,
        'score': session.overallScore,
        'bpm': session.targetBpm,
        'timingScore': session.timingScore,
        'consistencyScore': session.consistencyScore,
        'progressScore': session.progressScore,
        'frequencyScore': session.frequencyScore,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Calculate practice streak
  Map<String, int> _calculatePracticeStreak(List<Session> sessions) {
    if (sessions.isEmpty) return {'current': 0, 'longest': 0};
    
    // Sort sessions by date (newest first)
    final sortedSessions = List<Session>.from(sessions)
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    
    // Group by day
    final Set<String> practiceDays = {};
    for (final session in sortedSessions) {
      final dayKey = '${session.sessionDate.year}-${session.sessionDate.month}-${session.sessionDate.day}';
      practiceDays.add(dayKey);
    }
    
    final sortedDays = practiceDays.toList()..sort((a, b) => b.compareTo(a));
    
    // Calculate current streak
    int currentStreak = 0;
    final today = DateTime.now();
    DateTime checkDate = today;
    
    for (int i = 0; i < 365; i++) { // Max 365 days check
      final dayKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (sortedDays.contains(dayKey)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // Allow one day gap for "current" streak
        if (i == 0) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }
    
    // Calculate longest streak
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;
    
    for (final dayString in sortedDays.reversed) {
      final parts = dayString.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      
      if (lastDate == null || date.difference(lastDate).inDays == 1) {
        tempStreak++;
        longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
      } else {
        tempStreak = 1;
      }
      lastDate = date;
    }
    
    return {'current': currentStreak, 'longest': longestStreak};
  }

  /// Calculate average BPM
  int _calculateAverageBpm(List<Session> sessions) {
    if (sessions.isEmpty) return 0;
    final totalBpm = sessions.fold<int>(0, (total, session) => total + session.targetBpm);
    return (totalBpm / sessions.length).round();
  }

  /// Calculate improvement trend
  String _calculateImprovementTrend(List<Session> sessions) {
    if (sessions.length < 10) return 'insufficient_data';
    
    final recentSessions = sessions
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    
    final recent10 = recentSessions.take(10).toList();
    final previous10 = recentSessions.skip(10).take(10).toList();
    
    if (previous10.length < 10) return 'insufficient_data';
    
    final recentAvg = recent10.map((s) => s.overallScore).reduce((a, b) => a + b) / 10;
    final previousAvg = previous10.map((s) => s.overallScore).reduce((a, b) => a + b) / 10;
    
    final improvement = recentAvg - previousAvg;
    
    if (improvement > 5) return 'improving';
    if (improvement < -5) return 'declining';
    return 'stable';
  }
}

// Riverpod provider
final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsService();
});