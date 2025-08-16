import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_providers.dart';
import '../widgets/progress_charts_advanced.dart';
import '../widgets/achievements_grid.dart';
import '../widgets/best_takes_showcase.dart';
import '../widgets/streak_display.dart';
import '../../../../core/services/achievements_service.dart';
import '../../../../core/models/session.dart';

class AdvancedHistoryScreen extends ConsumerStatefulWidget {
  const AdvancedHistoryScreen({super.key});

  @override
  ConsumerState<AdvancedHistoryScreen> createState() => _AdvancedHistoryScreenState();
}

class _AdvancedHistoryScreenState extends ConsumerState<AdvancedHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Tu Progreso',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: _buildHeaderStats(),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    refreshHistoryProviders(ref);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Datos actualizados'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.analytics), text: 'Resumen'),
                    Tab(icon: Icon(Icons.show_chart), text: 'Progreso'),
                    Tab(icon: Icon(Icons.emoji_events), text: 'Logros'),
                    Tab(icon: Icon(Icons.star), text: 'Mejores'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildProgressTab(),
            _buildAchievementsTab(),
            _buildBestTakesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Consumer(
      builder: (context, ref, child) {
        final userStatsAsync = ref.watch(userStatsProvider);
        
        return userStatsAsync.when(
          data: (stats) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildHeaderStatCard(
                    'Sesiones',
                    stats['totalSessions'].toString(),
                    'Total',
                    Icons.music_note,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHeaderStatCard(
                    'Mejor Score',
                    stats['bestScore'].toString(),
                    stats['bestSessionRiff'] != '' 
                        ? stats['bestSessionRiff'].toString().substring(0, 10) + '...'
                        : 'Practica más',
                    Icons.emoji_events,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHeaderStatCard(
                    'Tiempo Total',
                    '${stats['totalPracticeHours']}h',
                    'Practicado',
                    Icons.access_time,
                  ),
                ),
              ],
            ),
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildHeaderStatCard(String title, String value, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 8,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer(
      builder: (context, ref, child) {
        final userStatsAsync = ref.watch(userStatsProvider);
        final practiceDatesAsync = ref.watch(practiceDatesProvider);
        final weeklySummaryAsync = ref.watch(weeklySummaryProvider);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Streak Display
              practiceDatesAsync.when(
                data: (practiceDates) => userStatsAsync.when(
                  data: (stats) => StreakDisplay(
                    currentStreak: stats['currentStreak'] ?? 0,
                    longestStreak: stats['longestStreak'] ?? 0,
                    practiceDates: practiceDates,
                  ),
                  loading: () => const _LoadingCard(height: 300),
                  error: (error, stack) => _ErrorCard('Error al cargar racha: $error'),
                ),
                loading: () => const _LoadingCard(height: 300),
                error: (error, stack) => _ErrorCard('Error al cargar fechas: $error'),
              ),
              
              const SizedBox(height: 24),
              
              // Weekly Summary
              Text(
                'Resumen Semanal',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              weeklySummaryAsync.when(
                data: (summary) => _buildWeeklySummaryCard(summary),
                loading: () => const _LoadingCard(height: 150),
                error: (error, stack) => _ErrorCard('Error al cargar resumen: $error'),
              ),
              
              const SizedBox(height: 24),
              
              // Recent Achievements Preview
              Text(
                'Logros Recientes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Consumer(
                builder: (context, ref, child) {
                  final achievementsAsync = ref.watch(achievementsProvider);
                  
                  return achievementsAsync.when(
                    data: (achievements) {
                      final unlockedAchievements = achievements
                          .where((a) => a.isUnlocked)
                          .take(4)
                          .toList();
                      
                      if (unlockedAchievements.isEmpty) {
                        return _buildNoAchievementsCard();
                      }
                      
                      return _buildAchievementsPreview(unlockedAchievements);
                    },
                    loading: () => const _LoadingCard(height: 120),
                    error: (error, stack) => _ErrorCard('Error al cargar logros: $error'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressTab() {
    return Consumer(
      builder: (context, ref, child) {
        final historicalDataAsync = ref.watch(historicalDataProvider(30));
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              historicalDataAsync.when(
                data: (chartData) => ProgressChartsAdvanced(
                  chartData: chartData,
                  chartType: 'score',
                ),
                loading: () => const _LoadingCard(height: 400),
                error: (error, stack) => _ErrorCard('Error al cargar datos: $error'),
              ),
              
              const SizedBox(height: 24),
              
              // Monthly summary
              Consumer(
                builder: (context, ref, child) {
                  final monthlySummaryAsync = ref.watch(monthlySummaryProvider);
                  
                  return monthlySummaryAsync.when(
                    data: (summary) => _buildMonthlySummaryCard(summary),
                    loading: () => const _LoadingCard(height: 200),
                    error: (error, stack) => _ErrorCard('Error al cargar resumen mensual: $error'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final achievementsAsync = ref.watch(achievementsProvider);
        
        return achievementsAsync.when(
          data: (achievements) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AchievementsGrid(
              achievements: achievements,
              onAchievementTap: (achievement) {
                // Achievement tap handled by the grid itself
              },
            ),
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _ErrorCard('Error al cargar logros: $error'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBestTakesTab() {
    return Consumer(
      builder: (context, ref, child) {
        final bestSessionsAsync = ref.watch(bestSessionsProvider);
        
        return bestSessionsAsync.when(
          data: (bestSessions) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: BestTakesShowcase(
              bestSessions: bestSessions,
              onSessionTap: (session) {
                _showSessionDetails(session);
              },
            ),
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _ErrorCard('Error al cargar mejores takes: $error'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklySummaryCard(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Sesiones',
                  summary['sessionsCount'].toString(),
                  Icons.music_note,
                  Theme.of(context).primaryColor,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Tiempo',
                  '${summary['totalMinutes']}m',
                  Icons.access_time,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Score Promedio',
                  summary['averageScore'].toString(),
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          if (summary['improvement'] != 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: summary['improvement'] > 0
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    summary['improvement'] > 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: summary['improvement'] > 0
                        ? Colors.green
                        : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${summary['improvement'] > 0 ? '+' : ''}${summary['improvement']} puntos vs semana anterior',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: summary['improvement'] > 0
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Resumen del Mes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Sesiones',
                  summary['sessionsCount'].toString(),
                  Icons.music_note,
                  Theme.of(context).primaryColor,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Horas',
                  '${summary['totalPracticeHours']}h',
                  Icons.schedule,
                  Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Riffs Únicos',
                  summary['uniqueRiffs'].toString(),
                  Icons.library_music,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Mejor Score',
                  summary['bestScore'].toString(),
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAchievementsPreview(List<Achievement> achievements) {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).cardColor,
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${achievement.points} pts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoAchievementsCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 32,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Practica para desbloquear logros',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionDetails(Session session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(session.songRiffId),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Score Total', '${session.overallScore}/100'),
            _buildDetailRow('Timing', '${session.timingScore}/100'),
            _buildDetailRow('Consistencia', '${session.consistencyScore}/100'),
            _buildDetailRow('BPM Objetivo', '${session.targetBpm}'),
            _buildDetailRow('Duración', '${session.durationMinutes} minutos'),
            _buildDetailRow('Fecha', _formatDate(session.sessionDate)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Helper widgets
class _LoadingCard extends StatelessWidget {
  final double height;
  
  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  
  const _ErrorCard(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

// Sticky tab bar delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}