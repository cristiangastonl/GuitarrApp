import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Production Monitoring Service
/// Provides comprehensive monitoring, error tracking, performance analytics,
/// and A/B testing framework for production deployment
class ProductionMonitoringService {
  // Monitoring state
  bool _isMonitoring = false;
  final Map<String, PerformanceMetric> _performanceMetrics = {};
  final List<ErrorEvent> _errorHistory = [];
  final List<UserEvent> _userEvents = [];
  final Map<String, ABTestVariant> _activeTests = {};
  
  // Configuration
  MonitoringConfig _config = MonitoringConfig.defaultConfig();
  
  // Analytics buffers
  final List<AnalyticsEvent> _analyticsBuffer = [];
  final Map<String, CrashReport> _crashes = {};
  final Map<String, UserSession> _activeSessions = {};
  
  // Event streams
  final StreamController<ErrorEvent> _errorController = StreamController.broadcast();
  final StreamController<PerformanceAlert> _performanceController = StreamController.broadcast();
  final StreamController<UserBehaviorInsight> _behaviorController = StreamController.broadcast();
  final StreamController<SystemHealthStatus> _healthController = StreamController.broadcast();
  
  /// Stream of error events
  Stream<ErrorEvent> get errorEvents => _errorController.stream;
  
  /// Stream of performance alerts
  Stream<PerformanceAlert> get performanceAlerts => _performanceController.stream;
  
  /// Stream of user behavior insights
  Stream<UserBehaviorInsight> get behaviorInsights => _behaviorController.stream;
  
  /// Stream of system health updates
  Stream<SystemHealthStatus> get healthUpdates => _healthController.stream;
  
  /// Initialize production monitoring
  Future<void> initializeMonitoring({MonitoringConfig? config}) async {
    _config = config ?? MonitoringConfig.defaultConfig();
    _isMonitoring = true;
    
    // Start monitoring loops
    _startErrorMonitoring();
    _startPerformanceMonitoring();
    _startHealthMonitoring();
    _startAnalyticsCollection();
    
    // Initialize crash reporting
    _initializeCrashReporting();
    
    // Load A/B test configurations
    await _loadABTestConfigurations();
  }
  
  /// Stop production monitoring
  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    
    // Flush remaining analytics
    await _flushAnalytics();
  }
  
  /// Log error with context
  void logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    if (!_isMonitoring) return;
    
    final errorEvent = ErrorEvent(
      id: _generateEventId(),
      error: error.toString(),
      stackTrace: stackTrace?.toString(),
      context: context,
      metadata: metadata ?? {},
      severity: severity,
      timestamp: DateTime.now(),
      userId: _getCurrentUserId(),
      sessionId: _getCurrentSessionId(),
      appVersion: _getAppVersion(),
      platform: _getPlatformInfo(),
    );
    
    _errorHistory.add(errorEvent);
    _errorController.add(errorEvent);
    
    // Auto-report critical errors
    if (severity == ErrorSeverity.critical) {
      _reportCriticalError(errorEvent);
    }
    
    // Limit error history size
    if (_errorHistory.length > _config.maxErrorHistory) {
      _errorHistory.removeAt(0);
    }
  }
  
  /// Record performance metric
  void recordPerformanceMetric(
    String name,
    double value, {
    String? unit,
    Map<String, dynamic>? tags,
  }) {
    if (!_isMonitoring) return;
    
    final metric = PerformanceMetric(
      name: name,
      value: value,
      unit: unit ?? 'ms',
      tags: tags ?? {},
      timestamp: DateTime.now(),
    );
    
    _performanceMetrics[name] = metric;
    
    // Check for performance alerts
    _checkPerformanceThresholds(metric);
    
    // Record in analytics
    _recordAnalyticsEvent(AnalyticsEvent(
      name: 'performance_metric',
      parameters: {
        'metric_name': name,
        'value': value,
        'unit': unit ?? 'ms',
        ...?tags,
      },
      timestamp: DateTime.now(),
    ));
  }
  
  /// Track user event
  void trackUserEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
    String? userId,
  }) {
    if (!_isMonitoring) return;
    
    final userEvent = UserEvent(
      name: eventName,
      parameters: parameters ?? {},
      userId: userId ?? _getCurrentUserId(),
      sessionId: _getCurrentSessionId(),
      timestamp: DateTime.now(),
    );
    
    _userEvents.add(userEvent);
    
    // Record in analytics
    _recordAnalyticsEvent(AnalyticsEvent(
      name: eventName,
      parameters: parameters ?? {},
      timestamp: DateTime.now(),
    ));
    
    // Analyze user behavior patterns
    _analyzeUserBehavior(userEvent);
  }
  
  /// Start user session tracking
  Future<String> startUserSession(String userId) async {
    final sessionId = _generateSessionId();
    
    final session = UserSession(
      id: sessionId,
      userId: userId,
      startTime: DateTime.now(),
      platform: _getPlatformInfo(),
      appVersion: _getAppVersion(),
      events: [],
    );
    
    _activeSessions[sessionId] = session;
    
    trackUserEvent('session_start', parameters: {
      'session_id': sessionId,
      'user_id': userId,
    });
    
    return sessionId;
  }
  
  /// End user session
  Future<void> endUserSession(String sessionId) async {
    final session = _activeSessions[sessionId];
    if (session == null) return;
    
    final endTime = DateTime.now();
    final duration = endTime.difference(session.startTime);
    
    final updatedSession = session.copyWith(
      endTime: endTime,
      duration: duration,
    );
    
    _activeSessions.remove(sessionId);
    
    trackUserEvent('session_end', parameters: {
      'session_id': sessionId,
      'duration_seconds': duration.inSeconds,
      'events_count': session.events.length,
    });
    
    // Analyze session quality
    _analyzeSessionQuality(updatedSession);
  }
  
  /// Configure A/B test
  Future<void> configureABTest({
    required String testId,
    required String testName,
    required List<ABTestVariant> variants,
    required double trafficAllocation,
    Map<String, dynamic>? targeting,
  }) async {
    final test = ABTest(
      id: testId,
      name: testName,
      variants: variants,
      trafficAllocation: trafficAllocation,
      targeting: targeting ?? {},
      isActive: true,
      startDate: DateTime.now(),
    );
    
    // Assign users to variants
    await _assignABTestVariants(test);
  }
  
  /// Get A/B test variant for user
  ABTestVariant? getABTestVariant(String testId, String userId) {
    final test = _activeTests[testId];
    if (test == null || !test.isActive) return null;
    
    // Check if user is already assigned
    final existingVariant = test.userAssignments[userId];
    if (existingVariant != null) return existingVariant;
    
    // Assign user to variant
    return _assignUserToVariant(test, userId);
  }
  
  /// Record A/B test conversion
  void recordABTestConversion(
    String testId,
    String userId,
    String conversionEvent, {
    double? value,
    Map<String, dynamic>? metadata,
  }) {
    final variant = getABTestVariant(testId, userId);
    if (variant == null) return;
    
    trackUserEvent('ab_test_conversion', parameters: {
      'test_id': testId,
      'variant_id': variant.id,
      'conversion_event': conversionEvent,
      'value': value,
      ...?metadata,
    });
  }
  
  /// Get comprehensive analytics report
  AnalyticsReport getAnalyticsReport({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
    final end = endDate ?? DateTime.now();
    
    final filteredEvents = _analyticsBuffer
        .where((event) => 
            event.timestamp.isAfter(start) && 
            event.timestamp.isBefore(end))
        .toList();
    
    final errorEvents = _errorHistory
        .where((error) => 
            error.timestamp.isAfter(start) && 
            error.timestamp.isBefore(end))
        .toList();
    
    // Calculate metrics
    final totalEvents = filteredEvents.length;
    final uniqueUsers = filteredEvents.map((e) => e.userId).where((id) => id != null).toSet().length;
    final errorRate = totalEvents > 0 ? errorEvents.length / totalEvents : 0.0;
    final crashRate = _calculateCrashRate(start, end);
    
    // Performance metrics
    final avgResponseTime = _calculateAverageMetric('response_time', start, end);
    final memoryUsage = _calculateAverageMetric('memory_usage', start, end);
    
    // User engagement metrics
    final sessionAnalytics = _calculateSessionAnalytics(start, end);
    
    return AnalyticsReport(
      startDate: start,
      endDate: end,
      totalEvents: totalEvents,
      uniqueUsers: uniqueUsers,
      errorRate: errorRate,
      crashRate: crashRate,
      averageResponseTime: avgResponseTime,
      averageMemoryUsage: memoryUsage,
      sessionAnalytics: sessionAnalytics,
      topEvents: _getTopEvents(filteredEvents),
      topErrors: _getTopErrors(errorEvents),
      performanceMetrics: _getPerformanceSnapshot(),
      abTestResults: _getABTestResults(),
      generatedAt: DateTime.now(),
    );
  }
  
  /// Get system health status
  SystemHealthStatus getSystemHealthStatus() {
    final cpuUsage = _getCPUUsage();
    final memoryUsage = _getMemoryUsage();
    final diskUsage = _getDiskUsage();
    final networkLatency = _getNetworkLatency();
    
    final overallHealth = _calculateOverallHealth([
      cpuUsage,
      memoryUsage,
      diskUsage,
      networkLatency,
    ]);
    
    return SystemHealthStatus(
      overallHealth: overallHealth,
      cpuUsage: cpuUsage,
      memoryUsage: memoryUsage,
      diskUsage: diskUsage,
      networkLatency: networkLatency,
      activeConnections: _getActiveConnections(),
      timestamp: DateTime.now(),
    );
  }
  
  /// Export monitoring data
  Future<String> exportMonitoringData({
    ExportFormat format = ExportFormat.json,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final report = getAnalyticsReport(startDate: startDate, endDate: endDate);
    
    switch (format) {
      case ExportFormat.json:
        return jsonEncode(report.toJson());
      case ExportFormat.csv:
        return _exportToCSV(report);
      case ExportFormat.xml:
        return _exportToXML(report);
    }
  }
  
  // Private methods
  void _startErrorMonitoring() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }
      
      // Check for error patterns
      _detectErrorPatterns();
    });
  }
  
  void _startPerformanceMonitoring() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }
      
      // Collect system metrics
      _collectSystemMetrics();
    });
  }
  
  void _startHealthMonitoring() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }
      
      // Update system health
      final healthStatus = getSystemHealthStatus();
      _healthController.add(healthStatus);
      
      // Check for health alerts
      _checkHealthAlerts(healthStatus);
    });
  }
  
  void _startAnalyticsCollection() {
    Timer.periodic(const Duration(minutes: 10), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }
      
      // Flush analytics buffer
      _flushAnalytics();
    });
  }
  
  void _initializeCrashReporting() {
    // Set up global error handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      logError(
        details.exception,
        stackTrace: details.stack,
        context: 'Flutter Framework Error',
        severity: ErrorSeverity.critical,
        metadata: {
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
    };
    
    // Handle platform-specific crashes
    if (!kIsWeb) {
      _setupNativeCrashReporting();
    }
  }
  
  void _setupNativeCrashReporting() {
    // Platform-specific crash reporting setup
    // In production, this would integrate with crash reporting services
  }
  
  Future<void> _loadABTestConfigurations() async {
    // Load A/B test configurations from remote or local storage
    // For demo purposes, we'll create a sample test
    await configureABTest(
      testId: 'home_screen_layout',
      testName: 'Home Screen Layout Test',
      variants: [
        ABTestVariant(
          id: 'control',
          name: 'Control',
          parameters: {'layout': 'original'},
          allocation: 0.5,
        ),
        ABTestVariant(
          id: 'variant_a',
          name: 'New Layout',
          parameters: {'layout': 'improved'},
          allocation: 0.5,
        ),
      ],
      trafficAllocation: 1.0,
    );
  }
  
  void _checkPerformanceThresholds(PerformanceMetric metric) {
    final thresholds = _config.performanceThresholds[metric.name];
    if (thresholds == null) return;
    
    if (metric.value > thresholds.critical) {
      _performanceController.add(PerformanceAlert(
        metricName: metric.name,
        value: metric.value,
        threshold: thresholds.critical,
        severity: AlertSeverity.critical,
        timestamp: DateTime.now(),
      ));
    } else if (metric.value > thresholds.warning) {
      _performanceController.add(PerformanceAlert(
        metricName: metric.name,
        value: metric.value,
        threshold: thresholds.warning,
        severity: AlertSeverity.warning,
        timestamp: DateTime.now(),
      ));
    }
  }
  
  void _recordAnalyticsEvent(AnalyticsEvent event) {
    final enrichedEvent = event.copyWith(
      userId: event.userId ?? _getCurrentUserId(),
      sessionId: _getCurrentSessionId(),
      platform: _getPlatformInfo(),
      appVersion: _getAppVersion(),
    );
    
    _analyticsBuffer.add(enrichedEvent);
    
    // Limit buffer size
    if (_analyticsBuffer.length > _config.maxAnalyticsBuffer) {
      _analyticsBuffer.removeAt(0);
    }
  }
  
  void _analyzeUserBehavior(UserEvent event) {
    // Pattern detection for user behavior insights
    final recentEvents = _userEvents
        .where((e) => e.userId == event.userId)
        .where((e) => DateTime.now().difference(e.timestamp).inMinutes <= 30)
        .toList();
    
    // Detect abandonment patterns
    if (_detectAbandonmentPattern(recentEvents)) {
      _behaviorController.add(UserBehaviorInsight(
        type: InsightType.abandonment,
        userId: event.userId,
        description: 'User showing abandonment pattern',
        confidence: 0.8,
        timestamp: DateTime.now(),
      ));
    }
    
    // Detect engagement patterns
    if (_detectHighEngagement(recentEvents)) {
      _behaviorController.add(UserBehaviorInsight(
        type: InsightType.highEngagement,
        userId: event.userId,
        description: 'User showing high engagement',
        confidence: 0.9,
        timestamp: DateTime.now(),
      ));
    }
  }
  
  bool _detectAbandonmentPattern(List<UserEvent> events) {
    if (events.length < 3) return false;
    
    // Simple abandonment detection: quick succession of error events
    final errorEvents = events.where((e) => e.name.contains('error')).toList();
    return errorEvents.length >= 2;
  }
  
  bool _detectHighEngagement(List<UserEvent> events) {
    if (events.length < 10) return false;
    
    // High engagement: many events in short time
    final timeSpan = events.last.timestamp.difference(events.first.timestamp);
    return timeSpan.inMinutes <= 15 && events.length >= 10;
  }
  
  void _analyzeSessionQuality(UserSession session) {
    final quality = _calculateSessionQuality(session);
    
    trackUserEvent('session_quality', parameters: {
      'session_id': session.id,
      'quality_score': quality,
      'duration_minutes': session.duration?.inMinutes ?? 0,
      'events_count': session.events.length,
    });
  }
  
  double _calculateSessionQuality(UserSession session) {
    if (session.duration == null) return 0.0;
    
    double score = 0.0;
    
    // Duration scoring
    final minutes = session.duration!.inMinutes;
    if (minutes >= 5) score += 0.4;
    if (minutes >= 15) score += 0.2;
    if (minutes >= 30) score += 0.2;
    
    // Event engagement scoring
    if (session.events.length >= 10) score += 0.2;
    
    return score.clamp(0.0, 1.0);
  }
  
  Future<void> _assignABTestVariants(ABTest test) async {
    _activeTests[test.id] = test;
  }
  
  ABTestVariant? _assignUserToVariant(ABTest test, String userId) {
    // Hash-based deterministic assignment
    final hash = userId.hashCode;
    final normalizedHash = (hash % 100) / 100.0;
    
    double cumulativeAllocation = 0.0;
    
    for (final variant in test.variants) {
      cumulativeAllocation += variant.allocation;
      if (normalizedHash <= cumulativeAllocation) {
        test.userAssignments[userId] = variant;
        
        // Track assignment
        trackUserEvent('ab_test_assigned', parameters: {
          'test_id': test.id,
          'variant_id': variant.id,
        });
        
        return variant;
      }
    }
    
    // Fallback to control
    return test.variants.first;
  }
  
  void _reportCriticalError(ErrorEvent error) {
    // In production, this would send to error reporting service
    if (kDebugMode) {
      print('CRITICAL ERROR: ${error.error}');
      print('Stack trace: ${error.stackTrace}');
    }
  }
  
  void _detectErrorPatterns() {
    final recentErrors = _errorHistory
        .where((error) => DateTime.now().difference(error.timestamp).inMinutes <= 10)
        .toList();
    
    if (recentErrors.length >= 5) {
      // Potential error spike
      _errorController.add(ErrorEvent(
        id: _generateEventId(),
        error: 'Error spike detected',
        context: 'Pattern Detection',
        severity: ErrorSeverity.warning,
        timestamp: DateTime.now(),
        metadata: {'error_count': recentErrors.length},
      ));
    }
  }
  
  void _collectSystemMetrics() {
    recordPerformanceMetric('cpu_usage', _getCPUUsage(), unit: '%');
    recordPerformanceMetric('memory_usage', _getMemoryUsage(), unit: 'MB');
    recordPerformanceMetric('network_latency', _getNetworkLatency(), unit: 'ms');
  }
  
  void _checkHealthAlerts(SystemHealthStatus status) {
    if (status.overallHealth < 0.3) {
      _performanceController.add(PerformanceAlert(
        metricName: 'system_health',
        value: status.overallHealth,
        threshold: 0.3,
        severity: AlertSeverity.critical,
        timestamp: DateTime.now(),
      ));
    }
  }
  
  Future<void> _flushAnalytics() async {
    if (_analyticsBuffer.isEmpty) return;
    
    // In production, this would send to analytics service
    if (kDebugMode) {
      print('Flushing ${_analyticsBuffer.length} analytics events');
    }
    
    _analyticsBuffer.clear();
  }
  
  double _calculateCrashRate(DateTime start, DateTime end) {
    final totalSessions = _activeSessions.length;
    final crashes = _crashes.values
        .where((crash) => 
            crash.timestamp.isAfter(start) && 
            crash.timestamp.isBefore(end))
        .length;
    
    return totalSessions > 0 ? crashes / totalSessions : 0.0;
  }
  
  double? _calculateAverageMetric(String metricName, DateTime start, DateTime end) {
    // Simplified calculation - in production, this would query historical data
    final metric = _performanceMetrics[metricName];
    return metric?.value;
  }
  
  SessionAnalytics _calculateSessionAnalytics(DateTime start, DateTime end) {
    final sessions = _activeSessions.values
        .where((session) => 
            session.startTime.isAfter(start) && 
            session.startTime.isBefore(end))
        .toList();
    
    if (sessions.isEmpty) {
      return SessionAnalytics.empty();
    }
    
    final avgDuration = sessions
        .where((s) => s.duration != null)
        .map((s) => s.duration!.inSeconds)
        .fold<double>(0.0, (sum, duration) => sum + duration) / sessions.length;
    
    final avgEventsPerSession = sessions
        .map((s) => s.events.length)
        .fold<double>(0.0, (sum, events) => sum + events) / sessions.length;
    
    return SessionAnalytics(
      totalSessions: sessions.length,
      averageDuration: Duration(seconds: avgDuration.round()),
      averageEventsPerSession: avgEventsPerSession,
      bounceRate: _calculateBounceRate(sessions),
    );
  }
  
  double _calculateBounceRate(List<UserSession> sessions) {
    if (sessions.isEmpty) return 0.0;
    
    final bouncedSessions = sessions
        .where((s) => s.duration != null && s.duration!.inSeconds < 30)
        .length;
    
    return bouncedSessions / sessions.length;
  }
  
  List<EventSummary> _getTopEvents(List<AnalyticsEvent> events) {
    final eventCounts = <String, int>{};
    
    for (final event in events) {
      eventCounts[event.name] = (eventCounts[event.name] ?? 0) + 1;
    }
    
    final sortedEvents = eventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEvents.take(10).map((entry) => EventSummary(
      name: entry.key,
      count: entry.value,
    )).toList();
  }
  
  List<ErrorSummary> _getTopErrors(List<ErrorEvent> errors) {
    final errorCounts = <String, int>{};
    
    for (final error in errors) {
      errorCounts[error.error] = (errorCounts[error.error] ?? 0) + 1;
    }
    
    final sortedErrors = errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedErrors.take(10).map((entry) => ErrorSummary(
      error: entry.key,
      count: entry.value,
    )).toList();
  }
  
  Map<String, double> _getPerformanceSnapshot() {
    return _performanceMetrics.map((key, value) => MapEntry(key, value.value));
  }
  
  Map<String, ABTestResult> _getABTestResults() {
    final results = <String, ABTestResult>{};
    
    for (final test in _activeTests.values) {
      final conversionEvents = _analyticsBuffer
          .where((event) => 
              event.name == 'ab_test_conversion' && 
              event.parameters['test_id'] == test.id)
          .toList();
      
      final variantResults = <String, VariantResult>{};
      
      for (final variant in test.variants) {
        final variantConversions = conversionEvents
            .where((event) => event.parameters['variant_id'] == variant.id)
            .length;
        
        final variantUsers = test.userAssignments.values
            .where((v) => v.id == variant.id)
            .length;
        
        final conversionRate = variantUsers > 0 ? variantConversions / variantUsers : 0.0;
        
        variantResults[variant.id] = VariantResult(
          variantId: variant.id,
          users: variantUsers,
          conversions: variantConversions,
          conversionRate: conversionRate,
        );
      }
      
      results[test.id] = ABTestResult(
        testId: test.id,
        testName: test.name,
        variantResults: variantResults,
        isSignificant: _calculateStatisticalSignificance(variantResults),
      );
    }
    
    return results;
  }
  
  bool _calculateStatisticalSignificance(Map<String, VariantResult> results) {
    // Simplified significance test - in production, use proper statistical tests
    return results.length >= 2 && 
           results.values.every((r) => r.users >= 100);
  }
  
  double _calculateOverallHealth(List<double> metrics) {
    if (metrics.isEmpty) return 1.0;
    
    // Convert all metrics to health scores (0-1, where 1 is healthy)
    final healthScores = metrics.map((metric) {
      // Assume metrics are percentages where lower is better for most
      return (1.0 - metric / 100.0).clamp(0.0, 1.0);
    }).toList();
    
    return healthScores.reduce((a, b) => a + b) / healthScores.length;
  }
  
  double _getCPUUsage() {
    // Platform-specific CPU usage calculation
    return math.Random().nextDouble() * 100; // Mock value
  }
  
  double _getMemoryUsage() {
    // Platform-specific memory usage calculation
    return math.Random().nextDouble() * 1024; // Mock value in MB
  }
  
  double _getDiskUsage() {
    // Platform-specific disk usage calculation
    return math.Random().nextDouble() * 100; // Mock value as percentage
  }
  
  double _getNetworkLatency() {
    // Network latency measurement
    return math.Random().nextDouble() * 200; // Mock value in ms
  }
  
  int _getActiveConnections() {
    // Active network connections count
    return math.Random().nextInt(10) + 1; // Mock value
  }
  
  String _exportToCSV(AnalyticsReport report) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Metric,Value');
    buffer.writeln('Total Events,${report.totalEvents}');
    buffer.writeln('Unique Users,${report.uniqueUsers}');
    buffer.writeln('Error Rate,${report.errorRate}');
    buffer.writeln('Crash Rate,${report.crashRate}');
    
    // Events
    buffer.writeln('\nTop Events');
    buffer.writeln('Event Name,Count');
    for (final event in report.topEvents) {
      buffer.writeln('${event.name},${event.count}');
    }
    
    return buffer.toString();
  }
  
  String _exportToXML(AnalyticsReport report) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<analytics_report>
  <period>
    <start>${report.startDate.toIso8601String()}</start>
    <end>${report.endDate.toIso8601String()}</end>
  </period>
  <metrics>
    <total_events>${report.totalEvents}</total_events>
    <unique_users>${report.uniqueUsers}</unique_users>
    <error_rate>${report.errorRate}</error_rate>
    <crash_rate>${report.crashRate}</crash_rate>
  </metrics>
  <generated_at>${report.generatedAt.toIso8601String()}</generated_at>
</analytics_report>''';
  }
  
  String _generateEventId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }
  
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  String? _getCurrentUserId() {
    // Get current user ID from authentication service
    return 'user_demo'; // Mock value
  }
  
  String _getCurrentSessionId() {
    // Get current session ID
    return 'session_demo'; // Mock value
  }
  
  String _getAppVersion() {
    // Get app version from package info
    return '1.0.0'; // Mock value
  }
  
  String _getPlatformInfo() {
    return Platform.operatingSystem;
  }
  
  void dispose() {
    _errorController.close();
    _performanceController.close();
    _behaviorController.close();
    _healthController.close();
  }
}

// Data Models
class MonitoringConfig {
  final bool enableErrorTracking;
  final bool enablePerformanceTracking;
  final bool enableAnalytics;
  final bool enableABTesting;
  final int maxErrorHistory;
  final int maxAnalyticsBuffer;
  final Map<String, PerformanceThreshold> performanceThresholds;
  
  const MonitoringConfig({
    required this.enableErrorTracking,
    required this.enablePerformanceTracking,
    required this.enableAnalytics,
    required this.enableABTesting,
    required this.maxErrorHistory,
    required this.maxAnalyticsBuffer,
    required this.performanceThresholds,
  });
  
  factory MonitoringConfig.defaultConfig() {
    return MonitoringConfig(
      enableErrorTracking: true,
      enablePerformanceTracking: true,
      enableAnalytics: true,
      enableABTesting: true,
      maxErrorHistory: 1000,
      maxAnalyticsBuffer: 5000,
      performanceThresholds: {
        'response_time': PerformanceThreshold(warning: 500, critical: 1000),
        'memory_usage': PerformanceThreshold(warning: 512, critical: 1024),
        'cpu_usage': PerformanceThreshold(warning: 70, critical: 90),
      },
    );
  }
}

class PerformanceThreshold {
  final double warning;
  final double critical;
  
  const PerformanceThreshold({required this.warning, required this.critical});
}

class ErrorEvent {
  final String id;
  final String error;
  final String? stackTrace;
  final String? context;
  final Map<String, dynamic> metadata;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;
  final String? appVersion;
  final String? platform;
  
  const ErrorEvent({
    required this.id,
    required this.error,
    this.stackTrace,
    this.context,
    required this.metadata,
    required this.severity,
    required this.timestamp,
    this.userId,
    this.sessionId,
    this.appVersion,
    this.platform,
  });
}

class PerformanceMetric {
  final String name;
  final double value;
  final String unit;
  final Map<String, dynamic> tags;
  final DateTime timestamp;
  
  const PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.tags,
    required this.timestamp,
  });
}

class UserEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final String userId;
  final String sessionId;
  final DateTime timestamp;
  
  const UserEvent({
    required this.name,
    required this.parameters,
    required this.userId,
    required this.sessionId,
    required this.timestamp,
  });
}

class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;
  final String? platform;
  final String? appVersion;
  
  const AnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
    this.userId,
    this.sessionId,
    this.platform,
    this.appVersion,
  });
  
  AnalyticsEvent copyWith({
    String? userId,
    String? sessionId,
    String? platform,
    String? appVersion,
  }) {
    return AnalyticsEvent(
      name: name,
      parameters: parameters,
      timestamp: timestamp,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      platform: platform ?? this.platform,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}

class UserSession {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final String platform;
  final String appVersion;
  final List<UserEvent> events;
  
  const UserSession({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.duration,
    required this.platform,
    required this.appVersion,
    required this.events,
  });
  
  UserSession copyWith({
    DateTime? endTime,
    Duration? duration,
    List<UserEvent>? events,
  }) {
    return UserSession(
      id: id,
      userId: userId,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      platform: platform,
      appVersion: appVersion,
      events: events ?? this.events,
    );
  }
}

class ABTest {
  final String id;
  final String name;
  final List<ABTestVariant> variants;
  final double trafficAllocation;
  final Map<String, dynamic> targeting;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final Map<String, ABTestVariant> userAssignments;
  
  ABTest({
    required this.id,
    required this.name,
    required this.variants,
    required this.trafficAllocation,
    required this.targeting,
    required this.isActive,
    required this.startDate,
    this.endDate,
    Map<String, ABTestVariant>? userAssignments,
  }) : userAssignments = userAssignments ?? {};
}

class ABTestVariant {
  final String id;
  final String name;
  final Map<String, dynamic> parameters;
  final double allocation;
  
  const ABTestVariant({
    required this.id,
    required this.name,
    required this.parameters,
    required this.allocation,
  });
}

class PerformanceAlert {
  final String metricName;
  final double value;
  final double threshold;
  final AlertSeverity severity;
  final DateTime timestamp;
  
  const PerformanceAlert({
    required this.metricName,
    required this.value,
    required this.threshold,
    required this.severity,
    required this.timestamp,
  });
}

class UserBehaviorInsight {
  final InsightType type;
  final String userId;
  final String description;
  final double confidence;
  final DateTime timestamp;
  
  const UserBehaviorInsight({
    required this.type,
    required this.userId,
    required this.description,
    required this.confidence,
    required this.timestamp,
  });
}

class SystemHealthStatus {
  final double overallHealth;
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final double networkLatency;
  final int activeConnections;
  final DateTime timestamp;
  
  const SystemHealthStatus({
    required this.overallHealth,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.networkLatency,
    required this.activeConnections,
    required this.timestamp,
  });
}

class AnalyticsReport {
  final DateTime startDate;
  final DateTime endDate;
  final int totalEvents;
  final int uniqueUsers;
  final double errorRate;
  final double crashRate;
  final double? averageResponseTime;
  final double? averageMemoryUsage;
  final SessionAnalytics sessionAnalytics;
  final List<EventSummary> topEvents;
  final List<ErrorSummary> topErrors;
  final Map<String, double> performanceMetrics;
  final Map<String, ABTestResult> abTestResults;
  final DateTime generatedAt;
  
  const AnalyticsReport({
    required this.startDate,
    required this.endDate,
    required this.totalEvents,
    required this.uniqueUsers,
    required this.errorRate,
    required this.crashRate,
    this.averageResponseTime,
    this.averageMemoryUsage,
    required this.sessionAnalytics,
    required this.topEvents,
    required this.topErrors,
    required this.performanceMetrics,
    required this.abTestResults,
    required this.generatedAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalEvents': totalEvents,
      'uniqueUsers': uniqueUsers,
      'errorRate': errorRate,
      'crashRate': crashRate,
      'averageResponseTime': averageResponseTime,
      'averageMemoryUsage': averageMemoryUsage,
      'sessionAnalytics': sessionAnalytics.toJson(),
      'topEvents': topEvents.map((e) => e.toJson()).toList(),
      'topErrors': topErrors.map((e) => e.toJson()).toList(),
      'performanceMetrics': performanceMetrics,
      'abTestResults': abTestResults.map((k, v) => MapEntry(k, v.toJson())),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

class SessionAnalytics {
  final int totalSessions;
  final Duration averageDuration;
  final double averageEventsPerSession;
  final double bounceRate;
  
  const SessionAnalytics({
    required this.totalSessions,
    required this.averageDuration,
    required this.averageEventsPerSession,
    required this.bounceRate,
  });
  
  factory SessionAnalytics.empty() {
    return const SessionAnalytics(
      totalSessions: 0,
      averageDuration: Duration.zero,
      averageEventsPerSession: 0.0,
      bounceRate: 0.0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'averageDuration': averageDuration.inSeconds,
      'averageEventsPerSession': averageEventsPerSession,
      'bounceRate': bounceRate,
    };
  }
}

class EventSummary {
  final String name;
  final int count;
  
  const EventSummary({required this.name, required this.count});
  
  Map<String, dynamic> toJson() => {'name': name, 'count': count};
}

class ErrorSummary {
  final String error;
  final int count;
  
  const ErrorSummary({required this.error, required this.count});
  
  Map<String, dynamic> toJson() => {'error': error, 'count': count};
}

class ABTestResult {
  final String testId;
  final String testName;
  final Map<String, VariantResult> variantResults;
  final bool isSignificant;
  
  const ABTestResult({
    required this.testId,
    required this.testName,
    required this.variantResults,
    required this.isSignificant,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'testId': testId,
      'testName': testName,
      'variantResults': variantResults.map((k, v) => MapEntry(k, v.toJson())),
      'isSignificant': isSignificant,
    };
  }
}

class VariantResult {
  final String variantId;
  final int users;
  final int conversions;
  final double conversionRate;
  
  const VariantResult({
    required this.variantId,
    required this.users,
    required this.conversions,
    required this.conversionRate,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'variantId': variantId,
      'users': users,
      'conversions': conversions,
      'conversionRate': conversionRate,
    };
  }
}

class CrashReport {
  final String id;
  final String crashType;
  final String error;
  final String stackTrace;
  final Map<String, dynamic> deviceInfo;
  final DateTime timestamp;
  
  const CrashReport({
    required this.id,
    required this.crashType,
    required this.error,
    required this.stackTrace,
    required this.deviceInfo,
    required this.timestamp,
  });
}

// Enums
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}

enum InsightType {
  abandonment,
  highEngagement,
  featureDiscovery,
  performanceIssue,
}

enum ExportFormat {
  json,
  csv,
  xml,
}

class ProductionMonitoringException implements Exception {
  final String message;
  
  const ProductionMonitoringException(this.message);
  
  @override
  String toString() => 'ProductionMonitoringException: $message';
}

// Riverpod providers
final productionMonitoringServiceProvider = Provider<ProductionMonitoringService>((ref) {
  return ProductionMonitoringService();
});

final errorEventsProvider = StreamProvider<ErrorEvent>((ref) {
  final service = ref.read(productionMonitoringServiceProvider);
  return service.errorEvents;
});

final performanceAlertsProvider = StreamProvider<PerformanceAlert>((ref) {
  final service = ref.read(productionMonitoringServiceProvider);
  return service.performanceAlerts;
});

final behaviorInsightsProvider = StreamProvider<UserBehaviorInsight>((ref) {
  final service = ref.read(productionMonitoringServiceProvider);
  return service.behaviorInsights;
});

final systemHealthProvider = StreamProvider<SystemHealthStatus>((ref) {
  final service = ref.read(productionMonitoringServiceProvider);
  return service.healthUpdates;
});

final analyticsReportProvider = Provider.family<AnalyticsReport, DateRange?>((ref, dateRange) {
  final service = ref.read(productionMonitoringServiceProvider);
  return service.getAnalyticsReport(
    startDate: dateRange?.start,
    endDate: dateRange?.end,
  );
});

class DateRange {
  final DateTime start;
  final DateTime end;
  
  const DateRange({required this.start, required this.end});
}