import 'dart:collection';

/// Captures and stores recent app errors in memory.
/// The last [maxEntries] errors are kept in a circular buffer.
class ErrorLogService {
  static final ErrorLogService _instance = ErrorLogService._();
  factory ErrorLogService() => _instance;
  ErrorLogService._();

  static const int maxEntries = 20;

  final Queue<ErrorEntry> _errors = Queue<ErrorEntry>();

  /// Record an error with optional stack trace.
  void log(Object error, StackTrace? stack, {String? context}) {
    final entry = ErrorEntry(
      timestamp: DateTime.now(),
      error: error.toString(),
      stackTrace: _trimStack(stack),
      context: context,
    );
    _errors.addLast(entry);
    while (_errors.length > maxEntries) {
      _errors.removeFirst();
    }
  }

  /// Get all stored errors (most recent last).
  List<ErrorEntry> get errors => _errors.toList();

  /// Whether there are any logged errors.
  bool get hasErrors => _errors.isNotEmpty;

  /// Format errors as a markdown string for inclusion in a GitHub issue.
  String formatForIssue() {
    if (_errors.isEmpty) return '_Sin errores recientes_';

    final buf = StringBuffer();
    for (final e in _errors) {
      buf.writeln('**${_formatTime(e.timestamp)}**${e.context != null ? ' (${e.context})' : ''}');
      buf.writeln('```');
      buf.writeln(e.error);
      if (e.stackTrace != null) {
        buf.writeln(e.stackTrace);
      }
      buf.writeln('```');
      buf.writeln();
    }
    return buf.toString();
  }

  void clear() => _errors.clear();

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  /// Keep only the first 8 frames to avoid huge stack traces.
  String? _trimStack(StackTrace? stack) {
    if (stack == null) return null;
    final lines = stack.toString().split('\n');
    if (lines.length <= 10) return stack.toString().trimRight();
    return '${lines.take(8).join('\n')}\n... (${lines.length - 8} more frames)';
  }
}

class ErrorEntry {
  final DateTime timestamp;
  final String error;
  final String? stackTrace;
  final String? context;

  const ErrorEntry({
    required this.timestamp,
    required this.error,
    this.stackTrace,
    this.context,
  });
}
