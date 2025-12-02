import 'package:flutter/widgets.dart';

// SOLID - Interface Segregation Principle
// Common widget contracts to ensure consistent behavior

abstract class IStatefulBaseWidget extends StatefulWidget {
  const IStatefulBaseWidget({super.key});
}

abstract class IAsyncWidget<T> {
  Future<void> loadData();
  void handleError(Object error);
  void handleLoading();
  void handleEmpty();
  Widget buildContent(T data);
}

abstract class IRefreshableWidget {
  Future<void> refresh();
  bool get isRefreshing;
}

abstract class ICacheableWidget {
  String get cacheKey;
  Duration get cacheTtl;
  bool get shouldCache;
}

abstract class IConfigurableWidget {
  Map<String, dynamic> get configuration;
  void updateConfiguration(Map<String, dynamic> config);
}

// DRY - Common widget states
enum WidgetState {
  initial,
  loading,
  loaded,
  error,
  empty,
  refreshing
}

// DRY - Common loading strategies
enum LoadingStrategy {
  immediate,
  deferred,
  lazy,
  background
}

// DRY - Common error handling strategies
enum ErrorStrategy {
  show,
  silent,
  retry,
  fallback
}