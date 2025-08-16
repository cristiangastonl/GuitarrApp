import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/spotify_smart_recommendations_service.dart';
import '../../core/services/audio_player_service.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'glass_card.dart';

class SmartRecommendationsWidget extends ConsumerWidget {
  final String userId;
  final VoidCallback? onRefresh;
  
  const SmartRecommendationsWidget({
    super.key,
    required this.userId,
    this.onRefresh,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(personalizedRecommendationsProvider(userId));
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref),
          const SizedBox(height: 16),
          recommendationsAsync.when(
            data: (recommendations) => _buildRecommendationsList(context, ref, recommendations),
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildErrorState(context, error),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome,
          color: GuitarrColors.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Recommendations',
                style: GuitarrTypography.headlineSmall.copyWith(
                  color: GuitarrColors.textPrimary,
                ),
              ),
              Text(
                'AI-powered song suggestions based on your progress',
                style: GuitarrTypography.bodySmall.copyWith(
                  color: GuitarrColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            ref.invalidate(personalizedRecommendationsProvider(userId));
            onRefresh?.call();
          },
          icon: Icon(
            Icons.refresh,
            color: GuitarrColors.secondary,
            size: 20,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecommendationsList(
    BuildContext context,
    WidgetRef ref,
    List<SpotifyRecommendation> recommendations,
  ) {
    if (recommendations.isEmpty) {
      return _buildEmptyState();
    }
    
    return Column(
      children: [
        ...recommendations.take(5).map((rec) => _buildRecommendationCard(context, ref, rec)),
        if (recommendations.length > 5) _buildShowMoreButton(context),
      ],
    );
  }
  
  Widget _buildRecommendationCard(
    BuildContext context,
    WidgetRef ref,
    SpotifyRecommendation recommendation,
  ) {
    final audioPlayerService = ref.watch(audioPlayerServiceProvider.notifier);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        blurIntensity: 5,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAlbumArt(recommendation.track.albumImageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrackInfo(recommendation),
              ),
              _buildControls(context, ref, recommendation, audioPlayerService),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAlbumArt(String? imageUrl) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GuitarrColors.primary.withOpacity(0.3),
            GuitarrColors.secondary.withOpacity(0.3),
          ],
        ),
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultAlbumArt(),
              ),
            )
          : _buildDefaultAlbumArt(),
    );
  }
  
  Widget _buildDefaultAlbumArt() {
    return Icon(
      Icons.music_note,
      color: GuitarrColors.textSecondary,
      size: 30,
    );
  }
  
  Widget _buildTrackInfo(SpotifyRecommendation recommendation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recommendation.track.name,
          style: GuitarrTypography.bodyLarge.copyWith(
            color: GuitarrColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          recommendation.track.artist,
          style: GuitarrTypography.bodyMedium.copyWith(
            color: GuitarrColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        _buildRecommendationDetails(recommendation),
      ],
    );
  }
  
  Widget _buildRecommendationDetails(SpotifyRecommendation recommendation) {
    return Row(
      children: [
        _buildScoreBadge('Match', recommendation.relevanceScore),
        const SizedBox(width: 8),
        _buildTypeBadge(recommendation.recommendationType),
        const SizedBox(width: 8),
        if (recommendation.track.hasPreview)
          Icon(
            Icons.preview,
            size: 16,
            color: GuitarrColors.success,
          ),
      ],
    );
  }
  
  Widget _buildScoreBadge(String label, double score) {
    final color = score >= 80 
        ? GuitarrColors.success 
        : score >= 60 
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
        '${score.toInt()}%',
        style: GuitarrTypography.bodySmall.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }
  
  Widget _buildTypeBadge(RecommendationType type) {
    String label;
    Color color;
    
    switch (type) {
      case RecommendationType.skillMatch:
        label = 'Skill Match';
        color = GuitarrColors.primary;
        break;
      case RecommendationType.genrePreference:
        label = 'Genre';
        color = GuitarrColors.secondary;
        break;
      case RecommendationType.techniqueImprovement:
        label = 'Technique';
        color = GuitarrColors.accent;
        break;
      case RecommendationType.progressionChallenge:
        label = 'Challenge';
        color = GuitarrColors.warning;
        break;
      case RecommendationType.similar:
        label = 'Similar';
        color = GuitarrColors.info;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GuitarrTypography.bodySmall.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }
  
  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    SpotifyRecommendation recommendation,
    AudioPlayerService audioPlayerService,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (recommendation.track.hasPreview)
          _buildPlayButton(context, ref, recommendation, audioPlayerService),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _openSpotifyTrack(recommendation.track.spotifyUrl),
          icon: Icon(
            Icons.open_in_new,
            color: GuitarrColors.secondary,
            size: 20,
          ),
          tooltip: 'Open in Spotify',
        ),
        IconButton(
          onPressed: () => _showRecommendationDetails(context, recommendation),
          icon: Icon(
            Icons.info_outline,
            color: GuitarrColors.textSecondary,
            size: 20,
          ),
          tooltip: 'Details',
        ),
      ],
    );
  }
  
  Widget _buildPlayButton(
    BuildContext context,
    WidgetRef ref,
    SpotifyRecommendation recommendation,
    AudioPlayerService audioPlayer,
  ) {
    return StreamBuilder<bool>(
      stream: audioPlayer.isPlayingStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        final currentUrl = audioPlayer.currentUrl;
        final isThisTrack = currentUrl == recommendation.track.previewUrl;
        
        return IconButton(
          onPressed: () => _togglePlayback(audioPlayer, recommendation.track.previewUrl!),
          icon: Icon(
            (isPlaying && isThisTrack) ? Icons.pause : Icons.play_arrow,
            color: GuitarrColors.primary,
            size: 24,
          ),
          tooltip: isPlaying && isThisTrack ? 'Pause' : 'Play Preview',
        );
      },
    );
  }
  
  Widget _buildLoadingButton() {
    return SizedBox(
      width: 24,
      height: 24,
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
      size: 24,
    );
  }
  
  Widget _buildLoadingState() {
    return Column(
      children: List.generate(3, (index) => _buildSkeletonCard()),
    );
  }
  
  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        blurIntensity: 5,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: GuitarrColors.textSecondary.withOpacity(0.2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: GuitarrColors.textSecondary.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: GuitarrColors.textSecondary.withOpacity(0.2),
                      ),
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
  
  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: GuitarrColors.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load recommendations',
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
            onPressed: onRefresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.music_off,
            color: GuitarrColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No recommendations yet',
            style: GuitarrTypography.bodyLarge.copyWith(
              color: GuitarrColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Practice more to get personalized song suggestions',
            style: GuitarrTypography.bodySmall.copyWith(
              color: GuitarrColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildShowMoreButton(BuildContext context) {
    return TextButton(
      onPressed: () => _showAllRecommendations(context),
      child: Text(
        'Show More Recommendations',
        style: GuitarrTypography.bodyMedium.copyWith(
          color: GuitarrColors.primary,
        ),
      ),
    );
  }
  
  // Actions
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
  
  void _showRecommendationDetails(BuildContext context, SpotifyRecommendation recommendation) {
    showDialog(
      context: context,
      builder: (context) => _RecommendationDetailsDialog(recommendation: recommendation),
    );
  }
  
  void _showAllRecommendations(BuildContext context) {
    // Navigate to full recommendations screen
  }
}

class _RecommendationDetailsDialog extends StatelessWidget {
  final SpotifyRecommendation recommendation;
  
  const _RecommendationDetailsDialog({required this.recommendation});
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: GuitarrColors.cardBackground,
      title: Text(
        'Recommendation Details',
        style: GuitarrTypography.headlineSmall.copyWith(
          color: GuitarrColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recommendation.track.name,
            style: GuitarrTypography.bodyLarge.copyWith(
              color: GuitarrColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'by ${recommendation.track.artist}',
            style: GuitarrTypography.bodyMedium.copyWith(
              color: GuitarrColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Why this song?',
            style: GuitarrTypography.bodyMedium.copyWith(
              color: GuitarrColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.reason,
            style: GuitarrTypography.bodyMedium.copyWith(
              color: GuitarrColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildScoreDetails(),
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
    );
  }
  
  Widget _buildScoreDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScoreRow('Relevance', recommendation.relevanceScore),
        _buildScoreRow('Difficulty Match', recommendation.difficultyMatch),
        _buildScoreRow('Genre Match', recommendation.genreMatch),
        _buildScoreRow('Technique Match', recommendation.techniqueMatch),
        _buildScoreRow('ML Score', recommendation.mlScore),
      ],
    );
  }
  
  Widget _buildScoreRow(String label, double score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GuitarrTypography.bodySmall.copyWith(
              color: GuitarrColors.textSecondary,
            ),
          ),
          Text(
            '${score.toInt()}%',
            style: GuitarrTypography.bodySmall.copyWith(
              color: GuitarrColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}