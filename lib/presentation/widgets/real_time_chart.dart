import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:netvigilant/domain/entities/real_time_metrics_entity.dart';

class RealTimeNetworkChart extends StatefulWidget {
  final Stream<RealTimeMetricsEntity> metricsStream;

  const RealTimeNetworkChart({super.key, required this.metricsStream});

  @override
  _RealTimeNetworkChartState createState() => _RealTimeNetworkChartState();
}

class _RealTimeNetworkChartState extends State<RealTimeNetworkChart> {
  late StreamSubscription<RealTimeMetricsEntity> _metricsSubscription;
  final List<FlSpot> _uplinkData = [];
  final List<FlSpot> _downlinkData = [];
  double _maxSpeed = 0;
  int _timeCounter = 0;

  @override
  void initState() {
    super.initState();
    _metricsSubscription = widget.metricsStream.listen((metrics) {
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
  void dispose() {
    _metricsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
