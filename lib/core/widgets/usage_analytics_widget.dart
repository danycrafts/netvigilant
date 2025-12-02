import 'package:flutter/material.dart';
import 'package:apptobe/core/services/cached_app_service.dart';
import 'package:apptobe/core/services/app_usage_service.dart';
import 'package:apptobe/core/constants/app_constants.dart';
import 'package:apptobe/core/utils/app_logger.dart';

class UsageAnalyticsWidget extends StatefulWidget {
  const UsageAnalyticsWidget({super.key});

  @override
  State<UsageAnalyticsWidget> createState() => _UsageAnalyticsWidgetState();
}

class _UsageAnalyticsWidgetState extends State<UsageAnalyticsWidget> {
  final CachedAppService _appService = CachedAppService();
  UsageStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Defer loading to avoid blocking UI build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUsageStats();
      }
    });
  }

  Future<void> _loadUsageStats() async {
    try {
      // Add timeout to prevent hanging
      final appsWithUsage = await _appService.getAppsWithUsageStats()
          .timeout(const Duration(seconds: 10));
      
      final appsWithData = appsWithUsage
          .where((app) => app.usageInfo != null)
          .toList();

      if (appsWithData.isEmpty) {
        if (mounted) {
          setState(() {
            _stats = null;
            _isLoading = false;
          });
        }
        return;
      }

      final totalUsage = appsWithData.fold<Duration>(
        Duration.zero,
        (total, app) => total + app.usageInfo!.totalTimeInForeground,
      );

      final totalLaunches = appsWithData.fold<int>(
        0,
        (total, app) => total + app.usageInfo!.launchCount,
      );

      final mostUsedApp = appsWithData.reduce((a, b) =>
          a.usageInfo!.totalTimeInForeground.compareTo(
              b.usageInfo!.totalTimeInForeground) > 0 ? a : b);

      final recentlyUsedApps = appsWithData
        ..sort((a, b) => b.usageInfo!.lastTimeUsed.compareTo(a.usageInfo!.lastTimeUsed));

      if (mounted) {
        setState(() {
          _stats = UsageStats(
            totalUsage: totalUsage,
            totalLaunches: totalLaunches,
            totalApps: appsWithData.length,
            mostUsedApp: mostUsedApp,
            recentlyUsedApps: recentlyUsedApps.take(3).toList(),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load usage analytics', error: e, tag: 'UsageAnalyticsWidget');
      if (mounted) {
        setState(() {
          _stats = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Usage Analytics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _loadUsageStats();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_stats == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No analytics available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Grant usage permission to see detailed analytics',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildAnalytics(_stats!),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalytics(UsageStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Screen Time',
                _formatDuration(stats.totalUsage),
                Icons.schedule,
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'App Launches',
                '${stats.totalLaunches}',
                Icons.launch,
                Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Apps',
                '${stats.totalApps}',
                Icons.apps,
                Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Most Used',
                stats.mostUsedApp.app.appName,
                Icons.star,
                Colors.orange,
                isText: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recently Used',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...stats.recentlyUsedApps.map((app) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        app.app.appName,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatRecentTime(app.usageInfo!.lastTimeUsed),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool isText = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            isText ? value : value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _formatRecentTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class UsageStats {
  final Duration totalUsage;
  final int totalLaunches;
  final int totalApps;
  final CachedAppInfo mostUsedApp;
  final List<CachedAppInfo> recentlyUsedApps;

  UsageStats({
    required this.totalUsage,
    required this.totalLaunches,
    required this.totalApps,
    required this.mostUsedApp,
    required this.recentlyUsedApps,
  });
}