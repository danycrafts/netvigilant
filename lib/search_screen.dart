import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:shimmer/shimmer.dart';
import 'package:apptobe/core/widgets/common_widgets.dart';
import 'package:apptobe/core/constants/app_constants.dart';
import 'package:apptobe/core/services/app_usage_service.dart';
import 'package:apptobe/core/services/permission_manager.dart';
import 'package:apptobe/core/services/cached_app_service.dart';
import 'package:apptobe/core/architecture/base_widgets/base_screen.dart';
import 'package:apptobe/core/architecture/dependency_injection/service_locator.dart';
import 'package:apptobe/core/interfaces/app_repository.dart';
import 'package:apptobe/core/interfaces/app_usage_repository.dart';
import 'package:apptobe/core/interfaces/permission_repository.dart';
import 'package:apptobe/core/interfaces/notification_service.dart';
import 'package:apptobe/core/models/cached_app_info.dart';

class SearchScreen extends BaseScreen {
  const SearchScreen({super.key});

  @override
  String get title => 'Search';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => refresh(),
        tooltip: 'Refresh apps',
      ),
    ];
  }


  @override
  Widget buildBody(BuildContext context) {
    return const _SearchScreenBody();
  }

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> 
    with WidgetsBindingObserver, LoadingScreenMixin, ErrorHandlingMixin {
  final TextEditingController _searchController = TextEditingController();
  final CachedAppService _appService = CachedAppService();
  late final IAppRepository _appRepository;
  late final IUsageRepository _usageRepository;
  late final IPermissionRepository _permissionRepository;
  late final INotificationService _notificationService;
  List<CachedAppInfo> _apps = [];
  List<CachedAppInfo> _filteredApps = [];
  bool _hasUsagePermission = false;
  bool _showUsageInGrid = false;

  // SOLID - Use injected services

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // SOLID - Initialize dependencies
    _appRepository = getIt<IAppRepository>();
    _usageRepository = getIt<IUsageRepository>();
    _permissionRepository = getIt<IPermissionRepository>();
    _notificationService = getIt<INotificationService>();
    
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
    setLoading(true);
    try {
      await Future.wait([
        _fetchApps(),
        _checkUsagePermission(),
      ]);
    } catch (error) {
      handleError(error);
    } finally {
      setLoading(false);
    }
  }

  Future<void> _checkUsagePermission() async {
    final hasPermission = await AppUsageService.hasUsagePermission();
    final storedPermission = await PermissionManager.hasStoredUsagePermission();
    
    if (mounted) {
      setState(() {
        _hasUsagePermission = hasPermission || storedPermission;
      });
    }
  }

  Future<void> _fetchApps({bool forceRefresh = false}) async {
    try {
      final apps = await _appService.getAppsWithUsageStats(
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _apps = apps;
          _filteredApps = apps;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _apps = [];
          _filteredApps = [];
        });
        setLoading(false);
      }
    }
  }

  void _filterApps() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredApps = _apps.where((appInfo) {
        return appInfo.app.appName.toLowerCase().contains(query);
      }).toList();
    });
  }

  void setShowUsageInGrid(bool value) {
    setState(() {
      _showUsageInGrid = value;
    });
  }

  void _showAppDetails(CachedAppInfo appInfo) {
    final app = appInfo.app;
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
                        color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.2).round()),
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
                        final granted = await PermissionManager.requestAndStoreUsagePermission();
                        await _checkUsagePermission();
                        if (!mounted) return;
                        if (granted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Usage permission granted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Permission denied. Please enable it in settings.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      child: const Text('Grant Permission'),
                    )
                  else
                    TextButton(
                      onPressed: () async {
                        await PermissionManager.revokeUsagePermission();
                        await _checkUsagePermission();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Usage permission revoked'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      child: const Text('Revoke Permission'),
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (appInfo.usageInfo != null)
                _buildUsageStats(appInfo.usageInfo!)
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'No usage data available for this app.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Usage Statistics',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatsRow(Icons.timer, 'Total Usage Time', _formatDuration(usageInfo.totalTimeInForeground)),
            const SizedBox(height: 8),
            _buildStatsRow(Icons.launch, 'Launch Count', '${usageInfo.launchCount} times'),
            const SizedBox(height: 8),
            _buildStatsRow(Icons.history, 'Last Used', _formatDateTime(usageInfo.lastTimeUsed)),
          ],
        ),
      ),
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

  Widget _buildStatsRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.7).round()),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
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
    // Use mixin for loading overlay
    return buildWithLoading(
      const _SearchScreenBody(),
    );
  }
}

// SOLID - Separate body widget with single responsibility  
class _SearchScreenBody extends StatelessWidget {
  const _SearchScreenBody();

  @override
  Widget build(BuildContext context) {
    final searchState = context.findAncestorStateOfType<_SearchScreenState>();
    
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          _buildSearchField(searchState),
          const SizedBox(height: AppConstants.smallSpacing),
          _buildUsageToggle(context, searchState),
          const SizedBox(height: AppConstants.defaultSpacing),
          _buildAppsList(searchState),
        ],
      ),
    );
  }

  // DRY - Reusable search field widget
  Widget _buildSearchField(_SearchScreenState? searchState) {
    return AppTextField(
      label: 'Search',
      controller: searchState?._searchController ?? TextEditingController(),
      hintText: 'Enter your search query...',
      prefixIcon: const Icon(Icons.search),
    );
  }

  // DRY - Reusable usage toggle widget
  Widget _buildUsageToggle(BuildContext context, _SearchScreenState? searchState) {
    return Row(
      children: [
        const Text('Show usage in grid'),
        const SizedBox(width: 8),
        Switch(
          value: searchState?._showUsageInGrid ?? false,
          onChanged: (searchState?._hasUsagePermission ?? false)
              ? (value) {
                  searchState?.setShowUsageInGrid(value);
                }
              : null,
        ),
        const Spacer(),
        if (!(searchState?._hasUsagePermission ?? true))
          Text(
            'Grant usage permission to show usage stats',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round()),
            ),
          ),
      ],
    );
  }

  // DRY - Reusable apps list widget
  Widget _buildAppsList(_SearchScreenState? searchState) {
    return Expanded(
      child: searchState?.isLoading == true
          ? const _ShimmerAppGrid()
          : (searchState?._apps.isEmpty ?? true)
              ? const Center(child: Text('No apps found on this device.'))
              : _AppGrid(
                  apps: searchState?._filteredApps ?? [],
                  showUsage: searchState?._showUsageInGrid ?? false,
                  onAppTap: searchState?._showAppDetails,
                ),
    );
  }
}

// SOLID - Single responsibility widget for loading state
class _ShimmerAppGrid extends StatelessWidget {
  const _ShimmerAppGrid();

  @override
  Widget build(BuildContext context) {
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
        itemBuilder: (context, index) => _buildShimmerItem(context, isDarkMode),
      ),
    );
  }

  // DRY - Reusable shimmer item
  Widget _buildShimmerItem(BuildContext context, bool isDarkMode) {
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
  }
}

// SOLID - Single responsibility widget for app grid
class _AppGrid extends StatelessWidget {
  final List<CachedAppInfo> apps;
  final bool showUsage;
  final Function(CachedAppInfo)? onAppTap;

  const _AppGrid({
    required this.apps,
    required this.showUsage,
    this.onAppTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: apps.length,
      itemBuilder: (context, index) => _AppGridItem(
        appInfo: apps[index],
        showUsage: showUsage,
        onTap: () => onAppTap?.call(apps[index]),
      ),
    );
  }
}

// SOLID - Single responsibility widget for individual app item
class _AppGridItem extends StatelessWidget {
  final CachedAppInfo appInfo;
  final bool showUsage;
  final VoidCallback? onTap;

  const _AppGridItem({
    required this.appInfo,
    required this.showUsage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final app = appInfo.app;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface.withAlpha((255 * 0.5).round()),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAppIcon(context, app),
              const SizedBox(height: 4),
              _buildAppName(context, app),
              if (showUsage && appInfo.usageInfo != null)
                _buildUsageText(context, appInfo.usageInfo!),
            ],
          ),
        ),
      ),
    );
  }

  // DRY - Reusable app icon widget
  Widget _buildAppIcon(BuildContext context, Application app) {
    if (app is ApplicationWithIcon) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          app.icon,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.2).round()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.android,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
      );
    }
  }

  // DRY - Reusable app name widget
  Widget _buildAppName(BuildContext context, Application app) {
    return Text(
      app.appName,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 10,
      ),
    );
  }

  // DRY - Reusable usage text widget
  Widget _buildUsageText(BuildContext context, AppUsageInfo usageInfo) {
    return Text(
      _formatUsageForGrid(usageInfo),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 8,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // DRY - Reusable formatting method
  String _formatUsageForGrid(AppUsageInfo usageInfo) {
    final duration = usageInfo.totalTimeInForeground;
    if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
