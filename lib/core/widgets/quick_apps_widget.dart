import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:apptobe/core/services/cached_app_service.dart';
import 'package:apptobe/core/services/app_usage_service.dart';
import 'package:apptobe/core/constants/app_constants.dart';
import 'package:apptobe/core/utils/app_logger.dart';

class QuickAppsWidget extends StatefulWidget {
  const QuickAppsWidget({super.key});

  @override
  State<QuickAppsWidget> createState() => _QuickAppsWidgetState();
}

class _QuickAppsWidgetState extends State<QuickAppsWidget> {
  final CachedAppService _appService = CachedAppService();
  List<CachedAppInfo> _topApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Defer loading to avoid blocking UI build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTopApps();
      }
    });
  }

  Future<void> _loadTopApps() async {
    try {
      // Add timeout to prevent hanging
      final appsWithUsage = await _appService.getAppsWithUsageStats()
          .timeout(const Duration(seconds: 10));
      
      final sortedApps = appsWithUsage
          .where((appInfo) => appInfo.usageInfo != null && 
                              appInfo.usageInfo!.totalTimeInForeground.inMinutes > 0)
          .toList()
        ..sort((a, b) => b.usageInfo!.totalTimeInForeground
                          .compareTo(a.usageInfo!.totalTimeInForeground));

      if (mounted) {
        setState(() {
          _topApps = sortedApps.take(6).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load top apps', error: e, tag: 'QuickAppsWidget');
      if (mounted) {
        setState(() {
          _topApps = [];
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
                  Icons.flash_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Access',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _loadTopApps();
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
            else if (_topApps.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.apps,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No usage data available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Grant usage permission to see your most used apps',
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: _topApps.length,
                itemBuilder: (context, index) {
                  final appInfo = _topApps[index];
                  final app = appInfo.app;
                  return _buildAppTile(app, appInfo.usageInfo);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppTile(Application app, AppUsageInfo? usageInfo) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (app is ApplicationWithIcon) {
            try {
              await DeviceApps.openApp(app.packageName);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not open ${app.appName}')),
                );
              }
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (app is ApplicationWithIcon)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    app.icon,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.android,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                app.appName,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (usageInfo != null)
                Text(
                  _formatUsage(usageInfo.totalTimeInForeground),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatUsage(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}