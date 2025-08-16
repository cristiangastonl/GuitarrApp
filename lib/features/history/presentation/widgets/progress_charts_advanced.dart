import 'package:flutter/material.dart';

class ProgressChartsAdvanced extends StatefulWidget {
  final List<Map<String, dynamic>> chartData;
  final String chartType;

  const ProgressChartsAdvanced({
    super.key,
    required this.chartData,
    this.chartType = 'score',
  });

  @override
  State<ProgressChartsAdvanced> createState() => _ProgressChartsAdvancedState();
}

class _ProgressChartsAdvancedState extends State<ProgressChartsAdvanced>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String selectedTimeframe = '30d';
  String selectedMetric = 'score';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
    selectedMetric = widget.chartType;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildMetricSelector(),
          const SizedBox(height: 20),
          _buildChart(),
          const SizedBox(height: 16),
          _buildInsights(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.analytics,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Progreso en el Tiempo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        _buildTimeframeSelector(),
      ],
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['7d', '30d', '90d'].map((timeframe) {
          final isSelected = selectedTimeframe == timeframe;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedTimeframe = timeframe;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
              ),
              child: Text(
                timeframe,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricSelector() {
    final metrics = [
      {'id': 'score', 'label': 'Score', 'icon': Icons.emoji_events},
      {'id': 'bpm', 'label': 'BPM', 'icon': Icons.speed},
      {'id': 'sessions', 'label': 'Sesiones', 'icon': Icons.music_note},
      {'id': 'minutes', 'label': 'Tiempo', 'icon': Icons.access_time},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: metrics.map((metric) {
          final isSelected = selectedMetric == metric['id'];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedMetric = metric['id'] as String;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).dividerColor,
                  ),
                  color: isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      metric['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).iconTheme.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      metric['label'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : null,
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    if (widget.chartData.isEmpty) {
      return _buildEmptyState();
    }

    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(double.infinity, 200),
            painter: LineChartPainter(
              data: widget.chartData,
              metric: selectedMetric,
              animationValue: _animationController.value,
              theme: Theme.of(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
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
              Icons.bar_chart,
              size: 48,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay datos suficientes',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Practica más para ver tu progreso',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsights() {
    if (widget.chartData.length < 2) return const SizedBox.shrink();

    final insights = _calculateInsights();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).primaryColor.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Icon(
            insights['trend'] == 'up' 
                ? Icons.trending_up
                : insights['trend'] == 'down'
                    ? Icons.trending_down
                    : Icons.trending_flat,
            color: insights['trend'] == 'up'
                ? Colors.green
                : insights['trend'] == 'down'
                    ? Colors.red
                    : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insights['message'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateInsights() {
    if (widget.chartData.length < 2) {
      return {'trend': 'neutral', 'message': 'Necesitas más datos para ver tendencias'};
    }

    final recent = widget.chartData.take(7).toList();
    final older = widget.chartData.skip(7).take(7).toList();

    if (older.isEmpty) {
      return {'trend': 'neutral', 'message': 'Sigue practicando para ver tu evolución'};
    }

    double recentAvg = 0;
    double olderAvg = 0;

    switch (selectedMetric) {
      case 'score':
        recentAvg = recent.map((d) => (d['avgScore'] ?? 0) as num).fold(0.0, (a, b) => a + b) / recent.length;
        olderAvg = older.map((d) => (d['avgScore'] ?? 0) as num).fold(0.0, (a, b) => a + b) / older.length;
        break;
      case 'bpm':
        recentAvg = recent.map((d) => (d['avgBpm'] ?? 0) as num).fold(0.0, (a, b) => a + b) / recent.length;
        olderAvg = older.map((d) => (d['avgBpm'] ?? 0) as num).fold(0.0, (a, b) => a + b) / older.length;
        break;
      case 'sessions':
        recentAvg = recent.map((d) => (d['sessions'] ?? 0) as num).fold(0.0, (a, b) => a + b) / recent.length;
        olderAvg = older.map((d) => (d['sessions'] ?? 0) as num).fold(0.0, (a, b) => a + b) / older.length;
        break;
      case 'minutes':
        recentAvg = recent.map((d) => (d['totalMinutes'] ?? 0) as num).fold(0.0, (a, b) => a + b) / recent.length;
        olderAvg = older.map((d) => (d['totalMinutes'] ?? 0) as num).fold(0.0, (a, b) => a + b) / older.length;
        break;
    }

    final difference = recentAvg - olderAvg;
    final percentChange = olderAvg > 0 ? (difference / olderAvg * 100).abs() : 0;

    String trend;
    String message;

    if (percentChange < 5) {
      trend = 'neutral';
      message = 'Tu rendimiento se mantiene estable';
    } else if (difference > 0) {
      trend = 'up';
      message = 'Tu ${_getMetricName()} está mejorando ${percentChange.round()}%';
    } else {
      trend = 'down';
      message = 'Tu ${_getMetricName()} ha bajado ${percentChange.round()}%';
    }

    return {'trend': trend, 'message': message};
  }

  String _getMetricName() {
    switch (selectedMetric) {
      case 'score': return 'score promedio';
      case 'bpm': return 'velocidad promedio';
      case 'sessions': return 'frecuencia de práctica';
      case 'minutes': return 'tiempo de práctica';
      default: return 'rendimiento';
    }
  }
}

class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final String metric;
  final double animationValue;
  final ThemeData theme;

  LineChartPainter({
    required this.data,
    required this.metric,
    required this.animationValue,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = theme.primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = theme.primaryColor
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = theme.dividerColor.withOpacity(0.3)
      ..strokeWidth = 1;

    // Get values for the selected metric
    final values = data.map((d) {
      switch (metric) {
        case 'score': return (d['avgScore'] ?? 0) as num;
        case 'bpm': return (d['avgBpm'] ?? 0) as num;
        case 'sessions': return (d['sessions'] ?? 0) as num;
        case 'minutes': return (d['totalMinutes'] ?? 0) as num;
        default: return 0;
      }
    }).toList();

    if (values.isEmpty) return;

    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();
    final minValue = values.reduce((a, b) => a < b ? a : b).toDouble();
    final range = maxValue - minValue;

    // Draw grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Draw chart line
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final normalizedValue = range > 0 ? (values[i] - minValue) / range : 0.5;
      final y = size.height * (1 - normalizedValue);
      
      points.add(Offset(x, y));
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Apply animation
    final animatedPath = Path();
    final pathMetrics = path.computeMetrics().first;
    final extractedPath = pathMetrics.extractPath(
      0,
      pathMetrics.length * animationValue,
    );
    animatedPath.addPath(extractedPath, Offset.zero);

    canvas.drawPath(animatedPath, paint);

    // Draw points
    for (int i = 0; i < (points.length * animationValue).round(); i++) {
      canvas.drawCircle(points[i], 4, pointPaint);
      canvas.drawCircle(points[i], 4, Paint()..color = theme.cardColor..style = PaintingStyle.fill);
      canvas.drawCircle(points[i], 2, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}