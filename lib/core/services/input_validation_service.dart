import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Servicio de validación y sanitización de entrada de usuario
/// 
/// Proporciona validación robusta para todos los datos de entrada
/// del usuario para prevenir vulnerabilidades de seguridad
class InputValidationService {
  // Expresiones regulares para validación
  static final RegExp _alphanumericRegex = RegExp(r'^[a-zA-Z0-9_\-\s]+$');
  static final RegExp _filenameRegex = RegExp(r'^[a-zA-Z0-9_\-\.]+$');
  static final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp _sessionNameRegex = RegExp(r'^[a-zA-Z0-9_\-]+$');
  
  // Caracteres peligrosos que deben ser removidos o escapados
  static const List<String> _dangerousChars = [
    '<', '>', '"', "'", '&', '\\', '/', '..', '%', ';', '|', '`', '\$'
  ];
  
  // Longitudes máximas para diferentes campos
  static const int _maxNameLength = 100;
  static const int _maxDescriptionLength = 500;
  static const int _maxNotesLength = 1000;
  static const int _maxFileNameLength = 100;

  /// Valida y sanitiza nombres de usuario/jugador
  ValidationResult<String> validatePlayerName(String name) {
    try {
      // Verificar entrada no nula y no vacía
      if (name.isEmpty) {
        return ValidationResult.error('El nombre no puede estar vacío');
      }
      
      // Verificar longitud
      if (name.length > _maxNameLength) {
        return ValidationResult.error('El nombre es demasiado largo (máximo $_maxNameLength caracteres)');
      }
      
      // Sanitizar entrada
      final sanitized = _sanitizeString(name);
      
      // Validar caracteres permitidos
      if (!_alphanumericRegex.hasMatch(sanitized)) {
        return ValidationResult.error('El nombre contiene caracteres no válidos');
      }
      
      // Verificar que no esté vacío después de sanitización
      if (sanitized.trim().isEmpty) {
        return ValidationResult.error('El nombre no puede estar vacío después de limpiar caracteres especiales');
      }
      
      return ValidationResult.success(sanitized.trim());
    } catch (e) {
      return ValidationResult.error('Error validando nombre: $e');
    }
  }

  /// Valida y sanitiza nombres de sesión de práctica
  ValidationResult<String> validateSessionName(String sessionName) {
    try {
      if (sessionName.isEmpty) {
        return ValidationResult.error('El nombre de sesión no puede estar vacío');
      }
      
      if (sessionName.length > _maxFileNameLength) {
        return ValidationResult.error('El nombre de sesión es demasiado largo');
      }
      
      // Sanitizar para uso en nombres de archivo
      final sanitized = _sanitizeFileName(sessionName);
      
      if (!_sessionNameRegex.hasMatch(sanitized)) {
        return ValidationResult.error('El nombre de sesión contiene caracteres no válidos');
      }
      
      return ValidationResult.success(sanitized);
    } catch (e) {
      return ValidationResult.error('Error validando nombre de sesión: $e');
    }
  }

  /// Valida y sanitiza nombres de archivo
  ValidationResult<String> validateFileName(String fileName) {
    try {
      if (fileName.isEmpty) {
        return ValidationResult.error('El nombre de archivo no puede estar vacío');
      }
      
      if (fileName.length > _maxFileNameLength) {
        return ValidationResult.error('El nombre de archivo es demasiado largo');
      }
      
      // Verificar extensión permitida
      if (!_hasValidFileExtension(fileName)) {
        return ValidationResult.error('Extensión de archivo no permitida');
      }
      
      // Sanitizar nombre de archivo
      final sanitized = _sanitizeFileName(fileName);
      
      if (!_filenameRegex.hasMatch(sanitized)) {
        return ValidationResult.error('El nombre de archivo contiene caracteres no válidos');
      }
      
      // Verificar que no sea un nombre de archivo reservado
      if (_isReservedFileName(sanitized)) {
        return ValidationResult.error('Nombre de archivo reservado del sistema');
      }
      
      return ValidationResult.success(sanitized);
    } catch (e) {
      return ValidationResult.error('Error validando nombre de archivo: $e');
    }
  }

  /// Valida rutas de archivo para prevenir directory traversal
  ValidationResult<String> validateFilePath(String filePath) {
    try {
      if (filePath.isEmpty) {
        return ValidationResult.error('La ruta de archivo no puede estar vacía');
      }
      
      // Verificar intentos de directory traversal
      if (filePath.contains('..') || 
          filePath.contains('//') || 
          filePath.startsWith('/') ||
          filePath.contains('\\')) {
        return ValidationResult.error('Ruta de archivo contiene secuencias peligrosas');
      }
      
      // Sanitizar la ruta
      final sanitized = _sanitizeFilePath(filePath);
      
      // Verificar que la ruta esté dentro de directorios permitidos
      if (!_isAllowedFilePath(sanitized)) {
        return ValidationResult.error('Ruta de archivo no permitida');
      }
      
      return ValidationResult.success(sanitized);
    } catch (e) {
      return ValidationResult.error('Error validando ruta de archivo: $e');
    }
  }

  /// Valida parámetros numéricos (BPM, duraciones, etc.)
  ValidationResult<int> validateNumericValue(
    int value, {
    required int min,
    required int max,
    required String fieldName,
  }) {
    try {
      if (value < min) {
        return ValidationResult.error('$fieldName debe ser al menos $min');
      }
      
      if (value > max) {
        return ValidationResult.error('$fieldName no puede ser mayor a $max');
      }
      
      return ValidationResult.success(value);
    } catch (e) {
      return ValidationResult.error('Error validando $fieldName: $e');
    }
  }

  /// Valida porcentajes y valores de precisión
  ValidationResult<double> validatePercentageValue(
    double value, {
    required String fieldName,
  }) {
    try {
      if (value < 0.0) {
        return ValidationResult.error('$fieldName no puede ser negativo');
      }
      
      if (value > 1.0) {
        return ValidationResult.error('$fieldName no puede ser mayor a 1.0');
      }
      
      return ValidationResult.success(value);
    } catch (e) {
      return ValidationResult.error('Error validando $fieldName: $e');
    }
  }

  /// Valida notas y descripciones de usuario
  ValidationResult<String> validateUserNotes(String notes) {
    try {
      if (notes.length > _maxNotesLength) {
        return ValidationResult.error('Las notas son demasiado largas (máximo $_maxNotesLength caracteres)');
      }
      
      // Sanitizar notas removiendo contenido potencialmente peligroso
      final sanitized = _sanitizeUserContent(notes);
      
      return ValidationResult.success(sanitized);
    } catch (e) {
      return ValidationResult.error('Error validando notas: $e');
    }
  }

  /// Valida descripciones
  ValidationResult<String> validateDescription(String description) {
    try {
      if (description.length > _maxDescriptionLength) {
        return ValidationResult.error('La descripción es demasiado larga (máximo $_maxDescriptionLength caracteres)');
      }
      
      final sanitized = _sanitizeUserContent(description);
      
      return ValidationResult.success(sanitized);
    } catch (e) {
      return ValidationResult.error('Error validando descripción: $e');
    }
  }

  /// Valida IDs de entidades
  ValidationResult<String> validateEntityId(String id, String entityType) {
    try {
      if (id.isEmpty) {
        return ValidationResult.error('El ID de $entityType no puede estar vacío');
      }
      
      // IDs deben ser alfanuméricos con guiones
      if (!RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(id)) {
        return ValidationResult.error('ID de $entityType contiene caracteres no válidos');
      }
      
      if (id.length > 50) {
        return ValidationResult.error('ID de $entityType es demasiado largo');
      }
      
      return ValidationResult.success(id);
    } catch (e) {
      return ValidationResult.error('Error validando ID de $entityType: $e');
    }
  }

  /// Valida configuraciones JSON para prevenir inyección
  ValidationResult<Map<String, dynamic>> validateJsonConfig(Map<String, dynamic> config) {
    try {
      // Verificar que no contenga claves peligrosas
      final dangerousKeys = ['__proto__', 'constructor', 'prototype'];
      
      for (final key in config.keys) {
        if (dangerousKeys.contains(key.toLowerCase())) {
          return ValidationResult.error('Configuración contiene claves no permitidas');
        }
        
        // Validar que las claves sean strings seguros
        if (!_alphanumericRegex.hasMatch(key)) {
          return ValidationResult.error('Clave de configuración contiene caracteres no válidos: $key');
        }
      }
      
      // Sanitizar valores string en la configuración
      final sanitizedConfig = <String, dynamic>{};
      for (final entry in config.entries) {
        if (entry.value is String) {
          sanitizedConfig[entry.key] = _sanitizeString(entry.value as String);
        } else {
          sanitizedConfig[entry.key] = entry.value;
        }
      }
      
      return ValidationResult.success(sanitizedConfig);
    } catch (e) {
      return ValidationResult.error('Error validando configuración: $e');
    }
  }

  // Métodos de sanitización privados

  /// Sanitiza strings generales removiendo caracteres peligrosos
  String _sanitizeString(String input) {
    String sanitized = input;
    
    // Remover caracteres peligrosos
    for (final char in _dangerousChars) {
      sanitized = sanitized.replaceAll(char, '');
    }
    
    // Remover caracteres de control
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    
    return sanitized;
  }

  /// Sanitiza nombres de archivo
  String _sanitizeFileName(String fileName) {
    String sanitized = fileName;
    
    // Remover caracteres no permitidos en nombres de archivo
    sanitized = sanitized.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
    
    // Remover caracteres de control
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    
    // Remover espacios al inicio y final
    sanitized = sanitized.trim();
    
    // Reemplazar espacios múltiples con uno solo
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    return sanitized;
  }

  /// Sanitiza rutas de archivo
  String _sanitizeFilePath(String filePath) {
    String sanitized = filePath;
    
    // Normalizar separadores de ruta
    sanitized = sanitized.replaceAll('\\', '/');
    
    // Remover dobles barras
    sanitized = sanitized.replaceAll('//', '/');
    
    // Remover referencias de directorio padre
    sanitized = sanitized.replaceAll('../', '');
    sanitized = sanitized.replaceAll('..\\', '');
    
    return sanitized;
  }

  /// Sanitiza contenido de usuario (notas, descripciones)
  String _sanitizeUserContent(String content) {
    String sanitized = content;
    
    // Remover tags HTML/XML peligrosos
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Escapar caracteres potencialmente peligrosos
    sanitized = sanitized.replaceAll('&', '&amp;');
    sanitized = sanitized.replaceAll('<', '&lt;');
    sanitized = sanitized.replaceAll('>', '&gt;');
    sanitized = sanitized.replaceAll('"', '&quot;');
    sanitized = sanitized.replaceAll("'", '&#x27;');
    
    return sanitized.trim();
  }

  // Métodos de verificación privados

  /// Verifica si la extensión de archivo es válida
  bool _hasValidFileExtension(String fileName) {
    const allowedExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.json', '.txt'];
    
    final extension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    return allowedExtensions.contains(extension);
  }

  /// Verifica si es un nombre de archivo reservado del sistema
  bool _isReservedFileName(String fileName) {
    const reservedNames = [
      'con', 'prn', 'aux', 'nul', 'com1', 'com2', 'com3', 'com4',
      'lpt1', 'lpt2', 'lpt3', 'config', 'system'
    ];
    
    final nameWithoutExtension = fileName.toLowerCase();
    final dotIndex = nameWithoutExtension.lastIndexOf('.');
    final baseName = dotIndex > 0 ? nameWithoutExtension.substring(0, dotIndex) : nameWithoutExtension;
    
    return reservedNames.contains(baseName);
  }

  /// Verifica si la ruta de archivo está en directorios permitidos
  bool _isAllowedFilePath(String filePath) {
    const allowedPrefixes = [
      'recordings/',
      'assets/',
      'cache/',
      'temp/',
    ];
    
    return allowedPrefixes.any((prefix) => filePath.startsWith(prefix));
  }
}

/// Resultado de validación genérico
class ValidationResult<T> {
  final bool isValid;
  final T? value;
  final String? error;

  const ValidationResult._({
    required this.isValid,
    this.value,
    this.error,
  });

  factory ValidationResult.success(T value) {
    return ValidationResult._(isValid: true, value: value);
  }

  factory ValidationResult.error(String error) {
    return ValidationResult._(isValid: false, error: error);
  }

  /// Ejecuta una función si la validación fue exitosa
  ValidationResult<R> map<R>(R Function(T value) mapper) {
    if (isValid && value != null) {
      try {
        return ValidationResult.success(mapper(value as T));
      } catch (e) {
        return ValidationResult.error('Error durante transformación: $e');
      }
    }
    return ValidationResult.error(error ?? 'Validación fallida');
  }

  /// Ejecuta una función si la validación falló
  ValidationResult<T> onError(Function(String error) onError) {
    if (!isValid && error != null) {
      onError(error!);
    }
    return this;
  }
}

/// Excepción para errores de validación
class ValidationException implements Exception {
  final String message;
  final String? field;

  const ValidationException(this.message, {this.field});

  @override
  String toString() {
    if (field != null) {
      return 'ValidationException [$field]: $message';
    }
    return 'ValidationException: $message';
  }
}

/// Provider para el servicio de validación
final inputValidationServiceProvider = Provider<InputValidationService>((ref) {
  return InputValidationService();
});

/// Utilidades de validación para uso rápido
class ValidationUtils {
  static final _service = InputValidationService();

  static String sanitizeSessionName(String sessionName) {
    final result = _service.validateSessionName(sessionName);
    return result.isValid ? result.value! : 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  static bool isValidBPM(int bpm) {
    final result = _service.validateNumericValue(bpm, min: 30, max: 300, fieldName: 'BPM');
    return result.isValid;
  }

  static bool isValidAccuracy(double accuracy) {
    final result = _service.validatePercentageValue(accuracy, fieldName: 'precisión');
    return result.isValid;
  }

  static String sanitizeUserInput(String input) {
    return _service._sanitizeString(input);
  }
}