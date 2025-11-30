import 'package:netvigilant/domain/entities/app_usage_entity.dart';
import 'package:netvigilant/domain/entities/network_traffic_entity.dart';
import 'package:netvigilant/domain/entities/real_time_metrics_entity.dart';

abstract class AbstractNetworkRepository {
  Future<Map<String, AppUsageEntity>> getHistoricalAppUsage({
    required DateTime start,
    required DateTime end,
  });

  Future<List<NetworkTrafficEntity>> getNetworkUsage({
    required DateTime start,
    required DateTime end,
  });

  Future<List<AppUsageEntity>> getAppUsage({
    required DateTime start,
    required DateTime end,
  });

  Stream<RealTimeMetricsEntity> getLiveTrafficStream();
  
  Future<void> startContinuousMonitoring();
  
  Future<void> stopContinuousMonitoring();

  Future<bool?> hasUsageStatsPermission();

  Future<void> requestUsageStatsPermission();


  Future<void> openBatteryOptimizationSettings();

  Future<bool?> hasIgnoreBatteryOptimizationPermission();
  Future<void> requestIgnoreBatteryOptimizationPermission();

  Future<Map<String, NetworkTrafficEntity>> getAggregatedNetworkUsageByUid({
    required DateTime start,
    required DateTime end,
  });

  // New method for exporting all historical network traffic
  Future<List<NetworkTrafficEntity>> getAllHistoricalNetworkTraffic();
}