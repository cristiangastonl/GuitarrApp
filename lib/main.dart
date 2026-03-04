import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/app/app.dart';
import 'core/services/error_log_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final errorLog = ErrorLogService();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env not available - AI features will be disabled
  }

  // Capture Flutter framework errors (widget build errors, layout issues, etc.)
  FlutterError.onError = (details) {
    FlutterError.presentError(details); // keep default red screen in debug
    errorLog.log(
      details.exceptionAsString(),
      details.stack,
      context: details.context?.toString(),
    );
  };

  // Capture async / platform errors not caught by Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    errorLog.log(error, stack, context: 'platform');
    return true; // prevent crash in release mode
  };

  runApp(
    const ProviderScope(
      child: GuitarrApp(),
    ),
  );
}
