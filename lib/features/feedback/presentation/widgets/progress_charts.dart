import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/feedback_analysis_service.dart';
import '../../../../shared/widgets/glass_card.dart';
import 'dart:math' as math;

/// Widget that displays progress charts and trends
class ProgressCharts extends ConsumerWidget {
  final String riffId;
  final SessionAnalysis currentAnalysis;
  
  const ProgressCharts({
    super.key,
    required this.riffId,
    required this.currentAnalysis,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionHistory = ref.watch(sessionHistoryProvider(riffId));
    final recentSessions = sessionHistory.getRecentSessions(14); // Last 2 weeks
    
    return Column(
      children: [
        // BPM Progress Chart
        _BpmProgressChart(
          sessions: recentSessions,
          currentAnalysis: currentAnalysis,
        ),
        
        const SizedBox(height: 16),
        
        // Score Trend Chart
        _ScoreTrendChart(
          sessions: recentSessions,
          currentAnalysis: currentAnalysis,
        ),
        
        const SizedBox(height: 16),
        
        // Practice Stats Summary
        _PracticeStatsCard(
          sessionHistory: sessionHistory,
          currentAnalysis: currentAnalysis,
        ),
      ],
    );
  }
}

/// Chart showing BPM progression over time
class _BpmProgressChart extends StatelessWidget {
  final List<SessionAnalysis> sessions;
  final SessionAnalysis currentAnalysis;
  
  const _BpmProgressChart({
    required this.sessions,
    required this.currentAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.length < 2) {
      return _EmptyChartPlaceholder(
        title: 'Progreso de BPM',
        message: 'Practica más para ver tu progreso de tempo',
        icon: Icons.speed,
      );
    }
    
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Progreso de BPM',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${currentAnalysis.recordedBpm} BPM actual',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              height: 120,
              child: _BpmLineChart(
                sessions: sessions,
                targetBpm: currentAnalysis.targetBpm,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // BPM stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  label: 'Objetivo',
                  value: '${currentAnalysis.targetBpm}',
                  color: Colors.grey[600]!,
                ),
                _StatItem(
                  label: 'Promedio',
                  value: '${_calculateAverageBpm(sessions)}',
                  color: Theme.of(context).colorScheme.primary,
                ),
                _StatItem(
                  label: 'Mejor',
                  value: '${_getHighestBpm(sessions)}',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  int _calculateAverageBpm(List<SessionAnalysis> sessions) {
    if (sessions.isEmpty) return 0;
    final sum = sessions.map((s) => s.recordedBpm).reduce((a, b) => a + b);
    return (sum / sessions.length).round();
  }
  
  int _getHighestBpm(List<SessionAnalysis> sessions) {
    if (sessions.isEmpty) return 0;
    return sessions.map((s) => s.recordedBpm).reduce(math.max);
  }
}

/// Line chart for BPM progression
class _BpmLineChart extends StatelessWidget {
  final List<SessionAnalysis> sessions;
  final int targetBpm;
  
  const _BpmLineChart({
    required this.sessions,
    required this.targetBpm,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BpmChartPainter(
        sessions: sessions,
        targetBpm: targetBpm,
        primaryColor: Theme.of(context).colorScheme.primary,
        targetColor: Colors.grey[400]!,
      ),
      size: const Size(double.infinity, 120),
    );
  }
}

/// Custom painter for BPM chart
class _BpmChartPainter extends CustomPainter {
  final List<SessionAnalysis> sessions;
  final int targetBpm;
  final Color primaryColor;
  final Color targetColor;
  
  _BpmChartPainter({
    required this.sessions,
    required this.targetBpm,
    required this.primaryColor,
    required this.targetColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (sessions.length < 2) return;
    
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    
    final targetPaint = Paint()
      ..color = targetColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Calculate bounds
    final minBpm = sessions.map((s) => s.recordedBpm).reduce(math.min);
    final maxBpm = math.max(
      sessions.map((s) => s.recordedBpm).reduce(math.max),
      targetBpm,
    );
    final range = maxBpm - minBpm;
    final adjustedMin = minBpm - (range * 0.1);
    final adjustedMax = maxBpm + (range * 0.1);
    final adjustedRange = adjustedMax - adjustedMin;
    
    // Draw target line
    final targetY = size.height - ((targetBpm - adjustedMin) / adjustedRange * size.height);
    canvas.drawLine(
      Offset(0, targetY),
      Offset(size.width, targetY),
      targetPaint,
    );
    
    // Draw BPM line
    final path = Path();
    final points = <Offset>[];
    
    for (int i = 0; i < sessions.length; i++) {
      final x = (i / (sessions.length - 1)) * size.width;
      final y = size.height - ((sessions[i].recordedBpm - adjustedMin) / adjustedRange * size.height);
      
      points.add(Offset(x, y));
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw dots at each point
    for (final point in points) {
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_BpmChartPainter oldDelegate) {
    return oldDelegate.sessions != sessions || oldDelegate.targetBpm != targetBpm;
  }
}

/// Chart showing overall score trends
class _ScoreTrendChart extends StatelessWidget {
  final List<SessionAnalysis> sessions;
  final SessionAnalysis currentAnalysis;
  
  const _ScoreTrendChart({
    required this.sessions,
    required this.currentAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.length < 2) {
      return _EmptyChartPlaceholder(
        title: 'Tendencia de Puntuación',
        message: 'Necesitas más sesiones para ver tendencias',
        icon: Icons.trending_up,
      );
    }
    
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tendencia de Puntuación',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTrendColor(sessions).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getTrendColor(sessions).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTrendIcon(sessions),
                        size: 16,
                        color: _getTrendColor(sessions),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTrendText(sessions),
                        style: TextStyle(
                          color: _getTrendColor(sessions),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              height: 100,
              child: _ScoreAreaChart(sessions: sessions),
            ),
            
            const SizedBox(height: 12),
            
            // Score improvement stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  label: 'Actual',
                  value: '${currentAnalysis.overallScore.round()}',
                  color: Theme.of(context).colorScheme.secondary,
                ),
                _StatItem(
                  label: 'Promedio',
                  value: '${_calculateAverageScore(sessions)}',
                  color: Theme.of(context).colorScheme.primary,
                ),
                _StatItem(
                  label: 'Mejor',
                  value: '${_getHighestScore(sessions)}',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getTrendColor(List<SessionAnalysis> sessions) {
    final improvement = _calculateScoreImprovement(sessions);
    if (improvement > 5) return Colors.green;
    if (improvement > 0) return Colors.orange;
    return Colors.red;
  }
  
  IconData _getTrendIcon(List<SessionAnalysis> sessions) {
    final improvement = _calculateScoreImprovement(sessions);
    if (improvement > 5) return Icons.trending_up;
    if (improvement > 0) return Icons.trending_flat;
    return Icons.trending_down;
  }
  
  String _getTrendText(List<SessionAnalysis> sessions) {
    final improvement = _calculateScoreImprovement(sessions);
    if (improvement > 5) return 'Mejorando';
    if (improvement > 0) return 'Estable';
    return 'Necesita trabajo';
  }
  
  double _calculateScoreImprovement(List<SessionAnalysis> sessions) {
    if (sessions.length < 4) return 0.0;
    
    final recent = sessions.take(sessions.length ~/ 2).toList();
    final older = sessions.skip(sessions.length ~/ 2).toList();
    
    final recentAvg = recent.map((s) => s.overallScore).reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.map((s) => s.overallScore).reduce((a, b) => a + b) / older.length;
    
    return recentAvg - olderAvg;
  }
  
  int _calculateAverageScore(List<SessionAnalysis> sessions) {
    if (sessions.isEmpty) return 0;
    final sum = sessions.map((s) => s.overallScore).reduce((a, b) => a + b);
    return (sum / sessions.length).round();
  }
  
  int _getHighestScore(List<SessionAnalysis> sessions) {
    if (sessions.isEmpty) return 0;
    return sessions.map((s) => s.overallScore).reduce(math.max).round();
  }
}

/// Area chart for score trends
class _ScoreAreaChart extends StatelessWidget {
  final List<SessionAnalysis> sessions;
  
  const _ScoreAreaChart({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScoreAreaPainter(
        sessions: sessions,
        primaryColor: Theme.of(context).colorScheme.secondary,
      ),
      size: const Size(double.infinity, 100),
    );
  }
}

/// Custom painter for score area chart
class _ScoreAreaPainter extends CustomPainter {
  final List<SessionAnalysis> sessions;
  final Color primaryColor;
  
  _ScoreAreaPainter({
    required this.sessions,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (sessions.length < 2) return;
    
    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final areaPaint = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    // Create paths
    final linePath = Path();
    final areaPath = Path();
    
    for (int i = 0; i < sessions.length; i++) {
      final x = (i / (sessions.length - 1)) * size.width;
      final y = size.height - (sessions[i].overallScore / 100 * size.height);
      
      if (i == 0) {
        linePath.moveTo(x, y);
        areaPath.moveTo(x, size.height);
        areaPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }
    
    // Close area path
    areaPath.lineTo(size.width, size.height);
    areaPath.close();
    
    // Draw area and line
    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(_ScoreAreaPainter oldDelegate) {
    return oldDelegate.sessions != sessions;
  }
}

/// Practice statistics summary card
class _PracticeStatsCard extends StatelessWidget {
  final SessionHistory sessionHistory;
  final SessionAnalysis currentAnalysis;
  
  const _PracticeStatsCard({
    required this.sessionHistory,
    required this.currentAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final streak = sessionHistory.practiceStreak;
    final totalSessions = sessionHistory.sessions.length;
    final recentSessions = sessionHistory.getRecentSessions(7);
    
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas de Práctica',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department,
                    label: 'Racha',
                    value: '$streak día${streak != 1 ? 's' : ''}',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.music_note,
                    label: 'Total',
                    value: '$totalSessions sesión${totalSessions != 1 ? 'es' : ''}',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.calendar_today,
                    label: 'Esta Semana',
                    value: '${recentSessions.length}',
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.timer,
                    label: 'Tiempo Total',
                    value: _formatTotalTime(sessionHistory.sessions),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTotalTime(List<SessionAnalysis> sessions) {
    final totalMinutes = sessions
        .map((s) => s.recordingDuration.inMinutes)
        .fold(0, (a, b) => a + b);
    
    if (totalMinutes < 60) {
      return '${totalMinutes}min';
    }
    
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    
    if (hours < 24) {
      return '${hours}h ${minutes}min';
    }
    
    final days = hours ~/ 24;
    final remainingHours = hours % 24;
    return '${days}d ${remainingHours}h';
  }
}

/// Individual stat card
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Stat item for inline display
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

/// Placeholder for empty charts
class _EmptyChartPlaceholder extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  
  const _EmptyChartPlaceholder({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}