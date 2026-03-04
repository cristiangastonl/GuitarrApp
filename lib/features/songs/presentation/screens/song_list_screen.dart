import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../core/data/songs_data.dart';
import '../../../../widgets/neon_text.dart';
import '../../../../widgets/arcade_button.dart';
import '../../../../widgets/score_display.dart';
import '../../../lessons/presentation/providers/game_provider.dart';
import '../providers/song_game_provider.dart';
import 'song_game_screen.dart';

class SongListScreen extends ConsumerStatefulWidget {
  final SongGenre? initialGenre;

  const SongListScreen({super.key, this.initialGenre});

  @override
  ConsumerState<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends ConsumerState<SongListScreen> {
  late SongGenre _selectedGenre;

  @override
  void initState() {
    super.initState();
    if (widget.initialGenre != null) {
      _selectedGenre = widget.initialGenre!;
    } else {
      // Try to restore from saved preference
      final saved = ref.read(songProgressProvider).preferredGenre;
      _selectedGenre = SongGenre.values.firstWhere(
        (g) => g.name == saved,
        orElse: () => SongGenre.rock,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final songProgress = ref.watch(songProgressProvider);
    final gameProgress = ref.watch(gameProgressProvider);
    final songs = SongsData.getSongsByGenre(_selectedGenre);

    return Scaffold(
      backgroundColor: ArcadeColors.background,
      appBar: AppBar(
        backgroundColor: ArcadeColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ArcadeColors.neonCyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const NeonText(
          text: 'CANCIONES',
          fontSize: 18,
          color: ArcadeColors.neonPink,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Genre tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _GenreTab(
                    label: 'ROCK',
                    color: ArcadeColors.neonRed,
                    isSelected: _selectedGenre == SongGenre.rock,
                    onTap: () => setState(() => _selectedGenre = SongGenre.rock),
                  ),
                  const SizedBox(width: 8),
                  _GenreTab(
                    label: 'POP',
                    color: ArcadeColors.neonPink,
                    isSelected: _selectedGenre == SongGenre.pop,
                    onTap: () => setState(() => _selectedGenre = SongGenre.pop),
                  ),
                  const SizedBox(width: 8),
                  _GenreTab(
                    label: 'BLUES',
                    color: ArcadeColors.neonPurple,
                    isSelected: _selectedGenre == SongGenre.blues,
                    onTap: () => setState(() => _selectedGenre = SongGenre.blues),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Song grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  final canPlay = SongsData.canPlaySong(
                    song,
                    gameProgress.levelStars,
                  );
                  final stars = songProgress.getStars(song.id);

                  return _SongCard(
                    song: song,
                    canPlay: canPlay,
                    stars: stars,
                    onTap: canPlay
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SongGameScreen(songId: song.id),
                              ),
                            );
                          }
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenreTab extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenreTab({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? NeonEffects.glow(color, intensity: 0.3)
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : color.withValues(alpha: 0.5),
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SongCard extends StatelessWidget {
  final SongData song;
  final bool canPlay;
  final int stars;
  final VoidCallback? onTap;

  const _SongCard({
    required this.song,
    required this.canPlay,
    required this.stars,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: canPlay
              ? ArcadeColors.backgroundLight
              : ArcadeColors.backgroundLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canPlay
                ? ArcadeColors.neonCyan.withValues(alpha: 0.4)
                : ArcadeColors.textMuted.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lock icon or difficulty
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Difficulty dots
                Row(
                  children: List.generate(
                    3,
                    (i) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < song.difficulty
                            ? ArcadeColors.neonOrange
                            : ArcadeColors.textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                if (!canPlay)
                  Icon(
                    Icons.lock,
                    color: ArcadeColors.textMuted,
                    size: 18,
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Title
            Text(
              song.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: canPlay
                    ? ArcadeColors.neonPink
                    : ArcadeColors.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // Artist
            Text(
              song.artist,
              style: TextStyle(
                fontSize: 11,
                color: canPlay
                    ? ArcadeColors.textSecondary
                    : ArcadeColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Chord badges
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: song.requiredChords.map((chord) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: canPlay
                        ? ArcadeColors.neonCyan.withValues(alpha: 0.15)
                        : ArcadeColors.textMuted.withValues(alpha: 0.1),
                    border: Border.all(
                      color: canPlay
                          ? ArcadeColors.neonCyan.withValues(alpha: 0.4)
                          : ArcadeColors.textMuted.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    chord,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: canPlay
                          ? ArcadeColors.neonCyan
                          : ArcadeColors.textMuted,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),

            // Stars
            if (stars > 0)
              StarRating(stars: stars, size: 18)
            else if (canPlay)
              Row(
                children: List.generate(
                  3,
                  (i) => const Icon(
                    Icons.star_border_rounded,
                    size: 18,
                    color: ArcadeColors.starEmpty,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
