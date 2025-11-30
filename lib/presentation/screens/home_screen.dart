import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netvigilant/presentation/providers/network_providers.dart';
import 'package:netvigilant/presentation/providers/database_providers.dart';
import 'package:netvigilant/presentation/widgets/real_time_speed_gauge.dart';
import 'package:netvigilant/presentation/screens/app_detail_screen.dart';
import 'package:netvigilant/domain/entities/real_time_metrics_entity.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realTimeMetricsAsyncValue = ref.watch(realTimeTrafficProvider);
    final historicalDataAsyncValue = ref.watch(historicalAppUsageProvider);
    final todayDataUsage = ref.watch(todayDataUsageProvider);
    final todayActiveApps = ref.watch(todayActiveAppsProvider);
    final todayPeakSpeed = ref.watch(todayPeakSpeedProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Simplified AppBar
          SliverAppBar(
            title: const Text('Overview'), // A simple title
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0.5,
          ),

          // Real-Time Speed Gauge
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: realTimeMetricsAsyncValue.when(
                data: (metrics) => RealTimeSpeedGauge(
                  uplinkSpeed: metrics.uplinkSpeed,
                  downlinkSpeed: metrics.downlinkSpeed,
                ),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text('Error loading speed data', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(error.toString(), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Dedicated Speed Display
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: realTimeMetricsAsyncValue.when(
                data: (metrics) => _buildSpeedDisplayCard(context, metrics),
                loading: () => Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
                error: (error, stack) => Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Connection Error: ${error.toString()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // Today's Usage Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Usage',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // Three columns for usage stats
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.8, // Adjust as needed
                          ),
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            switch (index) {
                              case 0:
                                return todayDataUsage.when(
                                  data: (usage) => _buildUsageStat(
                                    context,
                                    'Total Data',
                                    formatBytes(usage),
                                    Icons.data_usage,
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                  loading: () => _buildLoadingUsageStat(context, 'Total Data', Icons.data_usage),
                                  error: (_, __) => _buildUsageStat(
                                    context,
                                    'Total Data',
                                    '0 B',
                                    Icons.data_usage,
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              case 1:
                                return todayActiveApps.when(
                                  data: (apps) => _buildUsageStat(
                                    context,
                                    'Apps Active',
                                    apps.toString(),
                                    Icons.apps,
                                    Theme.of(context).colorScheme.secondary,
                                  ),
                                  loading: () => _buildLoadingUsageStat(context, 'Apps Active', Icons.apps),
                                  error: (_, __) => _buildUsageStat(
                                    context,
                                    'Apps Active',
                                    '0',
                                    Icons.apps,
                                    Theme.of(context).colorScheme.secondary,
                                  ),
                                );
                              case 2:
                                return todayPeakSpeed.when(
                                  data: (speed) => _buildUsageStat(
                                    context,
                                    'Peak Speed',
                                    '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s',
                                    Icons.speed,
                                    Theme.of(context).colorScheme.tertiary,
                                  ),
                                  loading: () => _buildLoadingUsageStat(context, 'Peak Speed', Icons.speed),
                                  error: (_, __) => _buildUsageStat(
                                    context,
                                    'Peak Speed',
                                    '0.0 MB/s',
                                    Icons.speed,
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
              ),

              const SizedBox(height: 16),

              // Top Apps by Usage
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Top Apps by Data Usage',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              
              historicalDataAsyncValue.when(
                data: (apps) => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: apps.length.clamp(0, 5), // Show top 5 apps
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
                          child: Text(
                            app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(app.appName),
                        subtitle: Text('Battery Impact: ${app.batteryUsage.toStringAsFixed(1)}%'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppDetailScreen(
                                packageName: app.packageName,
                                appName: app.appName,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 8),
                          Text('Unable to load app usage data', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('Make sure usage access permission is granted', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100), // Extra space at bottom
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStat(BuildContext context, String label, String value, IconData icon, Color itemColor) {
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

  Widget _buildLoadingUsageStat(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
          width: 40,
          height: 16,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildSpeedDisplayCard(BuildContext context, RealTimeMetricsEntity metrics) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSpeedItem(
              context,
              'Upload',
              '${(metrics.uplinkSpeed / 1024).toStringAsFixed(1)} KB/s',
              Icons.arrow_upward_rounded,
              theme.colorScheme.secondary, // Or a custom accent color
            ),
            Container(
              height: 40,
              width: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            _buildSpeedItem(
              context,
              'Download',
              '${(metrics.downlinkSpeed / 1024).toStringAsFixed(1)} KB/s',
              Icons.arrow_downward_rounded,
              theme.colorScheme.primary, // Or a custom accent color
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedItem(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}