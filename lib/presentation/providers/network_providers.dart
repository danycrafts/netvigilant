import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netvigilant/core/di/service_locator.dart';
import 'package:netvigilant/core/usecases/usecase.dart';
import 'package:netvigilant/domain/entities/real_time_metrics_entity.dart';
import 'package:netvigilant/domain/entities/app_usage_entity.dart';
import 'package:netvigilant/domain/entities/network_traffic_entity.dart';
import 'package:netvigilant/domain/repositories/background_monitoring_repository.dart';
import 'package:netvigilant/domain/repositories/network_repository.dart';
import 'package:netvigilant/domain/usecases/get_app_usage.dart';
import 'package:netvigilant/domain/usecases/get_network_usage.dart';
import 'package:netvigilant/domain/usecases/get_real_time_metrics.dart';
import 'package:netvigilant/domain/usecases/manage_monitoring.dart';
import 'package:netvigilant/domain/usecases/manage_permissions.dart';

// Repository providers
final networkRepositoryProvider = Provider<AbstractNetworkRepository>((ref) {
  return sl<AbstractNetworkRepository>();
});

final backgroundMonitoringRepositoryProvider = Provider<BackgroundMonitoringRepository>((ref) {
  return sl<BackgroundMonitoringRepository>();
});

// Use case providers
final getNetworkUsageProvider = Provider<GetNetworkUsage>((ref) {
  return sl<GetNetworkUsage>();
});

final getAppUsageProvider = Provider<GetAppUsage>((ref) {
  return sl<GetAppUsage>();
});

final getRealTimeMetricsProvider = Provider<GetRealTimeMetrics>((ref) {
  return sl<GetRealTimeMetrics>();
});

final startContinuousMonitoringProvider = Provider<StartContinuousMonitoring>((ref) {
  return sl<StartContinuousMonitoring>();
});

final stopContinuousMonitoringProvider = Provider<StopContinuousMonitoring>((ref) {
  return sl<StopContinuousMonitoring>();
});

final startBackgroundMonitoringProvider = Provider<StartBackgroundMonitoring>((ref) {
  return sl<StartBackgroundMonitoring>();
});

final stopBackgroundMonitoringProvider = Provider<StopBackgroundMonitoring>((ref) {
  return sl<StopBackgroundMonitoring>();
});

final checkBackgroundMonitoringStatusProvider = Provider<CheckBackgroundMonitoringStatus>((ref) {
  return sl<CheckBackgroundMonitoringStatus>();
});

final checkUsageStatsPermissionProvider = Provider<CheckUsageStatsPermission>((ref) {
  return sl<CheckUsageStatsPermission>();
});

final requestUsageStatsPermissionProvider = Provider<RequestUsageStatsPermission>((ref) {
  return sl<RequestUsageStatsPermission>();
});

// StreamProvider for real-time traffic metrics with auto-start
final realTimeTrafficProvider = StreamProvider<RealTimeMetricsEntity>((ref) {
  final getRealTimeMetrics = ref.watch(getRealTimeMetricsProvider);
  final repository = ref.watch(networkRepositoryProvider);
  
  return Stream.fromFuture(repository.startContinuousMonitoring())
      .asyncExpand((_) => getRealTimeMetrics.call(const NoParams())
          .map((result) => result.fold(
                (failure) => throw Exception(failure.toString()),
                (metrics) => metrics,
              )))
      .handleError((error) {
        return RealTimeMetricsEntity(
          uplinkSpeed: 0.0,
          downlinkSpeed: 0.0,
        );
      });
});

// FutureProvider for today's app usage data
final historicalAppUsageProvider = FutureProvider<List<AppUsageEntity>>((ref) async {
  try {
    final getAppUsage = ref.watch(getAppUsageProvider);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    final result = await getAppUsage.call(GetAppUsageParams(
      start: startOfDay,
      end: now,
    ));
    
    return result.fold(
      (failure) => [],
      (apps) {
        apps.sort((a, b) => b.networkUsage.compareTo(a.networkUsage));
        return apps;
      },
    );
  } catch (e) {
    return <AppUsageEntity>[];
  }
});

// FutureProvider for historical network usage
final historicalNetworkUsageProvider = FutureProvider.family<List<NetworkTrafficEntity>, ({DateTime start, DateTime end})>((ref, args) async {
  final getNetworkUsage = ref.watch(getNetworkUsageProvider);
  
  final result = await getNetworkUsage.call(GetNetworkUsageParams(
    start: args.start,
    end: args.end,
  ));
  
  return result.fold(
    (failure) => [],
    (usage) => usage,
  );
});

// Provider for weekly network usage
final weeklyNetworkUsageProvider = FutureProvider<List<NetworkTrafficEntity>>((ref) async {
  final getNetworkUsage = ref.watch(getNetworkUsageProvider);
  final now = DateTime.now();
  final startOfWeek = now.subtract(const Duration(days: 7));
  
  final result = await getNetworkUsage.call(GetNetworkUsageParams(
    start: startOfWeek,
    end: now,
  ));
  
  return result.fold(
    (failure) => [],
    (usage) => usage,
  );
});

// StateNotifierProvider for managing dashboard state
class DashboardState {
  final bool isMonitoring;
  final bool isBackgroundMonitoring;
  final bool hasPermission;
  final String? error;
  final bool isLoading;

  const DashboardState({
    this.isMonitoring = false,
    this.isBackgroundMonitoring = false,
    this.hasPermission = false,
    this.error,
    this.isLoading = false,
  });

  DashboardState copyWith({
    bool? isMonitoring,
    bool? isBackgroundMonitoring,
    bool? hasPermission,
    String? error,
    bool? isLoading,
  }) {
    return DashboardState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      isBackgroundMonitoring: isBackgroundMonitoring ?? this.isBackgroundMonitoring,
      hasPermission: hasPermission ?? this.hasPermission,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final CheckUsageStatsPermission _checkPermissionUseCase;
  final RequestUsageStatsPermission _requestPermissionUseCase;
  final StartContinuousMonitoring _startMonitoringUseCase;
  final StopContinuousMonitoring _stopMonitoringUseCase;
  final StartBackgroundMonitoring _startBackgroundMonitoringUseCase;
  final StopBackgroundMonitoring _stopBackgroundMonitoringUseCase;
  final CheckBackgroundMonitoringStatus _checkBackgroundStatusUseCase;

  DashboardNotifier(
    this._checkPermissionUseCase,
    this._requestPermissionUseCase,
    this._startMonitoringUseCase,
    this._stopMonitoringUseCase,
    this._startBackgroundMonitoringUseCase,
    this._stopBackgroundMonitoringUseCase,
    this._checkBackgroundStatusUseCase,
  ) : super(const DashboardState()) {
    _checkInitialStates();
  }

  Future<void> _checkInitialStates() async {
    state = state.copyWith(isLoading: true);
    await _checkPermission();
    await _checkBackgroundMonitoringStatus();
    state = state.copyWith(isLoading: false);
  }

  Future<void> _checkPermission() async {
    final result = await _checkPermissionUseCase.call(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(error: failure.toString()),
      (hasPermission) => state = state.copyWith(hasPermission: hasPermission),
    );
  }

  Future<void> _checkBackgroundMonitoringStatus() async {
    final result = await _checkBackgroundStatusUseCase.call(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(error: failure.toString()),
      (isActive) => state = state.copyWith(isBackgroundMonitoring: isActive),
    );
  }

  Future<void> startMonitoring() async {
    state = state.copyWith(isLoading: true);
    final result = await _startMonitoringUseCase.call(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(error: failure.toString(), isLoading: false),
      (_) => state = state.copyWith(isMonitoring: true, error: null, isLoading: false),
    );
  }

  Future<void> stopMonitoring() async {
    state = state.copyWith(isLoading: true);
    final result = await _stopMonitoringUseCase.call(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(error: failure.toString(), isLoading: false),
      (_) => state = state.copyWith(isMonitoring: false, error: null, isLoading: false),
    );
  }

  Future<void> startBackgroundMonitoring() async {
    state = state.copyWith(isLoading: true);
    final result = await _startBackgroundMonitoringUseCase.call(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(error: failure.toString(), isLoading: false),
      (_) => state = state.copyWith(isBackgroundMonitoring: true, error: null, isLoading: false),
    );
  }

  Future<void> stopBackgroundMonitoring() async {
    state = state.copyWith(isLoading: true);
    final result = await _stopBackgroundMonitoringUseCase.call(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(error: failure.toString(), isLoading: false),
      (_) => state = state.copyWith(isBackgroundMonitoring: false, error: null, isLoading: false),
    );
  }

  Future<void> requestPermission() async {
    state = state.copyWith(isLoading: true);
    final result = await _requestPermissionUseCase.call(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(error: failure.toString(), isLoading: false),
      (_) async {
        await _checkPermission();
        state = state.copyWith(error: null, isLoading: false);
      },
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(
    ref.watch(checkUsageStatsPermissionProvider),
    ref.watch(requestUsageStatsPermissionProvider),
    ref.watch(startContinuousMonitoringProvider),
    ref.watch(stopContinuousMonitoringProvider),
    ref.watch(startBackgroundMonitoringProvider),
    ref.watch(stopBackgroundMonitoringProvider),
    ref.watch(checkBackgroundMonitoringStatusProvider),
  );
});

// Provider for app-specific usage data
final appUsageProvider = FutureProvider.family<List<NetworkTrafficEntity>, String>((ref, packageName) async {
  final getNetworkUsage = ref.watch(getNetworkUsageProvider);
  final now = DateTime.now();
  final startOfWeek = now.subtract(const Duration(days: 7));
  
  final result = await getNetworkUsage.call(GetNetworkUsageParams(
    start: startOfWeek,
    end: now,
  ));
  
  return result.fold(
    (failure) => [],
    (allUsage) => allUsage.where((usage) => usage.packageName == packageName).toList(),
  );
});

// Provider for network history data for chart
final networkHistoryProvider = FutureProvider<List<NetworkTrafficEntity>>((ref) async {
  try {
    final getNetworkUsage = ref.watch(getNetworkUsageProvider);
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    final result = await getNetworkUsage.call(GetNetworkUsageParams(
      start: sevenDaysAgo,
      end: now,
    ));
    
    return result.fold(
      (failure) => [],
      (usage) => usage,
    );
  } catch (e) {
    return <NetworkTrafficEntity>[];
  }
});
