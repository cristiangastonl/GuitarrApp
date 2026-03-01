import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/arcade_theme.dart';
import '../../features/home/presentation/screens/arcade_home_screen.dart';

class GuitarrApp extends ConsumerWidget {
  const GuitarrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'GuitarrApp',
      theme: ArcadeTheme.theme,
      home: const ArcadeHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
