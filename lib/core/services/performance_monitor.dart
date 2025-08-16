import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Performance monitoring service for tracking app performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, _PerformanceMetric> _metrics = {};
  final List<_FrameRateEntry> _frameRateHistory = [];
  final int _maxHistorySize = 1000;
  
  Timer? _memoryMonitorTimer;
  Timer? _frameRateMonitorTimer;
  bool _isMonitoring = false;

  /// Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    _startMemoryMonitoring();
    _startFrameRateMonitoring();
    
    debugPrint('Performance monitoring started');
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    
    _memoryMonitorTimer?.cancel();
    _frameRateMonitorTimer?.cancel();
    
    debugPrint('Performance monitoring stopped');
  }

  /// Record a custom performance metric
  void recordMetric(String name, double value, {String? unit}) {
    _metrics[name] = _PerformanceMetric(
      name: name,
      value: value,
      unit: unit ?? 'ms',
      timestamp: DateTime.now(),
    );
  }

  /// Time a function execution
  Future<T> timeFunction<T>(String name, Future<T> Function() function) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await function();
      stopwatch.stop();
      recordMetric(name, stopwatch.elapsedMilliseconds.toDouble());
      return result;
    } catch (e) {
      stopwatch.stop();
      recordMetric('${name}_error', stopwatch.elapsedMilliseconds.toDouble());
      rethrow;
    }
  }

  /// Time a synchronous function execution
  T timeFunctionSync<T>(String name, T Function() function) {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = function();
      stopwatch.stop();
      recordMetric(name, stopwatch.elapsedMilliseconds.toDouble());
      return result;
    } catch (e) {
      stopwatch.stop();
      recordMetric('${name}_error', stopwatch.elapsedMilliseconds.toDouble());
      rethrow;
    }
  }

  /// Get performance report
  PerformanceReport getReport() {
    return PerformanceReport(
      metrics: Map.from(_metrics),
      averageFrameRate: _calculateAverageFrameRate(),
      memoryUsage: _getCurrentMemoryUsage(),
      frameDrops: _countFrameDrops(),
      timestamp: DateTime.now(),
    );
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _frameRateHistory.clear();
  }

  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final memoryUsage = _getCurrentMemoryUsage();
      recordMetric('memory_usage_mb', memoryUsage);
      
      // Warn if memory usage is high
      if (memoryUsage > 200) {
        debugPrint('⚠️ High memory usage detected: ${memoryUsage.toStringAsFixed(1)} MB');
      }
    });
  }

  void _startFrameRateMonitoring() {
    if (kIsWeb) return; // Frame rate monitoring not available on web
    
    _frameRateMonitorTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // This is a simplified frame rate calculation
      // In production, you'd use more sophisticated methods
      final now = DateTime.now();
      _frameRateHistory.add(_FrameRateEntry(
        timestamp: now,
        frameRate: 60.0, // Mock frame rate - replace with actual measurement
      ));
      
      // Keep history size manageable
      while (_frameRateHistory.length > _maxHistorySize) {
        _frameRateHistory.removeAt(0);
      }
    });
  }

  double _getCurrentMemoryUsage() {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Use platform-specific memory measurement
        // This is a mock implementation
        return ProcessInfo.currentRss / (1024 * 1024); // Convert to MB
      }
    } catch (e) {
      debugPrint('Error getting memory usage: $e');
    }
    return 0.0;
  }

  double _calculateAverageFrameRate() {
    if (_frameRateHistory.isEmpty) return 0.0;
    
    final sum = _frameRateHistory
        .map((entry) => entry.frameRate)
        .reduce((a, b) => a + b);
    
    return sum / _frameRateHistory.length;
  }

  int _countFrameDrops() {
    return _frameRateHistory
        .where((entry) => entry.frameRate < 55) // Consider frames below 55 FPS as drops
        .length;
  }

  /// Log performance warnings
  void logPerformanceWarnings() {
    final report = getReport();
    
    if (report.averageFrameRate < 50) {
      debugPrint('⚠️ Low frame rate detected: ${report.averageFrameRate.toStringAsFixed(1)} FPS');
    }
    
    if (report.memoryUsage > 150) {
      debugPrint('⚠️ High memory usage: ${report.memoryUsage.toStringAsFixed(1)} MB');
    }
    
    if (report.frameDrops > 10) {
      debugPrint('⚠️ High frame drop count: ${report.frameDrops}');
    }
    
    // Log slow operations
    final slowOperations = report.metrics.entries
        .where((entry) => entry.value.value > 100) // Operations taking more than 100ms
        .toList();
    
    for (final operation in slowOperations) {
      debugPrint('⚠️ Slow operation: ${operation.key} took ${operation.value.value.toStringAsFixed(1)}ms');
    }
  }
}

class _PerformanceMetric {
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;

  _PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
  });
}

class _FrameRateEntry {
  final DateTime timestamp;
  final double frameRate;

  _FrameRateEntry({
    required this.timestamp,
    required this.frameRate,
  });
}

class PerformanceReport {
  final Map<String, _PerformanceMetric> metrics;
  final double averageFrameRate;
  final double memoryUsage;
  final int frameDrops;
  final DateTime timestamp;

  const PerformanceReport({
    required this.metrics,
    required this.averageFrameRate,
    required this.memoryUsage,
    required this.frameDrops,
    required this.timestamp,
  });

  @override
  String toString() {
    return '''
Performance Report (${timestamp.toIso8601String()}):
- Average Frame Rate: ${averageFrameRate.toStringAsFixed(1)} FPS
- Memory Usage: ${memoryUsage.toStringAsFixed(1)} MB
- Frame Drops: $frameDrops
- Custom Metrics: ${metrics.length}
    ''';
  }
}

/// Extension methods for easy performance measurement
extension PerformanceExtensions on Future<T> Function() {
  Future<T> measured(String name) async {
    return PerformanceMonitor().timeFunction(name, this);
  }
}

extension PerformanceSyncExtensions on T Function() {
  T measured<T>(String name) {
    return PerformanceMonitor().timeFunctionSync(name, this);
  }
}

/// Performance monitoring widget wrapper
class PerformanceWrapper extends StatefulWidget {
  final Widget child;
  final String name;

  const PerformanceWrapper({
    super.key,
    required this.child,
    required this.name,
  });

  @override
  State<PerformanceWrapper> createState() => _PerformanceWrapperState();
}

class _PerformanceWrapperState extends State<PerformanceWrapper> {
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    PerformanceMonitor().recordMetric(
      '${widget.name}_widget_lifetime',
      _stopwatch.elapsedMilliseconds.toDouble(),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}