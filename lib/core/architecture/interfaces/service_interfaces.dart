// SOLID - Interface Segregation Principle
// Clean service contracts with single responsibilities

abstract class IAnalyticsService {
  Future<T> calculateUsageStatistics<T>();
  Future<List<T>> getTopUsedApps<T>(int limit);
  Future<List<T>> getRecentlyUsedApps<T>(int limit);
}

abstract class IAppLaunchService {
  Future<bool> launchApp(String packageName);
  Future<bool> canLaunchApp(String packageName);
}

abstract class IDataFetchService<T> {
  Future<T> fetchData();
  Future<T> fetchDataWithTimeout(Duration timeout);
  Future<void> refreshData();
}

abstract class IAsyncLoadingService<T> {
  Stream<AsyncState<T>> get state;
  Future<void> load();
  Future<void> reload();
}

abstract class INotificationService {
  Future<void> showSuccess(String message);
  Future<void> showError(String message);
  Future<void> showInfo(String message);
  Future<void> showWarning(String message);
}

// SOLID - Single Responsibility Principle
enum AsyncState<T> {
  loading,
  loaded,
  error,
  empty
}

class DataState<T> {
  final T? data;
  final String? error;
  final bool isLoading;
  final bool isEmpty;

  const DataState({
    this.data,
    this.error,
    this.isLoading = false,
    this.isEmpty = false,
  });

  const DataState.loading() : this(isLoading: true);
  const DataState.loaded(T data) : this(data: data);
  const DataState.error(String error) : this(error: error);
  const DataState.empty() : this(isEmpty: true);

  bool get hasData => data != null && !isLoading && error == null;
  bool get hasError => error != null;
}