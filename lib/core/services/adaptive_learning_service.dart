import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import 'stats_service.dart';
import 'chord_recognition_service.dart';
import 'technique_detection_service.dart';

/// Adaptive Learning Service
/// Creates personalized learning paths based on user performance, learning style,
/// and practice history using AI-driven curriculum adaptation
class AdaptiveLearningService {
  final StatsService _statsService;
  final ChordRecognitionService _chordService;
  final TechniqueDetectionService _techniqueService;
  
  // Learning state
  final Map<String, LearningProfile> _userProfiles = {};
  final Map<String, List<LearningObjective>> _userObjectives = {};
  final Map<String, LearningPath> _activePaths = {};
  
  // Curriculum database
  final Map<String, Curriculum> _curriculums = {};
  final Map<String, Exercise> _exercises = {};
  final Map<String, Lesson> _lessons = {};
  
  // AI adaptation parameters
  static const double _adaptationThreshold = 0.1;
  static const int _performanceHistoryLimit = 20;
  static const double _difficultyStepSize = 0.1;
  
  // Event streams
  final StreamController<LearningPathUpdate> _pathUpdateController = StreamController.broadcast();
  final StreamController<SkillAssessment> _skillController = StreamController.broadcast();
  final StreamController<LearningRecommendation> _recommendationController = StreamController.broadcast();
  
  AdaptiveLearningService(this._statsService, this._chordService, this._techniqueService) {
    _initializeCurriculums();
  }
  
  /// Stream of learning path updates
  Stream<LearningPathUpdate> get pathUpdates => _pathUpdateController.stream;
  
  /// Stream of skill assessments
  Stream<SkillAssessment> get skillAssessments => _skillController.stream;
  
  /// Stream of learning recommendations
  Stream<LearningRecommendation> get recommendations => _recommendationController.stream;
  
  /// Create personalized learning profile for user
  Future<LearningProfile> createLearningProfile({
    required String userId,
    required LearningGoal primaryGoal,
    required SkillLevel currentLevel,
    required LearningStyle learningStyle,
    List<String>? preferredGenres,
    List<String>? knownChords,
    List<TechniqueType>? knownTechniques,
    Duration? availablePracticeTime,
  }) async {
    try {
      // Assess current skills
      final skillAssessment = await _assessCurrentSkills(userId);
      
      // Create profile
      final profile = LearningProfile(
        userId: userId,
        primaryGoal: primaryGoal,
        currentLevel: currentLevel,
        learningStyle: learningStyle,
        preferredGenres: preferredGenres ?? ['rock', 'pop'],
        knownChords: knownChords ?? [],
        knownTechniques: knownTechniques ?? [],
        availablePracticeTime: availablePracticeTime ?? const Duration(minutes: 30),
        skillAssessment: skillAssessment,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      
      _userProfiles[userId] = profile;
      
      // Generate initial learning path
      final learningPath = await generateLearningPath(userId);
      _activePaths[userId] = learningPath;
      
      return profile;
    } catch (e) {
      throw AdaptiveLearningException('Failed to create learning profile: $e');
    }
  }
  
  /// Generate adaptive learning path for user
  Future<LearningPath> generateLearningPath(String userId) async {
    final profile = _userProfiles[userId];
    if (profile == null) {
      throw AdaptiveLearningException('User profile not found');
    }
    
    try {
      // Select appropriate curriculum
      final curriculum = _selectCurriculum(profile);
      
      // Generate personalized milestones
      final milestones = await _generateMilestones(profile, curriculum);
      
      // Create adaptive exercises
      final exercises = await _generateAdaptiveExercises(profile, milestones);
      
      // Calculate estimated timeline
      final timeline = _calculateLearningTimeline(profile, milestones);
      
      final learningPath = LearningPath(
        id: 'path_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        curriculum: curriculum,
        milestones: milestones,
        exercises: exercises,
        currentMilestone: 0,
        estimatedTimeline: timeline,
        adaptationHistory: [],
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      
      _pathUpdateController.add(LearningPathUpdate(
        type: PathUpdateType.created,
        path: learningPath,
        timestamp: DateTime.now(),
      ));
      
      return learningPath;
    } catch (e) {
      throw AdaptiveLearningException('Failed to generate learning path: $e');
    }
  }
  
  /// Update learning path based on recent performance
  Future<LearningPath> adaptLearningPath(String userId) async {
    final currentPath = _activePaths[userId];
    final profile = _userProfiles[userId];
    
    if (currentPath == null || profile == null) {
      throw AdaptiveLearningException('Learning path or profile not found');
    }
    
    try {
      // Analyze recent performance
      final performanceAnalysis = await _analyzeRecentPerformance(userId);
      
      // Check if adaptation is needed
      if (!_shouldAdaptPath(performanceAnalysis)) {
        return currentPath;
      }
      
      // Create adapted path
      final adaptedPath = await _createAdaptedPath(currentPath, profile, performanceAnalysis);
      
      // Update active path
      _activePaths[userId] = adaptedPath;
      
      _pathUpdateController.add(LearningPathUpdate(
        type: PathUpdateType.adapted,
        path: adaptedPath,
        timestamp: DateTime.now(),
        adaptationReason: performanceAnalysis.adaptationReason,
      ));
      
      return adaptedPath;
    } catch (e) {
      throw AdaptiveLearningException('Failed to adapt learning path: $e');
    }
  }
  
  /// Assess user's current skill level
  Future<SkillAssessment> assessCurrentSkills(String userId) async {
    return await _assessCurrentSkills(userId);
  }
  
  /// Get next recommended exercise
  Future<Exercise?> getNextExercise(String userId) async {
    final path = _activePaths[userId];
    if (path == null) return null;
    
    final currentMilestone = path.milestones[path.currentMilestone];
    final uncompletedExercises = path.exercises
        .where((ex) => 
            ex.milestoneId == currentMilestone.id && 
            !ex.isCompleted)
        .toList();
    
    if (uncompletedExercises.isEmpty) {
      // Check if milestone is complete
      if (_isMilestoneComplete(currentMilestone.id, path.exercises)) {
        await _advanceToNextMilestone(userId);
      }
      return null;
    }
    
    // Select exercise based on difficulty adaptation
    return _selectOptimalExercise(uncompletedExercises, userId);
  }
  
  /// Record exercise completion and performance
  Future<void> recordExerciseCompletion({
    required String userId,
    required String exerciseId,
    required double accuracy,
    required Duration timeSpent,
    required int attempts,
    Map<String, dynamic>? additionalMetrics,
  }) async {
    final path = _activePaths[userId];
    if (path == null) return;
    
    // Find and update exercise
    final exerciseIndex = path.exercises.indexWhere((ex) => ex.id == exerciseId);
    if (exerciseIndex == -1) return;
    
    final exercise = path.exercises[exerciseIndex];
    final completion = ExerciseCompletion(
      exerciseId: exerciseId,
      accuracy: accuracy,
      timeSpent: timeSpent,
      attempts: attempts,
      completedAt: DateTime.now(),
      additionalMetrics: additionalMetrics ?? {},
    );
    
    // Update exercise
    final updatedExercise = exercise.copyWith(
      isCompleted: accuracy >= exercise.targetAccuracy,
      completions: [...exercise.completions, completion],
      bestAccuracy: math.max(exercise.bestAccuracy, accuracy),
    );
    
    path.exercises[exerciseIndex] = updatedExercise;
    
    // Update learning profile with new performance data
    await _updateLearningProfile(userId, completion);
    
    // Check for path adaptation
    if (path.exercises.where((ex) => ex.isCompleted).length % 5 == 0) {
      await adaptLearningPath(userId);
    }
  }
  
  /// Get learning recommendations based on current state
  List<LearningRecommendation> getLearningRecommendations(String userId) {
    final profile = _userProfiles[userId];
    final path = _activePaths[userId];
    
    if (profile == null || path == null) return [];
    
    final recommendations = <LearningRecommendation>[];
    
    // Analyze weak areas
    final weakAreas = _identifyWeakAreas(userId);
    for (final area in weakAreas) {
      recommendations.add(LearningRecommendation(
        type: RecommendationType.remediation,
        title: 'Strengthen ${area.name}',
        description: area.suggestion,
        priority: RecommendationPriority.high,
        estimatedTime: const Duration(minutes: 15),
        targetSkills: [area.skill],
      ));
    }
    
    // Suggest next skills to learn
    final nextSkills = _suggestNextSkills(profile);
    for (final skill in nextSkills) {
      recommendations.add(LearningRecommendation(
        type: RecommendationType.progression,
        title: 'Learn ${skill.displayName}',
        description: 'You\'re ready to learn ${skill.displayName}',
        priority: RecommendationPriority.medium,
        estimatedTime: const Duration(minutes: 20),
        targetSkills: [skill],
      ));
    }
    
    // Practice schedule recommendations
    final scheduleRec = _generateScheduleRecommendation(profile);
    if (scheduleRec != null) {
      recommendations.add(scheduleRec);
    }
    
    return recommendations;
  }
  
  /// Get detailed progress report
  LearningProgressReport getProgressReport(String userId) {
    final profile = _userProfiles[userId];
    final path = _activePaths[userId];
    
    if (profile == null || path == null) {
      return LearningProgressReport.empty(userId);
    }
    
    final completedExercises = path.exercises.where((ex) => ex.isCompleted).length;
    final totalExercises = path.exercises.length;
    final progressPercentage = totalExercises > 0 ? completedExercises / totalExercises : 0.0;
    
    final skillProgression = _calculateSkillProgression(userId);
    final strengths = _identifyStrengths(userId);
    final challenges = _identifyWeakAreas(userId);
    
    return LearningProgressReport(
      userId: userId,
      overallProgress: progressPercentage,
      currentMilestone: path.currentMilestone + 1,
      totalMilestones: path.milestones.length,
      completedExercises: completedExercises,
      totalExercises: totalExercises,
      skillProgression: skillProgression,
      strengths: strengths.map((s) => s.name).toList(),
      challenges: challenges.map((c) => c.name).toList(),
      recommendedPracticeTime: _calculateRecommendedPracticeTime(profile),
      nextMilestoneETA: _estimateNextMilestoneCompletion(path),
      generatedAt: DateTime.now(),
    );
  }
  
  // Private methods
  void _initializeCurriculums() {
    // Beginner curriculum
    _curriculums['beginner'] = Curriculum(
      id: 'beginner',
      name: 'Beginner Guitar Fundamentals',
      description: 'Essential skills for starting guitar',
      targetLevel: SkillLevel.beginner,
      estimatedDuration: const Duration(weeks: 12),
      modules: [
        CurriculumModule(
          id: 'basics',
          name: 'Guitar Basics',
          skills: [Skill.holdingGuitar, Skill.tuning, Skill.basicStrumming],
          estimatedWeeks: 2,
        ),
        CurriculumModule(
          id: 'chords',
          name: 'Basic Chords',
          skills: [Skill.openChords, Skill.chordTransitions],
          estimatedWeeks: 4,
        ),
        CurriculumModule(
          id: 'techniques',
          name: 'Basic Techniques',
          skills: [Skill.alternatePicking, Skill.downstrokes],
          estimatedWeeks: 3,
        ),
        CurriculumModule(
          id: 'songs',
          name: 'First Songs',
          skills: [Skill.simpleSongs, Skill.rhythm],
          estimatedWeeks: 3,
        ),
      ],
    );
    
    // Intermediate curriculum
    _curriculums['intermediate'] = Curriculum(
      id: 'intermediate',
      name: 'Intermediate Guitar Skills',
      description: 'Advanced techniques and musical concepts',
      targetLevel: SkillLevel.intermediate,
      estimatedDuration: const Duration(weeks: 16),
      modules: [
        CurriculumModule(
          id: 'advanced_chords',
          name: 'Advanced Chords',
          skills: [Skill.barreChords, Skill.seventhChords, Skill.extendedChords],
          estimatedWeeks: 4,
        ),
        CurriculumModule(
          id: 'lead_guitar',
          name: 'Lead Guitar',
          skills: [Skill.scales, Skill.bending, Skill.vibrato],
          estimatedWeeks: 6,
        ),
        CurriculumModule(
          id: 'advanced_techniques',
          name: 'Advanced Techniques',
          skills: [Skill.hammerOns, Skill.pullOffs, Skill.slides],
          estimatedWeeks: 4,
        ),
        CurriculumModule(
          id: 'improvisation',
          name: 'Improvisation',
          skills: [Skill.improvisation, Skill.jamming],
          estimatedWeeks: 2,
        ),
      ],
    );
    
    // Advanced curriculum
    _curriculums['advanced'] = Curriculum(
      id: 'advanced',
      name: 'Advanced Guitar Mastery',
      description: 'Professional-level techniques and musicianship',
      targetLevel: SkillLevel.advanced,
      estimatedDuration: const Duration(weeks: 20),
      modules: [
        CurriculumModule(
          id: 'complex_techniques',
          name: 'Complex Techniques',
          skills: [Skill.tapping, Skill.sweepPicking, Skill.economyPicking],
          estimatedWeeks: 6,
        ),
        CurriculumModule(
          id: 'music_theory',
          name: 'Advanced Music Theory',
          skills: [Skill.modes, Skill.jazzHarmony, Skill.composition],
          estimatedWeeks: 8,
        ),
        CurriculumModule(
          id: 'professional_skills',
          name: 'Professional Skills',
          skills: [Skill.recording, Skill.performance, Skill.teaching],
          estimatedWeeks: 6,
        ),
      ],
    );
  }
  
  Future<SkillAssessment> _assessCurrentSkills(String userId) async {
    try {
      // Get user's practice history
      final sessions = await _statsService.getUserSessions(userId);
      
      // Assess different skill areas
      final chordSkills = await _assessChordSkills(userId);
      final techniqueSkills = await _assessTechniqueSkills(userId);
      final rhythmSkills = await _assessRhythmSkills(sessions);
      final theorySkills = await _assessTheorySkills(userId);
      
      // Calculate overall level
      final overallLevel = _calculateOverallLevel([
        chordSkills.level,
        techniqueSkills.level,
        rhythmSkills.level,
        theorySkills.level,
      ]);
      
      final assessment = SkillAssessment(
        userId: userId,
        overallLevel: overallLevel,
        chordSkills: chordSkills,
        techniqueSkills: techniqueSkills,
        rhythmSkills: rhythmSkills,
        theorySkills: theorySkills,
        assessedAt: DateTime.now(),
      );
      
      _skillController.add(assessment);
      
      return assessment;
    } catch (e) {
      throw AdaptiveLearningException('Failed to assess skills: $e');
    }
  }
  
  Future<SkillArea> _assessChordSkills(String userId) async {
    final chordStats = _chordService.getRecognitionStats();
    
    double level = 0.0;
    final strengths = <String>[];
    final weaknesses = <String>[];
    
    if (chordStats.uniqueChordsDetected >= 8) {
      level = 0.8;
      strengths.add('Good chord vocabulary');
    } else if (chordStats.uniqueChordsDetected >= 5) {
      level = 0.6;
      strengths.add('Basic chord knowledge');
    } else {
      level = 0.3;
      weaknesses.add('Limited chord vocabulary');
    }
    
    if (chordStats.averageAccuracy >= 0.8) {
      level += 0.15;
      strengths.add('Accurate chord playing');
    } else {
      weaknesses.add('Chord clarity needs work');
    }
    
    return SkillArea(
      name: 'Chord Skills',
      level: level.clamp(0.0, 1.0),
      strengths: strengths,
      weaknesses: weaknesses,
    );
  }
  
  Future<SkillArea> _assessTechniqueSkills(String userId) async {
    final techniqueStats = _techniqueService.getTechniqueStats();
    
    double level = 0.0;
    final strengths = <String>[];
    final weaknesses = <String>[];
    
    if (techniqueStats.techniquesDetected >= 5) {
      level = 0.7;
      strengths.add('Diverse technique knowledge');
    } else if (techniqueStats.techniquesDetected >= 3) {
      level = 0.5;
      strengths.add('Basic technique foundation');
    } else {
      level = 0.2;
      weaknesses.add('Limited technique variety');
    }
    
    if (techniqueStats.overallAccuracy >= 0.75) {
      level += 0.2;
      strengths.add('Good technique execution');
    } else {
      weaknesses.add('Technique accuracy needs improvement');
    }
    
    return SkillArea(
      name: 'Technique Skills',
      level: level.clamp(0.0, 1.0),
      strengths: strengths,
      weaknesses: weaknesses,
    );
  }
  
  Future<SkillArea> _assessRhythmSkills(List<Session> sessions) async {
    if (sessions.isEmpty) {
      return SkillArea(
        name: 'Rhythm Skills',
        level: 0.0,
        strengths: [],
        weaknesses: ['No practice data available'],
      );
    }
    
    final avgAccuracy = sessions.map((s) => s.accuracy).reduce((a, b) => a + b) / sessions.length;
    final bpmRange = sessions.map((s) => s.targetBpm).reduce(math.max) - 
                     sessions.map((s) => s.targetBpm).reduce(math.min);
    
    double level = avgAccuracy;
    final strengths = <String>[];
    final weaknesses = <String>[];
    
    if (avgAccuracy >= 0.8) {
      strengths.add('Consistent timing');
    } else {
      weaknesses.add('Timing accuracy needs work');
    }
    
    if (bpmRange >= 60) {
      strengths.add('Comfortable with tempo variations');
      level += 0.1;
    } else {
      weaknesses.add('Limited tempo range');
    }
    
    return SkillArea(
      name: 'Rhythm Skills',
      level: level.clamp(0.0, 1.0),
      strengths: strengths,
      weaknesses: weaknesses,
    );
  }
  
  Future<SkillArea> _assessTheorySkills(String userId) async {
    // Simplified theory assessment
    return SkillArea(
      name: 'Music Theory',
      level: 0.3, // Default beginner level
      strengths: [],
      weaknesses: ['Theory knowledge needs development'],
    );
  }
  
  SkillLevel _calculateOverallLevel(List<double> skillLevels) {
    final avgLevel = skillLevels.reduce((a, b) => a + b) / skillLevels.length;
    
    if (avgLevel >= 0.8) return SkillLevel.advanced;
    if (avgLevel >= 0.5) return SkillLevel.intermediate;
    return SkillLevel.beginner;
  }
  
  Curriculum _selectCurriculum(LearningProfile profile) {
    switch (profile.currentLevel) {
      case SkillLevel.beginner:
        return _curriculums['beginner']!;
      case SkillLevel.intermediate:
        return _curriculums['intermediate']!;
      case SkillLevel.advanced:
        return _curriculums['advanced']!;
    }
  }
  
  Future<List<Milestone>> _generateMilestones(LearningProfile profile, Curriculum curriculum) async {
    final milestones = <Milestone>[];
    
    for (int i = 0; i < curriculum.modules.length; i++) {
      final module = curriculum.modules[i];
      
      milestones.add(Milestone(
        id: 'milestone_${module.id}',
        title: module.name,
        description: 'Master ${module.name.toLowerCase()} skills',
        order: i,
        targetSkills: module.skills,
        requirements: _generateMilestoneRequirements(module),
        estimatedDuration: Duration(weeks: module.estimatedWeeks),
        isCompleted: false,
      ));
    }
    
    return milestones;
  }
  
  List<MilestoneRequirement> _generateMilestoneRequirements(CurriculumModule module) {
    return module.skills.map((skill) => MilestoneRequirement(
      skill: skill,
      targetAccuracy: 0.8,
      minimumAttempts: 5,
    )).toList();
  }
  
  Future<List<Exercise>> _generateAdaptiveExercises(LearningProfile profile, List<Milestone> milestones) async {
    final exercises = <Exercise>[];
    
    for (final milestone in milestones) {
      final milestoneExercises = await _generateMilestoneExercises(milestone, profile);
      exercises.addAll(milestoneExercises);
    }
    
    return exercises;
  }
  
  Future<List<Exercise>> _generateMilestoneExercises(Milestone milestone, LearningProfile profile) async {
    final exercises = <Exercise>[];
    
    for (final skill in milestone.targetSkills) {
      final skillExercises = _generateSkillExercises(skill, milestone.id, profile);
      exercises.addAll(skillExercises);
    }
    
    return exercises;
  }
  
  List<Exercise> _generateSkillExercises(Skill skill, String milestoneId, LearningProfile profile) {
    switch (skill) {
      case Skill.openChords:
        return [
          Exercise(
            id: 'open_chords_basic',
            milestoneId: milestoneId,
            title: 'Basic Open Chords',
            description: 'Practice C, G, Am, Em chords',
            skill: skill,
            difficulty: 0.3,
            targetAccuracy: 0.8,
            estimatedDuration: const Duration(minutes: 10),
            exerciseType: ExerciseType.chordPractice,
            parameters: {'chords': ['C', 'G', 'Am', 'Em']},
          ),
          Exercise(
            id: 'open_chords_transitions',
            milestoneId: milestoneId,
            title: 'Chord Transitions',
            description: 'Practice smooth transitions between open chords',
            skill: skill,
            difficulty: 0.5,
            targetAccuracy: 0.75,
            estimatedDuration: const Duration(minutes: 15),
            exerciseType: ExerciseType.chordProgression,
            parameters: {'progression': ['C', 'Am', 'F', 'G']},
          ),
        ];
      
      case Skill.alternatePicking:
        return [
          Exercise(
            id: 'alternate_picking_slow',
            milestoneId: milestoneId,
            title: 'Slow Alternate Picking',
            description: 'Practice alternate picking at slow tempo',
            skill: skill,
            difficulty: 0.4,
            targetAccuracy: 0.8,
            estimatedDuration: const Duration(minutes: 8),
            exerciseType: ExerciseType.techniquePractice,
            parameters: {'bpm': 80, 'technique': 'alternate_picking'},
          ),
          Exercise(
            id: 'alternate_picking_medium',
            milestoneId: milestoneId,
            title: 'Medium Tempo Picking',
            description: 'Increase picking speed',
            skill: skill,
            difficulty: 0.6,
            targetAccuracy: 0.75,
            estimatedDuration: const Duration(minutes: 12),
            exerciseType: ExerciseType.techniquePractice,
            parameters: {'bpm': 120, 'technique': 'alternate_picking'},
          ),
        ];
      
      default:
        return [
          Exercise(
            id: '${skill.name}_basic',
            milestoneId: milestoneId,
            title: 'Basic ${skill.displayName}',
            description: 'Introduction to ${skill.displayName}',
            skill: skill,
            difficulty: 0.3,
            targetAccuracy: 0.7,
            estimatedDuration: const Duration(minutes: 10),
            exerciseType: ExerciseType.general,
            parameters: {},
          ),
        ];
    }
  }
  
  Duration _calculateLearningTimeline(LearningProfile profile, List<Milestone> milestones) {
    final totalWeeks = milestones.fold<int>(0, (sum, milestone) => 
        sum + milestone.estimatedDuration.inDays ~/ 7);
    
    // Adjust based on available practice time
    final practiceHoursPerWeek = profile.availablePracticeTime.inMinutes * 7 / 60.0;
    
    double adjustmentFactor = 1.0;
    if (practiceHoursPerWeek < 2) {
      adjustmentFactor = 1.5; // Slower progress with less practice
    } else if (practiceHoursPerWeek > 7) {
      adjustmentFactor = 0.8; // Faster progress with more practice
    }
    
    final adjustedWeeks = (totalWeeks * adjustmentFactor).round();
    return Duration(days: adjustedWeeks * 7);
  }
  
  Future<PerformanceAnalysis> _analyzeRecentPerformance(String userId) async {
    final sessions = await _statsService.getUserSessions(userId);
    final recentSessions = sessions.take(_performanceHistoryLimit).toList();
    
    if (recentSessions.length < 5) {
      return PerformanceAnalysis(
        averageAccuracy: 0.0,
        progressTrend: ProgressTrend.stable,
        strugglingAreas: [],
        excellingAreas: [],
        adaptationReason: 'Insufficient data for analysis',
      );
    }
    
    final avgAccuracy = recentSessions.map((s) => s.accuracy).reduce((a, b) => a + b) / recentSessions.length;
    
    // Calculate trend
    final firstHalf = recentSessions.take(recentSessions.length ~/ 2);
    final secondHalf = recentSessions.skip(recentSessions.length ~/ 2);
    
    final firstHalfAvg = firstHalf.map((s) => s.accuracy).reduce((a, b) => a + b) / firstHalf.length;
    final secondHalfAvg = secondHalf.map((s) => s.accuracy).reduce((a, b) => a + b) / secondHalf.length;
    
    ProgressTrend trend;
    if (secondHalfAvg - firstHalfAvg > _adaptationThreshold) {
      trend = ProgressTrend.improving;
    } else if (firstHalfAvg - secondHalfAvg > _adaptationThreshold) {
      trend = ProgressTrend.declining;
    } else {
      trend = ProgressTrend.stable;
    }
    
    return PerformanceAnalysis(
      averageAccuracy: avgAccuracy,
      progressTrend: trend,
      strugglingAreas: _identifyStrugglingAreas(recentSessions),
      excellingAreas: _identifyExcellingAreas(recentSessions),
      adaptationReason: _generateAdaptationReason(trend, avgAccuracy),
    );
  }
  
  List<String> _identifyStrugglingAreas(List<Session> sessions) {
    // Simplified analysis
    final avgAccuracy = sessions.map((s) => s.accuracy).reduce((a, b) => a + b) / sessions.length;
    
    final strugglingAreas = <String>[];
    
    if (avgAccuracy < 0.6) {
      strugglingAreas.add('Overall accuracy');
    }
    
    final highBpmSessions = sessions.where((s) => s.targetBpm > 120);
    if (highBpmSessions.isNotEmpty) {
      final highBpmAvg = highBpmSessions.map((s) => s.accuracy).reduce((a, b) => a + b) / highBpmSessions.length;
      if (highBpmAvg < avgAccuracy - 0.2) {
        strugglingAreas.add('High tempo playing');
      }
    }
    
    return strugglingAreas;
  }
  
  List<String> _identifyExcellingAreas(List<Session> sessions) {
    final avgAccuracy = sessions.map((s) => s.accuracy).reduce((a, b) => a + b) / sessions.length;
    
    final excellingAreas = <String>[];
    
    if (avgAccuracy >= 0.8) {
      excellingAreas.add('Consistent accuracy');
    }
    
    final bpmRange = sessions.map((s) => s.targetBpm).reduce(math.max) - 
                     sessions.map((s) => s.targetBpm).reduce(math.min);
    if (bpmRange >= 60) {
      excellingAreas.add('Tempo versatility');
    }
    
    return excellingAreas;
  }
  
  String _generateAdaptationReason(ProgressTrend trend, double accuracy) {
    switch (trend) {
      case ProgressTrend.improving:
        return 'User showing consistent improvement - advancing difficulty';
      case ProgressTrend.declining:
        return 'Performance declining - providing additional support';
      case ProgressTrend.stable:
        if (accuracy >= 0.8) {
          return 'High performance maintained - ready for new challenges';
        } else {
          return 'Performance stable but below target - adjusting exercises';
        }
    }
  }
  
  bool _shouldAdaptPath(PerformanceAnalysis analysis) {
    return analysis.progressTrend != ProgressTrend.stable ||
           analysis.averageAccuracy < 0.6 ||
           analysis.averageAccuracy > 0.9;
  }
  
  Future<LearningPath> _createAdaptedPath(
    LearningPath currentPath,
    LearningProfile profile,
    PerformanceAnalysis analysis,
  ) async {
    final adaptedExercises = <Exercise>[];
    
    for (final exercise in currentPath.exercises) {
      if (exercise.isCompleted) {
        adaptedExercises.add(exercise);
        continue;
      }
      
      // Adapt difficulty based on performance
      double newDifficulty = exercise.difficulty;
      
      switch (analysis.progressTrend) {
        case ProgressTrend.improving:
          if (analysis.averageAccuracy >= 0.85) {
            newDifficulty += _difficultyStepSize;
          }
          break;
        case ProgressTrend.declining:
          newDifficulty -= _difficultyStepSize;
          break;
        case ProgressTrend.stable:
          if (analysis.averageAccuracy < 0.7) {
            newDifficulty -= _difficultyStepSize * 0.5;
          } else if (analysis.averageAccuracy > 0.9) {
            newDifficulty += _difficultyStepSize * 0.5;
          }
          break;
      }
      
      newDifficulty = newDifficulty.clamp(0.1, 1.0);
      
      final adaptedExercise = exercise.copyWith(difficulty: newDifficulty);
      adaptedExercises.add(adaptedExercise);
    }
    
    // Add adaptation record
    final adaptation = PathAdaptation(
      timestamp: DateTime.now(),
      reason: analysis.adaptationReason,
      changes: ['Difficulty adjusted based on performance'],
      previousMetrics: {'avgAccuracy': analysis.averageAccuracy},
    );
    
    return currentPath.copyWith(
      exercises: adaptedExercises,
      adaptationHistory: [...currentPath.adaptationHistory, adaptation],
      lastUpdated: DateTime.now(),
    );
  }
  
  bool _isMilestoneComplete(String milestoneId, List<Exercise> exercises) {
    final milestoneExercises = exercises.where((ex) => ex.milestoneId == milestoneId);
    return milestoneExercises.every((ex) => ex.isCompleted);
  }
  
  Future<void> _advanceToNextMilestone(String userId) async {
    final path = _activePaths[userId];
    if (path == null || path.currentMilestone >= path.milestones.length - 1) return;
    
    final updatedPath = path.copyWith(currentMilestone: path.currentMilestone + 1);
    _activePaths[userId] = updatedPath;
    
    _pathUpdateController.add(LearningPathUpdate(
      type: PathUpdateType.milestoneAdvanced,
      path: updatedPath,
      timestamp: DateTime.now(),
    ));
  }
  
  Exercise? _selectOptimalExercise(List<Exercise> exercises, String userId) {
    // Sort by difficulty and select based on recent performance
    exercises.sort((a, b) => a.difficulty.compareTo(b.difficulty));
    
    // For now, return the first exercise
    // In production, this would consider user's current performance level
    return exercises.first;
  }
  
  Future<void> _updateLearningProfile(String userId, ExerciseCompletion completion) async {
    final profile = _userProfiles[userId];
    if (profile == null) return;
    
    // Update skill assessment based on completion
    // This is a simplified update - in production, this would be more sophisticated
    final updatedProfile = profile.copyWith(lastUpdated: DateTime.now());
    _userProfiles[userId] = updatedProfile;
  }
  
  List<WeakArea> _identifyWeakAreas(String userId) {
    // Simplified weak area identification
    return [
      WeakArea(
        skill: Skill.openChords,
        name: 'Chord Clarity',
        suggestion: 'Focus on finger placement and string clarity',
      ),
    ];
  }
  
  List<Skill> _suggestNextSkills(LearningProfile profile) {
    // Simplified skill suggestion based on current level
    switch (profile.currentLevel) {
      case SkillLevel.beginner:
        return [Skill.chordTransitions, Skill.basicStrumming];
      case SkillLevel.intermediate:
        return [Skill.barreChords, Skill.scales];
      case SkillLevel.advanced:
        return [Skill.tapping, Skill.sweepPicking];
    }
  }
  
  LearningRecommendation? _generateScheduleRecommendation(LearningProfile profile) {
    if (profile.availablePracticeTime.inMinutes < 20) {
      return LearningRecommendation(
        type: RecommendationType.schedule,
        title: 'Increase Practice Time',
        description: 'Consider practicing for at least 20 minutes for better progress',
        priority: RecommendationPriority.medium,
        estimatedTime: const Duration(minutes: 20),
        targetSkills: [],
      );
    }
    return null;
  }
  
  Map<Skill, double> _calculateSkillProgression(String userId) {
    // Simplified skill progression calculation
    return {
      Skill.openChords: 0.7,
      Skill.alternatePicking: 0.5,
      Skill.rhythm: 0.6,
    };
  }
  
  List<WeakArea> _identifyStrengths(String userId) {
    return [
      WeakArea(
        skill: Skill.rhythm,
        name: 'Timing',
        suggestion: 'Great sense of rhythm',
      ),
    ];
  }
  
  Duration _calculateRecommendedPracticeTime(LearningProfile profile) {
    // Base recommendation on current level and goals
    switch (profile.currentLevel) {
      case SkillLevel.beginner:
        return const Duration(minutes: 20);
      case SkillLevel.intermediate:
        return const Duration(minutes: 30);
      case SkillLevel.advanced:
        return const Duration(minutes: 45);
    }
  }
  
  DateTime? _estimateNextMilestoneCompletion(LearningPath path) {
    if (path.currentMilestone >= path.milestones.length) return null;
    
    final currentMilestone = path.milestones[path.currentMilestone];
    final incompletedExercises = path.exercises
        .where((ex) => ex.milestoneId == currentMilestone.id && !ex.isCompleted)
        .length;
    
    // Estimate based on exercise count and typical completion time
    final estimatedDays = incompletedExercises * 2; // 2 days per exercise average
    
    return DateTime.now().add(Duration(days: estimatedDays));
  }
  
  void dispose() {
    _pathUpdateController.close();
    _skillController.close();
    _recommendationController.close();
  }
}

// Data Models
class LearningProfile {
  final String userId;
  final LearningGoal primaryGoal;
  final SkillLevel currentLevel;
  final LearningStyle learningStyle;
  final List<String> preferredGenres;
  final List<String> knownChords;
  final List<TechniqueType> knownTechniques;
  final Duration availablePracticeTime;
  final SkillAssessment skillAssessment;
  final DateTime createdAt;
  final DateTime lastUpdated;
  
  const LearningProfile({
    required this.userId,
    required this.primaryGoal,
    required this.currentLevel,
    required this.learningStyle,
    required this.preferredGenres,
    required this.knownChords,
    required this.knownTechniques,
    required this.availablePracticeTime,
    required this.skillAssessment,
    required this.createdAt,
    required this.lastUpdated,
  });
  
  LearningProfile copyWith({
    LearningGoal? primaryGoal,
    SkillLevel? currentLevel,
    LearningStyle? learningStyle,
    List<String>? preferredGenres,
    List<String>? knownChords,
    List<TechniqueType>? knownTechniques,
    Duration? availablePracticeTime,
    SkillAssessment? skillAssessment,
    DateTime? lastUpdated,
  }) {
    return LearningProfile(
      userId: userId,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      currentLevel: currentLevel ?? this.currentLevel,
      learningStyle: learningStyle ?? this.learningStyle,
      preferredGenres: preferredGenres ?? this.preferredGenres,
      knownChords: knownChords ?? this.knownChords,
      knownTechniques: knownTechniques ?? this.knownTechniques,
      availablePracticeTime: availablePracticeTime ?? this.availablePracticeTime,
      skillAssessment: skillAssessment ?? this.skillAssessment,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class LearningPath {
  final String id;
  final String userId;
  final Curriculum curriculum;
  final List<Milestone> milestones;
  final List<Exercise> exercises;
  final int currentMilestone;
  final Duration estimatedTimeline;
  final List<PathAdaptation> adaptationHistory;
  final DateTime createdAt;
  final DateTime lastUpdated;
  
  const LearningPath({
    required this.id,
    required this.userId,
    required this.curriculum,
    required this.milestones,
    required this.exercises,
    required this.currentMilestone,
    required this.estimatedTimeline,
    required this.adaptationHistory,
    required this.createdAt,
    required this.lastUpdated,
  });
  
  LearningPath copyWith({
    List<Exercise>? exercises,
    int? currentMilestone,
    List<PathAdaptation>? adaptationHistory,
    DateTime? lastUpdated,
  }) {
    return LearningPath(
      id: id,
      userId: userId,
      curriculum: curriculum,
      milestones: milestones,
      exercises: exercises ?? this.exercises,
      currentMilestone: currentMilestone ?? this.currentMilestone,
      estimatedTimeline: estimatedTimeline,
      adaptationHistory: adaptationHistory ?? this.adaptationHistory,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class Curriculum {
  final String id;
  final String name;
  final String description;
  final SkillLevel targetLevel;
  final Duration estimatedDuration;
  final List<CurriculumModule> modules;
  
  const Curriculum({
    required this.id,
    required this.name,
    required this.description,
    required this.targetLevel,
    required this.estimatedDuration,
    required this.modules,
  });
}

class CurriculumModule {
  final String id;
  final String name;
  final List<Skill> skills;
  final int estimatedWeeks;
  
  const CurriculumModule({
    required this.id,
    required this.name,
    required this.skills,
    required this.estimatedWeeks,
  });
}

class Milestone {
  final String id;
  final String title;
  final String description;
  final int order;
  final List<Skill> targetSkills;
  final List<MilestoneRequirement> requirements;
  final Duration estimatedDuration;
  final bool isCompleted;
  
  const Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.targetSkills,
    required this.requirements,
    required this.estimatedDuration,
    required this.isCompleted,
  });
}

class MilestoneRequirement {
  final Skill skill;
  final double targetAccuracy;
  final int minimumAttempts;
  
  const MilestoneRequirement({
    required this.skill,
    required this.targetAccuracy,
    required this.minimumAttempts,
  });
}

class Exercise {
  final String id;
  final String milestoneId;
  final String title;
  final String description;
  final Skill skill;
  final double difficulty;
  final double targetAccuracy;
  final Duration estimatedDuration;
  final ExerciseType exerciseType;
  final Map<String, dynamic> parameters;
  final bool isCompleted;
  final List<ExerciseCompletion> completions;
  final double bestAccuracy;
  
  const Exercise({
    required this.id,
    required this.milestoneId,
    required this.title,
    required this.description,
    required this.skill,
    required this.difficulty,
    required this.targetAccuracy,
    required this.estimatedDuration,
    required this.exerciseType,
    required this.parameters,
    this.isCompleted = false,
    this.completions = const [],
    this.bestAccuracy = 0.0,
  });
  
  Exercise copyWith({
    double? difficulty,
    bool? isCompleted,
    List<ExerciseCompletion>? completions,
    double? bestAccuracy,
  }) {
    return Exercise(
      id: id,
      milestoneId: milestoneId,
      title: title,
      description: description,
      skill: skill,
      difficulty: difficulty ?? this.difficulty,
      targetAccuracy: targetAccuracy,
      estimatedDuration: estimatedDuration,
      exerciseType: exerciseType,
      parameters: parameters,
      isCompleted: isCompleted ?? this.isCompleted,
      completions: completions ?? this.completions,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
    );
  }
}

class ExerciseCompletion {
  final String exerciseId;
  final double accuracy;
  final Duration timeSpent;
  final int attempts;
  final DateTime completedAt;
  final Map<String, dynamic> additionalMetrics;
  
  const ExerciseCompletion({
    required this.exerciseId,
    required this.accuracy,
    required this.timeSpent,
    required this.attempts,
    required this.completedAt,
    required this.additionalMetrics,
  });
}

class SkillAssessment {
  final String userId;
  final SkillLevel overallLevel;
  final SkillArea chordSkills;
  final SkillArea techniqueSkills;
  final SkillArea rhythmSkills;
  final SkillArea theorySkills;
  final DateTime assessedAt;
  
  const SkillAssessment({
    required this.userId,
    required this.overallLevel,
    required this.chordSkills,
    required this.techniqueSkills,
    required this.rhythmSkills,
    required this.theorySkills,
    required this.assessedAt,
  });
}

class SkillArea {
  final String name;
  final double level;
  final List<String> strengths;
  final List<String> weaknesses;
  
  const SkillArea({
    required this.name,
    required this.level,
    required this.strengths,
    required this.weaknesses,
  });
}

class PerformanceAnalysis {
  final double averageAccuracy;
  final ProgressTrend progressTrend;
  final List<String> strugglingAreas;
  final List<String> excellingAreas;
  final String adaptationReason;
  
  const PerformanceAnalysis({
    required this.averageAccuracy,
    required this.progressTrend,
    required this.strugglingAreas,
    required this.excellingAreas,
    required this.adaptationReason,
  });
}

class LearningPathUpdate {
  final PathUpdateType type;
  final LearningPath path;
  final DateTime timestamp;
  final String? adaptationReason;
  
  const LearningPathUpdate({
    required this.type,
    required this.path,
    required this.timestamp,
    this.adaptationReason,
  });
}

class LearningRecommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final Duration estimatedTime;
  final List<Skill> targetSkills;
  
  const LearningRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.estimatedTime,
    required this.targetSkills,
  });
}

class LearningProgressReport {
  final String userId;
  final double overallProgress;
  final int currentMilestone;
  final int totalMilestones;
  final int completedExercises;
  final int totalExercises;
  final Map<Skill, double> skillProgression;
  final List<String> strengths;
  final List<String> challenges;
  final Duration recommendedPracticeTime;
  final DateTime? nextMilestoneETA;
  final DateTime generatedAt;
  
  const LearningProgressReport({
    required this.userId,
    required this.overallProgress,
    required this.currentMilestone,
    required this.totalMilestones,
    required this.completedExercises,
    required this.totalExercises,
    required this.skillProgression,
    required this.strengths,
    required this.challenges,
    required this.recommendedPracticeTime,
    this.nextMilestoneETA,
    required this.generatedAt,
  });
  
  factory LearningProgressReport.empty(String userId) {
    return LearningProgressReport(
      userId: userId,
      overallProgress: 0.0,
      currentMilestone: 0,
      totalMilestones: 0,
      completedExercises: 0,
      totalExercises: 0,
      skillProgression: {},
      strengths: [],
      challenges: [],
      recommendedPracticeTime: const Duration(minutes: 20),
      generatedAt: DateTime.now(),
    );
  }
}

class PathAdaptation {
  final DateTime timestamp;
  final String reason;
  final List<String> changes;
  final Map<String, dynamic> previousMetrics;
  
  const PathAdaptation({
    required this.timestamp,
    required this.reason,
    required this.changes,
    required this.previousMetrics,
  });
}

class WeakArea {
  final Skill skill;
  final String name;
  final String suggestion;
  
  const WeakArea({
    required this.skill,
    required this.name,
    required this.suggestion,
  });
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final Skill targetSkill;
  final SkillLevel level;
  final Duration estimatedDuration;
  final List<String> prerequisites;
  
  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.targetSkill,
    required this.level,
    required this.estimatedDuration,
    required this.prerequisites,
  });
}

// Enums
enum LearningGoal {
  playFavoriteSongs,
  learnChords,
  improvisation,
  technicalMastery,
  performanceReady,
  composition,
}

enum SkillLevel {
  beginner,
  intermediate,
  advanced,
}

enum LearningStyle {
  visual,
  auditory,
  kinesthetic,
  mixed,
}

enum Skill {
  holdingGuitar,
  tuning,
  basicStrumming,
  openChords,
  chordTransitions,
  alternatePicking,
  downstrokes,
  simpleSongs,
  rhythm,
  barreChords,
  seventhChords,
  extendedChords,
  scales,
  bending,
  vibrato,
  hammerOns,
  pullOffs,
  slides,
  improvisation,
  jamming,
  tapping,
  sweepPicking,
  economyPicking,
  modes,
  jazzHarmony,
  composition,
  recording,
  performance,
  teaching,
}

extension SkillExtension on Skill {
  String get displayName {
    switch (this) {
      case Skill.holdingGuitar:
        return 'Holding Guitar';
      case Skill.tuning:
        return 'Tuning';
      case Skill.basicStrumming:
        return 'Basic Strumming';
      case Skill.openChords:
        return 'Open Chords';
      case Skill.chordTransitions:
        return 'Chord Transitions';
      case Skill.alternatePicking:
        return 'Alternate Picking';
      case Skill.downstrokes:
        return 'Downstrokes';
      case Skill.simpleSongs:
        return 'Simple Songs';
      case Skill.rhythm:
        return 'Rhythm';
      case Skill.barreChords:
        return 'Barre Chords';
      case Skill.seventhChords:
        return 'Seventh Chords';
      case Skill.extendedChords:
        return 'Extended Chords';
      case Skill.scales:
        return 'Scales';
      case Skill.bending:
        return 'String Bending';
      case Skill.vibrato:
        return 'Vibrato';
      case Skill.hammerOns:
        return 'Hammer-Ons';
      case Skill.pullOffs:
        return 'Pull-Offs';
      case Skill.slides:
        return 'Slides';
      case Skill.improvisation:
        return 'Improvisation';
      case Skill.jamming:
        return 'Jamming';
      case Skill.tapping:
        return 'Tapping';
      case Skill.sweepPicking:
        return 'Sweep Picking';
      case Skill.economyPicking:
        return 'Economy Picking';
      case Skill.modes:
        return 'Modes';
      case Skill.jazzHarmony:
        return 'Jazz Harmony';
      case Skill.composition:
        return 'Composition';
      case Skill.recording:
        return 'Recording';
      case Skill.performance:
        return 'Performance';
      case Skill.teaching:
        return 'Teaching';
    }
  }
}

enum ProgressTrend {
  improving,
  stable,
  declining,
}

enum PathUpdateType {
  created,
  adapted,
  milestoneAdvanced,
  completed,
}

enum ExerciseType {
  chordPractice,
  chordProgression,
  techniquePractice,
  scalePractice,
  songPractice,
  rhythmPractice,
  general,
}

enum RecommendationType {
  remediation,
  progression,
  challenge,
  schedule,
}

enum RecommendationPriority {
  low,
  medium,
  high,
  critical,
}

class AdaptiveLearningException implements Exception {
  final String message;
  
  const AdaptiveLearningException(this.message);
  
  @override
  String toString() => 'AdaptiveLearningException: $message';
}

// Riverpod providers
final adaptiveLearningServiceProvider = Provider<AdaptiveLearningService>((ref) {
  final statsService = ref.read(statsServiceProvider);
  final chordService = ref.read(chordRecognitionServiceProvider);
  final techniqueService = ref.read(techniqueDetectionServiceProvider);
  return AdaptiveLearningService(statsService, chordService, techniqueService);
});

final learningProfileProvider = FutureProvider.family<LearningProfile?, String>((ref, userId) async {
  final service = ref.read(adaptiveLearningServiceProvider);
  return service._userProfiles[userId];
});

final learningPathProvider = FutureProvider.family<LearningPath?, String>((ref, userId) async {
  final service = ref.read(adaptiveLearningServiceProvider);
  return service._activePaths[userId];
});

final learningPathUpdatesProvider = StreamProvider<LearningPathUpdate>((ref) {
  final service = ref.read(adaptiveLearningServiceProvider);
  return service.pathUpdates;
});

final skillAssessmentsProvider = StreamProvider<SkillAssessment>((ref) {
  final service = ref.read(adaptiveLearningServiceProvider);
  return service.skillAssessments;
});

final learningRecommendationsProvider = Provider.family<List<LearningRecommendation>, String>((ref, userId) {
  final service = ref.read(adaptiveLearningServiceProvider);
  return service.getLearningRecommendations(userId);
});

final learningProgressProvider = Provider.family<LearningProgressReport, String>((ref, userId) {
  final service = ref.read(adaptiveLearningServiceProvider);
  return service.getProgressReport(userId);
});

final nextExerciseProvider = FutureProvider.family<Exercise?, String>((ref, userId) async {
  final service = ref.read(adaptiveLearningServiceProvider);
  return service.getNextExercise(userId);
});