import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netvigilant/presentation/providers/network_providers.dart';
import 'package:netvigilant/presentation/widgets/app_traffic_list_view.dart';
import 'package:netvigilant/domain/entities/network_traffic_entity.dart';
import 'package:netvigilant/domain/entities/real_time_metrics_entity.dart';
import 'package:netvigilant/core/theme/app_theme.dart';
import 'package:netvigilant/core/widgets/time_series_chart.dart';
import 'package:netvigilant/core/widgets/metric_card.dart';
import 'package:netvigilant/core/widgets/status_indicator.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realTimeMetrics = ref.watch(realTimeTrafficProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Enhanced Hero Section
            SliverToBoxAdapter(
              child: _buildHeroSection(context, ref, realTimeMetrics),
            ),
            
            // Real-time Metrics Cards
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _buildMetricsRow(context, ref, realTimeMetrics),
              ),
            ),

            // Network Usage Chart
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: _buildNetworkUsageChart(context, ref),
              ),
            ),

            // Permission Status
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _buildPermissionCard(context, ref),
              ),
            ),

            // App Usage List
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: _buildAppUsageSection(context),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, WidgetRef ref, AsyncValue<RealTimeMetricsEntity> realTimeMetrics) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 180, // Slightly reduced height
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8), // Softer dark background
                  theme.colorScheme.surface.withValues(alpha: 0.8),
                  AppColors.primaryCyan.withValues(alpha: 0.05), // Very subtle accent
                ]
              : [
                  theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.8), // Softer light background
                  theme.colorScheme.surfaceContainer.withValues(alpha: 0.8),
                  AppColors.primaryCyan.withValues(alpha: 0.05), // Very subtle accent
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Floating orbs - made more subtle
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryCyan.withValues(alpha: 0.03), // More subtle
              ),
            ),
          ),
          Positioned(
            bottom: -15,
            left: -15,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGreen.withValues(alpha: 0.03), // More subtle
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'NetVigilant',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: AppColors.primaryCyan.withValues(alpha: 0.9), // Slightly softer
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6), // Slightly reduced spacing
                Text(
                  'Real-time Network Monitoring',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8), // Slightly more visible
                  ),
                ),
                const SizedBox(height: 12), // Slightly reduced spacing
                realTimeMetrics.when(
                  data: (metrics) => StatusIndicator( // Use generic StatusIndicator
                    status: StatusType.success,
                    text: 'MONITORING ACTIVE',
                  ),
                  loading: () => const StatusIndicator(
                    status: StatusType.neutral,
                    text: 'Connecting...',
                  ),
                  error: (_, __) => const StatusIndicator(
                    status: StatusType.error,
                    text: 'Connection Error',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, WidgetRef ref, AsyncValue<RealTimeMetricsEntity> realTimeMetrics) {
    return realTimeMetrics.when(
      data: (metrics) => MetricRow(
        metrics: [
          MetricCardData(
            title: 'Download',
            value: _formatSpeed(metrics.downlinkSpeed),
            icon: Icons.download_rounded,
            customColor: AppColors.actionBlue,
          ),
          MetricCardData(
            title: 'Upload',
            value: _formatSpeed(metrics.uplinkSpeed),
            icon: Icons.upload_rounded,
            customColor: AppColors.accentGreen,
          ),
          MetricCardData(
            title: 'Total',
            value: _formatSpeed(metrics.downlinkSpeed + metrics.uplinkSpeed),
            icon: Icons.speed_rounded,
            customColor: AppColors.primaryCyan,
          ),
        ],
      ),
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => MetricCard(
        data: MetricCardData(
          title: 'Connection Status',
          value: 'Error',
          subtitle: error.toString(),
          icon: Icons.error_outline,
        ),
        type: MetricCardType.error,
      ),
    );
  }

  Widget _buildNetworkUsageChart(BuildContext context, WidgetRef ref) {
    final networkHistory = ref.watch(networkHistoryProvider);

    return networkHistory.when(
      data: (networkData) {
        if (networkData.isEmpty) {
          return TimeSeriesChart(
            series: const [],
            title: '7-Day Network Usage',
            subtitle: 'No data available',
            yAxisLabel: 'Usage (MB)',
          );
        }

        final downloadSeries = _createTimeSeriesData(
          networkData,
          'Download',
          AppColors.actionBlue,
          isDownload: true,
        );

        final uploadSeries = _createTimeSeriesData(
          networkData,
          'Upload',
          AppColors.accentGreen,
          isDownload: false,
        );

        return TimeSeriesChart(
          series: [downloadSeries, uploadSeries],
          title: '7-Day Network Usage',
          subtitle: 'Download and upload trends',
          yAxisLabel: 'Usage (MB)',
          valueFormatter: (value) => '${value.toStringAsFixed(1)}MB',
          timeFormatter: (time) => '${time.month}/${time.day}',
        );
      },
      loading: () => TimeSeriesChart(
        series: const [],
        title: '7-Day Network Usage',
        subtitle: 'Loading...',
      ),
      error: (error, _) => TimeSeriesChart(
        series: const [],
        title: '7-Day Network Usage',
        subtitle: 'Error: ${error.toString()}',
      ),
    );
  }

  Widget _buildPermissionCard(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool?>(
      future: ref.read(networkRepositoryProvider).hasUsageStatsPermission(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MetricCard(
            data: MetricCardData(
              title: 'Permissions',
              value: 'Checking...',
              icon: Icons.security,
            ),
          );
        }

        final hasPermission = snapshot.data ?? false;
        return MetricCard(
          data: MetricCardData(
            title: 'Usage Stats Permission',
            value: hasPermission ? 'Granted' : 'Required',
            subtitle: hasPermission ? 'All features available' : 'Tap to grant permission',
            icon: hasPermission ? Icons.check_circle : Icons.warning,
            onTap: hasPermission ? null : () async {
              await ref.read(networkRepositoryProvider).requestUsageStatsPermission();
            },
          ),
          type: hasPermission ? MetricCardType.success : MetricCardType.warning,
        );
      },
    );
  }

  Widget _buildAppUsageSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Usage Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const AppTrafficListView(),
          ],
        ),
      ),
    );
  }

  TimeSeriesChartData _createTimeSeriesData(
    List<NetworkTrafficEntity> networkData,
    String name,
    Color color, {
    required bool isDownload,
  }) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    // Group data by day
    final Map<String, double> dailyUsage = {};
    
    for (int i = 0; i < 7; i++) {
      final day = weekAgo.add(Duration(days: i));
      final dayKey = '${day.year}-${day.month}-${day.day}';
      dailyUsage[dayKey] = 0.0;
    }
    
    for (final traffic in networkData) {
      if (traffic.timestamp.isAfter(weekAgo)) {
        final dayKey = '${traffic.timestamp.year}-${traffic.timestamp.month}-${traffic.timestamp.day}';
        final bytes = (isDownload ? traffic.rxBytes : traffic.txBytes).toDouble();
        dailyUsage[dayKey] = (dailyUsage[dayKey] ?? 0.0) + bytes;
      }
    }

    // Convert to data points
    final dataPoints = <TimeSeriesDataPoint>[];
    for (int i = 0; i < 7; i++) {
      final day = weekAgo.add(Duration(days: i));
      final dayKey = '${day.year}-${day.month}-${day.day}';
      final usageInMB = (dailyUsage[dayKey] ?? 0.0) / (1024 * 1024);
      dataPoints.add(TimeSeriesDataPoint(
        timestamp: day,
        value: usageInMB,
      ));
    }

    return TimeSeriesChartData(
      seriesName: name,
      dataPoints: dataPoints,
      color: color,
      showArea: true,
    );
  }

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else if (bytesPerSecond < 1024 * 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB/s';
    }
  }
}
