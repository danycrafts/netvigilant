import 'package:flutter/material.dart';
import 'package:netvigilant/core/theme/app_theme.dart';
import 'package:netvigilant/domain/entities/app_info_entity.dart';
import 'package:netvigilant/core/services/app_discovery_service.dart';

class AppInfoCard extends StatelessWidget {
  final AppInfoEntity app;
  final bool showUsageMetrics;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppInfoCard({
    super.key,
    required this.app,
    this.showUsageMetrics = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  // App icon or placeholder
                  _buildAppIcon(),
                  const SizedBox(width: 12),
                  
                  // App info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App name
                        Text(
                          app.appName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Package name
                        Text(
                          app.packageName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Basic info row
                        Row(
                          children: [
                            _buildInfoChip(app.category, Icons.category),
                            const SizedBox(width: 8),
                            _buildInfoChip(app.formattedAppSize, Icons.storage),
                            if (app.isSystemApp) ...[
                              const SizedBox(width: 8),
                              _buildInfoChip('System', Icons.settings, color: Colors.orange),
                            ],
                            if (app.isRunning) ...[
                              const SizedBox(width: 8),
                              _buildInfoChip('Running', Icons.play_circle, color: Colors.green),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Status indicators
                  Column(
                    children: [
                      if (app.isNewlyInstalled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      if (app.isRecentlyUpdated)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'UPDATED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      Text(
                        'v${app.versionName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              
              // Usage metrics (if enabled)
              if (showUsageMetrics && _hasUsageData()) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                _buildUsageMetrics(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: app.iconBase64 != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                AppDiscoveryService.decodeAppIcon(app.iconBase64)!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
              ),
            )
          : _buildDefaultIcon(),
    );
  }

  Widget _buildDefaultIcon() {
    return Icon(
      _getCategoryIcon(app.category),
      color: AppColors.primaryCyan,
      size: 24,
    );
  }

  Widget _buildInfoChip(String label, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? Colors.grey).withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color ?? Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color ?? Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageMetrics(BuildContext context) {
    return Column(
      children: [
        // Performance metrics
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                context,
                'CPU',
                '${app.cpuUsage.toStringAsFixed(1)}%',
                Icons.memory,
                _getUsageColor(app.cpuUsage, 100),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricItem(
                context,
                'Memory',
                app.formattedMemoryUsage,
                Icons.storage,
                _getUsageColor(app.memoryUsage, 1024),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricItem(
                context,
                'Battery',
                '${app.batteryUsage.toStringAsFixed(1)}%',
                Icons.battery_std,
                _getUsageColor(app.batteryUsage, 10),
              ),
            ),
          ],
        ),
        
        if (app.networkUsage > 0 || app.totalTimeInForeground > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (app.networkUsage > 0)
                Expanded(
                  child: _buildMetricItem(
                    context,
                    'Network',
                    app.formattedNetworkUsage,
                    Icons.network_check,
                    AppColors.primaryCyan,
                  ),
                ),
              if (app.networkUsage > 0 && app.totalTimeInForeground > 0)
                const SizedBox(width: 12),
              if (app.totalTimeInForeground > 0)
                Expanded(
                  child: _buildMetricItem(
                    context,
                    'Screen Time',
                    app.formattedTimeInForeground,
                    Icons.access_time,
                    Colors.purple,
                  ),
                ),
            ],
          ),
        ],
        
        // Usage intensity indicator
        if (app.usageIntensity > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 14,
                color: _getIntensityColor(app.usageCategory),
              ),
              const SizedBox(width: 4),
              Text(
                '${app.usageCategory} Usage',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getIntensityColor(app.usageCategory),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasUsageData() {
    return app.cpuUsage > 0 ||
           app.memoryUsage > 0 ||
           app.batteryUsage > 0 ||
           app.networkUsage > 0 ||
           app.totalTimeInForeground > 0;
  }

  Color _getUsageColor(double value, double maxValue) {
    final percentage = (value / maxValue) * 100;
    
    if (percentage > 75) {
      return Colors.red;
    } else if (percentage > 50) {
      return Colors.orange;
    } else if (percentage > 25) {
      return Colors.yellow.shade700;
    } else {
      return Colors.green;
    }
  }

  Color _getIntensityColor(String category) {
    switch (category.toLowerCase()) {
      case 'heavy':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'light':
        return Colors.yellow.shade700;
      default:
        return Colors.green;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'game':
        return Icons.games;
      case 'audio':
        return Icons.audiotrack;
      case 'video':
        return Icons.video_collection;
      case 'image':
        return Icons.image;
      case 'social':
        return Icons.people;
      case 'news':
        return Icons.newspaper;
      case 'maps':
        return Icons.map;
      case 'productivity':
        return Icons.work;
      case 'system':
        return Icons.settings;
      default:
        return Icons.apps;
    }
  }
}