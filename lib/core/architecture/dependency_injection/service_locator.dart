import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../interfaces/repository_interfaces.dart';
import '../interfaces/service_interfaces.dart';
import '../implementations/analytics_service_impl.dart';
import '../implementations/app_launch_service_impl.dart';
import '../implementations/notification_service_impl.dart';
import '../implementations/app_repository_impl.dart';
import '../implementations/usage_repository_impl.dart';
import '../implementations/permission_repository_impl.dart';
import '../implementations/cache_repository_impl.dart';
import '../../services/cache_service.dart';

// SOLID - Dependency Inversion: High-level modules don't depend on low-level modules
class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;
  static bool _isInitialized = false;

  static Future<void> initialize({
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  }) async {
    if (_isInitialized) return;

    // Register singletons
    _getIt.registerSingleton<CacheService>(CacheService());
    
    // Register repositories
    _getIt.registerLazySingleton<IAppRepository>(() => AppRepositoryImpl());
    _getIt.registerLazySingleton<IUsageRepository>(() => UsageRepositoryImpl());
    _getIt.registerLazySingleton<IPermissionRepository>(() => PermissionRepositoryImpl());
    _getIt.registerLazySingleton<ICacheRepository>(
      () => CacheRepositoryImpl(cacheService: _getIt<CacheService>()),
    );

    // Register services
    _getIt.registerLazySingleton<IAnalyticsService>(
      () => AnalyticsServiceImpl(
        usageRepository: _getIt<IUsageRepository>(),
        appRepository: _getIt<IAppRepository>(),
      ),
    );
    _getIt.registerLazySingleton<IAppLaunchService>(() => AppLaunchServiceImpl());
    _getIt.registerLazySingleton<INotificationService>(
      () => NotificationServiceImpl(scaffoldMessengerKey: scaffoldMessengerKey),
    );

    _isInitialized = true;
  }

  // Generic getter for any service
  static T get<T extends Object>() {
    return _getIt.get<T>();
  }

  // Specific getters for common services (DRY)
  static IAnalyticsService get analyticsService => get<IAnalyticsService>();
  static IAppLaunchService get appLaunchService => get<IAppLaunchService>();
  static INotificationService get notificationService => get<INotificationService>();
  static IAppRepository get appRepository => get<IAppRepository>();
  static IUsageRepository get usageRepository => get<IUsageRepository>();
  static IPermissionRepository get permissionRepository => get<IPermissionRepository>();
  static ICacheRepository get cacheRepository => get<ICacheRepository>();

  static void reset() {
    _getIt.reset();
    _isInitialized = false;
  }
}