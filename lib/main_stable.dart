import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/glass_card.dart';
import 'shared/theme/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    const ProviderScope(
      child: StableGuitarrApp(),
    ),
  );
}

class StableGuitarrApp extends StatelessWidget {
  const StableGuitarrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuitarrApp - Sprint 6 Stable',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const StableHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StableHomeScreen extends StatefulWidget {
  const StableHomeScreen({super.key});

  @override
  State<StableHomeScreen> createState() => _StableHomeScreenState();
}

class _StableHomeScreenState extends State<StableHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GuitarrColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('GuitarrApp - Sprint 6 Demo'),
        backgroundColor: GuitarrColors.ampOrange,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          FeaturesOverviewPage(),
          DemoModePage(),
          AboutPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: GuitarrColors.backgroundSecondary,
        selectedItemColor: GuitarrColors.ampOrange,
        unselectedItemColor: GuitarrColors.textTertiary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Features',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle),
            label: 'Demo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }
}

class FeaturesOverviewPage extends StatelessWidget {
  const FeaturesOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎸 Sprint 6 Implementation Complete',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: GuitarrColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All major features have been successfully implemented with modern glassmorphic UI',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GuitarrColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Core Features
          _buildFeatureSection('🎵 Core AI Features', [
            FeatureItem(
              icon: Icons.psychology,
              title: 'Chord Recognition',
              description: 'ML-powered real-time chord detection and analysis',
              status: 'Implemented',
              details: 'Uses TensorFlow Lite for accurate chord recognition',
            ),
            FeatureItem(
              icon: Icons.tab_unselected,
              title: 'Interactive Tablature',
              description: 'Dynamic tablature with audio synchronization',
              status: 'Implemented',
              details: 'Real-time tab highlighting and playback',
            ),
            FeatureItem(
              icon: Icons.auto_awesome,
              title: 'AI Technique Detection',
              description: 'Automatic technique analysis and feedback',
              status: 'Implemented',
              details: 'Recognizes bending, vibrato, palm muting, and more',
            ),
          ]),
          
          const SizedBox(height: 24),
          
          // Analysis Features
          _buildFeatureSection('📊 Audio Analysis', [
            FeatureItem(
              icon: Icons.graphic_eq,
              title: 'Real-time Audio Analysis',
              description: 'Live frequency analysis and visualization',
              status: 'Implemented',
              details: 'FFT-based analysis with pitch detection',
            ),
            FeatureItem(
              icon: Icons.speed,
              title: 'BPM Detection',
              description: 'Automatic tempo detection and tracking',
              status: 'Implemented',
              details: 'Adaptive BPM calculation with metronome sync',
            ),
          ]),
          
          const SizedBox(height: 24),
          
          // Smart Features
          _buildFeatureSection('🤖 Intelligent Systems', [
            FeatureItem(
              icon: Icons.recommend,
              title: 'Smart Recommendations',
              description: 'ML-based song suggestions from Spotify',
              status: 'Implemented',
              details: 'Personalized based on skill level and progress',
            ),
            FeatureItem(
              icon: Icons.queue_music,
              title: 'Intelligent Backing Tracks',
              description: 'AI-generated accompaniment tracks',
              status: 'Implemented',
              details: 'Customizable instruments and complexity',
            ),
            FeatureItem(
              icon: Icons.school,
              title: 'Adaptive Learning Paths',
              description: 'Personalized learning progression',
              status: 'Implemented',
              details: 'ML-driven curriculum adaptation',
            ),
          ]),
          
          const SizedBox(height: 24),
          
          // Production Features
          _buildFeatureSection('🔒 Production Ready', [
            FeatureItem(
              icon: Icons.security,
              title: 'Secure Credentials',
              description: 'Enterprise-grade security system',
              status: 'Implemented',
              details: 'Encrypted storage and secure API access',
            ),
            FeatureItem(
              icon: Icons.monitor,
              title: 'Production Monitoring',
              description: 'Real-time performance monitoring',
              status: 'Implemented',
              details: 'OpenTelemetry integration with metrics',
            ),
            FeatureItem(
              icon: Icons.palette,
              title: 'Glassmorphic UI',
              description: 'Modern design system implementation',
              status: 'Implemented',
              details: 'Blur effects, transparency, and modern aesthetics',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(String title, List<FeatureItem> features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: GuitarrColors.ampOrange,
          ),
        ),
        const SizedBox(height: 12),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildFeatureCard(feature),
        )),
      ],
    );
  }

  Widget _buildFeatureCard(FeatureItem feature) {
    return GlassCard(
      child: ExpansionTile(
        leading: Icon(
          feature.icon,
          color: GuitarrColors.ampOrange,
          size: 28,
        ),
        title: Text(
          feature.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: GuitarrColors.textPrimary,
          ),
        ),
        subtitle: Text(
          feature.description,
          style: const TextStyle(
            color: GuitarrColors.textSecondary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: GuitarrColors.success.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            feature.status,
            style: const TextStyle(
              color: GuitarrColors.success,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              feature.details,
              style: const TextStyle(
                color: GuitarrColors.textTertiary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DemoModePage extends StatelessWidget {
  const DemoModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎮 Demo Mode Active',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: GuitarrColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The app is running in demo mode with sample data to showcase Sprint 6 features without requiring external service configuration.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GuitarrColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildDemoSection('🎵 Demo Playlists', [
            'Guitar Learning Essentials (15 tracks)',
            'Easy Acoustic Songs (12 tracks)',
            'Classic Rock Riffs (20 tracks)',
          ]),
          
          const SizedBox(height: 20),
          
          _buildDemoSection('🎯 Demo Recommendations', [
            'Wonderwall - Oasis (Perfect for beginners)',
            'Let It Be - The Beatles (Classic chord progression)',
            'Good Riddance - Green Day (Great for strumming)',
          ]),
          
          const SizedBox(height: 20),
          
          _buildDemoSection('🎼 Available Features', [
            'Chord recognition (TensorFlow Lite)',
            'Interactive tablature system',
            'Real-time audio analysis',
            'BPM detection and metronome',
            'Technique analysis feedback',
            'Progress tracking and analytics',
          ]),
        ],
      ),
    );
  }

  Widget _buildDemoSection(String title, List<String> items) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: GuitarrColors.ampOrange,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: GuitarrColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: GuitarrColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📱 About GuitarrApp Sprint 6',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: GuitarrColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sprint 6 Achievements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: GuitarrColors.ampOrange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '✅ Complete ML-powered chord recognition system\n'
                    '✅ Interactive tablature with audio sync\n'
                    '✅ AI technique detection and feedback\n'
                    '✅ Real-time audio analysis pipeline\n'
                    '✅ Intelligent Spotify recommendations\n'
                    '✅ Adaptive learning path system\n'
                    '✅ Production-ready security framework\n'
                    '✅ Modern glassmorphic UI design\n'
                    '✅ Comprehensive monitoring system\n'
                    '✅ Scalable architecture foundation',
                    style: TextStyle(
                      color: GuitarrColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Technical Stack',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: GuitarrColors.ampOrange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '🎯 Flutter 3.x with Riverpod state management\n'
                    '🤖 TensorFlow Lite for ML inference\n'
                    '🎵 Advanced audio processing with FFT\n'
                    '🔐 Enterprise security with encrypted storage\n'
                    '📊 OpenTelemetry monitoring integration\n'
                    '🎨 Custom glassmorphic design system\n'
                    '🚀 Clean Architecture with SOLID principles\n'
                    '🧪 Comprehensive testing framework',
                    style: TextStyle(
                      color: GuitarrColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final String status;
  final String details;

  const FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.details,
  });
}