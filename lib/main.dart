import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/app/app.dart';
import 'core/services/secure_credentials_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase (solo para Android por ahora)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continuar sin Firebase para web en desarrollo
  }
  
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