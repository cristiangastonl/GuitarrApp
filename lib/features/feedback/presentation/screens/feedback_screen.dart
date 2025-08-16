import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/feedback_analysis_service.dart';
import '../../../../core/services/tips_engine_service.dart';
import '../../../../core/services/backing_track_service.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../widgets/score_visualization.dart';
import '../widgets/progress_charts.dart';
import '../widgets/tips_display.dart';

/// Screen that displays detailed feedback after a practice session
class FeedbackScreen extends ConsumerWidget {
  final SessionAnalysis analysis;
  final String riffId;
  
  const FeedbackScreen({
    super.key,
    required this.analysis,
    required this.riffId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backingTrack = ref.watch(backingTrackByIdProvider(riffId));
    final sessionHistory = ref.watch(sessionHistoryProvider(riffId));
    final overallStats = ref.watch(overallStatsProvider);
    
    // Create tip context for generating personalized recommendations
    final tipContext = TipContext(
      analysis: analysis,
      currentRiff: backingTrack,
      history: sessionHistory,
      overallStats: overallStats,
    );
    
    final tips = ref.watch(currentSessionTipsProvider(tipContext));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback de Sesión'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResults(context, analysis),
            tooltip: 'Compartir resultados',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Header
            _SessionHeader(
              analysis: analysis,
              riffName: backingTrack?.name ?? 'Riff Desconocido',
              artist: backingTrack?.artist ?? '',
            ),
            
            const SizedBox(height: 24),
            
            // Overall Score Visualization
            ScoreVisualization(analysis: analysis),
            
            const SizedBox(height: 24),
            
            // Detailed Score Breakdown
            _ScoreBreakdown(analysis: analysis),
            
            const SizedBox(height: 24),
            
            // Progress Charts
            ProgressCharts(
              riffId: riffId,
              currentAnalysis: analysis,
            ),
            
            const SizedBox(height: 24),
            
            // Tips and Recommendations
            TipsDisplay(tips: tips),
            
            const SizedBox(height: 24),
            
            // Session Details
            _SessionDetails(analysis: analysis),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            _ActionButtons(
              onPracticeAgain: () => _practiceAgain(context),
              onViewHistory: () => _viewHistory(context, riffId),
              onNextRiff: () => _suggestNextRiff(context, ref),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  void _shareResults(BuildContext context, SessionAnalysis analysis) {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de compartir próximamente disponible'),
      ),
    );
  }
  
  void _practiceAgain(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    // Navigate to practice screen
    // TODO: Implement navigation to practice with same riff
  }
  
  void _viewHistory(BuildContext context, String riffId) {
    // TODO: Navigate to detailed history view for this riff
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Historial detallado próximamente disponible'),
      ),
    );
  }
  
  void _suggestNextRiff(BuildContext context, WidgetRef ref) {
    // TODO: Implement riff recommendation based on current performance
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recomendaciones de riffs próximamente disponibles'),
      ),
    );
  }
}

/// Header section with session summary
class _SessionHeader extends StatelessWidget {
  final SessionAnalysis analysis;
  final String riffName;
  final String artist;
  
  const _SessionHeader({
    required this.analysis,
    required this.riffName,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
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
                        riffName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (artist.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          artist,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  analysis.performanceLevel.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Session metadata
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _MetadataChip(
                  icon: Icons.timer,
                  label: _formatDuration(analysis.recordingDuration),
                  color: Theme.of(context).colorScheme.primary,
                ),
                _MetadataChip(
                  icon: Icons.speed,
                  label: '${analysis.recordedBpm} BPM',
                  color: Theme.of(context).colorScheme.secondary,
                ),
                _MetadataChip(
                  icon: Icons.gps_fixed,
                  label: 'Meta: ${analysis.targetBpm} BPM',
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                _MetadataChip(
                  icon: Icons.calendar_today,
                  label: _formatDate(analysis.timestamp),
                  color: Theme.of(context).colorScheme.outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Small metadata chip widget
class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  
  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detailed score breakdown section
class _ScoreBreakdown extends StatelessWidget {
  final SessionAnalysis analysis;
  
  const _ScoreBreakdown({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Desglose de Puntuación',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _ScoreItem(
              label: 'Timing',
              score: analysis.timingScore,
              icon: Icons.timer,
              color: _getScoreColor(analysis.timingScore, context),
            ),
            
            const SizedBox(height: 12),
            
            _ScoreItem(
              label: 'Consistencia',
              score: analysis.consistencyScore,
              icon: Icons.trending_up,
              color: _getScoreColor(analysis.consistencyScore, context),
            ),
            
            const SizedBox(height: 12),
            
            _ScoreItem(
              label: 'Progreso',
              score: analysis.progressScore,
              icon: Icons.show_chart,
              color: _getScoreColor(analysis.progressScore, context),
            ),
            
            const SizedBox(height: 12),
            
            _ScoreItem(
              label: 'Frecuencia',
              score: analysis.frequencyScore,
              icon: Icons.event_repeat,
              color: _getScoreColor(analysis.frequencyScore, context),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getScoreColor(double score, BuildContext context) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

/// Individual score item widget
class _ScoreItem extends StatelessWidget {
  final String label;
  final double score;
  final IconData icon;
  final Color color;
  
  const _ScoreItem({
    required this.label,
    required this.score,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Container(
          width: 100,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (score / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '${score.round()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

/// Session details section
class _SessionDetails extends StatelessWidget {
  final SessionAnalysis analysis;
  
  const _SessionDetails({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles de la Sesión',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _DetailItem(
              label: 'Nivel de Performance',
              value: analysis.performanceLevel.displayName,
              icon: Icons.emoji_events,
            ),
            
            _DetailItem(
              label: 'Área Fuerte',
              value: analysis.strongestSkill.displayName,
              icon: Icons.star,
            ),
            
            _DetailItem(
              label: 'Área de Mejora',
              value: analysis.improvementArea.displayName,
              icon: Icons.trending_up,
            ),
            
            _DetailItem(
              label: 'Precisión de Tempo',
              value: '${(analysis.tempoAccuracy * 100).round()}%',
              icon: Icons.speed,
            ),
            
            _DetailItem(
              label: 'Sesiones esta Semana',
              value: '${analysis.practiceFrequency}',
              icon: Icons.calendar_today,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual detail item
class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  
  const _DetailItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action buttons section
class _ActionButtons extends StatelessWidget {
  final VoidCallback onPracticeAgain;
  final VoidCallback onViewHistory;
  final VoidCallback onNextRiff;
  
  const _ActionButtons({
    required this.onPracticeAgain,
    required this.onViewHistory,
    required this.onNextRiff,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary action - Practice Again
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onPracticeAgain,
            icon: const Icon(Icons.replay),
            label: const Text('Practicar de Nuevo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onViewHistory,
                icon: const Icon(Icons.history),
                label: const Text('Historial'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onNextRiff,
                icon: const Icon(Icons.skip_next),
                label: const Text('Siguiente'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}