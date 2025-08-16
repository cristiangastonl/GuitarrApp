import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/smart_recommendations_widget.dart';
import '../../../../shared/widgets/spotify_playlist_widget.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/theme/colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎸 GuitarrApp'),
      ),
      body: Padding(
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
            
            Expanded(
              child: ListView(
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
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Practice Now Button
            Container(
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    // Navigate to practice screen
                    // Will be implemented with proper navigation
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Practicar Ahora',
                          style: GuitarrTypography.buttonPrimary.copyWith(
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
}