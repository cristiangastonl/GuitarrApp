import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app/app.dart';
import 'core/services/secure_credentials_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar credenciales seguras
  try {
    final credentialsService = SecureCredentialsService();
    await credentialsService.initializeCredentials();
  } catch (e) {
    // En desarrollo, continuar sin credenciales
    // En producción, esto debería mostrar un error de configuración
    debugPrint('Warning: Failed to initialize secure credentials: $e');
  }
  
  runApp(
    const ProviderScope(
      child: GuitarrApp(),
    ),
  );
}