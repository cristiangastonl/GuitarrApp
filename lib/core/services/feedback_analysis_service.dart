import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'recording_service.dart';
import 'backing_track_service.dart';
import '../audio/metronome_service.dart';

/// Analysis result for a practice session
class SessionAnalysis {
  final String sessionId;
  final String riffId;
  final DateTime timestamp;
  final Duration recordingDuration;
  final int targetBpm;
  final int recordedBpm;
  
  // Analysis metrics
  final double timingConsistency; // 0.0 - 1.0
  final double tempoAccuracy; // 0.0 - 1.0 
  final double sessionProgress; // 0.0 - 1.0
  final int practiceFrequency; // sessions in last week
  
  // Calculated scores
  final double timingScore; // 0-100
  final double consistencyScore; // 0-100
  final double progressScore; // 0-100
  final double frequencyScore; // 0-100
  final double overallScore; // 0-100
  
  const SessionAnalysis({
    required this.sessionId,
    required this.riffId,
    required this.timestamp,
    required this.recordingDuration,
    required this.targetBpm,
    required this.recordedBpm,
    required this.timingConsistency,
    required this.tempoAccuracy,
    required this.sessionProgress,
    required this.practiceFrequency,
    required this.timingScore,
    required this.consistencyScore,
    required this.progressScore,
    required this.frequencyScore,
    required this.overallScore,
  });
  
  /// Performance level based on overall score
  PerformanceLevel get performanceLevel {
    if (overallScore >= 90) return PerformanceLevel.excellent;
    if (overallScore >= 80) return PerformanceLevel.great;
    if (overallScore >= 70) return PerformanceLevel.good;
    if (overallScore >= 60) return PerformanceLevel.fair;
    return PerformanceLevel.needsWork;
  }
  
  /// Get the strongest skill area
  SkillArea get strongestSkill {
    final scores = {
      SkillArea.timing: timingScore,
      SkillArea.consistency: consistencyScore,
      SkillArea.progress: progressScore,
      SkillArea.frequency: frequencyScore,
    };
    
    return scores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  /// Get the area that needs most improvement
  SkillArea get improvementArea {
    final scores = {
      SkillArea.timing: timingScore,
      SkillArea.consistency: consistencyScore,
      SkillArea.progress: progressScore,
      SkillArea.frequency: frequencyScore,
    };
    
    return scores.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }
}

/// Performance level categories
enum PerformanceLevel {
  excellent,
  great,
  good,
  fair,
  needsWork;
  
  String get displayName {
    switch (this) {
      case PerformanceLevel.excellent:
        return 'Excelente';
      case PerformanceLevel.great:
        return 'Muy Bien';
      case PerformanceLevel.good:
        return 'Bien';
      case PerformanceLevel.fair:
        return 'Regular';
      case PerformanceLevel.needsWork:
        return 'Necesita Práctica';
    }
  }
  
  String get emoji {
    switch (this) {
      case PerformanceLevel.excellent:
        return '🔥';
      case PerformanceLevel.great:
        return '🎸';
      case PerformanceLevel.good:
        return '👍';
      case PerformanceLevel.fair:
        return '📈';
      case PerformanceLevel.needsWork:
        return '💪';
    }
  }
}

/// Skill areas for analysis
enum SkillArea {
  timing,
  consistency,
  progress,
  frequency;
  
  String get displayName {
    switch (this) {
      case SkillArea.timing:
        return 'Timing';
      case SkillArea.consistency:
        return 'Consistencia';
      case SkillArea.progress:
        return 'Progreso';
      case SkillArea.frequency:
        return 'Frecuencia';
    }
  }
}

/// Historical session data for tracking progress
class SessionHistory {
  final List<SessionAnalysis> sessions;
  final String riffId;
  
  const SessionHistory({
    required this.sessions,
    required this.riffId,
  });
  
  /// Get sessions from the last N days
  List<SessionAnalysis> getRecentSessions(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return sessions
        .where((session) => session.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  /// Calculate average score improvement over time
  double get scoreImprovement {
    if (sessions.length < 2) return 0.0;
    
    final recent = getRecentSessions(7);
    final older = sessions
        .where((s) => !recent.contains(s))
        .toList();
    
    if (recent.isEmpty || older.isEmpty) return 0.0;
    
    final recentAvg = recent
        .map((s) => s.overallScore)
        .reduce((a, b) => a + b) / recent.length;
    
    final olderAvg = older
        .map((s) => s.overallScore)
        .reduce((a, b) => a + b) / older.length;
    
    return recentAvg - olderAvg;
  }
  
  /// Get best session
  SessionAnalysis? get bestSession {
    if (sessions.isEmpty) return null;
    return sessions.reduce((a, b) => a.overallScore > b.overallScore ? a : b);
  }
  
  /// Calculate practice streak in days
  int get practiceStreak {
    if (sessions.isEmpty) return 0;
    
    var streak = 0;
    var currentDate = DateTime.now();
    
    // Group sessions by date
    final sessionsByDate = <DateTime, List<SessionAnalysis>>{};
    for (final session in sessions) {
      final date = DateTime(
        session.timestamp.year,
        session.timestamp.month,
        session.timestamp.day,
      );
      sessionsByDate.putIfAbsent(date, () => []).add(session);
    }
    
    // Count consecutive days with practice
    while (true) {
      final checkDate = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
      );
      
      if (sessionsByDate.containsKey(checkDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }
}

/// Service for analyzing practice session recordings and generating feedback
class FeedbackAnalysisService {
  final Ref _ref;
  final Map<String, SessionHistory> _sessionHistories = {};
  
  FeedbackAnalysisService(this._ref);
  
  /// Analyze a completed recording session
  Future<SessionAnalysis> analyzeSession({
    required RecordingFile recording,
    required String riffId,
    required int targetBpm,
  }) async {
    final sessionId = _generateSessionId();
    final timestamp = recording.createdAt;
    final recordedBpm = recording.bpm ?? targetBpm;
    
    // Get historical data for this riff
    final history = _sessionHistories[riffId] ?? 
        const SessionHistory(sessions: [], riffId: '');
    
    // Calculate analysis metrics
    final timingConsistency = _calculateTimingConsistency(
      recording.duration,
      targetBpm,
      recordedBpm,
    );
    
    final tempoAccuracy = _calculateTempoAccuracy(targetBpm, recordedBpm);
    
    final sessionProgress = _calculateSessionProgress(history, targetBpm);
    
    final practiceFrequency = _calculatePracticeFrequency(history);
    
    // Calculate individual scores
    final timingScore = _calculateTimingScore(timingConsistency, tempoAccuracy);
    final consistencyScore = _calculateConsistencyScore(history, timingConsistency);
    final progressScore = _calculateProgressScore(sessionProgress, history);
    final frequencyScore = _calculateFrequencyScore(practiceFrequency);
    
    // Calculate weighted overall score
    final overallScore = _calculateOverallScore(
      timingScore: timingScore,
      consistencyScore: consistencyScore,
      progressScore: progressScore,
      frequencyScore: frequencyScore,
    );
    
    final analysis = SessionAnalysis(
      sessionId: sessionId,
      riffId: riffId,
      timestamp: timestamp,
      recordingDuration: recording.duration,
      targetBpm: targetBpm,
      recordedBpm: recordedBpm,
      timingConsistency: timingConsistency,
      tempoAccuracy: tempoAccuracy,
      sessionProgress: sessionProgress,
      practiceFrequency: practiceFrequency,
      timingScore: timingScore,
      consistencyScore: consistencyScore,
      progressScore: progressScore,
      frequencyScore: frequencyScore,
      overallScore: overallScore,
    );
    
    // Update history
    _updateSessionHistory(riffId, analysis);
    
    return analysis;
  }
  
  /// Get session history for a specific riff
  SessionHistory getSessionHistory(String riffId) {
    return _sessionHistories[riffId] ?? 
        SessionHistory(sessions: const [], riffId: riffId);
  }
  
  /// Get overall user statistics across all riffs
  Map<String, dynamic> getOverallStats() {
    final allSessions = _sessionHistories.values
        .expand((history) => history.sessions)
        .toList();
    
    if (allSessions.isEmpty) {
      return {
        'totalSessions': 0,
        'averageScore': 0.0,
        'totalPracticeTime': Duration.zero,
        'longestStreak': 0,
        'favoriteRiff': null,
      };
    }
    
    final totalSessions = allSessions.length;
    final averageScore = allSessions
        .map((s) => s.overallScore)
        .reduce((a, b) => a + b) / totalSessions;
    
    final totalPracticeTime = allSessions
        .map((s) => s.recordingDuration)
        .reduce((a, b) => a + b);
    
    final longestStreak = _sessionHistories.values
        .map((history) => history.practiceStreak)
        .fold(0, (max, streak) => streak > max ? streak : max);
    
    // Find most practiced riff
    final riffCounts = <String, int>{};
    for (final session in allSessions) {
      riffCounts[session.riffId] = (riffCounts[session.riffId] ?? 0) + 1;
    }
    
    final favoriteRiff = riffCounts.isNotEmpty
        ? riffCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : null;
    
    return {
      'totalSessions': totalSessions,
      'averageScore': averageScore,
      'totalPracticeTime': totalPracticeTime,
      'longestStreak': longestStreak,
      'favoriteRiff': favoriteRiff,
    };
  }
  
  // Private helper methods
  
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Calculate timing consistency based on recording duration vs expected duration
  double _calculateTimingConsistency(Duration recordingDuration, int targetBpm, int recordedBpm) {
    // Expected duration for a typical riff practice (assume 30 seconds at target BPM)
    const baseSeconds = 30.0;
    final expectedDuration = Duration(seconds: baseSeconds.round());
    
    // Calculate how close the recording duration is to expected
    final durationRatio = recordingDuration.inMilliseconds / expectedDuration.inMilliseconds;
    
    // Closer to 1.0 means better consistency
    final consistency = 1.0 - (durationRatio - 1.0).abs().clamp(0.0, 1.0);
    
    return consistency;
  }
  
  /// Calculate tempo accuracy based on target vs recorded BPM
  double _calculateTempoAccuracy(int targetBpm, int recordedBpm) {
    final difference = (targetBpm - recordedBpm).abs();
    final accuracy = 1.0 - (difference / targetBpm).clamp(0.0, 1.0);
    return accuracy;
  }
  
  /// Calculate session progress based on historical improvement
  double _calculateSessionProgress(SessionHistory history, int targetBpm) {
    if (history.sessions.isEmpty) return 0.5; // Neutral for first session
    
    final recentSessions = history.getRecentSessions(7);
    if (recentSessions.isEmpty) return 0.5;
    
    // Look at BPM progression over time
    final avgRecentBpm = recentSessions
        .map((s) => s.recordedBpm)
        .reduce((a, b) => a + b) / recentSessions.length;
    
    final progressRatio = avgRecentBpm / targetBpm;
    return progressRatio.clamp(0.0, 1.0);
  }
  
  /// Calculate practice frequency in the last week
  int _calculatePracticeFrequency(SessionHistory history) {
    return history.getRecentSessions(7).length;
  }
  
  /// Convert timing consistency and accuracy to a score
  double _calculateTimingScore(double consistency, double accuracy) {
    return ((consistency * 0.6 + accuracy * 0.4) * 100).clamp(0.0, 100.0);
  }
  
  /// Calculate consistency score based on historical variance
  double _calculateConsistencyScore(SessionHistory history, double currentConsistency) {
    if (history.sessions.length < 3) {
      return (currentConsistency * 80).clamp(0.0, 100.0); // Less confident with limited data
    }
    
    final recentSessions = history.getRecentSessions(7);
    final consistencies = recentSessions.map((s) => s.timingConsistency).toList();
    
    // Calculate variance in consistency
    final avg = consistencies.reduce((a, b) => a + b) / consistencies.length;
    final variance = consistencies
        .map((c) => (c - avg) * (c - avg))
        .reduce((a, b) => a + b) / consistencies.length;
    
    final consistencyScore = (1.0 - variance) * 100;
    return consistencyScore.clamp(0.0, 100.0);
  }
  
  /// Calculate progress score based on improvement over time
  double _calculateProgressScore(double sessionProgress, SessionHistory history) {
    final baseScore = sessionProgress * 60; // Base score from current progress
    
    // Bonus for showing improvement
    final improvement = history.scoreImprovement;
    final improvementBonus = (improvement * 0.4).clamp(0.0, 40.0);
    
    return (baseScore + improvementBonus).clamp(0.0, 100.0);
  }
  
  /// Calculate frequency score based on practice regularity
  double _calculateFrequencyScore(int frequency) {
    // Optimal frequency is practicing every day (7 sessions per week)
    final optimalFrequency = 7;
    final frequencyRatio = (frequency / optimalFrequency).clamp(0.0, 1.0);
    
    // Bonus for consistency even if not daily
    final consistencyBonus = frequency >= 3 ? 10.0 : 0.0;
    
    return (frequencyRatio * 90 + consistencyBonus).clamp(0.0, 100.0);
  }
  
  /// Calculate weighted overall score
  double _calculateOverallScore({
    required double timingScore,
    required double consistencyScore,
    required double progressScore,
    required double frequencyScore,
  }) {
    // Weights: 40% timing, 30% progress, 20% consistency, 10% frequency
    final weightedScore = (timingScore * 0.4) +
                         (progressScore * 0.3) +
                         (consistencyScore * 0.2) +
                         (frequencyScore * 0.1);
    
    return weightedScore.clamp(0.0, 100.0);
  }
  
  /// Update session history with new analysis
  void _updateSessionHistory(String riffId, SessionAnalysis analysis) {
    final currentHistory = _sessionHistories[riffId] ?? 
        SessionHistory(sessions: const [], riffId: riffId);
    
    final updatedSessions = [...currentHistory.sessions, analysis];
    
    // Keep only last 50 sessions per riff to manage memory
    if (updatedSessions.length > 50) {
      updatedSessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      updatedSessions.removeRange(50, updatedSessions.length);
    }
    
    _sessionHistories[riffId] = SessionHistory(
      sessions: updatedSessions,
      riffId: riffId,
    );
  }
}

/// Provider for the feedback analysis service
final feedbackAnalysisServiceProvider = Provider<FeedbackAnalysisService>((ref) {
  return FeedbackAnalysisService(ref);
});

/// Provider for getting session history for a specific riff
final sessionHistoryProvider = Provider.family<SessionHistory, String>((ref, riffId) {
  final service = ref.watch(feedbackAnalysisServiceProvider);
  return service.getSessionHistory(riffId);
});

/// Provider for overall user statistics
final overallStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(feedbackAnalysisServiceProvider);
  return service.getOverallStats();
});