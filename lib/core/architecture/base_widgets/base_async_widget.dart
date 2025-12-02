import 'package:flutter/material.dart' hide WidgetState;
import '../interfaces/widget_interfaces.dart';
import '../interfaces/service_interfaces.dart';

// SOLID - Base class implementing common async widget behavior
abstract class BaseAsyncWidget<T> extends StatefulWidget 
    implements IAsyncWidget<T>, IRefreshableWidget, ICacheableWidget {
  const BaseAsyncWidget({super.key});

  // Abstract methods that must be implemented by subclasses
  @override
  Widget buildContent(T data);
  
  @override
  Future<void> loadData();

  // Default implementations that can be overridden
  @override
  void handleError(Object error) {
    debugPrint('Widget Error: $error');
  }

  @override
  void handleLoading() {
    // Default: do nothing, handled by state
  }

  @override
  void handleEmpty() {
    // Default: do nothing, handled by state  
  }

  // Cacheable widget defaults
  @override
  String get cacheKey => runtimeType.toString();

  @override
  Duration get cacheTtl => const Duration(minutes: 5);

  @override
  bool get shouldCache => true;

  // Refreshable widget defaults  
  @override
  bool get isRefreshing => false;

  @override
  Future<void> refresh() async {
    await loadData();
  }

  @override
  State<BaseAsyncWidget<T>> createState() => _BaseAsyncWidgetState<T>();
}

class _BaseAsyncWidgetState<T> extends State<BaseAsyncWidget<T>> {
  WidgetState _state = WidgetState.initial;
  T? _data;
  String? _error;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadDataWithStrategy();
  }

  void _loadDataWithStrategy() {
    switch (_getLoadingStrategy()) {
      case LoadingStrategy.immediate:
        _loadData();
        break;
      case LoadingStrategy.deferred:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadData();
        });
        break;
      case LoadingStrategy.lazy:
        // Load on first interaction
        break;
      case LoadingStrategy.background:
        Future.microtask(() => _loadData());
        break;
    }
  }

  LoadingStrategy _getLoadingStrategy() {
    // Can be overridden in subclasses
    return LoadingStrategy.deferred;
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _state = WidgetState.loading;
      _error = null;
    });

    try {
      widget.handleLoading();
      await widget.loadData();
      
      if (mounted) {
        if (_data == null) {
          setState(() => _state = WidgetState.empty);
          widget.handleEmpty();
        } else {
          setState(() => _state = WidgetState.loaded);
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _state = WidgetState.error;
          _error = error.toString();
        });
        widget.handleError(error);
      }
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing || !mounted) return;

    setState(() {
      _isRefreshing = true;
      _state = WidgetState.refreshing;
    });

    try {
      await widget.refresh();
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _state = WidgetState.error;
          _error = error.toString();
        });
        widget.handleError(error);
      }
    }
  }

  void updateData(T data) {
    if (mounted) {
      setState(() => _data = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case WidgetState.initial:
      case WidgetState.loading:
        return _buildLoading();
      
      case WidgetState.loaded:
        return _data != null 
            ? widget.buildContent(_data!) 
            : _buildEmpty();
      
      case WidgetState.empty:
        return _buildEmpty();
      
      case WidgetState.error:
        return _buildError();
      
      case WidgetState.refreshing:
        return Stack(
          children: [
            if (_data != null) widget.buildContent(_data!),
            const Center(child: CircularProgressIndicator()),
          ],
        );
    }
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text('No data available'),
    );
  }

  Widget _buildError() {
    final errorStrategy = _getErrorStrategy();
    
    switch (errorStrategy) {
      case ErrorStrategy.show:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${_error ?? 'Unknown error'}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      
      case ErrorStrategy.silent:
        return _buildEmpty();
      
      case ErrorStrategy.retry:
        _loadData();
        return _buildLoading();
      
      case ErrorStrategy.fallback:
        return _buildFallback();
    }
  }

  Widget _buildFallback() {
    return const Center(
      child: Text('Fallback content'),
    );
  }

  ErrorStrategy _getErrorStrategy() {
    return ErrorStrategy.show;
  }
}