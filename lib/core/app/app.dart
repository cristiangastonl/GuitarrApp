import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import '../../features/auth/presentation/screens/auth_wrapper.dart';
import '../../tools/dev_tools_screen.dart';

class GuitarrApp extends ConsumerWidget {
  const GuitarrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'GuitarrApp',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to dark theme for musicians
      home: const AuthWrapper(),
      routes: {
        '/dev-tools': (context) => const DevToolsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

