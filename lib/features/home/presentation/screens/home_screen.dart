import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/riff_glass_card.dart';
import '../../../../shared/widgets/smart_recommendations_widget.dart';
import '../../../../shared/widgets/spotify_playlist_widget.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/theme/colors.dart';
import '../../../spotify_test_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎸 GuitarrApp'),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.developer_mode),
              onPressed: () => Navigator.pushNamed(context, '/dev-tools'),
              tooltip: 'Herramientas de Desarrollo',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Bienvenido!',
                              style: GuitarrTypography.displaySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mejora tu técnica de guitarra con práctica inteligente',
                              style: GuitarrTypography.bodyLarge.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Smart Recommendations Section
            SmartRecommendationsWidget(
              userId: 'user_1', // TODO: Get from user session
              onRefresh: () {
                // Handle refresh if needed
              },
            ),
            
            const SizedBox(height: 24),
            
            // Spotify Test Section (Only in debug mode)
            if (kDebugMode) ...[
              SpotifyTestWidget(),
              const SizedBox(height: 24),
            ],
            
            // Spotify Integration Section
            SpotifyPlaylistWidget(),
            
            const SizedBox(height: 24),
            
            // Active Goals Section
            Text(
              'Metas Activas',
              style: GuitarrTypography.headlineMedium.copyWith(
                color: GuitarrColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Active Goals List
            Column(
              children: [
                  RiffGlassCard(
                    name: 'Enter Sandman - Main Riff',
                    artist: 'Metallica',
                    genre: 'metal',
                    difficulty: 'medium',
                    targetBpm: 116,
                    currentBpm: 108,
                    progress: 0.7,
                    techniques: ['palm-muting', 'alternate-picking', 'downstrokes'],
                    riffId: 'enter_sandman_main',
                    showAudioControls: true,
                    animationDelay: const Duration(milliseconds: 200),
                  ),
                  RiffGlassCard(
                    name: 'Paranoid - Riff Principal',
                    artist: 'Black Sabbath',
                    genre: 'rock',
                    difficulty: 'medium',
                    targetBpm: 164,
                    currentBpm: 140,
                    progress: 0.4,
                    techniques: ['alternate-picking', 'power-chords'],
                    riffId: 'paranoid_main',
                    showAudioControls: true,
                    animationDelay: const Duration(milliseconds: 400),
                  ),
                  RiffGlassCard(
                    name: 'Back in Black - Intro',
                    artist: 'AC/DC',
                    genre: 'rock',
                    difficulty: 'hard',
                    targetBpm: 93,
                    currentBpm: 88,
                    progress: 0.3,
                    techniques: ['ghost-notes', 'palm-muting', 'dynamics'],
                    riffId: 'back_in_black_intro',
                    showAudioControls: true,
                    animationDelay: const Duration(milliseconds: 600),
                  ),
                ],
            ),
            
            const SizedBox(height: 16),
            
            // Practice Now Button
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: _PracticeNowButton(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
}

class _PracticeNowButton extends StatefulWidget {
  @override
  _PracticeNowButtonState createState() => _PracticeNowButtonState();
}

class _PracticeNowButtonState extends State<_PracticeNowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
        // Navigate to practice screen
        // Will be implemented with proper navigation
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(_isPressed ? 0.4 : 0.3),
                    blurRadius: _isPressed ? 20 : 16,
                    offset: Offset(0, _isPressed ? 12 : 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: value * 2 * 3.14159,
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 28,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: GuitarrTypography.buttonPrimary.copyWith(
                            fontSize: _isPressed ? 17 : 18,
                            color: Colors.white,
                          ),
                          child: Text('Practicar Ahora'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}