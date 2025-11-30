import 'package:flutter/services.dart';
import 'package:netvigilant/core/di/service_locator.dart';
import 'package:netvigilant/domain/usecases/manage_permissions.dart';
import 'package:netvigilant/core/usecases/usecase.dart';

class MethodChannelWrapper {
  final MethodChannel _methodChannel;

  MethodChannelWrapper(String channelName) : _methodChannel = MethodChannel(channelName);

  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    return await _methodChannel.invokeMethod(method, arguments);
  }
}

class EventChannelWrapper {
  final EventChannel _eventChannel;

  EventChannelWrapper(String channelName) : _eventChannel = EventChannel(channelName);

  Stream<T> receiveBroadcastStream<T>([dynamic arguments]) {
    return _eventChannel.receiveBroadcastStream(arguments).cast<T>();
  }
}

class PermissionChecker {
  // No longer needs a direct MethodChannel
  // static const MethodChannel _permissionChannel = MethodChannel('com.netvigilant.app/permissions');

  static Future<bool> hasUsageStatsPermission() async {
    final result = await sl<CheckUsageStatsPermission>().call(const NoParams());
    return result.fold(
      (failure) => false,
      (hasPermission) => hasPermission,
    );
  }

  static Future<void> requestUsageStatsPermission() async {
    await sl<RequestUsageStatsPermission>().call(const NoParams());
  }
}

