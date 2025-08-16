import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Aplicación en modo seguro sin servicios complejos
  runApp(
    const ProviderScope(
      child: SafeGuitarrApp(),
    ),
  );
}

class SafeGuitarrApp extends StatelessWidget {
  const SafeGuitarrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuitarrApp - Safe Mode',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SafeHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SafeHomeScreen extends StatelessWidget {
  const SafeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GuitarrApp - Sprint 6 Demo'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎸 Sprint 6 Features Implemented',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            FeatureCard(
              icon: Icons.music_note,
              title: 'Chord Recognition',
              description: 'ML-powered chord detection and analysis',
              status: 'Implemented',
            ),
            SizedBox(height: 12),
            FeatureCard(
              icon: Icons.tab,
              title: 'Interactive Tablature',
              description: 'Dynamic tabs with audio synchronization',
              status: 'Implemented',
            ),
            SizedBox(height: 12),
            FeatureCard(
              icon: Icons.psychology,
              title: 'AI Technique Detection',
              description: 'Automatic technique analysis and feedback',
              status: 'Implemented',
            ),
            SizedBox(height: 12),
            FeatureCard(
              icon: Icons.analytics,
              title: 'Real-time Audio Analysis',
              description: 'Live audio processing and visualization',
              status: 'Implemented',
            ),
            SizedBox(height: 12),
            FeatureCard(
              icon: Icons.school,
              title: 'Adaptive Learning',
              description: 'Personalized learning paths with ML',
              status: 'Implemented',
            ),
            SizedBox(height: 12),
            FeatureCard(
              icon: Icons.security,
              title: 'Production Security',
              description: 'Enterprise-grade security and monitoring',
              status: 'Implemented',
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String status;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}