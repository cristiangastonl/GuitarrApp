import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Servicio de logging seguro que evita la exposición de información sensible
/// 
/// Proporciona diferentes niveles de logging y filtra automáticamente
/// datos sensibles como credenciales, información personal, etc.
class SecureLoggingService {
  static const bool _isProduction = bool.fromEnvironment('dart.vm.product');
  
  // Patrones de datos sensibles que nunca deben loggearse
  static final List<RegExp> _sensitivePatterns = [
    RegExp(r'password', caseSensitive: false),
    RegExp(r'secret', caseSensitive: false),
    RegExp(r'token', caseSensitive: false),
    RegExp(r'key', caseSensitive: false),
    RegExp(r'credential', caseSensitive: false),
    RegExp(r'api_key', caseSensitive: false),
    RegExp(r'auth', caseSensitive: false),
    RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), // Email
    RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'), // Credit card-like numbers
  ];
  
  // Palabras clave que indican información sensible
  static const List<String> _sensitiveKeywords = [
    'password', 'secret', 'token', 'key', 'credential', 'auth',
    'client_id', 'client_secret', 'spotify', 'personal', 'private'
  ];

  /// Log de debug - solo en desarrollo
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_isProduction) return;
    
    final sanitizedMessage = _sanitizeMessage(message);
    final tagPrefix = tag != null ? '[$tag] ' : '';
    
    if (kDebugMode) {
      debugPrint('🐛 DEBUG: $tagPrefix$sanitizedMessage');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }

  /// Log de información general
  static void info(String message, {String? tag}) {
    final sanitizedMessage = _sanitizeMessage(message);
    final tagPrefix = tag != null ? '[$tag] ' : '';
    
    if (kDebugMode && !_isProduction) {
      debugPrint('ℹ️ INFO: $tagPrefix$sanitizedMessage');
    }
  }

  /// Log de advertencias
  static void warning(String message, {String? tag, Object? error}) {
    final sanitizedMessage = _sanitizeMessage(message);
    final tagPrefix = tag != null ? '[$tag] ' : '';
    
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: $tagPrefix$sanitizedMessage');
      if (error != null && !_isProduction) {
        debugPrint('Error details: ${_sanitizeErrorMessage(error.toString())}');
      }
    }
  }

  /// Log de errores críticos
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final sanitizedMessage = _sanitizeMessage(message);
    final tagPrefix = tag != null ? '[$tag] ' : '';
    
    // Los errores se loggean incluso en producción, pero sanitizados
    debugPrint('❌ ERROR: $tagPrefix$sanitizedMessage');
    
    if (error != null) {
      final sanitizedError = _sanitizeErrorMessage(error.toString());
      debugPrint('Error details: $sanitizedError');
    }
    
    // En desarrollo, incluir stack trace
    if (!_isProduction && stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }

  /// Log de eventos de seguridad
  static void security(String message, {String? tag, Map<String, dynamic>? metadata}) {
    final sanitizedMessage = _sanitizeMessage(message);
    final tagPrefix = tag != null ? '[$tag] ' : '';
    
    // Los eventos de seguridad siempre se loggean
    debugPrint('🔒 SECURITY: $tagPrefix$sanitizedMessage');
    
    if (metadata != null && !_isProduction) {
      final sanitizedMetadata = _sanitizeMetadata(metadata);
      debugPrint('Metadata: $sanitizedMetadata');
    }
  }

  /// Log de rendimiento
  static void performance(String message, {String? tag, Duration? duration}) {
    if (_isProduction) return;
    
    final sanitizedMessage = _sanitizeMessage(message);
    final tagPrefix = tag != null ? '[$tag] ' : '';
    final durationText = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    
    if (kDebugMode) {
      debugPrint('⚡ PERFORMANCE: $tagPrefix$sanitizedMessage$durationText');
    }
  }

  /// Log de auditoría para acciones importantes
  static void audit(String action, {String? userId, Map<String, dynamic>? details}) {
    final sanitizedAction = _sanitizeMessage(action);
    final userInfo = userId != null ? '[User: ${_sanitizeUserId(userId)}] ' : '';
    
    debugPrint('📋 AUDIT: $userInfo$sanitizedAction');
    
    if (details != null && !_isProduction) {
      final sanitizedDetails = _sanitizeMetadata(details);
      debugPrint('Details: $sanitizedDetails');
    }
  }

  // Métodos de sanitización privados

  /// Sanitiza el mensaje principal removiendo información sensible
  static String _sanitizeMessage(String message) {
    String sanitized = message;
    
    // Reemplazar patrones sensibles con placeholders
    for (final pattern in _sensitivePatterns) {
      sanitized = sanitized.replaceAll(pattern, '[REDACTED]');
    }
    
    // Reemplazar palabras clave sensibles
    for (final keyword in _sensitiveKeywords) {
      if (sanitized.toLowerCase().contains(keyword.toLowerCase())) {
        // Si contiene palabras sensibles, ser más agresivo en la sanitización
        sanitized = sanitized.replaceAllMapped(
          RegExp('$keyword\\s*[:=]\\s*[^\\s,}]+', caseSensitive: false),
          (match) => '${match.group(0)?.split(':')[0] ?? keyword}: [REDACTED]',
        );
      }
    }
    
    return sanitized;
  }

  /// Sanitiza mensajes de error
  static String _sanitizeErrorMessage(String errorMessage) {
    String sanitized = _sanitizeMessage(errorMessage);
    
    // Remover rutas de archivo completas que podrían revelar información del sistema
    sanitized = sanitized.replaceAll(RegExp(r'/[^/\s]+/[^/\s]+/[^/\s]+'), '/[PATH]/');
    sanitized = sanitized.replaceAll(RegExp(r'C:\\[^\\s]+\\[^\\s]+'), 'C:\\[PATH]\\');
    
    return sanitized;
  }

  /// Sanitiza metadatos y diccionarios
  static Map<String, dynamic> _sanitizeMetadata(Map<String, dynamic> metadata) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in metadata.entries) {
      final key = entry.key.toLowerCase();
      
      if (_sensitiveKeywords.any((keyword) => key.contains(keyword))) {
        sanitized[entry.key] = '[REDACTED]';
      } else if (entry.value is String) {
        sanitized[entry.key] = _sanitizeMessage(entry.value as String);
      } else if (entry.value is Map<String, dynamic>) {
        sanitized[entry.key] = _sanitizeMetadata(entry.value as Map<String, dynamic>);
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    
    return sanitized;
  }

  /// Sanitiza IDs de usuario para logging
  static String _sanitizeUserId(String userId) {
    if (userId.length > 8) {
      return '${userId.substring(0, 4)}****${userId.substring(userId.length - 4)}';
    }
    return '****';
  }

  /// Verifica si un mensaje contiene información sensible
  static bool _containsSensitiveData(String message) {
    return _sensitivePatterns.any((pattern) => pattern.hasMatch(message)) ||
           _sensitiveKeywords.any((keyword) => message.toLowerCase().contains(keyword));
  }
}

/// Extensión para facilitar el uso del logging seguro
extension SecureLogging on Object {
  void logDebug(String message, {String? tag}) {
    SecureLoggingService.debug(message, tag: tag ?? runtimeType.toString());
  }
  
  void logInfo(String message, {String? tag}) {
    SecureLoggingService.info(message, tag: tag ?? runtimeType.toString());
  }
  
  void logWarning(String message, {Object? error}) {
    SecureLoggingService.warning(message, tag: runtimeType.toString(), error: error);
  }
  
  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    SecureLoggingService.error(message, tag: runtimeType.toString(), error: error, stackTrace: stackTrace);
  }
  
  void logSecurity(String message, {Map<String, dynamic>? metadata}) {
    SecureLoggingService.security(message, tag: runtimeType.toString(), metadata: metadata);
  }
}

/// Utilitarios de logging para casos comunes
class LogUtils {
  /// Log de inicio de operación
  static void operationStarted(String operation, {String? tag}) {
    SecureLoggingService.debug('Started: $operation', tag: tag);
  }
  
  /// Log de finalización de operación
  static void operationCompleted(String operation, {Duration? duration, String? tag}) {
    SecureLoggingService.debug('Completed: $operation', tag: tag);
    if (duration != null) {
      SecureLoggingService.performance('Operation duration', tag: operation, duration: duration);
    }
  }
  
  /// Log de operación fallida
  static void operationFailed(String operation, Object error, {StackTrace? stackTrace, String? tag}) {
    SecureLoggingService.error('Failed: $operation', tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log de configuración aplicada
  static void configApplied(String configName, Map<String, dynamic> config) {
    SecureLoggingService.info('Configuration applied: $configName');
    SecureLoggingService.debug('Config details', tag: configName);
  }
  
  /// Log de evento de usuario
  static void userEvent(String event, {String? userId, Map<String, dynamic>? metadata}) {
    SecureLoggingService.audit(event, userId: userId, details: metadata);
  }
}

/// Provider para el servicio de logging seguro
final secureLoggingServiceProvider = Provider<SecureLoggingService>((ref) {
  return SecureLoggingService();
});

/// Constantes para etiquetas comunes de logging
class LogTags {
  static const String auth = 'AUTH';
  static const String database = 'DATABASE';
  static const String network = 'NETWORK';
  static const String audio = 'AUDIO';
  static const String recording = 'RECORDING';
  static const String playback = 'PLAYBACK';
  static const String ui = 'UI';
  static const String validation = 'VALIDATION';
  static const String security = 'SECURITY';
  static const String performance = 'PERFORMANCE';
}