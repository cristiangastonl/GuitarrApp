import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/advanced_analytics_service.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'glass_card.dart';
import 'analytics_chart_widget.dart';

class AdvancedAnalyticsWidget extends ConsumerStatefulWidget {
  final String userId;
  
  const AdvancedAnalyticsWidget({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<AdvancedAnalyticsWidget> createState() => _AdvancedAnalyticsWidgetState();
}

class _AdvancedAnalyticsWidgetState extends ConsumerState<AdvancedAnalyticsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateRange _selectedDateRange = DateRange.lastMonth();
  ChartTimeframe _selectedTimeframe = ChartTimeframe.weekly;
  
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
          _buildDateRangeSelector(),
          const SizedBox(height: 16),
          _buildTabBar(),
          const SizedBox(height: 16),
          SizedBox(
            height: 500,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildProgressTab(),
                _buildInsightsTab(),
                _buildComparisonTab(),
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
                GuitarrColors.accent,
                GuitarrColors.accent.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.analytics,
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
                'Advanced Analytics',
                style: GuitarrTypography.headlineSmall.copyWith(
                  color: GuitarrColors.textPrimary,
                ),
              ),
              Text(
                'Deep insights into your practice journey',
                style: GuitarrTypography.bodySmall.copyWith(
                  color: GuitarrColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _showAnalyticsInfo(),
          icon: Icon(
            Icons.help_outline,
            color: GuitarrColors.textSecondary,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Row(
      children: [
        Text(
          'Time Range:',
          style: GuitarrTypography.bodySmall.copyWith(
            color: GuitarrColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateRangeChip('Last Week', DateRange.lastWeek()),
                const SizedBox(width: 8),
                _buildDateRangeChip('Last Month', DateRange.lastMonth()),
                const SizedBox(width: 8),
                _buildDateRangeChip('Last Quarter', DateRange.lastQuarter()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeChip(String label, DateRange range) {
    final isSelected = _selectedDateRange.start == range.start && 
                     _selectedDateRange.end == range.end;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedDateRange = range;
          });
        }
      },
      selectedColor: GuitarrColors.primary.withOpacity(0.3),
      backgroundColor: GuitarrColors.cardBackground,
      labelStyle: GuitarrTypography.bodySmall.copyWith(
        color: isSelected ? GuitarrColors.primary : GuitarrColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
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
        Tab(text: 'Overview'),
        Tab(text: 'Progress'),
        Tab(text: 'Insights'),
        Tab(text: 'Compare'),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final dashboardAsync = ref.watch(analyticsDashboardProvider(widget.userId));
    
    return dashboardAsync.when(
      data: (dashboard) => SingleChildScrollView(
        child: Column(
          children: [
            _buildOverallStatsCards(dashboard.overallStats),
            const SizedBox(height: 16),
            _buildSkillBreakdownChart(dashboard.skillBreakdown),
            const SizedBox(height: 16),
            _buildPracticePatterns(dashboard.practicePatterns),
          ],
        ),
      ),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState('Failed to load dashboard', error),
    );
  }

  Widget _buildProgressTab() {
    final chartsRequest = ProgressChartsRequest(
      userId: widget.userId,
      dateRange: _selectedDateRange,
      timeframe: _selectedTimeframe,
    );
    
    final chartsAsync = ref.watch(progressChartsProvider(chartsRequest));
    
    return chartsAsync.when(
      data: (charts) => SingleChildScrollView(
        child: Column(
          children: [
            _buildTimeframeSelector(),
            const SizedBox(height: 16),
            _buildScoreProgressChart(charts.scoreOverTime),
            const SizedBox(height: 16),
            _buildBpmProgressChart(charts.bpmProgress),
            const SizedBox(height: 16),
            _buildPracticeTimeChart(charts.practiceTimeDistribution),
            const SizedBox(height: 16),
            _buildTechniqueProgressChart(charts.techniqueProgress),
          ],
        ),
      ),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState('Failed to load charts', error),
    );
  }

  Widget _buildInsightsTab() {
    final insightsAsync = ref.watch(practiceInsightsProvider(widget.userId));
    final predictionAsync = ref.watch(performancePredictionProvider(widget.userId));
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Performance Prediction Card
          predictionAsync.when(
            data: (prediction) => _buildPredictionCard(prediction),
            loading: () => _buildLoadingCard(),
            error: (error, stack) => _buildErrorCard('Prediction Error', error),
          ),
          const SizedBox(height: 16),
          // Practice Insights
          insightsAsync.when(
            data: (insights) => _buildInsightsList(insights),
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildErrorState('Failed to load insights', error),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildPersonalBestsCard(),
          const SizedBox(height: 16),
          _buildCommunityComparisonCard(),
          const SizedBox(height: 16),
          _buildGoalProgressCard(),
        ],
      ),
    );
  }

  Widget _buildOverallStatsCards(OverallStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Sessions', stats.totalSessions.toString(), Icons.assignment)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Practice Hours', '${stats.totalPracticeHours}h', Icons.schedule)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Average Score', '${stats.averageScore.toInt()}%', Icons.trending_up)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Current Streak', '${stats.currentStreak} days', Icons.local_fire_department)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Avg Accuracy', '${(stats.averageAccuracy * 100).toInt()}%', Icons.target)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Avg BPM', '${stats.averageBpm}', Icons.speed)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return GlassCard(
      blurIntensity: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: GuitarrColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GuitarrTypography.bodySmall.copyWith(
                    color: GuitarrColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GuitarrTypography.headlineMedium.copyWith(
                color: GuitarrColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillBreakdownChart(SkillBreakdown breakdown) {
    return GlassCard(
      blurIntensity: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skill Breakdown',
              style: GuitarrTypography.bodyLarge.copyWith(
                color: GuitarrColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...breakdown.skillLevels.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSkillBar(
                  entry.key.capitalize(),
                  entry.value,
                  breakdown.skillTrends[entry.key] ?? 0.0,
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSkillHighlight(
                    'Top Skill',
                    breakdown.topSkill.capitalize(),
                    GuitarrColors.success,
                    Icons.star,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSkillHighlight(
                    'Focus Area',
                    breakdown.improvementArea.capitalize(),
                    GuitarrColors.warning,
                    Icons.fitness_center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillBar(String skillName, double level, double trend) {
    final trendColor = trend > 0 ? GuitarrColors.success : 
                     trend < 0 ? GuitarrColors.error : GuitarrColors.textSecondary;
    final trendIcon = trend > 0 ? Icons.trending_up : 
                     trend < 0 ? Icons.trending_down : Icons.trending_flat;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              skillName,
              style: GuitarrTypography.bodyMedium.copyWith(
                color: GuitarrColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Icon(
                  trendIcon,
                  color: trendColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${level.toInt()}%',
                  style: GuitarrTypography.bodySmall.copyWith(
                    color: GuitarrColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: level / 100,
          backgroundColor: GuitarrColors.textSecondary.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            _getSkillColor(level),
          ),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildSkillHighlight(String title, String skill, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GuitarrTypography.bodySmall.copyWith(
              color: GuitarrColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            skill,
            style: GuitarrTypography.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPracticePatterns(PracticePatterns patterns) {
    return GlassCard(
      blurIntensity: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Practice Patterns',
              style: GuitarrTypography.bodyLarge.copyWith(
                color: GuitarrColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPatternCard(
                    'Typical Duration',
                    '${patterns.typicalDuration} min',
                    Icons.timer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPatternCard(
                    'Sessions/Week',
                    patterns.sessionsPerWeek.toStringAsFixed(1),
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPatternCard(
              'Consistency Score',
              '${patterns.consistency.toInt()}%',
              Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GuitarrColors.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuitarrColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: GuitarrColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GuitarrTypography.bodySmall.copyWith(
                    color: GuitarrColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: GuitarrTypography.bodyLarge.copyWith(
                    color: GuitarrColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Row(
      children: [
        Text(
          'Timeframe:',
          style: GuitarrTypography.bodySmall.copyWith(
            color: GuitarrColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: ChartTimeframe.values.map((timeframe) {
              final isSelected = _selectedTimeframe == timeframe;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(timeframe.name.capitalize()),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTimeframe = timeframe;
                      });
                    }
                  },
                  selectedColor: GuitarrColors.primary.withOpacity(0.3),
                  backgroundColor: GuitarrColors.cardBackground,
                  labelStyle: GuitarrTypography.bodySmall.copyWith(
                    color: isSelected ? GuitarrColors.primary : GuitarrColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreProgressChart(List<ChartDataPoint> data) {
    return _buildChartCard(
      'Score Progress',
      AnalyticsChartWidget(
        data: data,
        title: 'Overall Score Over Time',
        yAxisLabel: 'Score (%)',
        color: GuitarrColors.primary,
        chartType: ChartType.line,
      ),
    );
  }

  Widget _buildBpmProgressChart(List<ChartDataPoint> data) {
    return _buildChartCard(
      'BPM Progress',
      AnalyticsChartWidget(
        data: data,
        title: 'BPM Progress Over Time',
        yAxisLabel: 'BPM',
        color: GuitarrColors.secondary,
        chartType: ChartType.line,
      ),
    );
  }

  Widget _buildPracticeTimeChart(List<ChartDataPoint> data) {
    return _buildChartCard(
      'Practice Time',
      AnalyticsChartWidget(
        data: data,
        title: 'Practice Time Distribution',
        yAxisLabel: 'Minutes',
        color: GuitarrColors.accent,
        chartType: ChartType.bar,
      ),
    );
  }

  Widget _buildTechniqueProgressChart(Map<String, List<ChartDataPoint>> data) {
    return GlassCard(
      blurIntensity: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Technique Progress',
              style: GuitarrTypography.bodyLarge.copyWith(
                color: GuitarrColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: AnalyticsChartWidget(
                multiSeriesData: data,
                title: 'Technique Skills Over Time',
                yAxisLabel: 'Skill Level (%)',
                chartType: ChartType.multiLine,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return GlassCard(
      blurIntensity: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GuitarrTypography.bodyLarge.copyWith(
                color: GuitarrColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(PerformancePrediction prediction) {
    return GlassCard(
      blurIntensity: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: GuitarrColors.accent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Performance Prediction',
                  style: GuitarrTypography.bodyLarge.copyWith(
                    color: GuitarrColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPredictionMetric(
                    'Current Score',
                    '${prediction.currentScore.toInt()}%',
                    GuitarrColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPredictionMetric(
                    'Predicted Score',
                    '${prediction.predictedScore.toInt()}%',
                    _getTrendColor(prediction.trend),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPredictionMetric(
                    'Confidence',
                    '${(prediction.confidence * 100).toInt()}%',
                    GuitarrColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPredictionMetric(
                    'Next Level',
                    '${prediction.timeToNextLevel.inDays}d',
                    GuitarrColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionMetric(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GuitarrTypography.bodySmall.copyWith(
              color: GuitarrColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GuitarrTypography.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsList(List<PracticeInsight> insights) {
    if (insights.isEmpty) {
      return _buildEmptyInsightsState();
    }
    
    return Column(
      children: insights.map((insight) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildInsightCard(insight),
      )).toList(),
    );
  }

  Widget _buildInsightCard(PracticeInsight insight) {
    final color = _getInsightColor(insight.type);
    final icon = _getInsightIcon(insight.type);
    
    return GlassCard(
      blurIntensity: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: GuitarrTypography.bodyMedium.copyWith(
                          color: GuitarrColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        insight.description,
                        style: GuitarrTypography.bodySmall.copyWith(
                          color: GuitarrColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPriorityBadge(insight.priority),
              ],
            ),
            if (insight.actionable && insight.action != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _performInsightAction(insight),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    insight.action!,
                    style: GuitarrTypography.bodySmall,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(InsightPriority priority) {
    final color = switch (priority) {
      InsightPriority.high => GuitarrColors.error,
      InsightPriority.medium => GuitarrColors.warning,
      InsightPriority.low => GuitarrColors.info,
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: GuitarrTypography.bodySmall.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPersonalBestsCard() {
    return GlassCard(
      blurIntensity: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Bests',
              style: GuitarrTypography.bodyLarge.copyWith(
                color: GuitarrColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildPersonalBestCard('Highest Score', '92%', Icons.star)),
                const SizedBox(width: 12),
                Expanded(child: _buildPersonalBestCard('Max BPM', '180', Icons.speed)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildPersonalBestCard('Longest Session', '2h 15m', Icons.timer)),
                const SizedBox(width: 12),
                Expanded(child: _buildPersonalBestCard('Best Streak', '12 days', Icons.local_fire_department)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalBestCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GuitarrColors.success.withOpacity(0.1),
            GuitarrColors.success.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuitarrColors.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: GuitarrColors.success,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GuitarrTypography.bodySmall.copyWith(
              color: GuitarrColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GuitarrTypography.bodyMedium.copyWith(
              color: GuitarrColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityComparisonCard() {
    return GlassCard(
      blurIntensity: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Comparison',
              style: GuitarrTypography.bodyLarge.copyWith(
                color: GuitarrColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildComparisonMetric('Score Percentile', '78th', 'Top 22%'),
            const SizedBox(height: 12),
            _buildComparisonMetric('Practice Time', '82nd', 'More than 82% of users'),
            const SizedBox(height: 12),
            _buildComparisonMetric('Consistency', '65th', 'Above average'),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonMetric(String title, String percentile, String description) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GuitarrTypography.bodyMedium.copyWith(
                  color: GuitarrColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: GuitarrTypography.bodySmall.copyWith(
                  color: GuitarrColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: GuitarrColors.info.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GuitarrColors.info.withOpacity(0.3)),
          ),
          child: Text(
            percentile,
            style: GuitarrTypography.bodyMedium.copyWith(
              color: GuitarrColors.info,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalProgressCard() {
    return GlassCard(
      blurIntensity: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal Progress',
              style: GuitarrTypography.bodyLarge.copyWith(
                color: GuitarrColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildGoalProgressBar('Master Enter Sandman', 0.7),
            const SizedBox(height: 12),
            _buildGoalProgressBar('Reach 150 BPM', 0.85),
            const SizedBox(height: 12),
            _buildGoalProgressBar('Practice 30 days straight', 0.4),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgressBar(String goal, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              goal,
              style: GuitarrTypography.bodyMedium.copyWith(
                color: GuitarrColors.textPrimary,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: GuitarrTypography.bodySmall.copyWith(
                color: GuitarrColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: GuitarrColors.textSecondary.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(progress),
          ),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildLoadingCard() {
    return GlassCard(
      blurIntensity: 3,
      child: Container(
        height: 100,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
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
        ],
      ),
    );
  }

  Widget _buildErrorCard(String title, Object error) {
    return GlassCard(
      blurIntensity: 3,
      child: Container(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: GuitarrColors.error,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GuitarrTypography.bodySmall.copyWith(
                  color: GuitarrColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInsightsState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: GuitarrColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No insights available yet',
            style: GuitarrTypography.bodyLarge.copyWith(
              color: GuitarrColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Practice more to receive AI-powered insights',
            style: GuitarrTypography.bodySmall.copyWith(
              color: GuitarrColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getSkillColor(double level) {
    if (level >= 80) return GuitarrColors.success;
    if (level >= 60) return GuitarrColors.warning;
    return GuitarrColors.error;
  }

  Color _getTrendColor(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.improving:
        return GuitarrColors.success;
      case TrendDirection.declining:
        return GuitarrColors.error;
      case TrendDirection.stable:
        return GuitarrColors.textSecondary;
    }
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.achievement:
        return GuitarrColors.success;
      case InsightType.improvement:
        return GuitarrColors.warning;
      case InsightType.motivation:
        return GuitarrColors.primary;
      case InsightType.technique:
        return GuitarrColors.accent;
      case InsightType.warning:
        return GuitarrColors.error;
    }
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.achievement:
        return Icons.emoji_events;
      case InsightType.improvement:
        return Icons.trending_up;
      case InsightType.motivation:
        return Icons.psychology;
      case InsightType.technique:
        return Icons.music_note;
      case InsightType.warning:
        return Icons.warning;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return GuitarrColors.success;
    if (progress >= 0.5) return GuitarrColors.warning;
    return GuitarrColors.error;
  }

  void _showAnalyticsInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GuitarrColors.cardBackground,
        title: Text(
          'Advanced Analytics',
          style: GuitarrTypography.headlineSmall.copyWith(
            color: GuitarrColors.textPrimary,
          ),
        ),
        content: Text(
          'Get deep insights into your practice journey with AI-powered analytics, performance predictions, and personalized recommendations.',
          style: GuitarrTypography.bodyMedium.copyWith(
            color: GuitarrColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it!',
              style: TextStyle(color: GuitarrColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _performInsightAction(PracticeInsight insight) {
    // Implementation for performing insight actions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action: ${insight.action}'),
        backgroundColor: _getInsightColor(insight.type),
      ),
    );
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}