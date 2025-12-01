import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/auth_usecase.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/services/safe_preferences_manager.dart';
import '../data/services/simple_network_service.dart';
import '../interfaces/network_service.dart';
import '../presentation/providers/simplified_auth_provider.dart';
import '../presentation/providers/simplified_network_provider.dart';

class SimpleServiceLocator {
  static final SimpleServiceLocator _instance = SimpleServiceLocator._internal();
  factory SimpleServiceLocator() => _instance;
  SimpleServiceLocator._internal();

  final Map<Type, dynamic> _services = {};
  final Map<String, dynamic> _namedServices = {};

  T get<T>([String? name]) {
    if (name != null) {
      final service = _namedServices[name];
      if (service == null) {
        throw Exception('Service $T with name $name not found');
      }
      return service as T;
    }
    
    final service = _services[T];
    if (service == null) {
      throw Exception('Service $T not found');
    }
    return service as T;
  }

  void register<T>(T service, [String? name]) {
    if (name != null) {
      _namedServices[name] = service;
    } else {
      _services[T] = service;
    }
  }

  void registerLazy<T>(T Function() factory, [String? name]) {
    if (name != null) {
      _namedServices[name] = factory();
    } else {
      _services[T] = factory();
    }
  }
}

final serviceLocator = SimpleServiceLocator();

Future<void> setupServiceLocator() async {
  // Core services
  serviceLocator.register<SafePreferencesManager>(
    SafePreferencesManager.instance,
  );

  // Repositories
  serviceLocator.registerLazy<IAuthRepository>(
    () => AuthRepositoryImpl(serviceLocator.get<SafePreferencesManager>()),
  );

  // Use cases
  serviceLocator.registerLazy<AuthUseCase>(
    () => AuthUseCase(serviceLocator.get<IAuthRepository>()),
  );

  // Network services
  serviceLocator.register<INetworkService>(
    SimpleWifiNetworkService(),
    'wifi',
  );

  serviceLocator.register<INetworkService>(
    SimpleMobileNetworkService(),
    'mobile',
  );

  // Providers
  serviceLocator.registerLazy<SimplifiedAuthProvider>(
    () => SimplifiedAuthProvider(serviceLocator.get<AuthUseCase>()),
  );

  serviceLocator.registerLazy<SimplifiedNetworkProvider>(
    () => SimplifiedNetworkProvider(
      wifiService: serviceLocator.get<INetworkService>('wifi'),
      mobileService: serviceLocator.get<INetworkService>('mobile'),
    ),
  );
}

// Convenience getters
SimplifiedAuthProvider get authProvider => serviceLocator.get<SimplifiedAuthProvider>();
SimplifiedNetworkProvider get networkProvider => serviceLocator.get<SimplifiedNetworkProvider>();
SafePreferencesManager get prefsManager => serviceLocator.get<SafePreferencesManager>();