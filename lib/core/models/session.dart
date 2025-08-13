class Session {
  final String id;
  final String userId;
  final String songRiffId;
  final DateTime startTime;
  final DateTime? endTime;
  final int targetBpm;
  final int actualBpm;
  final int durationMinutes;
  final double accuracy; // 0.0 to 1.0
  final int successfulRuns;
  final int totalAttempts;
  final List<SessionFeedback> feedback;
  final String notes;
  final bool completed;

  const Session({
    required this.id,
    required this.userId,
    required this.songRiffId,
    required this.startTime,
    this.endTime,
    required this.targetBpm,
    required this.actualBpm,
    required this.durationMinutes,
    required this.accuracy,
    required this.successfulRuns,
    required this.totalAttempts,
    required this.feedback,
    this.notes = '',
    this.completed = false,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      userId: json['userId'] as String,
      songRiffId: json['songRiffId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime'] as String)
          : null,
      targetBpm: json['targetBpm'] as int,
      actualBpm: json['actualBpm'] as int,
      durationMinutes: json['durationMinutes'] as int,
      accuracy: (json['accuracy'] as num).toDouble(),
      successfulRuns: json['successfulRuns'] as int,
      totalAttempts: json['totalAttempts'] as int,
      feedback: (json['feedback'] as List)
          .map((f) => SessionFeedback.fromJson(f as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'songRiffId': songRiffId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'targetBpm': targetBpm,
      'actualBpm': actualBpm,
      'durationMinutes': durationMinutes,
      'accuracy': accuracy,
      'successfulRuns': successfulRuns,
      'totalAttempts': totalAttempts,
      'feedback': feedback.map((f) => f.toJson()).toList(),
      'notes': notes,
      'completed': completed,
    };
  }

  Session copyWith({
    String? id,
    String? userId,
    String? songRiffId,
    DateTime? startTime,
    DateTime? endTime,
    int? targetBpm,
    int? actualBpm,
    int? durationMinutes,
    double? accuracy,
    int? successfulRuns,
    int? totalAttempts,
    List<SessionFeedback>? feedback,
    String? notes,
    bool? completed,
  }) {
    return Session(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      songRiffId: songRiffId ?? this.songRiffId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      targetBpm: targetBpm ?? this.targetBpm,
      actualBpm: actualBpm ?? this.actualBpm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      accuracy: accuracy ?? this.accuracy,
      successfulRuns: successfulRuns ?? this.successfulRuns,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      feedback: feedback ?? this.feedback,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Session &&
        other.id == id &&
        other.userId == userId &&
        other.songRiffId == songRiffId &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.targetBpm == targetBpm &&
        other.actualBpm == actualBpm &&
        other.durationMinutes == durationMinutes &&
        other.accuracy == accuracy &&
        other.successfulRuns == successfulRuns &&
        other.totalAttempts == totalAttempts &&
        other.feedback.toString() == feedback.toString() &&
        other.notes == notes &&
        other.completed == completed;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      songRiffId,
      startTime,
      endTime,
      targetBpm,
      actualBpm,
      durationMinutes,
      accuracy,
      successfulRuns,
      totalAttempts,
      feedback,
      notes,
      completed,
    );
  }
}

class SessionFeedback {
  final String type; // 'timing', 'technique', 'general'
  final String message;
  final DateTime timestamp;
  final double? severity; // 0.0 to 1.0, null for positive feedback

  const SessionFeedback({
    required this.type,
    required this.message,
    required this.timestamp,
    this.severity,
  });

  factory SessionFeedback.fromJson(Map<String, dynamic> json) {
    return SessionFeedback(
      type: json['type'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      severity: (json['severity'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionFeedback &&
        other.type == type &&
        other.message == message &&
        other.timestamp == timestamp &&
        other.severity == severity;
  }

  @override
  int get hashCode {
    return Object.hash(type, message, timestamp, severity);
  }
}