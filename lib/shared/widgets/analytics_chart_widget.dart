import 'package:flutter/material.dart';
import '../../core/services/advanced_analytics_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'dart:math' as math;

enum ChartType {
  line,
  bar,
  multiLine,
  area,
}

class AnalyticsChartWidget extends StatefulWidget {
  final List<ChartDataPoint>? data;
  final Map<String, List<ChartDataPoint>>? multiSeriesData;
  final String title;
  final String? yAxisLabel;
  final Color? color;
  final ChartType chartType;
  final bool showGrid;
  final bool showTooltip;
  final double? minY;
  final double? maxY;
  
  const AnalyticsChartWidget({
    super.key,
    this.data,
    this.multiSeriesData,
    required this.title,
    this.yAxisLabel,
    this.color,
    required this.chartType,
    this.showGrid = true,
    this.showTooltip = true,
    this.minY,
    this.maxY,
  }) : assert(data != null || multiSeriesData != null, 'Either data or multiSeriesData must be provided');

  @override
  State<AnalyticsChartWidget> createState() => _AnalyticsChartWidgetState();
}

class _AnalyticsChartWidgetState extends State<AnalyticsChartWidget> {
  String? _hoveredPoint;
  Offset? _hoverPosition;
  
  @override
  Widget build(BuildContext context) {
    if (_isEmpty()) {
      return _buildEmptyState();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty) ...[
          Text(
            widget.title,
            style: GuitarrTypography.bodyMedium.copyWith(
              color: GuitarrColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: Stack(
            children: [
              _buildChart(),
              if (widget.showTooltip && _hoveredPoint != null && _hoverPosition != null)
                _buildTooltip(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildChart() {
    return MouseRegion(
      onHover: (event) {
        if (widget.showTooltip) {
          _updateHover(event.localPosition);
        }
      },
      onExit: (event) {
        setState(() {
          _hoveredPoint = null;
          _hoverPosition = null;
        });
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: _ChartPainter(
          data: widget.data,
          multiSeriesData: widget.multiSeriesData,
          chartType: widget.chartType,
          color: widget.color ?? GuitarrColors.primary,
          showGrid: widget.showGrid,
          yAxisLabel: widget.yAxisLabel,
          minY: widget.minY,
          maxY: widget.maxY,
        ),
      ),
    );
  }
  
  Widget _buildTooltip() {
    return Positioned(
      left: _hoverPosition!.dx + 10,
      top: _hoverPosition!.dy - 30,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: GuitarrColors.cardBackground.withOpacity(0.9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: GuitarrColors.primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          _hoveredPoint!,
          style: GuitarrTypography.bodySmall.copyWith(
            color: GuitarrColors.textPrimary,
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            color: GuitarrColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: GuitarrTypography.bodyMedium.copyWith(
              color: GuitarrColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  bool _isEmpty() {
    if (widget.chartType == ChartType.multiLine) {
      return widget.multiSeriesData?.isEmpty ?? true;
    }
    return widget.data?.isEmpty ?? true;
  }
  
  void _updateHover(Offset position) {
    // Implementation for hover detection would go here
    // For now, we'll show a simple tooltip
    final data = widget.data ?? [];
    if (data.isNotEmpty) {
      final index = (position.dx / 200 * data.length).round().clamp(0, data.length - 1);
      final point = data[index];
      setState(() {
        _hoveredPoint = '${point.label}: ${point.y.toStringAsFixed(1)}';
        _hoverPosition = position;
      });
    }
  }
}

class _ChartPainter extends CustomPainter {
  final List<ChartDataPoint>? data;
  final Map<String, List<ChartDataPoint>>? multiSeriesData;
  final ChartType chartType;
  final Color color;
  final bool showGrid;
  final String? yAxisLabel;
  final double? minY;
  final double? maxY;
  
  _ChartPainter({
    this.data,
    this.multiSeriesData,
    required this.chartType,
    required this.color,
    required this.showGrid,
    this.yAxisLabel,
    this.minY,
    this.maxY,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (_isEmpty()) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final fillPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // Calculate chart area (leaving space for axes)
    const margin = 40.0;
    final chartRect = Rect.fromLTWH(
      margin,
      margin / 2,
      size.width - margin * 1.5,
      size.height - margin,
    );
    
    if (showGrid) {
      _drawGrid(canvas, chartRect);
    }
    
    switch (chartType) {
      case ChartType.line:
        _drawLineChart(canvas, chartRect, paint);
        break;
      case ChartType.bar:
        _drawBarChart(canvas, chartRect, paint, fillPaint);
        break;
      case ChartType.multiLine:
        _drawMultiLineChart(canvas, chartRect);
        break;
      case ChartType.area:
        _drawAreaChart(canvas, chartRect, paint, fillPaint);
        break;
    }
    
    _drawAxes(canvas, size, chartRect);
  }
  
  void _drawGrid(Canvas canvas, Rect chartRect) {
    final gridPaint = Paint()
      ..color = GuitarrColors.textSecondary.withOpacity(0.2)
      ..strokeWidth = 0.5;
    
    // Vertical grid lines
    for (int i = 0; i <= 5; i++) {
      final x = chartRect.left + (chartRect.width * i / 5);
      canvas.drawLine(
        Offset(x, chartRect.top),
        Offset(x, chartRect.bottom),
        gridPaint,
      );
    }
    
    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = chartRect.top + (chartRect.height * i / 4);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }
  }
  
  void _drawLineChart(Canvas canvas, Rect chartRect, Paint paint) {
    if (data == null || data!.isEmpty) return;
    
    final points = _getScaledPoints(data!, chartRect);
    
    if (points.length < 2) return;
    
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    canvas.drawPath(path, paint);
    
    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    for (final point in points) {
      canvas.drawCircle(point, 3, pointPaint);
    }
  }
  
  void _drawBarChart(Canvas canvas, Rect chartRect, Paint paint, Paint fillPaint) {
    if (data == null || data!.isEmpty) return;
    
    final barWidth = chartRect.width / data!.length * 0.8;
    final spacing = chartRect.width / data!.length * 0.2;
    
    final minValue = minY ?? data!.map((p) => p.y).reduce(math.min);
    final maxValue = maxY ?? data!.map((p) => p.y).reduce(math.max);
    final valueRange = maxValue - minValue;
    
    for (int i = 0; i < data!.length; i++) {
      final point = data![i];
      final x = chartRect.left + (i * (barWidth + spacing)) + spacing / 2;
      final normalizedValue = (point.y - minValue) / valueRange;
      final barHeight = chartRect.height * normalizedValue;
      final y = chartRect.bottom - barHeight;
      
      final barRect = Rect.fromLTWH(x, y, barWidth, barHeight);
      canvas.drawRect(barRect, fillPaint);
      canvas.drawRect(barRect, paint);
    }
  }
  
  void _drawMultiLineChart(Canvas canvas, Rect chartRect) {
    if (multiSeriesData == null) return;
    
    final colors = [
      GuitarrColors.primary,
      GuitarrColors.secondary,
      GuitarrColors.accent,
      GuitarrColors.success,
      GuitarrColors.warning,
    ];
    
    int colorIndex = 0;
    
    for (final entry in multiSeriesData!.entries) {
      final seriesData = entry.value;
      if (seriesData.isEmpty) continue;
      
      final seriesColor = colors[colorIndex % colors.length];
      colorIndex++;
      
      final paint = Paint()
        ..color = seriesColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      final points = _getScaledPoints(seriesData, chartRect);
      
      if (points.length < 2) continue;
      
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      
      canvas.drawPath(path, paint);
      
      // Draw points
      final pointPaint = Paint()
        ..color = seriesColor
        ..style = PaintingStyle.fill;
      
      for (final point in points) {
        canvas.drawCircle(point, 2, pointPaint);
      }
    }
  }
  
  void _drawAreaChart(Canvas canvas, Rect chartRect, Paint paint, Paint fillPaint) {
    if (data == null || data!.isEmpty) return;
    
    final points = _getScaledPoints(data!, chartRect);
    
    if (points.length < 2) return;
    
    final path = Path();
    path.moveTo(points.first.dx, chartRect.bottom);
    path.lineTo(points.first.dx, points.first.dy);
    
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    path.lineTo(points.last.dx, chartRect.bottom);
    path.close();
    
    canvas.drawPath(path, fillPaint);
    
    // Draw line on top
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    
    canvas.drawPath(linePath, paint);
  }
  
  void _drawAxes(Canvas canvas, Size size, Rect chartRect) {
    final axisPaint = Paint()
      ..color = GuitarrColors.textSecondary
      ..strokeWidth = 1;
    
    // Y-axis
    canvas.drawLine(
      Offset(chartRect.left, chartRect.top),
      Offset(chartRect.left, chartRect.bottom),
      axisPaint,
    );
    
    // X-axis
    canvas.drawLine(
      Offset(chartRect.left, chartRect.bottom),
      Offset(chartRect.right, chartRect.bottom),
      axisPaint,
    );
    
    // Y-axis labels
    if (data != null && data!.isNotEmpty) {
      final minValue = minY ?? data!.map((p) => p.y).reduce(math.min);
      final maxValue = maxY ?? data!.map((p) => p.y).reduce(math.max);
      
      _drawYAxisLabels(canvas, chartRect, minValue, maxValue);
    }
  }
  
  void _drawYAxisLabels(Canvas canvas, Rect chartRect, double minValue, double maxValue) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (int i = 0; i <= 4; i++) {
      final value = minValue + (maxValue - minValue) * (4 - i) / 4;
      final y = chartRect.top + (chartRect.height * i / 4);
      
      textPainter.text = TextSpan(
        text: value.toStringAsFixed(0),
        style: GuitarrTypography.bodySmall.copyWith(
          color: GuitarrColors.textSecondary,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(chartRect.left - textPainter.width - 8, y - textPainter.height / 2),
      );
    }
  }
  
  List<Offset> _getScaledPoints(List<ChartDataPoint> data, Rect chartRect) {
    if (data.isEmpty) return [];
    
    final minX = data.map((p) => p.x).reduce(math.min);
    final maxX = data.map((p) => p.x).reduce(math.max);
    final minValue = minY ?? data.map((p) => p.y).reduce(math.min);
    final maxValue = maxY ?? data.map((p) => p.y).reduce(math.max);
    
    final xRange = maxX - minX;
    final yRange = maxValue - minValue;
    
    return data.map((point) {
      final x = chartRect.left + ((point.x - minX) / xRange) * chartRect.width;
      final y = chartRect.bottom - ((point.y - minValue) / yRange) * chartRect.height;
      return Offset(x, y);
    }).toList();
  }
  
  bool _isEmpty() {
    if (chartType == ChartType.multiLine) {
      return multiSeriesData?.isEmpty ?? true;
    }
    return data?.isEmpty ?? true;
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}