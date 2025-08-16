import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: GuitarrAppDemo(),
    ),
  );
}

class GuitarrAppDemo extends StatelessWidget {
  const GuitarrAppDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuitarrApp - Sprint 6 Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1B1B1B),
      ),
      home: const DemoHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DemoHomeScreen extends StatefulWidget {
  const DemoHomeScreen({super.key});

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🎸 GuitarrApp Sprint 6',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            FeaturesPage(),
            PracticePage(),
            AnalyticsPage(),
            SettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: const Color(0xFF2D2D2D),
        selectedItemColor: const Color(0xFFFF6B35),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Features',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Practice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      FeatureItem(
        icon: Icons.psychology,
        title: 'Chord Recognition',
        description: 'ML-powered real-time chord detection',
        status: 'Active',
        color: Colors.blue,
      ),
      FeatureItem(
        icon: Icons.tab_unselected,
        title: 'Interactive Tablature',
        description: 'Dynamic tabs with audio sync',
        status: 'Active',
        color: Colors.green,
      ),
      FeatureItem(
        icon: Icons.auto_awesome,
        title: 'AI Technique Detection',
        description: 'Automatic technique analysis',
        status: 'Active',
        color: Colors.purple,
      ),
      FeatureItem(
        icon: Icons.graphic_eq,
        title: 'Real-time Audio Analysis',
        description: 'FFT-based frequency analysis',
        status: 'Active',
        color: Colors.orange,
      ),
      FeatureItem(
        icon: Icons.recommend,
        title: 'Smart Recommendations',
        description: 'ML-based song suggestions',
        status: 'Demo Mode',
        color: Colors.teal,
      ),
      FeatureItem(
        icon: Icons.queue_music,
        title: 'Intelligent Backing Tracks',
        description: 'AI-generated accompaniment',
        status: 'Demo Mode',
        color: Colors.indigo,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '🚀 Sprint 6 Features',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'All major features implemented and ready for testing',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 24),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FeatureCard(feature: feature),
        )),
      ],
    );
  }
}

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> with TickerProviderStateMixin {
  late AnimationController _chordController;
  late Animation<double> _chordAnimation;
  String _currentChord = 'Em';
  double _confidence = 0.95;

  @override
  void initState() {
    super.initState();
    _chordController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _chordAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chordController, curve: Curves.elasticOut),
    );
    
    // Simulate chord detection
    _simulateChordDetection();
  }

  void _simulateChordDetection() {
    final chords = ['Em', 'Am', 'C', 'G', 'D', 'F'];
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentChord = chords[DateTime.now().millisecond % chords.length];
          _confidence = 0.85 + (DateTime.now().millisecond % 15) / 100;
        });
        _chordController.forward().then((_) {
          _chordController.reset();
        });
        _simulateChordDetection();
      }
    });
  }

  @override
  void dispose() {
    _chordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎸 Practice Mode',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // Chord Recognition Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B35).withOpacity(0.2),
                  const Color(0xFF4ECDC4).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                const Text(
                  'Detected Chord',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                ScaleTransition(
                  scale: _chordAnimation,
                  child: Text(
                    _currentChord,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _confidence,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Audio Analysis Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 Real-time Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAnalysisRow('Pitch Detection', 'A4 (440 Hz)', Colors.green),
                _buildAnalysisRow('BPM Detection', '120 BPM', Colors.blue),
                _buildAnalysisRow('Audio Quality', 'Excellent', Colors.purple),
                _buildAnalysisRow('Technique', 'Strumming', Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '📈 Practice Analytics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        
        _buildStatCard('Total Practice Time', '47 hours', Icons.timer, Colors.blue),
        const SizedBox(height: 16),
        _buildStatCard('Chords Learned', '23 chords', Icons.music_note, Colors.green),
        const SizedBox(height: 16),
        _buildStatCard('Accuracy Rate', '94.2%', Icons.gps_fixed, Colors.orange),
        const SizedBox(height: 16),
        _buildStatCard('Current Streak', '12 days', Icons.local_fire_department, Colors.red),
        
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎯 Recent Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildAchievement('Chord Master', 'Learned 20+ chords'),
              _buildAchievement('Consistent Player', '10+ day streak'),
              _buildAchievement('Accuracy Expert', '90%+ accuracy rate'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievement(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFFFFD93D), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '⚙️ Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        
        _buildSettingCard(
          '🔊 Audio Settings',
          'Configure microphone and audio processing',
          Icons.mic,
        ),
        _buildSettingCard(
          '🤖 AI Configuration',
          'Adjust ML model sensitivity and accuracy',
          Icons.psychology,
        ),
        _buildSettingCard(
          '🎵 Music Preferences',
          'Set your favorite genres and artists',
          Icons.music_note,
        ),
        _buildSettingCard(
          '📊 Analytics',
          'Manage practice data and progress tracking',
          Icons.analytics,
        ),
        _buildSettingCard(
          '🔒 Privacy & Security',
          'Secure credentials and data protection',
          Icons.security,
        ),
        
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎸 About Sprint 6',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'All major AI and ML features have been successfully implemented:\n\n'
                '✅ Chord Recognition\n'
                '✅ Interactive Tablature\n'
                '✅ AI Technique Detection\n'
                '✅ Real-time Audio Analysis\n'
                '✅ Smart Recommendations\n'
                '✅ Intelligent Backing Tracks\n'
                '✅ Production Security',
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF6B35), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final FeatureItem feature;

  const FeatureCard({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            feature.color.withOpacity(0.2),
            feature.color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: feature.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(feature.icon, color: feature.color, size: 32),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: feature.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  feature.status,
                  style: TextStyle(
                    color: feature.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feature.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feature.description,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.4,
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
  final Color color;

  FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.color,
  });
}