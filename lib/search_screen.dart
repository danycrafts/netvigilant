import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:usage_tracker/usage_tracker.dart';
import 'package:apptobe/core/widgets/common_widgets.dart';
import 'package:apptobe/core/constants/app_constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  List<Application> _apps = [];
  List<Application> _filteredApps = [];
  bool _isLoading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionsAndFetchApps();
    _searchController.addListener(_filterApps);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionStatus();
    }
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.appUsage.status;
    if (status.isGranted) {
      if (_apps.isEmpty && !_isLoading) {
        setState(() {
          _isLoading = true;
          _permissionDenied = false;
        });
        _fetchApps();
      }
    }
  }

  Future<void> _requestPermissionsAndFetchApps() async {
    final status = await Permission.appUsage.request();
    if (status.isGranted) {
      _fetchApps();
    } else {
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
      });
    }
  }

  Future<void> _fetchApps() async {
    final apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );
    if (mounted) {
      setState(() {
        _apps = apps;
        _filteredApps = apps;
        _isLoading = false;
        _permissionDenied = false;
      });
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

  void _showAppDetails(Application app) async {
    final usageData = await UsageTracker.getAppUsageData(
      DateTime.now().subtract(const Duration(days: 1)),
      DateTime.now(),
    );
    final appUsage = usageData.firstWhere(
      (usage) => usage['packageName'] == app.packageName,
      orElse: () => {'foregroundTime': 0},
    );
    final foregroundTime = Duration(milliseconds: appUsage['foregroundTime']);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${app.appName}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Package: ${app.packageName}'),
              const SizedBox(height: 8),
              Text('Version: ${app.versionName}'),
              const SizedBox(height: 8),
              Text('Foreground Time (24h): ${foregroundTime.inMinutes} minutes'),
            ],
          ),
        );
      },
    );
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
                  : _permissionDenied
                      ? const Center(child: Text('Permission denied. Please grant usage access in settings.'))
                      : _buildAppGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
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
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              Container(
                height: 8,
                width: 40,
                color: Colors.white,
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
        return GestureDetector(
          onTap: () => _showAppDetails(app),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (app is ApplicationWithIcon)
                Image.memory(app.icon, width: 40, height: 40),
              const SizedBox(height: 4),
              Text(
                app.appName,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
