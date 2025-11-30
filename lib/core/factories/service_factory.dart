// SOLID Principles: Dependency Inversion & Open/Closed Principle
// Factory pattern for service creation and dependency injection

import 'package:netvigilant/core/interfaces/data_processor.dart';
import 'package:netvigilant/core/interfaces/repository.dart';
import 'package:netvigilant/core/interfaces/storage.dart';
import 'package:netvigilant/core/services/concurrent_data_processor.dart';

/// Abstract factory for creating services
abstract class IServiceFactory {
  T create<T>();
  void register<T>(T Function() creator);
  void registerSingleton<T>(T instance);
  bool isRegistered<T>();
}

/// Concrete service factory implementation
class ServiceFactory implements IServiceFactory {
  static final ServiceFactory _instance = ServiceFactory._internal();
  factory ServiceFactory() => _instance;
  ServiceFactory._internal();

  final Map<Type, Function()> _creators = {};
  final Map<Type, dynamic> _singletons = {};

  @override
  T create<T>() {
    // Check for singleton first
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }

    // Check for registered creator
    if (_creators.containsKey(T)) {
      return _creators[T]!() as T;
    }

    // Default implementations based on interface
    if (T == IPreferencesStorage) {
      throw UnimplementedError('LocalStorageService requires async initialization. Use getInstance() method.');
    }
    
    if (T == IDatabaseStorage) {
      throw UnimplementedError('DatabaseService requires DatabaseHelper parameter. Use factory registration instead.');
    }

    throw UnimplementedError('No factory registered for type $T');
  }

  @override
  void register<T>(T Function() creator) {
    _creators[T] = creator;
  }

  @override
  void registerSingleton<T>(T instance) {
    _singletons[T] = instance;
  }

  @override
  bool isRegistered<T>() {
    return _creators.containsKey(T) || _singletons.containsKey(T);
  }

  /// Clear all registrations (useful for testing)
  void clear() {
    _creators.clear();
    _singletons.clear();
  }

  /// Initialize default services
  void initializeDefaults() {
    // Note: LocalStorageService and DatabaseService should be registered separately
    // as they require specific initialization
    
    // Register singletons that can be created without dependencies
    // registerSingleton<IConcurrentDataProcessor>(ConcurrentDataProcessor());
  }
}

/// Repository factory for creating repository instances
class RepositoryFactory {
  static final RepositoryFactory _instance = RepositoryFactory._internal();
  factory RepositoryFactory() => _instance;
  RepositoryFactory._internal();

  final Map<Type, Function()> _creators = {};

  T create<T>() {
    if (_creators.containsKey(T)) {
      return _creators[T]!() as T;
    }

    // Default repository implementations
    if (T == INetworkRepository) {
      return _createNetworkRepository() as T;
    }

    throw UnimplementedError('No repository factory registered for type $T');
  }

  void register<T>(T Function() creator) {
    _creators[T] = creator;
  }

  INetworkRepository _createNetworkRepository() {
    // This would be injected in a real DI container
    throw UnimplementedError('NetworkRepository creation needs dependency injection setup');
  }
}

/// Data processor factory
class ProcessorFactory {
  static final ProcessorFactory _instance = ProcessorFactory._internal();
  factory ProcessorFactory() => _instance;
  ProcessorFactory._internal();

  final Map<String, IConcurrentDataProcessor> _processors = {};

  IConcurrentDataProcessor<T, R> create<T, R>(String processorType) {
    if (_processors.containsKey(processorType)) {
      return _processors[processorType] as IConcurrentDataProcessor<T, R>;
    }

    // Create default processor
    final processor = ConcurrentDataProcessor() as IConcurrentDataProcessor<T, R>;
    _processors[processorType] = processor;
    return processor;
  }

  void register(String type, IConcurrentDataProcessor processor) {
    _processors[type] = processor;
  }
}

/// Storage factory for creating storage instances
class StorageFactory {
  static final StorageFactory _instance = StorageFactory._internal();
  factory StorageFactory() => _instance;
  StorageFactory._internal();

  T create<T>(StorageType type) {
    switch (type) {
      case StorageType.preferences:
        if (T == IPreferencesStorage) {
          throw UnimplementedError('LocalStorageService requires async initialization. Use getInstance() method.');
        }
        break;
      case StorageType.database:
        if (T == IDatabaseStorage) {
          throw UnimplementedError('DatabaseService requires DatabaseHelper parameter. Use factory registration instead.');
        }
        break;
      case StorageType.cache:
        // Return cache implementation
        break;
      case StorageType.secure:
        // Return secure storage implementation
        break;
      case StorageType.blob:
        // Return blob storage implementation
        break;
    }

    throw UnimplementedError('Storage type $type not implemented for $T');
  }
}

enum StorageType {
  preferences,
  database,
  cache,
  secure,
  blob,
}