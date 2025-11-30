import 'package:netvigilant/core/utils/logger.dart';
import 'package:flutter/services.dart';

class PlatformChannelService {
  static const MethodChannel _networkStatsChannel =
      MethodChannel('com.example.netvigilant/network_stats');
  static const EventChannel _trafficStreamChannel =
      EventChannel('com.example.netvigilant/traffic_stream');

  Future<dynamic> invokeMethod(String method, [dynamic arguments]) async {
    try {
      return await _networkStatsChannel.invokeMethod(method, arguments);
    } on PlatformException catch (e) {
      // Handle exception
      log("Failed to invoke method: '${e.message}'.", error: e);
      return null;
    }
  }

  Stream<dynamic> receiveBroadcastStream([dynamic arguments]) {
    return _trafficStreamChannel.receiveBroadcastStream(arguments);
  }
}
