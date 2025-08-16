import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/spotify_playlist_service.dart';
import '../../core/services/audio_player_service.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'glass_card.dart';

class SpotifyPlaylistWidget extends ConsumerStatefulWidget {
  const SpotifyPlaylistWidget({super.key});

  @override
  ConsumerState<SpotifyPlaylistWidget> createState() => _SpotifyPlaylistWidgetState();
}

class _SpotifyPlaylistWidgetState extends ConsumerState<SpotifyPlaylistWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTabBar(),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGuitarTracksTab(),
                _buildPlaylistsTab(),
                _buildSavedTracksTab(),
                _buildTopTracksTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1DB954), // Spotify green
                const Color(0xFF1DB954).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.library_music,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spotify Integration',
                style: GuitarrTypography.headlineSmall.copyWith(
                  color: GuitarrColors.textPrimary,
                ),
              ),
              Text(
                'Import your favorite tracks for guitar practice',
                style: GuitarrTypography.bodySmall.copyWith(
                  color: GuitarrColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _buildAuthButton(),
      ],
    );
  }

  Widget _buildAuthButton() {
    return FutureBuilder<bool>(
      future: ref.read(spotifyPlaylistServiceProvider).isAuthenticated(),
      builder: (context, snapshot) {
        final isAuthenticated = snapshot.data ?? false;
        
        if (isAuthenticated) {
          return IconButton(
            onPressed: () => _showAuthMenu(context),
            icon: Icon(
              Icons.account_circle,
              color: const Color(0xFF1DB954),
              size: 24,
            ),
          );
        } else {
          return ElevatedButton.icon(
            onPressed: () => _authenticateWithSpotify(),
            icon: const Icon(Icons.login, size: 16),
            label: const Text('Connect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: GuitarrTypography.bodySmall,
            ),
          );
        }
      },
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorColor: GuitarrColors.primary,
      labelColor: GuitarrColors.textPrimary,
      unselectedLabelColor: GuitarrColors.textSecondary,
      labelStyle: GuitarrTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelStyle: GuitarrTypography.bodySmall,
      tabs: const [
        Tab(text: 'Guitar Tracks'),
        Tab(text: 'Playlists'),
        Tab(text: 'Saved'),
        Tab(text: 'Top Tracks'),
      ],
    );
  }

  Widget _buildGuitarTracksTab() {
    final guitarTracksAsync = ref.watch(guitarTracksProvider);
    
    return guitarTracksAsync.when(
      data: (tracks) => _buildTrackList(tracks, showGuitarScore: true),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState('Failed to load guitar tracks', error),
    );
  }

  Widget _buildPlaylistsTab() {
    final playlistsAsync = ref.watch(userPlaylistsProvider);
    
    return playlistsAsync.when(
      data: (playlists) => _buildPlaylistList(playlists),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState('Failed to load playlists', error),
    );
  }

  Widget _buildSavedTracksTab() {
    final savedTracksAsync = ref.watch(userSavedTracksProvider);
    
    return savedTracksAsync.when(
      data: (tracks) => _buildTrackList(tracks),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState('Failed to load saved tracks', error),
    );
  }

  Widget _buildTopTracksTab() {
    final topTracksAsync = ref.watch(userTopTracksProvider);
    
    return topTracksAsync.when(
      data: (tracks) => _buildTrackList(tracks),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState('Failed to load top tracks', error),
    );
  }

  Widget _buildPlaylistList(List<SpotifyPlaylist> playlists) {
    if (playlists.isEmpty) {
      return _buildEmptyState('No playlists found');
    }

    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return _buildPlaylistCard(playlist);
      },
    );
  }

  Widget _buildPlaylistCard(SpotifyPlaylist playlist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        blurIntensity: 3,
        child: ListTile(
          leading: _buildPlaylistImage(playlist.imageUrl),
          title: Text(
            playlist.name,
            style: GuitarrTypography.bodyMedium.copyWith(
              color: GuitarrColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${playlist.trackCount} tracks • ${playlist.ownerName}',
            style: GuitarrTypography.bodySmall.copyWith(
              color: GuitarrColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            onPressed: () => _showPlaylistTracks(playlist),
            icon: Icon(
              Icons.arrow_forward_ios,
              color: GuitarrColors.secondary,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistImage(String? imageUrl) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          colors: [
            GuitarrColors.primary.withOpacity(0.3),
            GuitarrColors.secondary.withOpacity(0.3),
          ],
        ),
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultPlaylistIcon(),
              ),
            )
          : _buildDefaultPlaylistIcon(),
    );
  }

  Widget _buildDefaultPlaylistIcon() {
    return Icon(
      Icons.playlist_play,
      color: GuitarrColors.textSecondary,
      size: 24,
    );
  }

  Widget _buildTrackList(List<SpotifyPlaylistTrack> tracks, {bool showGuitarScore = false}) {
    if (tracks.isEmpty) {
      return _buildEmptyState('No tracks found');
    }

    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return _buildTrackCard(track, showGuitarScore: showGuitarScore);
      },
    );
  }

  Widget _buildTrackCard(SpotifyPlaylistTrack track, {bool showGuitarScore = false}) {
    final audioPlayerService = ref.watch(audioPlayerServiceProvider.notifier);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        blurIntensity: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildTrackImage(track.albumImageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrackInfo(track, showGuitarScore: showGuitarScore),
              ),
              _buildTrackControls(track, audioPlayerService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackImage(String? imageUrl) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          colors: [
            GuitarrColors.primary.withOpacity(0.3),
            GuitarrColors.secondary.withOpacity(0.3),
          ],
        ),
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.music_note,
                  color: GuitarrColors.textSecondary,
                  size: 20,
                ),
              ),
            )
          : Icon(
              Icons.music_note,
              color: GuitarrColors.textSecondary,
              size: 20,
            ),
    );
  }

  Widget _buildTrackInfo(SpotifyPlaylistTrack track, {bool showGuitarScore = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          track.track,
          style: GuitarrTypography.bodyMedium.copyWith(
            color: GuitarrColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          track.artist,
          style: GuitarrTypography.bodySmall.copyWith(
            color: GuitarrColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (showGuitarScore && track.guitarScore > 0)
          const SizedBox(height: 4),
        if (showGuitarScore && track.guitarScore > 0)
          _buildGuitarScoreBadge(track.guitarScore),
      ],
    );
  }

  Widget _buildGuitarScoreBadge(double score) {
    final color = score >= 0.8 
        ? GuitarrColors.success 
        : score >= 0.6 
            ? GuitarrColors.warning 
            : GuitarrColors.error;
            
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        'Guitar: ${(score * 100).toInt()}%',
        style: GuitarrTypography.bodySmall.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildTrackControls(SpotifyPlaylistTrack track, AudioPlayerService audioPlayerService) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (track.hasPreview)
          _buildPlayButton(track, audioPlayerService),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _openSpotifyTrack(track.spotifyUrl),
          icon: Icon(
            Icons.open_in_new,
            color: GuitarrColors.secondary,
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton(SpotifyPlaylistTrack track, AudioPlayerService audioPlayer) {
    return StreamBuilder<bool>(
      stream: audioPlayer.isPlayingStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        final currentUrl = audioPlayer.currentUrl;
        final isThisTrack = currentUrl == track.previewUrl;
        
        return IconButton(
          onPressed: () => _togglePlayback(audioPlayer, track.previewUrl!),
          icon: Icon(
            (isPlaying && isThisTrack) ? Icons.pause : Icons.play_arrow,
            color: GuitarrColors.primary,
            size: 20,
          ),
        );
      },
    );
  }

  Widget _buildLoadingButton() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(GuitarrColors.primary),
      ),
    );
  }

  Widget _buildErrorButton() {
    return Icon(
      Icons.error_outline,
      color: GuitarrColors.error,
      size: 20,
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String title, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: GuitarrColors.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GuitarrTypography.bodyLarge.copyWith(
              color: GuitarrColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: GuitarrTypography.bodySmall.copyWith(
              color: GuitarrColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _refreshCurrentTab(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off,
            color: GuitarrColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GuitarrTypography.bodyLarge.copyWith(
              color: GuitarrColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Actions
  Future<void> _authenticateWithSpotify() async {
    try {
      final service = ref.read(spotifyPlaylistServiceProvider);
      final authUrl = await service.generateAuthUrl();
      
      if (authUrl != null) {
        // In a real app, you would launch the URL and handle the redirect
        // For now, we'll show a dialog with the URL
        _showAuthUrlDialog(authUrl);
      } else {
        _showErrorDialog('Configuration Error', 'Spotify is not configured. Running in demo mode.');
      }
    } catch (e) {
      _showErrorDialog('Authentication Error', e.toString());
    }
  }

  void _showAuthUrlDialog(String authUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GuitarrColors.cardBackground,
        title: Text(
          'Spotify Authentication',
          style: GuitarrTypography.headlineSmall.copyWith(
            color: GuitarrColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To import your Spotify playlists, you need to authenticate with Spotify.',
              style: GuitarrTypography.bodyMedium.copyWith(
                color: GuitarrColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Auth URL:',
              style: GuitarrTypography.bodySmall.copyWith(
                color: GuitarrColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              authUrl,
              style: GuitarrTypography.bodySmall.copyWith(
                color: GuitarrColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: GuitarrColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GuitarrColors.cardBackground,
        title: Text(
          title,
          style: GuitarrTypography.headlineSmall.copyWith(
            color: GuitarrColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: GuitarrTypography.bodyMedium.copyWith(
            color: GuitarrColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: GuitarrColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showAuthMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GuitarrColors.cardBackground,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.logout, color: GuitarrColors.error),
              title: Text(
                'Disconnect Spotify',
                style: GuitarrTypography.bodyMedium.copyWith(
                  color: GuitarrColors.textPrimary,
                ),
              ),
              onTap: () async {
                await ref.read(spotifyPlaylistServiceProvider).logout();
                Navigator.of(context).pop();
                setState(() {}); // Refresh the auth button
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaylistTracks(SpotifyPlaylist playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PlaylistTracksScreen(playlist: playlist),
      ),
    );
  }

  Future<void> _togglePlayback(AudioPlayerService audioPlayer, String url) async {
    try {
      if (audioPlayer.currentUrl == url && await audioPlayer.isPlaying) {
        await audioPlayer.pause();
      } else {
        await audioPlayer.playFromUrl(url);
      }
    } catch (e) {
      // Handle playback error
    }
  }

  void _openSpotifyTrack(String spotifyUrl) {
    // Implementation for opening Spotify URL
    // This would typically use url_launcher package
  }

  void _refreshCurrentTab() {
    final currentIndex = _tabController.index;
    switch (currentIndex) {
      case 0:
        ref.invalidate(guitarTracksProvider);
        break;
      case 1:
        ref.invalidate(userPlaylistsProvider);
        break;
      case 2:
        ref.invalidate(userSavedTracksProvider);
        break;
      case 3:
        ref.invalidate(userTopTracksProvider);
        break;
    }
  }
}

class _PlaylistTracksScreen extends ConsumerWidget {
  final SpotifyPlaylist playlist;

  const _PlaylistTracksScreen({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(playlistTracksProvider(playlist.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        backgroundColor: GuitarrColors.cardBackground,
      ),
      backgroundColor: GuitarrColors.background,
      body: tracksAsync.when(
        data: (tracks) => ListView.builder(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                blurIntensity: 3,
                child: ListTile(
                  leading: track.albumImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            track.albumImageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.music_note,
                          color: GuitarrColors.textSecondary,
                        ),
                  title: Text(
                    track.track,
                    style: GuitarrTypography.bodyMedium.copyWith(
                      color: GuitarrColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    track.artist,
                    style: GuitarrTypography.bodySmall.copyWith(
                      color: GuitarrColors.textSecondary,
                    ),
                  ),
                  trailing: track.hasPreview
                      ? Icon(
                          Icons.play_arrow,
                          color: GuitarrColors.primary,
                        )
                      : null,
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Failed to load tracks: $error',
            style: GuitarrTypography.bodyMedium.copyWith(
              color: GuitarrColors.error,
            ),
          ),
        ),
      ),
    );
  }
}