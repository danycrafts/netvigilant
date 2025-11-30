import 'package:flutter/services.dart';
import 'package:netvigilant/core/utils/logger.dart';

class NotificationService {
  static const MethodChannel _notificationChannel = MethodChannel('com.netvigilant.app/notifications');

  Future<void> showBasicNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _notificationChannel.invokeMethod('showBasicNotification', {
        'id': id,
        'title': title,
        'body': body,
        'payload': payload,
      });
    } on PlatformException catch (e) {
      log('NotificationService: Failed to show basic notification: ${e.message}');
    }
  }

  Future<void> showProgressNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
    String? payload,
  }) async {
    try {
      await _notificationChannel.invokeMethod('showProgressNotification', {
        'id': id,
        'title': title,
        'body': body,
        'progress': progress,
        'maxProgress': maxProgress,
        'payload': payload,
      });
    } on PlatformException catch (e) {
      log('NotificationService: Failed to show progress notification: ${e.message}');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationChannel.invokeMethod('cancelNotification', {'id': id});
    } on PlatformException catch (e) {
      log('NotificationService: Failed to cancel notification: ${e.message}');
    }
  }

  Future<void> updateProgressNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
  }) async {
    try {
      await _notificationChannel.invokeMethod('updateProgressNotification', {
        'id': id,
        'title': title,
        'body': body,
        'progress': progress,
        'maxProgress': maxProgress,
      });
    } on PlatformException catch (e) {
      log('NotificationService: Failed to update progress notification: ${e.message}');
    }
  }
}
