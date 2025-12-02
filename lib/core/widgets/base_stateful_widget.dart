import 'package:flutter/material.dart';

abstract class BaseStatefulWidget extends StatefulWidget {
  const BaseStatefulWidget({super.key});
}

abstract class BaseStatefulState<T extends BaseStatefulWidget> extends State<T> 
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDisposed => _isDisposed;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    onInitialize();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    onDispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    onAppLifecycleStateChanged(state);
  }

  void onInitialize() {}
  void onDispose() {}
  void onAppLifecycleStateChanged(AppLifecycleState state) {}

  void setLoading(bool loading, [String? message]) {
    if (!mounted) return;
    setState(() {
      _isLoading = loading;
      if (!loading) _errorMessage = null;
    });
  }

  void setError(String error) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });
  }

  void clearError() {
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
    });
  }

  void safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    String? loadingMessage,
    bool showLoading = true,
    bool handleError = true,
  }) async {
    try {
      if (showLoading) setLoading(true, loadingMessage);
      final result = await operation();
      if (showLoading) setLoading(false);
      return result;
    } catch (e) {
      if (handleError) {
        setError(e.toString());
      } else {
        if (showLoading) setLoading(false);
        rethrow;
      }
      return null;
    }
  }

  void showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildContent(context);
  }

  Widget buildContent(BuildContext context);
}

mixin CacheStateMixin<T extends BaseStatefulWidget> on BaseStatefulState<T> {
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  void cacheData(String key, dynamic data, {Duration? ttl}) {
    _cache[key] = data;
    if (ttl != null) {
      _cacheTimestamps[key] = DateTime.now().add(ttl);
    }
  }

  T? getCachedData<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null && DateTime.now().isAfter(timestamp)) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }
    return _cache[key] as T?;
  }

  void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }
}

mixin RefreshStateMixin<T extends BaseStatefulWidget> on BaseStatefulState<T> {
  bool _isRefreshing = false;
  
  bool get isRefreshing => _isRefreshing;

  Future<void> refresh({bool forceRefresh = false}) async {
    if (_isRefreshing && !forceRefresh) return;
    
    _isRefreshing = true;
    safeSetState(() {});
    
    try {
      await onRefresh();
    } finally {
      _isRefreshing = false;
      safeSetState(() {});
    }
  }

  Future<void> onRefresh();

  Widget buildRefreshIndicator(Widget child) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: child,
    );
  }
}