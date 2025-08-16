import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';

/// Technique Detection Service
/// Uses AI and signal processing to detect guitar playing techniques in real-time
/// Provides form correction, timing analysis, and personalized improvement suggestions
class TechniqueDetectionService {
  // Detection state
  bool _isDetecting = false;
  final Map<TechniqueType, TechniqueDetector> _detectors = {};
  final List<TechniqueDetectionResult> _detectionHistory = [];
  
  // Analysis parameters
  static const int _sampleRate = 44100;
  static const int _windowSize = 1024;
  static const double _detectionThreshold = 0.7;
  static const int _historyLimit = 1000;
  
  // Real-time feedback
  final StreamController<TechniqueDetectionResult> _detectionController = StreamController.broadcast();
  final StreamController<TechniqueFeedback> _feedbackController = StreamController.broadcast();
  final StreamController<TechniqueStats> _statsController = StreamController.broadcast();
  
  TechniqueDetectionService() {
    _initializeDetectors();
  }
  
  /// Stream of technique detection results
  Stream<TechniqueDetectionResult> get detectionResults => _detectionController.stream;
  
  /// Stream of real-time feedback
  Stream<TechniqueFeedback> get feedback => _feedbackController.stream;
  
  /// Stream of technique statistics
  Stream<TechniqueStats> get stats => _statsController.stream;
  
  /// Start real-time technique detection
  Future<void> startDetection({
    List<TechniqueType>? targetTechniques,
    double? sensitivity,
  }) async {
    if (_isDetecting) return;
    
    _isDetecting = true;
    
    // Configure detectors based on target techniques
    final techniques = targetTechniques ?? TechniqueType.values;
    for (final technique in techniques) {
      _detectors[technique]?.setSensitivity(sensitivity ?? 0.7);
    }
    
    // Start background detection
    _startDetectionLoop();
  }
  
  /// Stop technique detection
  Future<void> stopDetection() async {
    _isDetecting = false;
  }
  
  /// Analyze audio buffer for techniques
  Future<List<TechniqueDetectionResult>> analyzeAudioBuffer(
    Float32List audioBuffer, {
    List<TechniqueType>? targetTechniques,
  }) async {
    try {
      final results = <TechniqueDetectionResult>[];
      final techniques = targetTechniques ?? TechniqueType.values;
      
      for (final technique in techniques) {
        final detector = _detectors[technique];
        if (detector != null) {
          final result = await detector.analyze(audioBuffer);
          if (result.confidence >= _detectionThreshold) {
            results.add(result);
            _addToHistory(result);
          }
        }
      }
      
      // Sort by confidence
      results.sort((a, b) => b.confidence.compareTo(a.confidence));
      
      // Generate feedback
      if (results.isNotEmpty) {
        final feedback = _generateFeedback(results);
        _feedbackController.add(feedback);
      }
      
      return results;
    } catch (e) {
      throw TechniqueDetectionException('Failed to analyze audio: $e');
    }
  }
  
  /// Analyze specific technique in detail
  Future<DetailedTechniqueAnalysis> analyzeSpecificTechnique({
    required TechniqueType technique,
    required Float32List audioBuffer,
    TechniqueParameters? parameters,
  }) async {
    final detector = _detectors[technique];
    if (detector == null) {
      throw TechniqueDetectionException('Detector for $technique not available');
    }
    
    final result = await detector.analyze(audioBuffer);
    final detailedAnalysis = await detector.getDetailedAnalysis(audioBuffer, parameters);
    
    return DetailedTechniqueAnalysis(
      technique: technique,
      confidence: result.confidence,
      timing: detailedAnalysis.timing,
      accuracy: detailedAnalysis.accuracy,
      form: detailedAnalysis.form,
      suggestions: detailedAnalysis.suggestions,
      targetParameters: parameters,
      measuredParameters: detailedAnalysis.measuredParameters,
      timestamp: DateTime.now(),
    );
  }
  
  /// Get technique statistics
  TechniqueStatsOverview getTechniqueStats({
    TechniqueType? specificTechnique,
    Duration? timeWindow,
  }) {
    final relevantHistory = _getRelevantHistory(specificTechnique, timeWindow);
    
    if (relevantHistory.isEmpty) {
      return TechniqueStatsOverview.empty();
    }
    
    final stats = <TechniqueType, TechniqueStats>{};
    
    // Group by technique
    final groupedResults = <TechniqueType, List<TechniqueDetectionResult>>{};
    for (final result in relevantHistory) {
      groupedResults[result.technique] ??= [];
      groupedResults[result.technique]!.add(result);
    }
    
    // Calculate stats for each technique
    for (final entry in groupedResults.entries) {
      final technique = entry.key;
      final results = entry.value;
      
      final avgConfidence = results.map((r) => r.confidence).reduce((a, b) => a + b) / results.length;
      final avgAccuracy = results.map((r) => r.accuracy).reduce((a, b) => a + b) / results.length;
      final consistency = _calculateConsistency(results);
      final improvement = _calculateImprovement(results);
      
      stats[technique] = TechniqueStats(
        technique: technique,
        attemptCount: results.length,
        averageConfidence: avgConfidence,
        averageAccuracy: avgAccuracy,
        consistency: consistency,
        improvement: improvement,
        lastAttempt: results.last.timestamp,
        bestAttempt: results.reduce((a, b) => a.accuracy > b.accuracy ? a : b),
      );
    }
    
    return TechniqueStatsOverview(
      totalAttempts: relevantHistory.length,
      techniquesDetected: stats.keys.length,
      overallAccuracy: relevantHistory.map((r) => r.accuracy).reduce((a, b) => a + b) / relevantHistory.length,
      individualStats: stats,
      timeWindow: timeWindow,
      analysisDate: DateTime.now(),
    );
  }
  
  /// Get personalized practice recommendations
  List<TechniqueRecommendation> getPracticeRecommendations({
    TechniqueLevel? userLevel,
    List<TechniqueType>? focusAreas,
  }) {
    final recommendations = <TechniqueRecommendation>[];
    final stats = getTechniqueStats(timeWindow: const Duration(days: 7));
    
    // Analyze weakness patterns
    final weaknesses = _identifyWeaknesses(stats);
    for (final weakness in weaknesses) {
      recommendations.add(TechniqueRecommendation(
        type: RecommendationType.improvement,
        technique: weakness.technique,
        priority: RecommendationPriority.high,
        title: 'Improve ${weakness.technique.displayName}',
        description: 'Your ${weakness.technique.displayName} accuracy is below target. Focus on ${_getTechniqueAdvice(weakness.technique)}',
        targetAccuracy: 0.85,
        currentAccuracy: weakness.averageAccuracy,
        exerciseCount: 3,
        estimatedTime: const Duration(minutes: 15),
      ));
    }
    
    // Suggest new techniques based on mastered ones
    final masteredTechniques = _getMasteredTechniques(stats);
    final nextTechniques = _suggestNextTechniques(masteredTechniques, userLevel);
    for (final technique in nextTechniques) {
      recommendations.add(TechniqueRecommendation(
        type: RecommendationType.newTechnique,
        technique: technique,
        priority: RecommendationPriority.medium,
        title: 'Learn ${technique.displayName}',
        description: 'You\'re ready to learn ${technique.displayName}. ${_getTechniqueIntroduction(technique)}',
        targetAccuracy: 0.7,
        currentAccuracy: 0.0,
        exerciseCount: 5,
        estimatedTime: const Duration(minutes: 20),
      ));
    }
    
    // Suggest consistency practice for intermediate techniques
    final inconsistentTechniques = _getInconsistentTechniques(stats);
    for (final technique in inconsistentTechniques) {
      recommendations.add(TechniqueRecommendation(
        type: RecommendationType.consistency,
        technique: technique.technique,
        priority: RecommendationPriority.medium,
        title: 'Improve ${technique.technique.displayName} Consistency',
        description: 'Work on making your ${technique.technique.displayName} more consistent',
        targetAccuracy: technique.averageAccuracy + 0.1,
        currentAccuracy: technique.averageAccuracy,
        exerciseCount: 4,
        estimatedTime: const Duration(minutes: 12),
      ));
    }
    
    // Sort by priority
    recommendations.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    
    return recommendations.take(5).toList();
  }
  
  /// Compare technique execution to ideal form
  Future<TechniqueComparison> compareToIdealForm({
    required TechniqueType technique,
    required Float32List audioBuffer,
  }) async {
    final detector = _detectors[technique];
    if (detector == null) {
      throw TechniqueDetectionException('Detector for $technique not available');
    }
    
    final analysis = await detector.getDetailedAnalysis(audioBuffer, null);
    final idealParameters = _getIdealParameters(technique);
    
    return TechniqueComparison(
      technique: technique,
      userForm: analysis.form,
      idealForm: idealParameters.idealForm,
      deviations: _calculateDeviations(analysis.form, idealParameters.idealForm),
      overallMatch: _calculateOverallMatch(analysis.form, idealParameters.idealForm),
      suggestions: _generateFormSuggestions(technique, analysis.form, idealParameters.idealForm),
      timestamp: DateTime.now(),
    );
  }
  
  /// Calibrate detectors for user's playing style
  Future<void> calibrateForUser({
    required String userId,
    required Map<TechniqueType, List<Float32List>> calibrationSamples,
  }) async {
    for (final entry in calibrationSamples.entries) {
      final technique = entry.key;
      final samples = entry.value;
      final detector = _detectors[technique];
      
      if (detector != null && samples.isNotEmpty) {
        await detector.calibrate(samples);
      }
    }
  }
  
  // Private methods
  void _initializeDetectors() {
    _detectors[TechniqueType.alternatePicking] = AlternatePickingDetector();
    _detectors[TechniqueType.palmMuting] = PalmMutingDetector();
    _detectors[TechniqueType.bending] = BendingDetector();
    _detectors[TechniqueType.vibrato] = VibratoDetector();
    _detectors[TechniqueType.hammerOn] = HammerOnDetector();
    _detectors[TechniqueType.pullOff] = PullOffDetector();
    _detectors[TechniqueType.slide] = SlideDetector();
    _detectors[TechniqueType.tremoloPicking] = TremoloPickingDetector();
    _detectors[TechniqueType.tapping] = TappingDetector();
  }
  
  void _startDetectionLoop() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isDetecting) {
        timer.cancel();
        return;
      }
      
      // In a real implementation, this would capture audio from microphone
      // and analyze it using the configured detectors
    });
  }
  
  void _addToHistory(TechniqueDetectionResult result) {
    _detectionHistory.add(result);
    _detectionController.add(result);
    
    // Limit history size
    if (_detectionHistory.length > _historyLimit) {
      _detectionHistory.removeAt(0);
    }
    
    // Update stats
    final stats = getTechniqueStats();
    _statsController.add(stats.individualStats[result.technique] ?? TechniqueStats.empty(result.technique));
  }
  
  TechniqueFeedback _generateFeedback(List<TechniqueDetectionResult> results) {
    final best = results.first;
    
    FeedbackType feedbackType;
    String message;
    List<String> suggestions;
    
    if (best.accuracy >= 0.9) {
      feedbackType = FeedbackType.excellent;
      message = 'Excellent ${best.technique.displayName}!';
      suggestions = ['Great form!', 'Keep up the consistency'];
    } else if (best.accuracy >= 0.75) {
      feedbackType = FeedbackType.good;
      message = 'Good ${best.technique.displayName}';
      suggestions = _getImprovementSuggestions(best.technique, best.accuracy);
    } else if (best.accuracy >= 0.6) {
      feedbackType = FeedbackType.needsWork;
      message = '${best.technique.displayName} needs work';
      suggestions = _getBasicSuggestions(best.technique);
    } else {
      feedbackType = FeedbackType.poor;
      message = 'Focus on ${best.technique.displayName} fundamentals';
      suggestions = _getFundamentalSuggestions(best.technique);
    }
    
    return TechniqueFeedback(
      type: feedbackType,
      message: message,
      suggestions: suggestions,
      detectedTechnique: best.technique,
      accuracy: best.accuracy,
      confidence: best.confidence,
      timestamp: DateTime.now(),
    );
  }
  
  List<TechniqueDetectionResult> _getRelevantHistory(TechniqueType? technique, Duration? timeWindow) {
    var results = _detectionHistory;
    
    if (technique != null) {
      results = results.where((r) => r.technique == technique).toList();
    }
    
    if (timeWindow != null) {
      final cutoff = DateTime.now().subtract(timeWindow);
      results = results.where((r) => r.timestamp.isAfter(cutoff)).toList();
    }
    
    return results;
  }
  
  double _calculateConsistency(List<TechniqueDetectionResult> results) {
    if (results.length < 2) return 1.0;
    
    final accuracies = results.map((r) => r.accuracy).toList();
    final mean = accuracies.reduce((a, b) => a + b) / accuracies.length;
    final variance = accuracies.map((a) => math.pow(a - mean, 2)).reduce((a, b) => a + b) / accuracies.length;
    final standardDeviation = math.sqrt(variance);
    
    // Convert to consistency score (lower deviation = higher consistency)
    return (1.0 - standardDeviation).clamp(0.0, 1.0);
  }
  
  double _calculateImprovement(List<TechniqueDetectionResult> results) {
    if (results.length < 5) return 0.0;
    
    final recentAccuracy = results.skip(results.length - 3).map((r) => r.accuracy).reduce((a, b) => a + b) / 3;
    final earlierAccuracy = results.take(3).map((r) => r.accuracy).reduce((a, b) => a + b) / 3;
    
    return (recentAccuracy - earlierAccuracy).clamp(-1.0, 1.0);
  }
  
  List<TechniqueStats> _identifyWeaknesses(TechniqueStatsOverview overview) {
    return overview.individualStats.values
        .where((stats) => stats.averageAccuracy < 0.7 && stats.attemptCount >= 3)
        .toList()
      ..sort((a, b) => a.averageAccuracy.compareTo(b.averageAccuracy));
  }
  
  List<TechniqueType> _getMasteredTechniques(TechniqueStatsOverview overview) {
    return overview.individualStats.values
        .where((stats) => stats.averageAccuracy >= 0.85 && stats.consistency >= 0.8)
        .map((stats) => stats.technique)
        .toList();
  }
  
  List<TechniqueType> _suggestNextTechniques(List<TechniqueType> mastered, TechniqueLevel? userLevel) {
    final progressionMap = {
      TechniqueType.alternatePicking: [TechniqueType.tremoloPicking, TechniqueType.palmMuting],
      TechniqueType.palmMuting: [TechniqueType.tremoloPicking],
      TechniqueType.hammerOn: [TechniqueType.pullOff, TechniqueType.slide],
      TechniqueType.pullOff: [TechniqueType.slide, TechniqueType.tapping],
      TechniqueType.bending: [TechniqueType.vibrato],
      TechniqueType.vibrato: [TechniqueType.bending],
    };
    
    final suggestions = <TechniqueType>{};
    
    for (final masteredTechnique in mastered) {
      final nextTechniques = progressionMap[masteredTechnique] ?? [];
      suggestions.addAll(nextTechniques);
    }
    
    // Remove already mastered techniques
    suggestions.removeAll(mastered);
    
    return suggestions.take(3).toList();
  }
  
  List<TechniqueStats> _getInconsistentTechniques(TechniqueStatsOverview overview) {
    return overview.individualStats.values
        .where((stats) => stats.averageAccuracy >= 0.6 && stats.consistency < 0.7)
        .toList();
  }
  
  String _getTechniqueAdvice(TechniqueType technique) {
    switch (technique) {
      case TechniqueType.alternatePicking:
        return 'hand position and pick angle';
      case TechniqueType.palmMuting:
        return 'palm placement and pressure';
      case TechniqueType.bending:
        return 'finger strength and pitch accuracy';
      case TechniqueType.vibrato:
        return 'wrist motion and rhythm';
      case TechniqueType.hammerOn:
        return 'finger strength and timing';
      case TechniqueType.pullOff:
        return 'finger positioning and release';
      case TechniqueType.slide:
        return 'finger pressure and smoothness';
      case TechniqueType.tremoloPicking:
        return 'wrist flexibility and speed';
      case TechniqueType.tapping:
        return 'finger independence and clarity';
    }
  }
  
  String _getTechniqueIntroduction(TechniqueType technique) {
    switch (technique) {
      case TechniqueType.alternatePicking:
        return 'Start with slow, controlled movements.';
      case TechniqueType.palmMuting:
        return 'Begin with light palm contact.';
      case TechniqueType.bending:
        return 'Practice half-step bends first.';
      case TechniqueType.vibrato:
        return 'Start with wide, slow vibrato.';
      case TechniqueType.hammerOn:
        return 'Focus on finger strength exercises.';
      case TechniqueType.pullOff:
        return 'Practice clean note separation.';
      case TechniqueType.slide:
        return 'Begin with short slide distances.';
      case TechniqueType.tremoloPicking:
        return 'Build up speed gradually.';
      case TechniqueType.tapping:
        return 'Start with simple two-finger patterns.';
    }
  }
  
  List<String> _getImprovementSuggestions(TechniqueType technique, double accuracy) {
    switch (technique) {
      case TechniqueType.alternatePicking:
        return ['Focus on pick angle', 'Keep movements small', 'Practice with metronome'];
      case TechniqueType.palmMuting:
        return ['Adjust palm pressure', 'Check hand position', 'Practice muted/open alternation'];
      default:
        return ['Practice slowly', 'Focus on form', 'Use metronome'];
    }
  }
  
  List<String> _getBasicSuggestions(TechniqueType technique) {
    return ['Slow down tempo', 'Focus on fundamentals', 'Practice basic exercises'];
  }
  
  List<String> _getFundamentalSuggestions(TechniqueType technique) {
    return ['Review technique basics', 'Practice foundation exercises', 'Consider video tutorials'];
  }
  
  TechniqueParameters _getIdealParameters(TechniqueType technique) {
    switch (technique) {
      case TechniqueType.alternatePicking:
        return TechniqueParameters(
          idealForm: TechniqueForm(
            handPosition: 'Relaxed, slightly angled',
            fingerPosition: 'Pick held between thumb and index',
            movement: 'Small, controlled wrist motion',
            timing: 'Even, consistent',
          ),
          optimalTempo: 120,
          targetAccuracy: 0.9,
        );
      default:
        return TechniqueParameters(
          idealForm: TechniqueForm(
            handPosition: 'Relaxed',
            fingerPosition: 'Natural curve',
            movement: 'Controlled',
            timing: 'Steady',
          ),
          optimalTempo: 100,
          targetAccuracy: 0.8,
        );
    }
  }
  
  List<FormDeviation> _calculateDeviations(TechniqueForm userForm, TechniqueForm idealForm) {
    final deviations = <FormDeviation>[];
    
    // Simplified deviation calculation
    if (userForm.handPosition != idealForm.handPosition) {
      deviations.add(FormDeviation(
        aspect: 'Hand Position',
        deviation: 0.3,
        description: 'Hand position differs from ideal',
      ));
    }
    
    return deviations;
  }
  
  double _calculateOverallMatch(TechniqueForm userForm, TechniqueForm idealForm) {
    // Simplified matching calculation
    int matches = 0;
    int total = 4; // handPosition, fingerPosition, movement, timing
    
    if (userForm.handPosition == idealForm.handPosition) matches++;
    if (userForm.fingerPosition == idealForm.fingerPosition) matches++;
    if (userForm.movement == idealForm.movement) matches++;
    if (userForm.timing == idealForm.timing) matches++;
    
    return matches / total;
  }
  
  List<String> _generateFormSuggestions(TechniqueType technique, TechniqueForm userForm, TechniqueForm idealForm) {
    final suggestions = <String>[];
    
    if (userForm.handPosition != idealForm.handPosition) {
      suggestions.add('Adjust hand position: ${idealForm.handPosition}');
    }
    
    if (userForm.fingerPosition != idealForm.fingerPosition) {
      suggestions.add('Check finger position: ${idealForm.fingerPosition}');
    }
    
    return suggestions;
  }
  
  void dispose() {
    _detectionController.close();
    _feedbackController.close();
    _statsController.close();
  }
}

// Abstract base class for technique detectors
abstract class TechniqueDetector {
  double _sensitivity = 0.7;
  
  void setSensitivity(double sensitivity) {
    _sensitivity = sensitivity.clamp(0.1, 1.0);
  }
  
  Future<TechniqueDetectionResult> analyze(Float32List audioBuffer);
  
  Future<DetailedAnalysis> getDetailedAnalysis(Float32List audioBuffer, TechniqueParameters? parameters);
  
  Future<void> calibrate(List<Float32List> samples) async {
    // Default implementation - override in specific detectors
  }
}

// Specific technique detectors
class AlternatePickingDetector extends TechniqueDetector {
  @override
  Future<TechniqueDetectionResult> analyze(Float32List audioBuffer) async {
    // Analyze attack patterns and timing consistency
    final attackStrength = _analyzeAttackPatterns(audioBuffer);
    final timingConsistency = _analyzeTimingConsistency(audioBuffer);
    
    final confidence = (attackStrength + timingConsistency) / 2;
    final accuracy = confidence * 0.9; // Slightly conservative
    
    return TechniqueDetectionResult(
      technique: TechniqueType.alternatePicking,
      confidence: confidence,
      accuracy: accuracy,
      timestamp: DateTime.now(),
      parameters: {'attack_strength': attackStrength, 'timing_consistency': timingConsistency},
    );
  }
  
  @override
  Future<DetailedAnalysis> getDetailedAnalysis(Float32List audioBuffer, TechniqueParameters? parameters) async {
    // Detailed alternate picking analysis
    return DetailedAnalysis(
      timing: TimingAnalysis(consistency: 0.8, averageInterval: 0.5),
      accuracy: 0.85,
      form: TechniqueForm(
        handPosition: 'Good',
        fingerPosition: 'Proper pick grip',
        movement: 'Consistent wrist motion',
        timing: 'Steady',
      ),
      suggestions: ['Maintain consistent pick angle', 'Focus on even attacks'],
      measuredParameters: {'pick_angle': 45.0, 'attack_velocity': 0.7},
    );
  }
  
  double _analyzeAttackPatterns(Float32List audioBuffer) {
    // Simplified attack analysis
    double totalAttack = 0.0;
    int attackCount = 0;
    
    for (int i = 1; i < audioBuffer.length; i++) {
      final diff = (audioBuffer[i] - audioBuffer[i - 1]).abs();
      if (diff > 0.1) { // Attack threshold
        totalAttack += diff;
        attackCount++;
      }
    }
    
    return attackCount > 0 ? (totalAttack / attackCount).clamp(0.0, 1.0) : 0.0;
  }
  
  double _analyzeTimingConsistency(Float32List audioBuffer) {
    // Simplified timing analysis
    return 0.8; // Mock value
  }
}

class PalmMutingDetector extends TechniqueDetector {
  @override
  Future<TechniqueDetectionResult> analyze(Float32List audioBuffer) async {
    final dampening = _analyzeDampening(audioBuffer);
    final consistency = _analyzeMutingConsistency(audioBuffer);
    
    final confidence = (dampening + consistency) / 2;
    final accuracy = confidence * 0.85;
    
    return TechniqueDetectionResult(
      technique: TechniqueType.palmMuting,
      confidence: confidence,
      accuracy: accuracy,
      timestamp: DateTime.now(),
      parameters: {'dampening': dampening, 'consistency': consistency},
    );
  }
  
  @override
  Future<DetailedAnalysis> getDetailedAnalysis(Float32List audioBuffer, TechniqueParameters? parameters) async {
    return DetailedAnalysis(
      timing: TimingAnalysis(consistency: 0.75, averageInterval: 0.0),
      accuracy: 0.8,
      form: TechniqueForm(
        handPosition: 'Palm on strings',
        fingerPosition: 'Normal',
        movement: 'Controlled muting',
        timing: 'Consistent',
      ),
      suggestions: ['Adjust palm pressure', 'Maintain consistent contact'],
      measuredParameters: {'mute_level': 0.6},
    );
  }
  
  double _analyzeDampening(Float32List audioBuffer) {
    // Analyze frequency dampening
    return 0.75; // Mock value
  }
  
  double _analyzeMutingConsistency(Float32List audioBuffer) {
    return 0.7; // Mock value
  }
}

// Additional detector implementations would follow similar patterns...
class BendingDetector extends TechniqueDetector {
  @override
  Future<TechniqueDetectionResult> analyze(Float32List audioBuffer) async {
    return TechniqueDetectionResult(
      technique: TechniqueType.bending,
      confidence: 0.8,
      accuracy: 0.75,
      timestamp: DateTime.now(),
      parameters: {},
    );
  }
  
  @override
  Future<DetailedAnalysis> getDetailedAnalysis(Float32List audioBuffer, TechniqueParameters? parameters) async {
    return DetailedAnalysis(
      timing: TimingAnalysis(consistency: 0.7, averageInterval: 0.0),
      accuracy: 0.75,
      form: TechniqueForm(handPosition: 'Good', fingerPosition: 'Good', movement: 'Good', timing: 'Good'),
      suggestions: [],
      measuredParameters: {},
    );
  }
}

class VibratoDetector extends TechniqueDetector {
  @override
  Future<TechniqueDetectionResult> analyze(Float32List audioBuffer) async {
    return TechniqueDetectionResult(
      technique: TechniqueType.vibrato,
      confidence: 0.7,
      accuracy: 0.7,
      timestamp: DateTime.now(),
      parameters: {},
    );
  }
  
  @override
  Future<DetailedAnalysis> getDetailedAnalysis(Float32List audioBuffer, TechniqueParameters? parameters) async {
    return DetailedAnalysis(
      timing: TimingAnalysis(consistency: 0.6, averageInterval: 0.0),
      accuracy: 0.7,
      form: TechniqueForm(handPosition: 'Good', fingerPosition: 'Good', movement: 'Good', timing: 'Good'),
      suggestions: [],
      measuredParameters: {},
    );
  }
}

class HammerOnDetector extends TechniqueDetector {
  @override
  Future<TechniqueDetectionResult> analyze(Float32List audioBuffer) async {
    return TechniqueDetectionResult(
      technique: TechniqueType.hammerOn,
      confidence: 0.75,
      accuracy: 0.8,
      timestamp: DateTime.now(),
      parameters: {},
    );
  }
  
  @override
  Future<DetailedAnalysis> getDetailedAnalysis(Float32List audioBuffer, TechniqueParameters? parameters) async {
    return DetailedAnalysis(
      timing: TimingAnalysis(consistency: 0.8, averageInterval: 0.0),
      accuracy: 0.8,
      form: TechniqueForm(handPosition: 'Good', fingerPosition: 'Good', movement: 'Good', timing: 'Good'),
      suggestions: [],
      measuredParameters: {},
    );
  }
}

class PullOffDetector extends TechniqueDetector {
  @override
  Future<TechniqueDetectionResult> analyze(Float32List audioBuffer) async {
    return TechniqueDetectionResult(
      technique: TechniqueType.pullOff,
      confidence: 0.72,
      accuracy: 0.78,
      timestamp: DateTime.now(),
      parameters: {},
    );
  }
  
  @override
  Future<DetailedAnalysis> getDetailedAnalysis(Float32List audioBuffer, TechniqueParameters? parameters) async {
    return DetailedAnalysis(
      timing: TimingAnalysis(consistency: 0.75, averageInterval: 0.0),
      accuracy: 0.78,
      form: TechniqueForm(handPosition: 'Good', fingerPosition: 'Good', movement: 'Good', timing: 'Good'),
      suggestions: [],
      measuredParameters: {},
    );
  }
}

class SlideDetector extends TechniqueDetector {
  @override
  Future<TechniqueDetectionResult> analyze(Float32List audioBuffer) async {
    return TechniqueDetectionResult(
      technique: TechniqueType.slide,
      confidence: 0.68,
      accuracy: 0.72,
      timestamp: DateTime.now(),
      parameters: {},
    );
  }
  
  @override
  Future<DetailedAnalysis> getDetailedAnalysis(Float32List audioBuffer, TechniqueParameters? parameters) async {
    return DetailedAnalysis(
      timing: TimingAnalysis(consistency: 0.7, averageInterval: 0.0),
      accuracy: 0.72,
      form: TechniqueForm(handPosition: 'Good', fingerPosition: 'Good', movement: 'Good', timing: 'Good'),
      suggestions: [],
      measuredParameters: {},
    );
  }
}

class TremoloPickingDetector extends TechniqueDetector {
  @override
  Future<TechniqueDetectionResult> analyze(Float32List audioBuffer) async {
    return TechniqueDetectionResult(
      technique: TechniqueType.tremoloPicking,
      confidence: 0.65,
      accuracy: 0.7,
      timestamp: DateTime.now(),
      parameters: {},
    );
  }
  
  @override
  Future<DetailedAnalysis> getDetailedAnalysis(Float32List audioBuffer, TechniqueParameters? parameters) async {
    return DetailedAnalysis(
      timing: TimingAnalysis(consistency: 0.65, averageInterval: 0.0),
      accuracy: 0.7,
      form: TechniqueForm(handPosition: 'Good', fingerPosition: 'Good', movement: 'Good', timing: 'Good'),
      suggestions: [],
      measuredParameters: {},
    );
  }
}

class TappingDetector extends TechniqueDetector {
  @override
  Future<TechniqueDetectionResult> analyze(Float32List audioBuffer) async {
    return TechniqueDetectionResult(
      technique: TechniqueType.tapping,
      confidence: 0.6,
      accuracy: 0.65,
      timestamp: DateTime.now(),
      parameters: {},
    );
  }
  
  @override
  Future<DetailedAnalysis> getDetailedAnalysis(Float32List audioBuffer, TechniqueParameters? parameters) async {
    return DetailedAnalysis(
      timing: TimingAnalysis(consistency: 0.6, averageInterval: 0.0),
      accuracy: 0.65,
      form: TechniqueForm(handPosition: 'Good', fingerPosition: 'Good', movement: 'Good', timing: 'Good'),
      suggestions: [],
      measuredParameters: {},
    );
  }
}

// Data Models
class TechniqueDetectionResult {
  final TechniqueType technique;
  final double confidence;
  final double accuracy;
  final DateTime timestamp;
  final Map<String, dynamic> parameters;
  
  const TechniqueDetectionResult({
    required this.technique,
    required this.confidence,
    required this.accuracy,
    required this.timestamp,
    required this.parameters,
  });
}

class DetailedTechniqueAnalysis {
  final TechniqueType technique;
  final double confidence;
  final TimingAnalysis timing;
  final double accuracy;
  final TechniqueForm form;
  final List<String> suggestions;
  final TechniqueParameters? targetParameters;
  final Map<String, dynamic> measuredParameters;
  final DateTime timestamp;
  
  const DetailedTechniqueAnalysis({
    required this.technique,
    required this.confidence,
    required this.timing,
    required this.accuracy,
    required this.form,
    required this.suggestions,
    this.targetParameters,
    required this.measuredParameters,
    required this.timestamp,
  });
}

class DetailedAnalysis {
  final TimingAnalysis timing;
  final double accuracy;
  final TechniqueForm form;
  final List<String> suggestions;
  final Map<String, dynamic> measuredParameters;
  
  const DetailedAnalysis({
    required this.timing,
    required this.accuracy,
    required this.form,
    required this.suggestions,
    required this.measuredParameters,
  });
}

class TimingAnalysis {
  final double consistency;
  final double averageInterval;
  
  const TimingAnalysis({
    required this.consistency,
    required this.averageInterval,
  });
}

class TechniqueForm {
  final String handPosition;
  final String fingerPosition;
  final String movement;
  final String timing;
  
  const TechniqueForm({
    required this.handPosition,
    required this.fingerPosition,
    required this.movement,
    required this.timing,
  });
}

class TechniqueParameters {
  final TechniqueForm idealForm;
  final int optimalTempo;
  final double targetAccuracy;
  
  const TechniqueParameters({
    required this.idealForm,
    required this.optimalTempo,
    required this.targetAccuracy,
  });
}

class TechniqueFeedback {
  final FeedbackType type;
  final String message;
  final List<String> suggestions;
  final TechniqueType detectedTechnique;
  final double accuracy;
  final double confidence;
  final DateTime timestamp;
  
  const TechniqueFeedback({
    required this.type,
    required this.message,
    required this.suggestions,
    required this.detectedTechnique,
    required this.accuracy,
    required this.confidence,
    required this.timestamp,
  });
}

class TechniqueStats {
  final TechniqueType technique;
  final int attemptCount;
  final double averageConfidence;
  final double averageAccuracy;
  final double consistency;
  final double improvement;
  final DateTime lastAttempt;
  final TechniqueDetectionResult bestAttempt;
  
  const TechniqueStats({
    required this.technique,
    required this.attemptCount,
    required this.averageConfidence,
    required this.averageAccuracy,
    required this.consistency,
    required this.improvement,
    required this.lastAttempt,
    required this.bestAttempt,
  });
  
  factory TechniqueStats.empty(TechniqueType technique) {
    final now = DateTime.now();
    return TechniqueStats(
      technique: technique,
      attemptCount: 0,
      averageConfidence: 0.0,
      averageAccuracy: 0.0,
      consistency: 0.0,
      improvement: 0.0,
      lastAttempt: now,
      bestAttempt: TechniqueDetectionResult(
        technique: technique,
        confidence: 0.0,
        accuracy: 0.0,
        timestamp: now,
        parameters: {},
      ),
    );
  }
}

class TechniqueStatsOverview {
  final int totalAttempts;
  final int techniquesDetected;
  final double overallAccuracy;
  final Map<TechniqueType, TechniqueStats> individualStats;
  final Duration? timeWindow;
  final DateTime analysisDate;
  
  const TechniqueStatsOverview({
    required this.totalAttempts,
    required this.techniquesDetected,
    required this.overallAccuracy,
    required this.individualStats,
    this.timeWindow,
    required this.analysisDate,
  });
  
  factory TechniqueStatsOverview.empty() {
    return TechniqueStatsOverview(
      totalAttempts: 0,
      techniquesDetected: 0,
      overallAccuracy: 0.0,
      individualStats: {},
      analysisDate: DateTime.now(),
    );
  }
}

class TechniqueRecommendation {
  final RecommendationType type;
  final TechniqueType technique;
  final RecommendationPriority priority;
  final String title;
  final String description;
  final double targetAccuracy;
  final double currentAccuracy;
  final int exerciseCount;
  final Duration estimatedTime;
  
  const TechniqueRecommendation({
    required this.type,
    required this.technique,
    required this.priority,
    required this.title,
    required this.description,
    required this.targetAccuracy,
    required this.currentAccuracy,
    required this.exerciseCount,
    required this.estimatedTime,
  });
}

class TechniqueComparison {
  final TechniqueType technique;
  final TechniqueForm userForm;
  final TechniqueForm idealForm;
  final List<FormDeviation> deviations;
  final double overallMatch;
  final List<String> suggestions;
  final DateTime timestamp;
  
  const TechniqueComparison({
    required this.technique,
    required this.userForm,
    required this.idealForm,
    required this.deviations,
    required this.overallMatch,
    required this.suggestions,
    required this.timestamp,
  });
}

class FormDeviation {
  final String aspect;
  final double deviation;
  final String description;
  
  const FormDeviation({
    required this.aspect,
    required this.deviation,
    required this.description,
  });
}

// Enums
enum TechniqueType {
  alternatePicking,
  palmMuting,
  bending,
  vibrato,
  hammerOn,
  pullOff,
  slide,
  tremoloPicking,
  tapping,
}

extension TechniqueTypeExtension on TechniqueType {
  String get displayName {
    switch (this) {
      case TechniqueType.alternatePicking:
        return 'Alternate Picking';
      case TechniqueType.palmMuting:
        return 'Palm Muting';
      case TechniqueType.bending:
        return 'String Bending';
      case TechniqueType.vibrato:
        return 'Vibrato';
      case TechniqueType.hammerOn:
        return 'Hammer-On';
      case TechniqueType.pullOff:
        return 'Pull-Off';
      case TechniqueType.slide:
        return 'Slide';
      case TechniqueType.tremoloPicking:
        return 'Tremolo Picking';
      case TechniqueType.tapping:
        return 'Tapping';
    }
  }
}

enum TechniqueLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

enum FeedbackType {
  excellent,
  good,
  needsWork,
  poor,
}

enum RecommendationType {
  improvement,
  newTechnique,
  consistency,
  challenge,
}

enum RecommendationPriority {
  low,
  medium,
  high,
  critical,
}

class TechniqueDetectionException implements Exception {
  final String message;
  
  const TechniqueDetectionException(this.message);
  
  @override
  String toString() => 'TechniqueDetectionException: $message';
}

// Riverpod providers
final techniqueDetectionServiceProvider = Provider<TechniqueDetectionService>((ref) {
  return TechniqueDetectionService();
});

final techniqueDetectionResultsProvider = StreamProvider<TechniqueDetectionResult>((ref) {
  final service = ref.read(techniqueDetectionServiceProvider);
  return service.detectionResults;
});

final techniqueFeedbackProvider = StreamProvider<TechniqueFeedback>((ref) {
  final service = ref.read(techniqueDetectionServiceProvider);
  return service.feedback;
});

final techniqueStatsProvider = Provider<TechniqueStatsOverview>((ref) {
  final service = ref.read(techniqueDetectionServiceProvider);
  return service.getTechniqueStats();
});

final practiceRecommendationsProvider = Provider<List<TechniqueRecommendation>>((ref) {
  final service = ref.read(techniqueDetectionServiceProvider);
  return service.getPracticeRecommendations();
});