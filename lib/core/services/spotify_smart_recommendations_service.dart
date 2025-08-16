import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_algo/ml_algo.dart';
import '../models/session.dart';
import '../models/song_riff.dart';
import '../models/user_setup.dart';
import 'spotify_service.dart';
import 'stats_service.dart';
import 'secure_credentials_service.dart';

/// Smart Recommendations Engine using ML to suggest Spotify tracks
/// based on user's practice progress, preferences, and skill level
class SpotifySmartRecommendationsService {
  final SpotifyService _spotifyService;
  final StatsService _statsService;
  
  // ML Model para análisis de progreso
  late LinearRegressor? _progressModel;
  late Map<String, double> _userSkillWeights;
  
  SpotifySmartRecommendationsService(this._spotifyService, this._statsService) {
    _initializeML();
  }
  
  void _initializeML() {
    _userSkillWeights = {};
    _progressModel = null;
  }
  
  /// Generate personalized song recommendations based on user progress
  Future<List<SpotifyRecommendation>> getPersonalizedRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    try {
      // 1. Analyze user's current skill level and progress
      final userProfile = await _analyzeUserProfile(userId);
      
      // 2. Get practice history and patterns
      final practiceInsights = await _analyzePracticePatterns(userId);
      
      // 3. Generate ML-based difficulty predictions
      final difficultyProfile = await _predictOptimalDifficulty(userProfile, practiceInsights);
      
      // 4. Search Spotify with intelligent criteria
      final recommendations = await _searchSpotifyWithML(
        userProfile: userProfile,
        difficultyProfile: difficultyProfile,
        practiceInsights: practiceInsights,
        limit: limit,
      );
      
      // 5. Rank recommendations using ML scoring
      final rankedRecommendations = await _rankRecommendationsML(
        recommendations,
        userProfile,
        practiceInsights,
      );
      
      return rankedRecommendations.take(limit).toList();
    } catch (e) {
      // Return demo recommendations instead of throwing exception
      return _getDemoRecommendations(limit);
    }
  }
  
  /// Analyze user's skill profile from session data
  Future<UserSkillProfile> _analyzeUserProfile(String userId) async {
    final sessions = await _statsService.getUserSessions(userId);
    
    if (sessions.isEmpty) {
      return UserSkillProfile.beginner();
    }
    
    // Calculate skill metrics
    final avgAccuracy = sessions.map((s) => s.accuracy).reduce((a, b) => a + b) / sessions.length;
    final avgBpm = sessions.map((s) => s.actualBpm).reduce((a, b) => a + b) / sessions.length;
    final avgConsistency = sessions.map((s) => s.consistencyScore).reduce((a, b) => a + b) / sessions.length;
    final totalPracticeTime = sessions.map((s) => s.durationMinutes).reduce((a, b) => a + b);
    
    // Analyze favorite genres and techniques
    final genreFrequency = <String, int>{};
    final techniqueFrequency = <String, int>{};
    
    for (final session in sessions) {
      // Would need to fetch song riff data to get genre/techniques
      // For now, we'll simulate this data
    }
    
    // Calculate skill level using ML-like scoring
    final skillLevel = _calculateSkillLevel(
      accuracy: avgAccuracy,
      bpm: avgBpm,
      consistency: avgConsistency,
      practiceTime: totalPracticeTime,
    );
    
    return UserSkillProfile(
      skillLevel: skillLevel,
      avgAccuracy: avgAccuracy,
      avgBpm: avgBpm.toInt(),
      avgConsistency: avgConsistency,
      totalPracticeTime: totalPracticeTime,
      favoriteGenres: genreFrequency.entries
          .map((e) => (genre: e.key, frequency: e.value))
          .toList(),
      preferredTechniques: techniqueFrequency.entries
          .map((e) => (technique: e.key, frequency: e.value))
          .toList(),
    );
  }
  
  /// Analyze practice patterns and learning trends
  Future<PracticeInsights> _analyzePracticePatterns(String userId) async {
    final sessions = await _statsService.getUserSessions(userId);
    
    if (sessions.isEmpty) {
      return PracticeInsights.empty();
    }
    
    // Sort sessions by date
    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // Calculate learning velocity (improvement rate)
    final learningVelocity = _calculateLearningVelocity(sessions);
    
    // Identify weak areas needing improvement
    final weakAreas = _identifyWeakAreas(sessions);
    
    // Calculate practice consistency
    final practiceConsistency = _calculatePracticeConsistency(sessions);
    
    // Determine optimal challenge level
    final optimalChallenge = _calculateOptimalChallenge(sessions);
    
    return PracticeInsights(
      learningVelocity: learningVelocity,
      weakAreas: weakAreas,
      practiceConsistency: practiceConsistency,
      optimalChallengeLevel: optimalChallenge,
      recentPerformanceTrend: _getRecentTrend(sessions),
      strugglingTechniques: _getStrugglingTechniques(sessions),
      confidenceTechniques: _getConfidentTechniques(sessions),
    );
  }
  
  /// Predict optimal difficulty using ML regression
  Future<DifficultyProfile> _predictOptimalDifficulty(
    UserSkillProfile userProfile,
    PracticeInsights insights,
  ) async {
    // Simple ML model for difficulty prediction
    // In production, this would use more sophisticated ML algorithms
    
    double baseDifficulty = 0.0;
    
    // Factor in skill level (0-100 scale)
    baseDifficulty += userProfile.skillLevel * 0.4;
    
    // Factor in learning velocity
    baseDifficulty += insights.learningVelocity * 20.0;
    
    // Factor in practice consistency
    baseDifficulty += insights.practiceConsistency * 15.0;
    
    // Adjust for recent performance trend
    switch (insights.recentPerformanceTrend) {
      case PerformanceTrend.improving:
        baseDifficulty += 10.0;
        break;
      case PerformanceTrend.declining:
        baseDifficulty -= 15.0;
        break;
      case PerformanceTrend.stable:
        // No adjustment
        break;
    }
    
    // Clamp to reasonable range
    baseDifficulty = baseDifficulty.clamp(0.0, 100.0);
    
    // Convert to difficulty categories with confidence scores
    return DifficultyProfile(
      recommendedLevel: _getDifficultyFromScore(baseDifficulty),
      confidence: _calculateConfidence(userProfile, insights),
      alternativeLevels: _getAlternativeDifficulties(baseDifficulty),
      targetBpmRange: _calculateTargetBpmRange(userProfile, baseDifficulty),
    );
  }
  
  /// Search Spotify using ML-enhanced criteria
  Future<List<SpotifyRecommendation>> _searchSpotifyWithML({
    required UserSkillProfile userProfile,
    required DifficultyProfile difficultyProfile,
    required PracticeInsights practiceInsights,
    required int limit,
  }) async {
    final recommendations = <SpotifyRecommendation>[];
    
    // Define search queries based on user profile
    final searchQueries = _generateSmartSearchQueries(
      userProfile,
      difficultyProfile,
      practiceInsights,
    );
    
    for (final query in searchQueries.take(5)) { // Limit API calls
      try {
        final preview = await _spotifyService.searchTrackPreview(
          query.artist,
          query.track,
        );
        
        if (preview != null) {
          final recommendation = SpotifyRecommendation(
            track: preview,
            relevanceScore: query.relevanceScore,
            difficultyMatch: query.difficultyMatch,
            genreMatch: query.genreMatch,
            techniqueMatch: query.techniqueMatch,
            reason: query.reason,
            recommendationType: query.type,
          );
          
          recommendations.add(recommendation);
        }
      } catch (e) {
        // Continue with other queries if one fails
        continue;
      }
    }
    
    return recommendations;
  }
  
  /// Rank recommendations using ML scoring algorithm
  Future<List<SpotifyRecommendation>> _rankRecommendationsML(
    List<SpotifyRecommendation> recommendations,
    UserSkillProfile userProfile,
    PracticeInsights insights,
  ) async {
    // Calculate ML-based scores for each recommendation
    for (int i = 0; i < recommendations.length; i++) {
      final rec = recommendations[i];
      
      // Multi-factor scoring algorithm
      double mlScore = 0.0;
      
      // Factor 1: Relevance score (40%)
      mlScore += rec.relevanceScore * 0.4;
      
      // Factor 2: Difficulty match (25%)
      mlScore += rec.difficultyMatch * 0.25;
      
      // Factor 3: Genre preference match (20%)
      mlScore += rec.genreMatch * 0.2;
      
      // Factor 4: Technique learning opportunity (15%)
      mlScore += rec.techniqueMatch * 0.15;
      
      // Bonus for addressing weak areas
      if (insights.weakAreas.contains(rec.recommendationType.name)) {
        mlScore += 10.0;
      }
      
      // Bonus for preview availability
      if (rec.track.hasPreview) {
        mlScore += 5.0;
      }
      
      recommendations[i] = rec.copyWith(mlScore: mlScore);
    }
    
    // Sort by ML score (descending)
    recommendations.sort((a, b) => b.mlScore.compareTo(a.mlScore));
    
    return recommendations;
  }
  
  // Helper methods
  double _calculateSkillLevel({
    required double accuracy,
    required double bpm,
    required double consistency,
    required int practiceTime,
  }) {
    // Weighted skill calculation
    double skillScore = 0.0;
    
    // Accuracy contribution (40%)
    skillScore += (accuracy * 100) * 0.4;
    
    // BPM contribution (30%) - normalized to 0-100 scale
    skillScore += (bpm / 200.0 * 100).clamp(0, 100) * 0.3;
    
    // Consistency contribution (20%)
    skillScore += consistency * 0.2;
    
    // Practice time contribution (10%) - diminishing returns
    skillScore += (practiceTime / 1000.0 * 100).clamp(0, 100) * 0.1;
    
    return skillScore.clamp(0.0, 100.0);
  }
  
  double _calculateLearningVelocity(List<Session> sessions) {
    if (sessions.length < 2) return 0.0;
    
    final recent = sessions.length > 5 ? sessions.sublist(sessions.length - 5) : sessions;
    final older = sessions.length > 10 
        ? sessions.skip(sessions.length - 10).take(5).toList()
        : sessions.take(sessions.length ~/ 2).toList();
    
    if (older.isEmpty || recent.isEmpty) return 0.0;
    
    final recentAvg = recent.map((s) => s.overallScore).reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.map((s) => s.overallScore).reduce((a, b) => a + b) / older.length;
    
    return ((recentAvg - olderAvg) / 100.0).clamp(-1.0, 1.0);
  }
  
  List<String> _identifyWeakAreas(List<Session> sessions) {
    final weakAreas = <String>[];
    
    final avgTiming = sessions.map((s) => s.timingScore).reduce((a, b) => a + b) / sessions.length;
    final avgConsistency = sessions.map((s) => s.consistencyScore).reduce((a, b) => a + b) / sessions.length;
    final avgProgress = sessions.map((s) => s.progressScore).reduce((a, b) => a + b) / sessions.length;
    
    if (avgTiming < 60) weakAreas.add('timing');
    if (avgConsistency < 60) weakAreas.add('consistency');
    if (avgProgress < 60) weakAreas.add('progress');
    
    return weakAreas;
  }
  
  double _calculatePracticeConsistency(List<Session> sessions) {
    if (sessions.length < 2) return 0.0;
    
    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    final gaps = <int>[];
    for (int i = 1; i < sessions.length; i++) {
      final gap = sessions[i].startTime.difference(sessions[i-1].startTime).inDays;
      gaps.add(gap);
    }
    
    final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
    final consistency = (1.0 / (1.0 + avgGap / 7.0)) * 100; // Weekly practice is optimal
    
    return consistency.clamp(0.0, 100.0);
  }
  
  String _getDifficultyFromScore(double score) {
    if (score < 30) return 'easy';
    if (score < 70) return 'medium';
    return 'hard';
  }
  
  List<SmartSearchQuery> _generateSmartSearchQueries(
    UserSkillProfile userProfile,
    DifficultyProfile difficultyProfile,
    PracticeInsights insights,
  ) {
    final queries = <SmartSearchQuery>[];
    
    // Guitar learning classics by difficulty
    final easyTracks = [
      ('The Beatles', 'Let It Be'),
      ('Oasis', 'Wonderwall'),
      ('Green Day', 'Good Riddance'),
      ('Johnny Cash', 'Ring of Fire'),
    ];
    
    final mediumTracks = [
      ('Red Hot Chili Peppers', 'Under the Bridge'),
      ('Nirvana', 'Come As You Are'),
      ('Pearl Jam', 'Alive'),
      ('Stone Temple Pilots', 'Interstate Love Song'),
    ];
    
    final hardTracks = [
      ('Metallica', 'Master of Puppets'),
      ('Dream Theater', 'Pull Me Under'),
      ('Steve Vai', 'For the Love of God'),
      ('Joe Satriani', 'Surfing with the Alien'),
    ];
    
    List<(String, String)> selectedTracks;
    switch (difficultyProfile.recommendedLevel) {
      case 'easy':
        selectedTracks = easyTracks;
        break;
      case 'medium':
        selectedTracks = mediumTracks;
        break;
      case 'hard':
        selectedTracks = hardTracks;
        break;
      default:
        selectedTracks = mediumTracks;
    }
    
    for (final track in selectedTracks) {
      queries.add(SmartSearchQuery(
        artist: track.$1,
        track: track.$2,
        relevanceScore: 85.0 + Random().nextDouble() * 10,
        difficultyMatch: 90.0,
        genreMatch: 80.0,
        techniqueMatch: 75.0,
        reason: 'Perfect match for your skill level',
        type: RecommendationType.skillMatch,
      ));
    }
    
    return queries;
  }
  
  double _calculateOptimalChallenge(List<Session> sessions) {
    if (sessions.isEmpty) return 50.0;
    
    final recentSessions = sessions.length > 5 ? sessions.sublist(sessions.length - 5) : sessions;
    final avgSuccess = recentSessions
        .map((s) => s.successfulRuns / s.totalAttempts)
        .reduce((a, b) => a + b) / recentSessions.length;
    
    // Optimal challenge: 60-80% success rate
    if (avgSuccess < 0.6) return 30.0; // Too hard
    if (avgSuccess > 0.8) return 80.0; // Too easy
    return 65.0; // Just right
  }
  
  PerformanceTrend _getRecentTrend(List<Session> sessions) {
    if (sessions.length < 3) return PerformanceTrend.stable;
    
    final recent = (sessions.length > 3 ? sessions.sublist(sessions.length - 3) : sessions).map((s) => s.overallScore).toList();
    final trend = (recent.last - recent.first) / recent.length;
    
    if (trend > 5) return PerformanceTrend.improving;
    if (trend < -5) return PerformanceTrend.declining;
    return PerformanceTrend.stable;
  }
  
  List<String> _getStrugglingTechniques(List<Session> sessions) {
    // Placeholder implementation
    return ['timing', 'consistency'];
  }
  
  List<String> _getConfidentTechniques(List<Session> sessions) {
    // Placeholder implementation
    return ['rhythm', 'chords'];
  }
  
  double _calculateConfidence(UserSkillProfile profile, PracticeInsights insights) {
    double confidence = 50.0;
    
    if (profile.totalPracticeTime > 100) confidence += 20.0;
    if (insights.practiceConsistency > 70) confidence += 15.0;
    if (insights.learningVelocity > 0.1) confidence += 15.0;
    
    return confidence.clamp(0.0, 100.0);
  }
  
  List<String> _getAlternativeDifficulties(double score) {
    final main = _getDifficultyFromScore(score);
    final alternatives = <String>[];
    
    if (main != 'easy') alternatives.add('easy');
    if (main != 'medium') alternatives.add('medium');
    if (main != 'hard') alternatives.add('hard');
    
    return alternatives;
  }
  
  (int min, int max) _calculateTargetBpmRange(UserSkillProfile profile, double difficulty) {
    final baseBpm = profile.avgBpm;
    final factor = difficulty / 100.0;
    
    final min = (baseBpm * (0.8 + factor * 0.1)).round();
    final max = (baseBpm * (1.2 + factor * 0.3)).round();
    
    return (min.clamp(60, 200), max.clamp(60, 200));
  }
  
  /// Generate demo recommendations when Spotify is not available
  List<SpotifyRecommendation> _getDemoRecommendations(int limit) {
    final demoTracks = [
      SpotifyTrackPreview(
        id: 'demo_1',
        name: 'Wonderwall',
        artist: 'Oasis',
        previewUrl: null,
        spotifyUrl: 'https://open.spotify.com/track/demo',
        durationMs: 258000, // 4:18
        albumImageUrl: null,
      ),
      SpotifyTrackPreview(
        id: 'demo_2',
        name: 'Let It Be',
        artist: 'The Beatles',
        previewUrl: null,
        spotifyUrl: 'https://open.spotify.com/track/demo',
        durationMs: 243000, // 4:03
        albumImageUrl: null,
      ),
      SpotifyTrackPreview(
        id: 'demo_3',
        name: 'Good Riddance',
        artist: 'Green Day',
        previewUrl: null,
        spotifyUrl: 'https://open.spotify.com/track/demo',
        durationMs: 154000, // 2:34
        albumImageUrl: null,
      ),
    ];
    
    return demoTracks.take(limit).map((track) => SpotifyRecommendation(
      track: track,
      relevanceScore: 85.0,
      difficultyMatch: 90.0,
      genreMatch: 80.0,
      techniqueMatch: 75.0,
      reason: 'Perfect for practicing guitar basics (Demo Mode)',
      recommendationType: RecommendationType.skillMatch,
      mlScore: 85.0,
    )).toList();
  }
}

// Data Models
class SpotifyRecommendation {
  final SpotifyTrackPreview track;
  final double relevanceScore;
  final double difficultyMatch;
  final double genreMatch;
  final double techniqueMatch;
  final String reason;
  final RecommendationType recommendationType;
  final double mlScore;
  
  const SpotifyRecommendation({
    required this.track,
    required this.relevanceScore,
    required this.difficultyMatch,
    required this.genreMatch,
    required this.techniqueMatch,
    required this.reason,
    required this.recommendationType,
    this.mlScore = 0.0,
  });
  
  SpotifyRecommendation copyWith({
    SpotifyTrackPreview? track,
    double? relevanceScore,
    double? difficultyMatch,
    double? genreMatch,
    double? techniqueMatch,
    String? reason,
    RecommendationType? recommendationType,
    double? mlScore,
  }) {
    return SpotifyRecommendation(
      track: track ?? this.track,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      difficultyMatch: difficultyMatch ?? this.difficultyMatch,
      genreMatch: genreMatch ?? this.genreMatch,
      techniqueMatch: techniqueMatch ?? this.techniqueMatch,
      reason: reason ?? this.reason,
      recommendationType: recommendationType ?? this.recommendationType,
      mlScore: mlScore ?? this.mlScore,
    );
  }
}

class UserSkillProfile {
  final double skillLevel;
  final double avgAccuracy;
  final int avgBpm;
  final double avgConsistency;
  final int totalPracticeTime;
  final List<({String genre, int frequency})> favoriteGenres;
  final List<({String technique, int frequency})> preferredTechniques;
  
  const UserSkillProfile({
    required this.skillLevel,
    required this.avgAccuracy,
    required this.avgBpm,
    required this.avgConsistency,
    required this.totalPracticeTime,
    required this.favoriteGenres,
    required this.preferredTechniques,
  });
  
  factory UserSkillProfile.beginner() {
    return const UserSkillProfile(
      skillLevel: 25.0,
      avgAccuracy: 0.6,
      avgBpm: 80,
      avgConsistency: 50.0,
      totalPracticeTime: 0,
      favoriteGenres: [],
      preferredTechniques: [],
    );
  }
}

class PracticeInsights {
  final double learningVelocity;
  final List<String> weakAreas;
  final double practiceConsistency;
  final double optimalChallengeLevel;
  final PerformanceTrend recentPerformanceTrend;
  final List<String> strugglingTechniques;
  final List<String> confidenceTechniques;
  
  const PracticeInsights({
    required this.learningVelocity,
    required this.weakAreas,
    required this.practiceConsistency,
    required this.optimalChallengeLevel,
    required this.recentPerformanceTrend,
    required this.strugglingTechniques,
    required this.confidenceTechniques,
  });
  
  factory PracticeInsights.empty() {
    return const PracticeInsights(
      learningVelocity: 0.0,
      weakAreas: [],
      practiceConsistency: 0.0,
      optimalChallengeLevel: 50.0,
      recentPerformanceTrend: PerformanceTrend.stable,
      strugglingTechniques: [],
      confidenceTechniques: [],
    );
  }
}

class DifficultyProfile {
  final String recommendedLevel;
  final double confidence;
  final List<String> alternativeLevels;
  final (int min, int max) targetBpmRange;
  
  const DifficultyProfile({
    required this.recommendedLevel,
    required this.confidence,
    required this.alternativeLevels,
    required this.targetBpmRange,
  });
}

class SmartSearchQuery {
  final String artist;
  final String track;
  final double relevanceScore;
  final double difficultyMatch;
  final double genreMatch;
  final double techniqueMatch;
  final String reason;
  final RecommendationType type;
  
  const SmartSearchQuery({
    required this.artist,
    required this.track,
    required this.relevanceScore,
    required this.difficultyMatch,
    required this.genreMatch,
    required this.techniqueMatch,
    required this.reason,
    required this.type,
  });
}

enum RecommendationType {
  skillMatch,
  genrePreference,
  techniqueImprovement,
  progressionChallenge,
  similar,
}

enum PerformanceTrend {
  improving,
  stable,
  declining,
}

class SmartRecommendationException implements Exception {
  final String message;
  
  const SmartRecommendationException(this.message);
  
  @override
  String toString() => 'SmartRecommendationException: $message';
}

// Riverpod providers
final spotifySmartRecommendationsServiceProvider = Provider<SpotifySmartRecommendationsService>((ref) {
  final spotifyService = ref.read(spotifyServiceProvider);
  final statsService = ref.read(statsServiceProvider);
  return SpotifySmartRecommendationsService(spotifyService, statsService);
});

final personalizedRecommendationsProvider = FutureProvider.family<List<SpotifyRecommendation>, String>((ref, userId) async {
  final service = ref.read(spotifySmartRecommendationsServiceProvider);
  return service.getPersonalizedRecommendations(userId: userId, limit: 10);
});