import 'package:flutter/material.dart';
import '../interfaces/service_interfaces.dart';

// SOLID - Single Responsibility: Only handles notifications
class NotificationServiceImpl implements INotificationService {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  const NotificationServiceImpl({
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  }) : _scaffoldMessengerKey = scaffoldMessengerKey;

  @override
  Future<void> showSuccess(String message) async {
    _showSnackBar(message, Colors.green);
  }

  @override
  Future<void> showError(String message) async {
    _showSnackBar(message, Colors.red);
  }

  @override
  Future<void> showInfo(String message) async {
    _showSnackBar(message, Colors.blue);
  }

  @override
  Future<void> showWarning(String message) async {
    _showSnackBar(message, Colors.orange);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}