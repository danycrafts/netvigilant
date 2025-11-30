import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netvigilant/domain/entities/real_time_metrics_entity.dart';

class RealTimeNetworkChart extends StatefulWidget {
  final AsyncValue<RealTimeMetricsEntity> asyncMetrics;

  const RealTimeNetworkChart({super.key, required this.asyncMetrics});

  @override
  _RealTimeNetworkChartState createState() => _RealTimeNetworkChartState();
}

class _RealTimeNetworkChartState extends State<RealTimeNetworkChart> {
  final List<FlSpot> _uplinkData = [];
  final List<FlSpot> _downlinkData = [];
  double _maxSpeed = 0;
  int _timeCounter = 0;

  @override
  void didUpdateWidget(RealTimeNetworkChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.asyncMetrics.whenData((metrics) {
      setState(() {
        _timeCounter++;
        // Keep a fixed window of 30 data points
        if (_uplinkData.length >= 30) {
          _uplinkData.removeAt(0);
          _downlinkData.removeAt(0);
        }
        _uplinkData.add(FlSpot(_timeCounter.toDouble(), metrics.uplinkSpeed));
        _downlinkData.add(FlSpot(_timeCounter.toDouble(), metrics.downlinkSpeed));

        // Update the max speed for the y-axis
        final maxCurrentSpeed = metrics.uplinkSpeed > metrics.downlinkSpeed
            ? metrics.uplinkSpeed
            : metrics.downlinkSpeed;
        if (maxCurrentSpeed > _maxSpeed) {
          _maxSpeed = maxCurrentSpeed;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.asyncMetrics.when(
      data: (metrics) => _buildChart(context),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text('Error loading real-time data', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(error.toString(), style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: _timeCounter > 30 ? (_timeCounter - 30).toDouble() : 0,
        maxX: _timeCounter.toDouble(),
        minY: 0,
        maxY: _maxSpeed * 1.2, // Add some padding to the max speed
        lineBarsData: [
          _buildLineChartBarData(_uplinkData, Colors.blue),
          _buildLineChartBarData(_downlinkData, Colors.green),
        ],
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.3),
      ),
    );
  }
}
