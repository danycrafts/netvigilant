import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RealTimeSpeedGauge extends StatefulWidget {
  final double uplinkSpeed; // in bytes per second
  final double downlinkSpeed; // in bytes per second

  const RealTimeSpeedGauge({
    super.key,
    required this.uplinkSpeed,
    required this.downlinkSpeed,
  });

  @override
  State<RealTimeSpeedGauge> createState() => _RealTimeSpeedGaugeState();
}

class _RealTimeSpeedGaugeState extends State<RealTimeSpeedGauge> {
  List<FlSpot> downloadData = [];
  List<FlSpot> uploadData = [];
  int dataPoints = 0;
  static const int maxDataPoints = 20; // Show last 20 data points to reduce rendering load
  DateTime? lastUpdate;

  @override
  void didUpdateWidget(RealTimeSpeedGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final now = DateTime.now();
    
    // Throttle updates to max once per 1000ms to reduce main thread work
    if (lastUpdate != null && now.difference(lastUpdate!).inMilliseconds < 1000) {
      return;
    }
    
    // Only update if the values have actually changed to avoid unnecessary rebuilds
    if (oldWidget.downlinkSpeed != widget.downlinkSpeed || 
        oldWidget.uplinkSpeed != widget.uplinkSpeed) {
      
      lastUpdate = now;
      
      // Use more efficient data management
      if (downloadData.length >= maxDataPoints) {
        downloadData.removeAt(0);
        uploadData.removeAt(0);
        
        // More efficient shifting without creating new lists
        for (int i = 0; i < downloadData.length; i++) {
          downloadData[i] = FlSpot(downloadData[i].x - 1, downloadData[i].y);
          uploadData[i] = FlSpot(uploadData[i].x - 1, uploadData[i].y);
        }
        dataPoints--;
      }
      
      final newX = dataPoints.toDouble();
      downloadData.add(FlSpot(newX, widget.downlinkSpeed / (1024 * 1024))); // Convert to MB/s
      uploadData.add(FlSpot(newX, widget.uplinkSpeed / (1024 * 1024))); // Convert to MB/s
      dataPoints++;
    }
  }

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(1)} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else if (bytesPerSecond < 1024 * 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024 * 1024)).toStringAsFixed(3)} GB/s';
    }
  }

  double _getSpeedValue(double bytesPerSecond) {
    return bytesPerSecond / (1024 * 1024); // Convert to MB/s for gauge
  }

  @override
  Widget build(BuildContext context) {
    final downloadSpeedValue = _getSpeedValue(widget.downlinkSpeed);
    final uploadSpeedValue = _getSpeedValue(widget.uplinkSpeed);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-time Network Speed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Speed indicators
            Row(
              children: [
                Expanded(
                  child: _buildSpeedIndicator(
                    context,
                    'Download',
                    widget.downlinkSpeed,
                    Icons.download,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSpeedIndicator(
                    context,
                    'Upload',
                    widget.uplinkSpeed,
                    Icons.upload,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Circular progress indicators for visual representation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSpeedGauge(
                  context,
                  'Download',
                  downloadSpeedValue,
                  Colors.green,
                  50.0, // Max MB/s for scale
                ),
                _buildSpeedGauge(
                  context,
                  'Upload',
                  uploadSpeedValue,
                  Colors.orange,
                  10.0, // Max MB/s for scale (upload usually lower)
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Real-time chart
            if (downloadData.isNotEmpty)
              Container(
                height: 150,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Speed History (MB/s)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1,
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              left: BorderSide(color: Colors.grey.withAlpha((255 * 0.3).round())),
                              bottom: BorderSide(color: Colors.grey.withAlpha((255 * 0.3).round())),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: downloadData,
                              isCurved: true,
                              color: Colors.green,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.green.withAlpha((255 * 0.1).round()),
                              ),
                            ),
                            LineChartBarData(
                              spots: uploadData,
                              isCurved: true,
                              color: Colors.orange,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.orange.withAlpha((255 * 0.1).round()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedIndicator(
    BuildContext context,
    String label,
    double speed,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatSpeed(speed),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedGauge(
    BuildContext context,
    String label,
    double value,
    Color color,
    double maxValue,
  ) {
    final progress = (value / maxValue).clamp(0.0, 1.0);
    
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                color: color,
                backgroundColor: color.withAlpha((255 * 0.2).round()),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'MB/s',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
