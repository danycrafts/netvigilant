import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:shimmer/shimmer.dart';
import 'package:netvigilant/core/widgets/common_widgets.dart';
import 'package:netvigilant/core/constants/app_constants.dart';
import 'package:netvigilant/core/services/app_usage_service.dart';
import 'package:netvigilant/core/services/permission_manager.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  List<Application> _apps = [];
  List<Application> _filteredApps = [];
  bool _isLoading = true;
  bool _hasUsagePermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();
    _searchController.addListener(_filterApps);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkUsagePermission();
    }
  }

  Future<void> _initializeScreen() async {
    await _fetchApps();
    await _checkUsagePermission();
  }

  Future<void> _checkUsagePermission() async {
    final hasPermission = await AppUsageService.hasUsagePermission();
    if (mounted) {
      setState(() {
        _hasUsagePermission = hasPermission;
      });
    }
  }

  Future<void> _fetchApps() async {
    try {
      final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: true, // Show all apps including system apps
        onlyAppsWithLaunchIntent:
            false, // Show all apps even without launch intent
      );
      if (mounted) {
        setState(() {
          _apps = apps;
          _filteredApps = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _apps = [];
          _filteredApps = [];
          _isLoading = false;
        });
      }
    }
  }

  void _filterApps() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredApps = _apps.where((app) {
        return app.appName.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showAppDetails(Application app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (app is ApplicationWithIcon)
                    Image.memory(app.icon, width: 48, height: 48)
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.primary.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.android,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.appName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          app.packageName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'App Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Version', app.versionName ?? 'Unknown'),
              _buildInfoRow('Package Name', app.packageName),
              _buildInfoRow('System App', app.systemApp ? 'Yes' : 'No'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Usage Statistics',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (!_hasUsagePermission)
                    TextButton(
                      onPressed: () async {
                        await PermissionManager.requestAndStoreUsagePermission();
                        await _checkUsagePermission();
                      },
                      child: const Text('Grant Permission'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_hasUsagePermission)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Usage statistics require app usage permission. Tap "Grant Permission" to enable.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                FutureBuilder<AppUsageInfo?>(
                  future: AppUsageService.getAppUsageInfo(app.packageName),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasData && snapshot.data != null) {
                      return _buildUsageStats(snapshot.data!);
                    } else {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'No usage data available for this app.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStats(AppUsageInfo usageInfo) {
    return Column(
      children: [
        _buildInfoRow(
            'Total Usage Time', _formatDuration(usageInfo.totalTimeInForeground)),
        _buildInfoRow('Launch Count', usageInfo.launchCount.toString()),
        _buildInfoRow('Last Used', _formatDateTime(usageInfo.lastTimeUsed)),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Search',
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            AppTextField(
              label: 'Search',
              controller: _searchController,
              hintText: 'Enter your search query...',
              prefixIcon: const Icon(Icons.search),
            ),
            const SizedBox(height: AppConstants.defaultSpacing),
            Expanded(
              child: _isLoading
                  ? _buildShimmerGrid()
                  : _apps.isEmpty
                      ? const Center(
                          child: Text('No apps found on this device.'))
                      : _buildAppGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[500]! : Colors.grey[100]!,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 16,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 8,
                width: 40,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _filteredApps.length,
      itemBuilder: (context, index) {
        final app = _filteredApps[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAppDetails(app),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surface.withAlpha(128),
              ),
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
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.android,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    app.appName,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
