import 'package:get_it/get_it.dart';
import 'package:apptobe/core/interfaces/app_repository.dart';
import 'package:apptobe/core/interfaces/app_usage_repository.dart';
import 'package:apptobe/core/interfaces/location_repository.dart';
import 'package:apptobe/core/interfaces/permission_repository.dart';
import 'package:apptobe/core/interfaces/notification_service.dart';
import 'package:apptobe/core/repositories/app_repository.dart';
import 'package:apptobe/core/repositories/app_usage_repository.dart';
import 'package:apptobe/core/repositories/location_repository.dart';
import 'package:apptobe/core/repositories/permission_repository.dart';
import 'package:apptobe/core/services/notification_service.dart';

final getIt = GetIt.instance;

void setup() {
  // Services
  getIt.registerLazySingleton<INotificationService>(() => NotificationService());

  // Repositories
  getIt.registerLazySingleton<IAppRepository>(() => AppRepository());
  getIt.registerLazySingleton<IAppUsageRepository>(() => AppUsageRepository());
  getIt.registerLazySingleton<ILocationRepository>(() => LocationRepository());
  getIt.registerLazySingleton<IPermissionRepository>(() => PermissionRepository());
}
