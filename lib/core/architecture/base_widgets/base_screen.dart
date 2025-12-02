import 'package:flutter/material.dart';
import '../interfaces/widget_interfaces.dart';
import '../dependency_injection/service_locator.dart';

// SOLID - Base screen class with common functionality
abstract class BaseScreen extends StatefulWidget implements IRefreshableWidget {
  const BaseScreen({super.key});

  // Abstract methods
  String get title;
  Widget buildBody(BuildContext context);

  // Optional overrides
  List<Widget>? buildActions(BuildContext context) => null;
  Widget? buildFloatingActionButton(BuildContext context) => null;
  bool get showAppBar => true;
  bool get showBottomNavigation => false;
  
  @override
  bool get isRefreshing => false;

  @override
  Future<void> refresh() async {
    // Default implementation - can be overridden
  }

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? _buildAppBar(context) : null,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: widget.buildBody(context),
      ),
      floatingActionButton: widget.buildFloatingActionButton(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(widget.title),
      actions: widget.buildActions(context),
      elevation: 2,
    );
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      await widget.refresh();
    } catch (error) {
      if (mounted) {
        ServiceLocator.notificationService.showError(
          'Refresh failed: ${error.toString()}'
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }
}

// DRY - Common screen configurations
mixin LoadingScreenMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    if (mounted) {
      setState(() => _isLoading = loading);
    }
  }

  Widget buildWithLoading(Widget child) {
    return Stack(
      children: [
        child,
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

// DRY - Common error handling mixin
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  void handleError(Object error, {bool showSnackBar = true}) {
    if (showSnackBar && mounted) {
      ServiceLocator.notificationService.showError(
        'Error: ${error.toString()}'
      );
    }
    debugPrint('Screen Error: $error');
  }

  void handleSuccess(String message) {
    if (mounted) {
      ServiceLocator.notificationService.showSuccess(message);
    }
  }
}