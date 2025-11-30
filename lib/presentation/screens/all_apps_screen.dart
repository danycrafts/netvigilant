import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netvigilant/core/theme/app_theme.dart';
import 'package:netvigilant/core/services/app_discovery_service.dart';
import 'package:netvigilant/domain/entities/app_info_entity.dart';
import 'package:netvigilant/presentation/providers/app_discovery_providers.dart';
import 'package:netvigilant/presentation/widgets/app_info_card.dart';
import 'package:netvigilant/presentation/widgets/app_search_bar.dart';

class AllAppsScreen extends ConsumerStatefulWidget {
  const AllAppsScreen({super.key});

  @override
  ConsumerState<AllAppsScreen> createState() => _AllAppsScreenState();
}

class _AllAppsScreenState extends ConsumerState<AllAppsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _includeSystemApps = false;
  AppSortCriteria _sortBy = AppSortCriteria.name;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Applications'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshApps,
            tooltip: 'Refresh Apps',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: _handleSortSelection,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'size', child: Text('Sort by Size')),
              const PopupMenuItem(value: 'category', child: Text('Sort by Category')),
              const PopupMenuItem(value: 'install', child: Text('Sort by Install Date')),
              const PopupMenuItem(value: 'update', child: Text('Sort by Update Date')),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'order',
                child: Row(
                  children: [
                    Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                    const SizedBox(width: 8),
                    Text(_sortAscending ? 'Ascending' : 'Descending'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: _handleFilterSelection,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'system',
                child: Row(
                  children: [
                    Checkbox(
                      value: _includeSystemApps,
                      onChanged: (value) => _toggleSystemApps(),
                    ),
                    const Text('Include System Apps'),
                  ],
                ),
              ),
              const PopupMenuItem(value: 'clear', child: Text('Clear Filters')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Apps'),
            Tab(text: 'With Usage'),
            Tab(text: 'Categories'),
            Tab(text: 'Statistics'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppSearchBar(
              controller: _searchController,
              onChanged: _updateSearchQuery,
              onClear: _clearSearch,
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllAppsTab(),
                _buildUsageAppsTab(),
                _buildCategoriesTab(),
                _buildStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllAppsTab() {
    final params = AppDiscoveryParams(
      includeSystemApps: _includeSystemApps,
      includeIcons: false, // Icons can slow down loading
      useCache: true,
    );

    final appsAsyncValue = ref.watch(allAppsProvider(params));

    return appsAsyncValue.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Discovering installed applications...'),
          ],
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text('Error loading apps: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshApps,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (apps) {
        final filteredApps = _filterAndSortApps(apps);
        
        if (filteredApps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty 
                    ? 'No apps found matching "$_searchQuery"'
                    : 'No apps found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _clearSearch,
                    child: const Text('Clear search'),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Results summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '${filteredApps.length} apps found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Apps list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: filteredApps.length,
                itemBuilder: (context, index) {
                  final app = filteredApps[index];
                  return AppInfoCard(
                    app: app,
                    onTap: () => _showAppDetails(app),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUsageAppsTab() {
    final appsAsyncValue = ref.watch(appsWithUsageProvider);

    return appsAsyncValue.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading app usage data...'),
          ],
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text('Error loading usage data: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(appsWithUsageProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (apps) {
        final filteredApps = _filterAndSortApps(apps);
        
        if (filteredApps.isEmpty) {
          return const Center(
            child: Text('No usage data available'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: filteredApps.length,
          itemBuilder: (context, index) {
            final app = filteredApps[index];
            return AppInfoCard(
              app: app,
              showUsageMetrics: true,
              onTap: () => _showAppDetails(app),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    final categoriesAsyncValue = ref.watch(appCategoriesProvider);

    return categoriesAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error loading categories: $error'),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(
            child: Text('No categories available'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              child: ListTile(
                leading: Icon(_getCategoryIcon(category)),
                title: Text(category),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showCategoryApps(category),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    final statsAsyncValue = ref.watch(appStatisticsProvider);

    return statsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error loading statistics: $error'),
      ),
      data: (stats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App Statistics',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              // Overview cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Apps',
                      '${stats['totalApps'] ?? 0}',
                      Icons.apps,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'User Apps',
                      '${stats['userApps'] ?? 0}',
                      Icons.person,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'System Apps',
                      '${stats['systemApps'] ?? 0}',
                      Icons.settings,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Categories',
                      '${stats['categoriesCount'] ?? 0}',
                      Icons.category,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Total size card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storage, color: AppColors.primaryCyan),
                          const SizedBox(width: 8),
                          Text(
                            'Storage Usage',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Size: ${_formatBytes(stats['totalSize'] ?? 0)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        'Average Size: ${_formatBytes(stats['averageSize'] ?? 0)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Categories breakdown
              if (stats['categories'] != null) ...[
                Text(
                  'Apps by Category',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...((stats['categories'] as Map<String, dynamic>).entries.map(
                  (entry) => Card(
                    child: ListTile(
                      leading: Icon(_getCategoryIcon(entry.key)),
                      title: Text(entry.key),
                      trailing: Text('${entry.value} apps'),
                    ),
                  ),
                )),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: AppColors.primaryCyan),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<AppInfoEntity> _filterAndSortApps(List<AppInfoEntity> apps) {
    var filteredApps = apps;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredApps = filteredApps.where((app) {
        return app.appName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               app.packageName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply sorting
    return AppDiscoveryService.sortApps(
      filteredApps,
      sortBy: _sortBy,
      ascending: _sortAscending,
    );
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _toggleSystemApps() {
    setState(() {
      _includeSystemApps = !_includeSystemApps;
    });
  }

  void _handleSortSelection(String value) {
    setState(() {
      switch (value) {
        case 'name':
          _sortBy = AppSortCriteria.name;
          break;
        case 'size':
          _sortBy = AppSortCriteria.size;
          break;
        case 'category':
          _sortBy = AppSortCriteria.category;
          break;
        case 'install':
          _sortBy = AppSortCriteria.installTime;
          break;
        case 'update':
          _sortBy = AppSortCriteria.updateTime;
          break;
        case 'order':
          _sortAscending = !_sortAscending;
          break;
      }
    });
  }

  void _handleFilterSelection(String value) {
    switch (value) {
      case 'system':
        _toggleSystemApps();
        break;
      case 'clear':
        setState(() {
          _includeSystemApps = false;
          _searchQuery = '';
          _searchController.clear();
        });
        break;
    }
  }

  Future<void> _refreshApps() async {
    await AppDiscoveryService.clearCache();
    ref.invalidate(allAppsProvider);
    ref.invalidate(appsWithUsageProvider);
    ref.invalidate(appCategoriesProvider);
    ref.invalidate(appStatisticsProvider);
  }

  void _showAppDetails(AppInfoEntity app) {
    // Navigate to app detail screen
    // This would be implemented as part of the app detail functionality
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app.appName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              app.packageName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('Size: ${app.formattedAppSize}'),
            Text('Category: ${app.category}'),
            Text('Version: ${app.versionName}'),
            if (app.isRunning) const Text('Status: Running'),
            if (app.cpuUsage > 0) Text('CPU Usage: ${app.cpuUsage.toStringAsFixed(1)}%'),
            if (app.memoryUsage > 0) Text('Memory Usage: ${app.formattedMemoryUsage}'),
          ],
        ),
      ),
    );
  }

  void _showCategoryApps(String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('$category Apps')),
          body: Consumer(
            builder: (context, ref, child) {
              final appsAsyncValue = ref.watch(appsByCategoryProvider(category));
              
              return appsAsyncValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error loading apps: $error'),
                ),
                data: (apps) => ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return AppInfoCard(
                      app: app,
                      onTap: () => _showAppDetails(app),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
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

  String _formatBytes(dynamic bytes) {
    final size = (bytes as num?)?.toInt() ?? 0;
    if (size < 1024) {
      return '${size}B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)}KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }
}