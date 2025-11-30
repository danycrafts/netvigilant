import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:netvigilant/core/theme/app_theme.dart';

class TimeSeriesDataPoint {
  final DateTime timestamp;
  final double value;
  final String? label;

  const TimeSeriesDataPoint({
    required this.timestamp,
    required this.value,
    this.label,
  });
}

class TimeSeriesChartData {
  final String seriesName;
  final List<TimeSeriesDataPoint> dataPoints;
  final Color color;
  final bool showArea;
  final bool showPoints;

  const TimeSeriesChartData({
    required this.seriesName,
    required this.dataPoints,
    required this.color,
    this.showArea = false,
    this.showPoints = false,
  });
}

class TimeSeriesChart extends StatelessWidget {
  final List<TimeSeriesChartData> series;
  final String? title;
  final String? subtitle;
  final String yAxisLabel;
  final String xAxisLabel;
  final double? minY;
  final double? maxY;
  final Duration? timeRange;
  final bool showGrid;
  final bool showLegend;
  final String Function(double)? valueFormatter;
  final String Function(DateTime)? timeFormatter;

  const TimeSeriesChart({
    super.key,
    required this.series,
    this.title,
    this.subtitle,
    this.yAxisLabel = '',
    this.xAxisLabel = '',
    this.minY,
    this.maxY,
    this.timeRange,
    this.showGrid = true,
    this.showLegend = true,
    this.valueFormatter,
    this.timeFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (series.isEmpty || series.every((s) => s.dataPoints.isEmpty)) {
      return _buildEmptyState(context);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleLarge,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
            if (showLegend && series.length > 1) ...[
              _buildLegend(context),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: showGrid,
                    drawVerticalLine: showGrid,
                    drawHorizontalLine: showGrid,
                    verticalInterval: _calculateVerticalInterval(),
                    horizontalInterval: _calculateHorizontalInterval(),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? AppColors.chartGrid : Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: isDark ? AppColors.chartGrid : Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) => _buildYAxisTitle(value, context),
                      ),
                      axisNameWidget: yAxisLabel.isNotEmpty ? Text(
                        yAxisLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ) : null,
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => _buildXAxisTitle(value, context),
                      ),
                      axisNameWidget: xAxisLabel.isNotEmpty ? Text(
                        xAxisLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ) : null,
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  lineBarsData: series.map((seriesData) => _buildLineChartBarData(seriesData)).toList(),
                  minY: _calculateMinY(),
                  maxY: _calculateMaxY(),
                  minX: _calculateMinX(),
                  maxX: _calculateMaxX(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No Data Available',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chart will display when data is available',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: series.map((seriesData) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(
              color: seriesData.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            seriesData.seriesName,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      )).toList(),
    );
  }

  Widget _buildYAxisTitle(double value, BuildContext context) {
    final theme = Theme.of(context);
    final formattedValue = valueFormatter?.call(value) ?? value.toStringAsFixed(1);
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Text(
        formattedValue,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildXAxisTitle(double value, BuildContext context) {
    final theme = Theme.of(context);
    
    // Convert value back to timestamp
    final timestamp = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    final formattedTime = timeFormatter?.call(timestamp) ?? 
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Text(
        formattedTime,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(TimeSeriesChartData seriesData) {
    final spots = seriesData.dataPoints.map((point) => FlSpot(
      point.timestamp.millisecondsSinceEpoch.toDouble(),
      point.value,
    )).toList();

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: seriesData.color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(show: seriesData.showPoints),
      belowBarData: seriesData.showArea ? BarAreaData(
        show: true,
        color: seriesData.color.withValues(alpha: 0.1),
      ) : BarAreaData(show: false),
    );
  }

  double? _calculateMinY() {
    if (minY != null) return minY;
    
    if (series.isEmpty) return 0;
    
    final allValues = series.expand((s) => s.dataPoints.map((p) => p.value)).toList();
    if (allValues.isEmpty) return 0;
    
    final min = allValues.reduce((a, b) => a < b ? a : b);
    return min * 0.9; // Add 10% padding below
  }

  double? _calculateMaxY() {
    if (maxY != null) return maxY;
    
    if (series.isEmpty) return 100;
    
    final allValues = series.expand((s) => s.dataPoints.map((p) => p.value)).toList();
    if (allValues.isEmpty) return 100;
    
    final max = allValues.reduce((a, b) => a > b ? a : b);
    return max * 1.1; // Add 10% padding above
  }

  double? _calculateMinX() {
    if (series.isEmpty) return 0;
    
    final allTimestamps = series.expand((s) => s.dataPoints.map((p) => p.timestamp.millisecondsSinceEpoch.toDouble())).toList();
    if (allTimestamps.isEmpty) return 0;
    
    return allTimestamps.reduce((a, b) => a < b ? a : b);
  }

  double? _calculateMaxX() {
    if (series.isEmpty) return 1;
    
    final allTimestamps = series.expand((s) => s.dataPoints.map((p) => p.timestamp.millisecondsSinceEpoch.toDouble())).toList();
    if (allTimestamps.isEmpty) return 1;
    
    return allTimestamps.reduce((a, b) => a > b ? a : b);
  }

  double? _calculateVerticalInterval() {
    final minX = _calculateMinX() ?? 0;
    final maxX = _calculateMaxX() ?? 1;
    final range = maxX - minX;
    if (range <= 0) {
      // If range is zero or negative, return a default small interval (e.g., 1 unit on the x-axis)
      return 1.0;
    }
    return range / 5; // Show ~5 vertical lines
  }

  double? _calculateHorizontalInterval() {
    final minY = _calculateMinY() ?? 0;
    final maxY = _calculateMaxY() ?? 1;
    final range = maxY - minY;
    if (range <= 0) {
      // If range is zero or negative, return a default small interval (e.g., 1 unit on the y-axis)
      return 1.0;
    }
    return range / 4; // Show ~4 horizontal lines
  }
}