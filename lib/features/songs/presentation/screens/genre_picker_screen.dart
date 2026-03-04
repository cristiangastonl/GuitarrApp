import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../core/data/songs_data.dart';
import '../../../../widgets/neon_text.dart';
import '../providers/song_game_provider.dart';
import 'song_list_screen.dart';

class GenrePickerScreen extends ConsumerWidget {
  const GenrePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ArcadeColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const NeonText(
                text: 'ELEGÍ TU ESTILO',
                fontSize: 28,
                color: ArcadeColors.neonPink,
                animate: true,
                blinkDuration: Duration(milliseconds: 2000),
              ),
              const SizedBox(height: 8),
              const Text(
                'Siempre podés cambiar después',
                style: TextStyle(
                  color: ArcadeColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Column(
                  children: [
                    _GenreCard(
                      genre: SongGenre.rock,
                      title: 'ROCK',
                      subtitle: 'Nirvana, Green Day, Bob Dylan',
                      icon: Icons.whatshot,
                      color: ArcadeColors.neonRed,
                      onTap: () => _selectGenre(context, ref, SongGenre.rock),
                    ),
                    const SizedBox(height: 16),
                    _GenreCard(
                      genre: SongGenre.pop,
                      title: 'POP',
                      subtitle: 'Vance Joy, Ben E. King, Passenger',
                      icon: Icons.music_note,
                      color: ArcadeColors.neonPink,
                      onTap: () => _selectGenre(context, ref, SongGenre.pop),
                    ),
                    const SizedBox(height: 16),
                    _GenreCard(
                      genre: SongGenre.blues,
                      title: 'BLUES',
                      subtitle: '12-Bar Blues, Elvis Presley',
                      icon: Icons.nightlife,
                      color: ArcadeColors.neonPurple,
                      onTap: () => _selectGenre(context, ref, SongGenre.blues),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectGenre(BuildContext context, WidgetRef ref, SongGenre genre) {
    ref.read(songProgressProvider.notifier).setPreferredGenre(genre.name);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SongListScreen(initialGenre: genre),
      ),
    );
  }
}

class _GenreCard extends StatelessWidget {
  final SongGenre genre;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GenreCard({
    required this.genre,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
            boxShadow: NeonEffects.glow(color, intensity: 0.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 48),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 4,
                  shadows: NeonEffects.textGlow(color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: ArcadeColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
