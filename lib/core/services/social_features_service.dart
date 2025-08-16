import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import 'stats_service.dart';

/// Social Features Service
/// Handles sharing progress, friend challenges, and community features
class SocialFeaturesService {
  final StatsService _statsService;
  
  // Simulated data - in production this would connect to a backend
  final Map<String, UserProfile> _userProfiles = {};
  final Map<String, List<String>> _friendships = {};
  final List<Challenge> _activeChallenges = [];
  final List<SocialPost> _socialPosts = [];
  final Map<String, List<Achievement>> _userAchievements = {};
  
  SocialFeaturesService(this._statsService) {
    _initializeSampleData();
  }
  
  /// Get user's social profile
  Future<UserProfile> getUserProfile(String userId) async {
    return _userProfiles[userId] ?? UserProfile.defaultProfile(userId);
  }
  
  /// Update user's social profile
  Future<void> updateUserProfile(UserProfile profile) async {
    _userProfiles[profile.userId] = profile;
  }
  
  /// Get user's friends list
  Future<List<UserProfile>> getUserFriends(String userId) async {
    final friendIds = _friendships[userId] ?? [];
    return friendIds.map((id) => _userProfiles[id] ?? UserProfile.defaultProfile(id)).toList();
  }
  
  /// Send friend request
  Future<bool> sendFriendRequest(String fromUserId, String toUserId) async {
    // In a real app, this would send a notification to the target user
    // For now, we'll auto-accept to simulate the feature
    await _addFriendship(fromUserId, toUserId);
    return true;
  }
  
  /// Add friendship (mutual)
  Future<void> _addFriendship(String userId1, String userId2) async {
    _friendships[userId1] ??= [];
    _friendships[userId2] ??= [];
    
    if (!_friendships[userId1]!.contains(userId2)) {
      _friendships[userId1]!.add(userId2);
    }
    if (!_friendships[userId2]!.contains(userId1)) {
      _friendships[userId2]!.add(userId1);
    }
  }
  
  /// Share practice achievement
  Future<SocialPost> shareAchievement({
    required String userId,
    required String achievementId,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final userProfile = await getUserProfile(userId);
    
    final post = SocialPost(
      id: _generatePostId(),
      userId: userId,
      userName: userProfile.displayName,
      userAvatar: userProfile.avatarUrl,
      type: SocialPostType.achievement,
      content: description,
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
      likes: 0,
      comments: [],
    );
    
    _socialPosts.insert(0, post); // Add to beginning for newest first
    return post;
  }
  
  /// Share practice session
  Future<SocialPost> sharePracticeSession({
    required String userId,
    required Session session,
    String? customMessage,
  }) async {
    final userProfile = await getUserProfile(userId);
    
    final content = customMessage ?? 
        'Just practiced for ${session.durationMinutes} minutes at ${session.targetBpm} BPM! 🎸';
    
    final metadata = {
      'sessionId': session.id,
      'bpm': session.targetBpm,
      'accuracy': session.accuracy,
      'duration': session.durationMinutes,
      'score': session.overallScore,
    };
    
    final post = SocialPost(
      id: _generatePostId(),
      userId: userId,
      userName: userProfile.displayName,
      userAvatar: userProfile.avatarUrl,
      type: SocialPostType.practiceSession,
      content: content,
      metadata: metadata,
      timestamp: DateTime.now(),
      likes: 0,
      comments: [],
    );
    
    _socialPosts.insert(0, post);
    return post;
  }
  
  /// Get social feed for user (friends' activities)
  Future<List<SocialPost>> getSocialFeed(String userId, {int limit = 20}) async {
    final friendIds = _friendships[userId] ?? [];
    friendIds.add(userId); // Include user's own posts
    
    final feedPosts = _socialPosts
        .where((post) => friendIds.contains(post.userId))
        .take(limit)
        .toList();
    
    return feedPosts;
  }
  
  /// Get community leaderboard
  Future<List<LeaderboardEntry>> getCommunityLeaderboard({
    LeaderboardType type = LeaderboardType.weeklyScore,
    int limit = 10,
  }) async {
    final entries = <LeaderboardEntry>[];
    
    for (final userId in _userProfiles.keys) {
      final profile = _userProfiles[userId]!;
      final stats = await _calculateUserStats(userId, type);
      
      entries.add(LeaderboardEntry(
        userId: userId,
        userName: profile.displayName,
        userAvatar: profile.avatarUrl,
        score: stats.score,
        rank: 0, // Will be set after sorting
        metadata: stats.metadata,
      ));
    }
    
    // Sort by score (descending)
    entries.sort((a, b) => b.score.compareTo(a.score));
    
    // Set ranks
    for (int i = 0; i < entries.length; i++) {
      entries[i] = entries[i].copyWith(rank: i + 1);
    }
    
    return entries.take(limit).toList();
  }
  
  /// Create practice challenge
  Future<Challenge> createChallenge({
    required String creatorId,
    required String challengeeName,
    required String description,
    required ChallengeType type,
    required Map<String, dynamic> parameters,
    required Duration duration,
    List<String>? invitedFriends,
  }) async {
    final challenge = Challenge(
      id: _generateChallengeId(),
      creatorId: creatorId,
      name: challengeeName,
      description: description,
      type: type,
      parameters: parameters,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(duration),
      participants: {creatorId: ChallengeParticipant.creator(creatorId)},
      status: ChallengeStatus.active,
      createdAt: DateTime.now(),
    );
    
    _activeChallenges.add(challenge);
    
    // Send invitations
    if (invitedFriends != null) {
      for (final friendId in invitedFriends) {
        await _sendChallengeInvitation(challenge.id, friendId);
      }
    }
    
    return challenge;
  }
  
  /// Join challenge
  Future<bool> joinChallenge(String challengeId, String userId) async {
    final challengeIndex = _activeChallenges.indexWhere((c) => c.id == challengeId);
    if (challengeIndex == -1) return false;
    
    final challenge = _activeChallenges[challengeIndex];
    if (challenge.status != ChallengeStatus.active) return false;
    
    final participant = ChallengeParticipant.participant(userId);
    final updatedChallenge = challenge.copyWith(
      participants: {...challenge.participants, userId: participant},
    );
    
    _activeChallenges[challengeIndex] = updatedChallenge;
    return true;
  }
  
  /// Get user's active challenges
  Future<List<Challenge>> getUserChallenges(String userId) async {
    return _activeChallenges
        .where((challenge) => 
            challenge.participants.containsKey(userId) &&
            challenge.status == ChallengeStatus.active)
        .toList();
  }
  
  /// Update challenge progress
  Future<void> updateChallengeProgress(String challengeId, String userId, Map<String, dynamic> progress) async {
    final challengeIndex = _activeChallenges.indexWhere((c) => c.id == challengeId);
    if (challengeIndex == -1) return;
    
    final challenge = _activeChallenges[challengeIndex];
    final participant = challenge.participants[userId];
    if (participant == null) return;
    
    final updatedParticipant = participant.copyWith(
      progress: {...participant.progress, ...progress},
      lastUpdated: DateTime.now(),
    );
    
    final updatedChallenge = challenge.copyWith(
      participants: {
        ...challenge.participants,
        userId: updatedParticipant,
      },
    );
    
    _activeChallenges[challengeIndex] = updatedChallenge;
  }
  
  /// Like a social post
  Future<void> likePost(String postId, String userId) async {
    final postIndex = _socialPosts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;
    
    final post = _socialPosts[postIndex];
    final newLikes = post.likedBy.contains(userId) 
        ? post.likes - 1
        : post.likes + 1;
    
    final newLikedBy = post.likedBy.contains(userId)
        ? post.likedBy.where((id) => id != userId).toList()
        : [...post.likedBy, userId];
    
    _socialPosts[postIndex] = post.copyWith(
      likes: newLikes,
      likedBy: newLikedBy,
    );
  }
  
  /// Add comment to post
  Future<void> addComment(String postId, String userId, String comment) async {
    final postIndex = _socialPosts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;
    
    final userProfile = await getUserProfile(userId);
    final post = _socialPosts[postIndex];
    
    final newComment = SocialComment(
      id: _generateCommentId(),
      userId: userId,
      userName: userProfile.displayName,
      userAvatar: userProfile.avatarUrl,
      content: comment,
      timestamp: DateTime.now(),
    );
    
    _socialPosts[postIndex] = post.copyWith(
      comments: [...post.comments, newComment],
    );
  }
  
  /// Get user achievements
  Future<List<Achievement>> getUserAchievements(String userId) async {
    return _userAchievements[userId] ?? [];
  }
  
  /// Award achievement to user
  Future<void> awardAchievement(String userId, Achievement achievement) async {
    _userAchievements[userId] ??= [];
    
    // Check if user already has this achievement
    final existingIndex = _userAchievements[userId]!
        .indexWhere((a) => a.id == achievement.id);
    
    if (existingIndex == -1) {
      _userAchievements[userId]!.add(achievement);
      
      // Share achievement automatically if it's shareable
      if (achievement.isShareable) {
        await shareAchievement(
          userId: userId,
          achievementId: achievement.id,
          description: 'Unlocked "${achievement.title}" achievement! ${achievement.description}',
          metadata: {
            'achievementId': achievement.id,
            'achievementType': achievement.type.name,
          },
        );
      }
    }
  }
  
  // Helper methods
  Future<UserStats> _calculateUserStats(String userId, LeaderboardType type) async {
    final sessions = await _statsService.getUserSessions(userId);
    
    switch (type) {
      case LeaderboardType.weeklyScore:
        final weekSessions = sessions.where((s) => 
            s.startTime.isAfter(DateTime.now().subtract(const Duration(days: 7)))).toList();
        final score = weekSessions.isEmpty ? 0.0 :
            weekSessions.map((s) => s.overallScore).reduce((a, b) => a + b) / weekSessions.length;
        return UserStats(score, {'sessions': weekSessions.length});
        
      case LeaderboardType.totalPracticeTime:
        final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
        return UserStats(totalMinutes.toDouble(), {'totalHours': totalMinutes / 60});
        
      case LeaderboardType.consistency:
        final daysWithPractice = sessions
            .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
            .toSet()
            .length;
        return UserStats(daysWithPractice.toDouble(), {'uniqueDays': daysWithPractice});
        
      case LeaderboardType.averageBpm:
        final avgBpm = sessions.isEmpty ? 0.0 :
            sessions.map((s) => s.targetBpm).reduce((a, b) => a + b) / sessions.length;
        return UserStats(avgBpm, {'totalSessions': sessions.length});
    }
  }
  
  void _initializeSampleData() {
    // Create sample user profiles
    _userProfiles['user_1'] = UserProfile(
      userId: 'user_1',
      displayName: 'GuitarHero92',
      avatarUrl: 'https://example.com/avatar1.jpg',
      level: 15,
      totalPracticeHours: 120,
      favoriteTechniques: ['alternate-picking', 'power-chords'],
      joinedDate: DateTime.now().subtract(const Duration(days: 90)),
    );
    
    _userProfiles['user_2'] = UserProfile(
      userId: 'user_2',
      displayName: 'MetalMaster',
      avatarUrl: 'https://example.com/avatar2.jpg',
      level: 22,
      totalPracticeHours: 200,
      favoriteTechniques: ['palm-muting', 'tremolo-picking'],
      joinedDate: DateTime.now().subtract(const Duration(days: 180)),
    );
    
    _userProfiles['user_3'] = UserProfile(
      userId: 'user_3',
      displayName: 'BluesLover',
      avatarUrl: 'https://example.com/avatar3.jpg',
      level: 18,
      totalPracticeHours: 150,
      favoriteTechniques: ['bending', 'vibrato'],
      joinedDate: DateTime.now().subtract(const Duration(days: 120)),
    );
    
    // Create friendships
    _friendships['user_1'] = ['user_2', 'user_3'];
    _friendships['user_2'] = ['user_1'];
    _friendships['user_3'] = ['user_1'];
    
    // Create sample social posts
    _socialPosts.addAll([
      SocialPost(
        id: 'post_1',
        userId: 'user_2',
        userName: 'MetalMaster',
        userAvatar: 'https://example.com/avatar2.jpg',
        type: SocialPostType.achievement,
        content: 'Just unlocked "Speed Demon" achievement! 🔥 Hit 180 BPM on alternate picking!',
        metadata: {'achievementId': 'speed_demon', 'bpm': 180},
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 5,
        likedBy: ['user_1', 'user_3'],
        comments: [
          SocialComment(
            id: 'comment_1',
            userId: 'user_1',
            userName: 'GuitarHero92',
            userAvatar: 'https://example.com/avatar1.jpg',
            content: 'Awesome! I\'m still working on 160 BPM 😅',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      SocialPost(
        id: 'post_2',
        userId: 'user_3',
        userName: 'BluesLover',
        userAvatar: 'https://example.com/avatar3.jpg',
        type: SocialPostType.practiceSession,
        content: 'Great practice session! Worked on bending techniques for 45 minutes 🎸',
        metadata: {'duration': 45, 'technique': 'bending', 'score': 85},
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        likes: 3,
        likedBy: ['user_1'],
        comments: [],
      ),
    ]);
    
    // Create sample achievements
    _userAchievements['user_1'] = [
      Achievement(
        id: 'first_practice',
        title: 'First Steps',
        description: 'Complete your first practice session',
        type: AchievementType.milestone,
        iconUrl: 'https://example.com/achievement1.png',
        earnedAt: DateTime.now().subtract(const Duration(days: 30)),
        isShareable: true,
      ),
    ];
  }
  
  Future<void> _sendChallengeInvitation(String challengeId, String userId) async {
    // In a real app, this would send a push notification or in-app notification
    // For now, we'll simulate by auto-joining some users
    if (Random().nextBool()) {
      await joinChallenge(challengeId, userId);
    }
  }
  
  String _generatePostId() => 'post_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  String _generateChallengeId() => 'challenge_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  String _generateCommentId() => 'comment_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
}

// Data Models
class UserProfile {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int level;
  final int totalPracticeHours;
  final List<String> favoriteTechniques;
  final DateTime joinedDate;
  final String? bio;
  final bool isPublic;
  
  const UserProfile({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.level,
    required this.totalPracticeHours,
    required this.favoriteTechniques,
    required this.joinedDate,
    this.bio,
    this.isPublic = true,
  });
  
  factory UserProfile.defaultProfile(String userId) {
    return UserProfile(
      userId: userId,
      displayName: 'Player$userId',
      level: 1,
      totalPracticeHours: 0,
      favoriteTechniques: [],
      joinedDate: DateTime.now(),
    );
  }
  
  UserProfile copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    int? level,
    int? totalPracticeHours,
    List<String>? favoriteTechniques,
    DateTime? joinedDate,
    String? bio,
    bool? isPublic,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      totalPracticeHours: totalPracticeHours ?? this.totalPracticeHours,
      favoriteTechniques: favoriteTechniques ?? this.favoriteTechniques,
      joinedDate: joinedDate ?? this.joinedDate,
      bio: bio ?? this.bio,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}

class SocialPost {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final SocialPostType type;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final int likes;
  final List<String> likedBy;
  final List<SocialComment> comments;
  
  const SocialPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.type,
    required this.content,
    required this.metadata,
    required this.timestamp,
    required this.likes,
    this.likedBy = const [],
    this.comments = const [],
  });
  
  SocialPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    SocialPostType? type,
    String? content,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    int? likes,
    List<String>? likedBy,
    List<SocialComment>? comments,
  }) {
    return SocialPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      type: type ?? this.type,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
    );
  }
}

class SocialComment {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime timestamp;
  
  const SocialComment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.timestamp,
  });
}

class Challenge {
  final String id;
  final String creatorId;
  final String name;
  final String description;
  final ChallengeType type;
  final Map<String, dynamic> parameters;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, ChallengeParticipant> participants;
  final ChallengeStatus status;
  final DateTime createdAt;
  
  const Challenge({
    required this.id,
    required this.creatorId,
    required this.name,
    required this.description,
    required this.type,
    required this.parameters,
    required this.startTime,
    required this.endTime,
    required this.participants,
    required this.status,
    required this.createdAt,
  });
  
  Challenge copyWith({
    String? id,
    String? creatorId,
    String? name,
    String? description,
    ChallengeType? type,
    Map<String, dynamic>? parameters,
    DateTime? startTime,
    DateTime? endTime,
    Map<String, ChallengeParticipant>? participants,
    ChallengeStatus? status,
    DateTime? createdAt,
  }) {
    return Challenge(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      parameters: parameters ?? this.parameters,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }
  
  bool get isActive => status == ChallengeStatus.active && DateTime.now().isBefore(endTime);
}

class ChallengeParticipant {
  final String userId;
  final ChallengeRole role;
  final Map<String, dynamic> progress;
  final DateTime joinedAt;
  final DateTime lastUpdated;
  
  const ChallengeParticipant({
    required this.userId,
    required this.role,
    required this.progress,
    required this.joinedAt,
    required this.lastUpdated,
  });
  
  factory ChallengeParticipant.creator(String userId) {
    return ChallengeParticipant(
      userId: userId,
      role: ChallengeRole.creator,
      progress: {},
      joinedAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }
  
  factory ChallengeParticipant.participant(String userId) {
    return ChallengeParticipant(
      userId: userId,
      role: ChallengeRole.participant,
      progress: {},
      joinedAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }
  
  ChallengeParticipant copyWith({
    String? userId,
    ChallengeRole? role,
    Map<String, dynamic>? progress,
    DateTime? joinedAt,
    DateTime? lastUpdated,
  }) {
    return ChallengeParticipant(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      progress: progress ?? this.progress,
      joinedAt: joinedAt ?? this.joinedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? userAvatar;
  final double score;
  final int rank;
  final Map<String, dynamic> metadata;
  
  const LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.score,
    required this.rank,
    required this.metadata,
  });
  
  LeaderboardEntry copyWith({
    String? userId,
    String? userName,
    String? userAvatar,
    double? score,
    int? rank,
    Map<String, dynamic>? metadata,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      metadata: metadata ?? this.metadata,
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final String? iconUrl;
  final DateTime earnedAt;
  final bool isShareable;
  final Map<String, dynamic> metadata;
  
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.iconUrl,
    required this.earnedAt,
    this.isShareable = true,
    this.metadata = const {},
  });
}

class UserStats {
  final double score;
  final Map<String, dynamic> metadata;
  
  const UserStats(this.score, this.metadata);
}

// Enums
enum SocialPostType {
  achievement,
  practiceSession,
  challenge,
  milestone,
  general,
}

enum ChallengeType {
  practiceTime,
  bpmGoal,
  techniqueChallenge,
  consistencyChallenge,
  skillImprovement,
}

enum ChallengeStatus {
  active,
  completed,
  cancelled,
}

enum ChallengeRole {
  creator,
  participant,
}

enum LeaderboardType {
  weeklyScore,
  totalPracticeTime,
  consistency,
  averageBpm,
}

enum AchievementType {
  milestone,
  skill,
  consistency,
  social,
  special,
}

class SocialFeaturesException implements Exception {
  final String message;
  
  const SocialFeaturesException(this.message);
  
  @override
  String toString() => 'SocialFeaturesException: $message';
}

// Riverpod providers
final socialFeaturesServiceProvider = Provider<SocialFeaturesService>((ref) {
  final statsService = ref.read(statsServiceProvider);
  return SocialFeaturesService(statsService);
});

final userProfileProvider = FutureProvider.family<UserProfile, String>((ref, userId) async {
  final service = ref.read(socialFeaturesServiceProvider);
  return service.getUserProfile(userId);
});

final userFriendsProvider = FutureProvider.family<List<UserProfile>, String>((ref, userId) async {
  final service = ref.read(socialFeaturesServiceProvider);
  return service.getUserFriends(userId);
});

final socialFeedProvider = FutureProvider.family<List<SocialPost>, String>((ref, userId) async {
  final service = ref.read(socialFeaturesServiceProvider);
  return service.getSocialFeed(userId);
});

final communityLeaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, LeaderboardType>((ref, type) async {
  final service = ref.read(socialFeaturesServiceProvider);
  return service.getCommunityLeaderboard(type: type);
});

final userChallengesProvider = FutureProvider.family<List<Challenge>, String>((ref, userId) async {
  final service = ref.read(socialFeaturesServiceProvider);
  return service.getUserChallenges(userId);
});

final userAchievementsProvider = FutureProvider.family<List<Achievement>, String>((ref, userId) async {
  final service = ref.read(socialFeaturesServiceProvider);
  return service.getUserAchievements(userId);
});