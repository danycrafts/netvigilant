import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:netvigilant/presentation/providers/database_providers.dart'; // Import formatBytes and formatTime
import 'package:collection/collection.dart'; // For groupBy

class AppDetailScreen extends ConsumerWidget {
  final String packageName;
  final String appName;

  const AppDetailScreen({
    super.key,
    required this.packageName,
    required this.appName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appData = ref.watch(appSpecificDataProvider(packageName));
    final dailyNetworkUsage = ref.watch(appDailyNetworkUsageProvider(packageName));
    final networkTypeBreakdown = ref.watch(appNetworkTypeBreakdownProvider(packageName));
    final backgroundUsage = ref.watch(appBackgroundUsageProvider(packageName));

    return Scaffold(
      appBar: AppBar(
        title: Text(appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share app usage report functionality will be implemented
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Overview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
                          child: Text(
                            appName.isNotEmpty ? appName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 24,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                packageName,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
            // Metrics as a responsive GridView
            GridView.builder(
              shrinkWrap: true, // Important for GridView inside SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Three columns
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8, // Adjust as needed
              ),
              itemCount: 3, // Fixed number of metrics
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return appData.when(
                      data: (data) => _buildMetricItem(
                        context,
                        'Total Data',
                        formatBytes(data['totalBytes']!),
                        Icons.data_usage,
                        Theme.of(context).colorScheme.primary,
                      ),
                      loading: () => _buildLoadingMetricItem(context, 'Total Data', Icons.data_usage),
                      error: (_, __) => _buildMetricItem(
                        context,
                        'Total Data',
                        '0 B',
                        Icons.data_usage,
                        Theme.of(context).colorScheme.primary,
                      ),
                    );
                  case 1:
                    return appData.when(
                      data: (data) => _buildMetricItem(
                        context,
                        'Screen Time',
                        formatTime(data['foregroundTimeHours']!),
                        Icons.access_time,
                        Theme.of(context).colorScheme.secondary,
                      ),
                      loading: () => _buildLoadingMetricItem(context, 'Screen Time', Icons.access_time),
                      error: (_, __) => _buildMetricItem(
                        context,
                        'Screen Time',
                        '0m',
                        Icons.access_time,
                        Theme.of(context).colorScheme.secondary,
                      ),
                    );
                  case 2:
                    return appData.when(
                      data: (data) => _buildMetricItem(
                        context,
                        'Battery',
                        '${data['avgBatteryUsage']!.toStringAsFixed(1)}%',
                        Icons.battery_std,
                        Theme.of(context).colorScheme.tertiary,
                      ),
                      loading: () => _buildLoadingMetricItem(context, 'Battery', Icons.battery_std),
                      error: (_, __) => _buildMetricItem(
                        context,
                        'Battery',
                        '0.0%',
                        Icons.battery_std,
                        Theme.of(context).colorScheme.tertiary,
                      ),
                    );
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Usage Chart
            Text(
              'Data Usage (Last 7 Days)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 200,
                  child: dailyNetworkUsage.when(
                    data: (data) {
                      final spots = data.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), (entry.value['totalBytes'] / (1024 * 1024)).toDouble()); // Convert bytes to MB
                      }).toList();

                      // Get current day of week for labels
                      final now = DateTime.now();
                      final startOfWeek = now.subtract(const Duration(days: 6)); // 7 days including today
                      final dayLabels = List<String>.generate(7, (index) {
                        final date = startOfWeek.add(Duration(days: index));
                        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
                      });

                      return LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: (spots.map((e) => e.y).maxOrNull ?? 0) / 4, // Dynamic interval
                                getTitlesWidget: (value, meta) {
                                  return Text('${value.toInt()}MB', style: Theme.of(context).textTheme.bodySmall);
                                },
                                reservedSize: 40,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 8,
                                    child: Text(dayLabels[value.toInt()], style: Theme.of(context).textTheme.bodySmall),
                                  );
                                },
                                reservedSize: 30,
                              ),
                            ),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withAlpha((255 * 0.3).round()),
                                ],
                              ),
                              barWidth: 3,
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor.withAlpha((255 * 0.3).round()),
                                    Theme.of(context).primaryColor.withAlpha((255 * 0.3).round()),
                                  ],
                                ),
                              ),
                              dotData: FlDotData(show: false),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Center(child: Text('Error loading chart data', style: Theme.of(context).textTheme.bodyLarge)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Network Type Breakdown
            Text(
              'Network Type Usage',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: networkTypeBreakdown.when(
                  data: (breakdown) {
                    final wifiBytes = breakdown['wifiBytes'] ?? 0.0;
                    final mobileBytes = breakdown['mobileBytes'] ?? 0.0;
                    final totalBytes = wifiBytes + mobileBytes;

                    double wifiPercentage = totalBytes > 0 ? (wifiBytes / totalBytes) * 100 : 0.0;
                    double mobilePercentage = totalBytes > 0 ? (mobileBytes / totalBytes) * 100 : 0.0;

                    List<PieChartSectionData> sections = [];
                    if (wifiBytes > 0) {
                      sections.add(PieChartSectionData(
                        value: wifiBytes,
                        color: Colors.blue,
                        title: 'WiFi\n${wifiPercentage.toStringAsFixed(0)}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ));
                    }
                    if (mobileBytes > 0) {
                      sections.add(PieChartSectionData(
                        value: mobileBytes,
                        color: Colors.orange,
                        title: 'Mobile\n${mobilePercentage.toStringAsFixed(0)}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ));
                    }
                    
                    if (sections.isEmpty) {
                      sections.add(PieChartSectionData(
                        value: 1,
                        color: Colors.grey,
                        title: 'No Data',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ));
                    }

                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 150,
                            child: PieChart(
                              PieChartData(
                                sections: sections,
                                centerSpaceRadius: 20,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildNetworkTypeItem('WiFi', formatBytes(wifiBytes), Colors.blue),
                              const SizedBox(height: 8),
                              _buildNetworkTypeItem('Mobile Data', formatBytes(mobileBytes), Colors.orange),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(child: Text('Error loading network breakdown', style: Theme.of(context).textTheme.bodyLarge)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Usage Patterns
            Text(
              'Usage Patterns',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.schedule, color: Colors.green),
                    title: const Text('Peak Usage Time'),
                    subtitle: const Text('N/A'), // Placeholder for now
                    trailing: const Text(
                      'N/A',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.nights_stay, color: Colors.purple),
                    title: const Text('Background Usage'),
                    subtitle: const Text('Last 30 days'),
                    trailing: backgroundUsage.when(
                      data: (data) => Text(
                        formatBytes(data),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => Container(
                        width: 50,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      error: (_, __) => Text(
                        '0 B',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.trending_up, color: Colors.red),
                    title: const Text('Weekly Trend'),
                    subtitle: const Text('Usage compared to last week'),
                    trailing: const Text(
                      'N/A', // Placeholder for now
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Data limit functionality will be implemented
                      _showSetLimitDialog(context);
                    },
                    icon: const Icon(Icons.data_usage),
                    label: const Text('Set Data Limit'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Network blocking functionality will be implemented
                      _showBlockAppDialog(context);
                    },
                    icon: const Icon(Icons.block),
                    label: const Text('Block Network'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 100), // Extra space at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color itemColor, // Renamed from 'color' to 'itemColor' for clarity
  ) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundColor: itemColor.withValues(alpha: 0.1),
          radius: 24,
          child: Icon(icon, color: itemColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: itemColor,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildNetworkTypeItem(String type, String usage, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              usage,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  void _showSetLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double limit = 1000; // MB
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Set Data Limit for $appName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Monthly data limit: ${limit.toInt()} MB'),
                  const SizedBox(height: 16),
                  Slider(
                    value: limit,
                    min: 100,
                    max: 5000,
                    divisions: 49,
                    label: '${limit.toInt()} MB',
                    onChanged: (double value) {
                      setState(() => limit = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Set Limit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBlockAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Block Network Access for $appName'),
          content: const Text(
            'This will prevent the app from accessing the internet. The app may not function properly without network access.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Block', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingMetricItem(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              radius: 24,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 60,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}