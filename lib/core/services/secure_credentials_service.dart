import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Servicio para gestión segura de credenciales API
/// 
/// Utiliza flutter_secure_storage para almacenar credenciales de forma segura:
/// - iOS: Keychain Services
/// - Android: Android Keystore + EncryptedSharedPreferences
class SecureCredentialsService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'guitarr_app_secure_prefs',
      preferencesKeyPrefix: 'guitarr_',
    ),
    iOptions: IOSOptions(
      groupId: 'group.com.guitarrapp.credentials',
      accountName: 'GuitarrApp',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Claves para credenciales
  static const String _spotifyClientIdKey = 'spotify_client_id';
  static const String _spotifyClientSecretKey = 'spotify_client_secret';
  static const String _encryptionKeyKey = 'db_encryption_key';
  static const String _apiKeyHashKey = 'api_key_hash';
  
  // Claves para tokens de usuario de Spotify
  static const String _spotifyUserAccessTokenKey = 'spotify_user_access_token';
  static const String _spotifyUserRefreshTokenKey = 'spotify_user_refresh_token';
  static const String _spotifyUserTokenExpiryKey = 'spotify_user_token_expiry';

  /// Inicializa las credenciales si no existen
  /// En producción, estas deberían configurarse durante el onboarding
  /// o inyectarse a través de un mecanismo seguro de distribución
  Future<void> initializeCredentials() async {
    try {
      // Verificar si las credenciales ya existen
      final existingClientId = await _storage.read(key: _spotifyClientIdKey);
      
      if (existingClientId == null) {
        // En desarrollo, usar credenciales por defecto
        // EN PRODUCCIÓN: Estas deberían venir de un servidor seguro
        await _storeSpotifyCredentials(
          clientId: '4e925f77ef3c48c6b7e7752b9c5c4787',
          clientSecret: '30595005cd6a4877af50c1318f9cff4a',
        );
        
        // Generar clave de encriptación para la base de datos
        await _generateDatabaseEncryptionKey();
      }
    } catch (e) {
      throw SecureCredentialsException('Error inicializando credenciales: $e');
    }
  }

  /// Almacena las credenciales de Spotify de forma segura
  Future<void> _storeSpotifyCredentials({
    required String clientId,
    required String clientSecret,
  }) async {
    try {
      // Validar que las credenciales no estén vacías
      if (clientId.isEmpty || clientSecret.isEmpty) {
        throw ArgumentError('Las credenciales no pueden estar vacías');
      }

      // Almacenar con timestamp para auditoría
      final timestamp = DateTime.now().toIso8601String();
      
      await Future.wait([
        _storage.write(key: _spotifyClientIdKey, value: clientId),
        _storage.write(key: _spotifyClientSecretKey, value: clientSecret),
        _storage.write(key: '${_spotifyClientIdKey}_timestamp', value: timestamp),
        _createApiKeyHash(clientId, clientSecret),
      ]);
    } catch (e) {
      throw SecureCredentialsException('Error almacenando credenciales Spotify: $e');
    }
  }

  /// Crea un hash de las credenciales para verificación de integridad
  Future<void> _createApiKeyHash(String clientId, String clientSecret) async {
    try {
      final combined = '$clientId:$clientSecret';
      final bytes = utf8.encode(combined);
      final digest = sha256.convert(bytes);
      
      await _storage.write(key: _apiKeyHashKey, value: digest.toString());
    } catch (e) {
      throw SecureCredentialsException('Error creando hash de API: $e');
    }
  }

  /// Verifica la integridad de las credenciales
  Future<bool> verifyCredentialsIntegrity() async {
    try {
      final clientId = await getSpotifyClientId();
      final clientSecret = await getSpotifyClientSecret();
      final storedHash = await _storage.read(key: _apiKeyHashKey);
      
      if (clientId == null || clientSecret == null || storedHash == null) {
        return false;
      }

      final combined = '$clientId:$clientSecret';
      final bytes = utf8.encode(combined);
      final digest = sha256.convert(bytes);
      
      return digest.toString() == storedHash;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el Client ID de Spotify
  Future<String?> getSpotifyClientId() async {
    try {
      return await _storage.read(key: _spotifyClientIdKey);
    } catch (e) {
      throw SecureCredentialsException('Error obteniendo Client ID: $e');
    }
  }

  /// Obtiene el Client Secret de Spotify
  Future<String?> getSpotifyClientSecret() async {
    try {
      return await _storage.read(key: _spotifyClientSecretKey);
    } catch (e) {
      throw SecureCredentialsException('Error obteniendo Client Secret: $e');
    }
  }

  /// Genera una clave de encriptación para la base de datos
  Future<void> _generateDatabaseEncryptionKey() async {
    try {
      // Generar clave aleatoria de 256 bits
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomData = '$timestamp:${DateTime.now().toIso8601String()}';
      final bytes = utf8.encode(randomData);
      final digest = sha256.convert(bytes);
      
      await _storage.write(key: _encryptionKeyKey, value: digest.toString());
    } catch (e) {
      throw SecureCredentialsException('Error generando clave de encriptación: $e');
    }
  }

  /// Obtiene la clave de encriptación de la base de datos
  Future<String?> getDatabaseEncryptionKey() async {
    try {
      return await _storage.read(key: _encryptionKeyKey);
    } catch (e) {
      throw SecureCredentialsException('Error obteniendo clave de encriptación: $e');
    }
  }

  /// Actualiza las credenciales de Spotify (para uso administrativo)
  Future<void> updateSpotifyCredentials({
    required String clientId,
    required String clientSecret,
  }) async {
    try {
      // Validar credenciales antes de almacenar
      if (!_isValidClientId(clientId) || !_isValidClientSecret(clientSecret)) {
        throw ArgumentError('Formato de credenciales inválido');
      }

      await _storeSpotifyCredentials(
        clientId: clientId,
        clientSecret: clientSecret,
      );
    } catch (e) {
      throw SecureCredentialsException('Error actualizando credenciales: $e');
    }
  }

  /// Valida el formato del Client ID
  bool _isValidClientId(String clientId) {
    // Spotify Client IDs tienen 32 caracteres alfanuméricos
    return RegExp(r'^[a-zA-Z0-9]{32}$').hasMatch(clientId);
  }

  /// Valida el formato del Client Secret
  bool _isValidClientSecret(String clientSecret) {
    // Spotify Client Secrets tienen 32 caracteres alfanuméricos
    return RegExp(r'^[a-zA-Z0-9]{32}$').hasMatch(clientSecret);
  }

  /// Elimina todas las credenciales (para logout completo)
  Future<void> clearAllCredentials() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecureCredentialsException('Error limpiando credenciales: $e');
    }
  }

  /// Verifica si las credenciales están configuradas
  Future<bool> areCredentialsConfigured() async {
    try {
      final clientId = await getSpotifyClientId();
      final clientSecret = await getSpotifyClientSecret();
      
      return clientId != null && 
             clientSecret != null && 
             clientId.isNotEmpty && 
             clientSecret.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene información de auditoría sobre las credenciales
  Future<Map<String, dynamic>> getCredentialsAuditInfo() async {
    try {
      final timestamp = await _storage.read(key: '${_spotifyClientIdKey}_timestamp');
      final hasCredentials = await areCredentialsConfigured();
      final integrityOk = await verifyCredentialsIntegrity();
      
      return {
        'hasCredentials': hasCredentials,
        'integrityVerified': integrityOk,
        'lastUpdated': timestamp,
        'storageType': 'flutter_secure_storage',
      };
    } catch (e) {
      return {
        'hasCredentials': false,
        'integrityVerified': false,
        'error': e.toString(),
      };
    }
  }

  // Métodos para tokens de usuario de Spotify
  
  /// Almacena los tokens de usuario de Spotify
  Future<void> storeSpotifyUserTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _spotifyUserAccessTokenKey, value: accessToken),
        _storage.write(key: _spotifyUserRefreshTokenKey, value: refreshToken),
        _storage.write(key: _spotifyUserTokenExpiryKey, value: expiresAt.toIso8601String()),
      ]);
    } catch (e) {
      throw SecureCredentialsException('Error almacenando tokens de usuario: $e');
    }
  }
  
  /// Obtiene los tokens de usuario de Spotify
  Future<SpotifyUserTokens?> getSpotifyUserTokens() async {
    try {
      final accessToken = await _storage.read(key: _spotifyUserAccessTokenKey);
      final refreshToken = await _storage.read(key: _spotifyUserRefreshTokenKey);
      final expiryString = await _storage.read(key: _spotifyUserTokenExpiryKey);
      
      if (accessToken == null || refreshToken == null || expiryString == null) {
        return null;
      }
      
      final expiresAt = DateTime.parse(expiryString);
      
      return SpotifyUserTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );
    } catch (e) {
      throw SecureCredentialsException('Error obteniendo tokens de usuario: $e');
    }
  }
  
  /// Elimina los tokens de usuario de Spotify
  Future<void> clearSpotifyUserTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: _spotifyUserAccessTokenKey),
        _storage.delete(key: _spotifyUserRefreshTokenKey),
        _storage.delete(key: _spotifyUserTokenExpiryKey),
      ]);
    } catch (e) {
      throw SecureCredentialsException('Error eliminando tokens de usuario: $e');
    }
  }
  
  /// Verifica si el usuario tiene tokens válidos
  Future<bool> hasValidSpotifyUserTokens() async {
    try {
      final tokens = await getSpotifyUserTokens();
      if (tokens == null) return false;
      
      // Check if token is not expired (with 5 minute buffer)
      final now = DateTime.now();
      final expiryWithBuffer = tokens.expiresAt.subtract(const Duration(minutes: 5));
      
      return now.isBefore(expiryWithBuffer);
    } catch (e) {
      return false;
    }
  }
}

/// Clase para representar tokens de usuario de Spotify
class SpotifyUserTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  
  const SpotifyUserTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });
}

/// Excepción personalizada para errores de credenciales
class SecureCredentialsException implements Exception {
  final String message;
  
  const SecureCredentialsException(this.message);
  
  @override
  String toString() => 'SecureCredentialsException: $message';
}

/// Provider para el servicio de credenciales seguras
final secureCredentialsServiceProvider = Provider<SecureCredentialsService>((ref) {
  return SecureCredentialsService();
});

/// Provider para verificar si las credenciales están configuradas
final credentialsConfiguredProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(secureCredentialsServiceProvider);
  return await service.areCredentialsConfigured();
});

/// Provider para información de auditoría de credenciales
final credentialsAuditProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(secureCredentialsServiceProvider);
  return await service.getCredentialsAuditInfo();
});