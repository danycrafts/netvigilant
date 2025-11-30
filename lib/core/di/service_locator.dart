import 'package:get_it/get_it.dart';
import 'package:netvigilant/core/platform/platform_channel_wrappers.dart';
import 'package:netvigilant/core/services/local_storage_service.dart';
import 'package:netvigilant/data/datasources/background_monitoring_datasource.dart';
import 'package:netvigilant/data/database/database_helper.dart';
import 'package:netvigilant/data/services/database_service.dart';
import 'package:netvigilant/data/parsers/data_parser.dart';
import 'package:netvigilant/data/repositories/background_monitoring_repository_impl.dart';
import 'package:netvigilant/data/repositories/network_repository_impl.dart';
import 'package:netvigilant/domain/repositories/background_monitoring_repository.dart';
import 'package:netvigilant/domain/repositories/network_repository.dart';
import 'package:netvigilant/domain/usecases/get_app_usage.dart';
import 'package:netvigilant/domain/usecases/get_network_usage.dart';
import 'package:netvigilant/domain/usecases/get_real_time_metrics.dart';
import 'package:netvigilant/domain/usecases/manage_monitoring.dart';
import 'package:netvigilant/domain/usecases/manage_permissions.dart';
import 'package:netvigilant/core/services/notification_service.dart';
import 'package:netvigilant/core/services/data_export_service.dart'; // New import for DataExportService

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Platform Channel Wrappers
  sl.registerLazySingleton<MethodChannelWrapper>(
    () => MethodChannelWrapper('com.example.netvigilant/network_stats'),
  );
  
  sl.registerLazySingleton<EventChannelWrapper>(
    () => EventChannelWrapper('com.example.netvigilant/traffic_stream'),
  );

  // Services
  final localStorageService = await LocalStorageService.getInstance();
  sl.registerLazySingleton<LocalStorageService>(() => localStorageService);
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
  sl.registerLazySingleton<DatabaseService>(() => DatabaseService(sl<DatabaseHelper>()));
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<DataExportService>(() => DataExportService(sl<DatabaseService>(), sl<NotificationService>())); // Register DataExportService

  // Data Parsers
  sl.registerLazySingleton<NetworkTrafficParser>(() => NetworkTrafficParser());
  sl.registerLazySingleton<AppUsageParser>(() => AppUsageParser());

  // Data Sources
  sl.registerLazySingleton<BackgroundMonitoringDataSource>(
    () => BackgroundMonitoringDataSourceImpl(
      localStorageService: sl<LocalStorageService>(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<AbstractNetworkRepository>(
    () => NetworkRepositoryImpl(
      methodChannel: sl<MethodChannelWrapper>(),
      eventChannel: sl<EventChannelWrapper>(),
      networkTrafficParser: sl<NetworkTrafficParser>(),
      appUsageParser: sl<AppUsageParser>(),
      databaseService: sl<DatabaseService>(),
    ),
  );

  sl.registerLazySingleton<BackgroundMonitoringRepository>(
    () => BackgroundMonitoringRepositoryImpl(
      dataSource: sl<BackgroundMonitoringDataSource>(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetNetworkUsage(sl<AbstractNetworkRepository>()));
  sl.registerLazySingleton(() => GetAppUsage(sl<AbstractNetworkRepository>()));
  sl.registerLazySingleton(() => GetRealTimeMetrics(sl<AbstractNetworkRepository>()));
  sl.registerLazySingleton(() => StartContinuousMonitoring(sl<AbstractNetworkRepository>()));
  sl.registerLazySingleton(() => StopContinuousMonitoring(sl<AbstractNetworkRepository>()));
  sl.registerLazySingleton(() => StartBackgroundMonitoring(sl<BackgroundMonitoringRepository>()));
  sl.registerLazySingleton(() => StopBackgroundMonitoring(sl<BackgroundMonitoringRepository>()));
  sl.registerLazySingleton(() => CheckBackgroundMonitoringStatus(sl<BackgroundMonitoringRepository>()));
  sl.registerLazySingleton(() => CheckUsageStatsPermission(sl<AbstractNetworkRepository>()));
  sl.registerLazySingleton(() => RequestUsageStatsPermission(sl<AbstractNetworkRepository>()));
  sl.registerLazySingleton(() => OpenBatteryOptimizationSettings(sl<AbstractNetworkRepository>()));
}

// Convenience getters for commonly used dependencies
AbstractNetworkRepository get networkRepository => sl<AbstractNetworkRepository>();
BackgroundMonitoringRepository get backgroundMonitoringRepository => sl<BackgroundMonitoringRepository>();
LocalStorageService get localStorageService => sl<LocalStorageService>();