import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netvigilant/core/services/app_discovery_service.dart';
import 'package:netvigilant/domain/entities/app_info_entity.dart';
import 'package:netvigilant/core/utils/logger.dart';

/// Provider for all installed applications
final allAppsProvider = FutureProvider.autoDispose.family<List<AppInfoEntity>, AppDiscoveryParams>(
  (ref, params) async {
    try {
      return await AppDiscoveryService.getAllInstalledApps(
        includeSystemApps: params.includeSystemApps,
        includeIcons: params.includeIcons,
        useCache: params.useCache,
      );
    } catch (e) {
      log('AllAppsProvider: Error loading apps: $e');
      rethrow;
    }
  },
);

/// Provider for apps with real-time usage data
final appsWithUsageProvider = FutureProvider.autoDispose<List<AppInfoEntity>>(
  (ref) async {
    try {
      return await AppDiscoveryService.getAllAppsWithUsage(useCache: false);
    } catch (e) {
      log('AppsWithUsageProvider: Error loading usage data: $e');
      rethrow;
    }
  },
);

/// Provider for app search results
final appSearchProvider = FutureProvider.autoDispose.family<List<AppInfoEntity>, AppSearchParams>(
  (ref, params) async {
    try {
      if (params.query.trim().isEmpty) {
        return [];
      }
      return await AppDiscoveryService.searchApps(
        query: params.query,
        includeSystemApps: params.includeSystemApps,
      );
    } catch (e) {
      log('AppSearchProvider: Error searching apps: $e');
      rethrow;
    }
  },
);

/// Provider for apps by category
final appsByCategoryProvider = FutureProvider.autoDispose.family<List<AppInfoEntity>, String>(
  (ref, category) async {
    try {
      return await AppDiscoveryService.getAppsByCategory(category);
    } catch (e) {
      log('AppsByCategoryProvider: Error loading category apps: $e');
      rethrow;
    }
  },
);

/// Provider for recently updated apps
final recentlyUpdatedAppsProvider = FutureProvider.autoDispose.family<List<AppInfoEntity>, int>(
  (ref, daysBack) async {
    try {
      return await AppDiscoveryService.getRecentlyUpdatedApps(daysBack: daysBack);
    } catch (e) {
      log('RecentlyUpdatedAppsProvider: Error loading recent apps: $e');
      rethrow;
    }
  },
);

/// Provider for available app categories
final appCategoriesProvider = FutureProvider.autoDispose<List<String>>(
  (ref) async {
    try {
      return await AppDiscoveryService.getAvailableCategories();
    } catch (e) {
      log('AppCategoriesProvider: Error loading categories: $e');
      rethrow;
    }
  },
);

/// Provider for app statistics
final appStatisticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    try {
      return await AppDiscoveryService.getAppStatistics();
    } catch (e) {
      log('AppStatisticsProvider: Error loading statistics: $e');
      rethrow;
    }
  },
);

/// StateNotifier for managing app filtering and sorting
class AppManagerNotifier extends StateNotifier<AppManagerState> {
  AppManagerNotifier() : super(AppManagerState());

  /// Update filter criteria
  void updateFilter({
    String? nameQuery,
    String? category,
    bool? isSystemApp,
    bool? isRunning,
    int? minSize,
    int? maxSize,
    DateTime? installedAfter,
    DateTime? updatedAfter,
  }) {
    state = state.copyWith(
      filterCriteria: state.filterCriteria.copyWith(
        nameQuery: nameQuery,
        category: category,
        isSystemApp: isSystemApp,
        isRunning: isRunning,
        minSize: minSize,
        maxSize: maxSize,
        installedAfter: installedAfter,
        updatedAfter: updatedAfter,
      ),
    );
  }

  /// Update sort criteria
  void updateSort(AppSortCriteria sortBy, bool ascending) {
    state = state.copyWith(
      sortCriteria: AppSortState(sortBy: sortBy, ascending: ascending),
    );
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      filterCriteria: AppFilterCriteria(),
    );
  }

  /// Apply filters and sorting to app list
  List<AppInfoEntity> processApps(List<AppInfoEntity> apps) {
    // Apply filters
    var filteredApps = AppDiscoveryService.filterApps(
      apps,
      nameQuery: state.filterCriteria.nameQuery,
      category: state.filterCriteria.category,
      isSystemApp: state.filterCriteria.isSystemApp,
      isRunning: state.filterCriteria.isRunning,
      minSize: state.filterCriteria.minSize,
      maxSize: state.filterCriteria.maxSize,
      installedAfter: state.filterCriteria.installedAfter,
      updatedAfter: state.filterCriteria.updatedAfter,
    );

    // Apply sorting
    return AppDiscoveryService.sortApps(
      filteredApps,
      sortBy: state.sortCriteria.sortBy,
      ascending: state.sortCriteria.ascending,
    );
  }
}

/// Provider for app manager state
final appManagerProvider = StateNotifierProvider<AppManagerNotifier, AppManagerState>(
  (ref) => AppManagerNotifier(),
);

/// Provider for processed (filtered and sorted) apps
final processedAppsProvider = Provider.autoDispose.family<AsyncValue<List<AppInfoEntity>>, AppDiscoveryParams>(
  (ref, params) {
    final appsAsyncValue = ref.watch(allAppsProvider(params));

    return appsAsyncValue.when(
      data: (apps) {
        final processedApps = ref.read(appManagerProvider.notifier).processApps(apps);
        return AsyncValue.data(processedApps);
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

/// Provider for top apps by various criteria
final topAppsProvider = Provider.autoDispose.family<AsyncValue<List<AppInfoEntity>>, TopAppsParams>(
  (ref, params) {
    final appsAsyncValue = ref.watch(appsWithUsageProvider);

    return appsAsyncValue.when(
      data: (apps) {
        final topApps = apps.topBy(params.criteria, params.count);
        return AsyncValue.data(topApps);
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

/// Provider for app cache statistics
final appCacheStatsProvider = Provider<Map<String, dynamic>>((ref) {
  return AppDiscoveryService.getCacheStats();
});

// Parameter classes for providers
class AppDiscoveryParams {
  final bool includeSystemApps;
  final bool includeIcons;
  final bool useCache;

  const AppDiscoveryParams({
    this.includeSystemApps = false,
    this.includeIcons = false,
    this.useCache = true,
  });
}

class AppSearchParams {
  final String query;
  final bool includeSystemApps;

  const AppSearchParams({
    required this.query,
    this.includeSystemApps = false,
  });
}

class TopAppsParams {
  final AppSortCriteria criteria;
  final int count;

  const TopAppsParams({
    required this.criteria,
    this.count = 10,
  });
}

// State classes
class AppManagerState {
  final AppFilterCriteria filterCriteria;
  final AppSortState sortCriteria;

  AppManagerState({
    AppFilterCriteria? filterCriteria,
    AppSortState? sortCriteria,
  })  : filterCriteria = filterCriteria ?? AppFilterCriteria(),
        sortCriteria = sortCriteria ?? AppSortState();

  AppManagerState copyWith({
    AppFilterCriteria? filterCriteria,
    AppSortState? sortCriteria,
  }) {
    return AppManagerState(
      filterCriteria: filterCriteria ?? this.filterCriteria,
      sortCriteria: sortCriteria ?? this.sortCriteria,
    );
  }
}

class AppFilterCriteria {
  final String? nameQuery;
  final String? category;
  final bool? isSystemApp;
  final bool? isRunning;
  final int? minSize;
  final int? maxSize;
  final DateTime? installedAfter;
  final DateTime? updatedAfter;

  AppFilterCriteria({
    this.nameQuery,
    this.category,
    this.isSystemApp,
    this.isRunning,
    this.minSize,
    this.maxSize,
    this.installedAfter,
    this.updatedAfter,
  });

  AppFilterCriteria copyWith({
    String? nameQuery,
    String? category,
    bool? isSystemApp,
    bool? isRunning,
    int? minSize,
    int? maxSize,
    DateTime? installedAfter,
    DateTime? updatedAfter,
  }) {
    return AppFilterCriteria(
      nameQuery: nameQuery ?? this.nameQuery,
      category: category ?? this.category,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      isRunning: isRunning ?? this.isRunning,
      minSize: minSize ?? this.minSize,
      maxSize: maxSize ?? this.maxSize,
      installedAfter: installedAfter ?? this.installedAfter,
      updatedAfter: updatedAfter ?? this.updatedAfter,
    );
  }

  bool get hasActiveFilters {
    return nameQuery?.isNotEmpty == true ||
        category != null ||
        isSystemApp != null ||
        isRunning != null ||
        minSize != null ||
        maxSize != null ||
        installedAfter != null ||
        updatedAfter != null;
  }
}

class AppSortState {
  final AppSortCriteria sortBy;
  final bool ascending;

  AppSortState({
    this.sortBy = AppSortCriteria.name,
    this.ascending = true,
  });

  AppSortState copyWith({
    AppSortCriteria? sortBy,
    bool? ascending,
  }) {
    return AppSortState(
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }
}