import 'dart:async';
import 'dart:isolate';
import 'package:netvigilant/core/errors/failures.dart';
import 'package:netvigilant/core/platform/platform_channel_wrappers.dart';
import 'package:netvigilant/core/services/concurrent_data_processor.dart';
import 'package:netvigilant/core/utils/logger.dart';
import 'package:netvigilant/data/parsers/data_parser.dart';
import 'package:netvigilant/data/services/database_service.dart';
import 'package:netvigilant/domain/entities/app_usage_entity.dart';
import 'package:netvigilant/domain/entities/network_traffic_entity.dart';
import 'package:netvigilant/domain/entities/real_time_metrics_entity.dart';
import 'package:netvigilant/domain/repositories/network_repository.dart';


class NetworkRepositoryImpl implements AbstractNetworkRepository {
  final MethodChannelWrapper _methodChannel;
  final EventChannelWrapper _eventChannel;
  final NetworkTrafficParser _networkTrafficParser;
  final AppUsageParser _appUsageParser;
  final DatabaseService _databaseService;

  NetworkRepositoryImpl({
    required MethodChannelWrapper methodChannel,
    required EventChannelWrapper eventChannel,
    required NetworkTrafficParser networkTrafficParser,
    required AppUsageParser appUsageParser,
    required DatabaseService databaseService,
  })  : _methodChannel = methodChannel,
        _eventChannel = eventChannel,
        _networkTrafficParser = networkTrafficParser,
        _appUsageParser = appUsageParser,
        _databaseService = databaseService;

  @override
  Future<List<AppUsageEntity>> getAppUsage({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      // Try to get from database first
      final cachedData = await _databaseService.getAppUsageData(
        startDate: start,
        endDate: end,
      );

      // If we have cached data for recent requests, return it
      if (cachedData.isNotEmpty) {
        return cachedData;
      }

      // Otherwise, fetch from platform and cache
      log('NetworkRepository: Fetching app usage from platform for ${end.difference(start).inHours} hours');
      final List<dynamic>? data = await _methodChannel.invokeMethod(
        'getAppUsage',
        {
          'start': start.millisecondsSinceEpoch,
          'end': end.millisecondsSinceEpoch,
        },
      );
      
      if (data == null || data.isEmpty) {
        log('NetworkRepository: No app usage data received from platform');
        return [];
      }
      
      // Convert to map format for concurrent processing
      final rawData = data.map((item) => Map<String, dynamic>.from(item)).toList();
      log('NetworkRepository: Processing ${rawData.length} app usage items concurrently');
      
      // Use concurrent processor for better performance
      final parsedData = await ConcurrentDataProcessor.processAppUsageDataConcurrently(rawData);
      
      // Cache the data for future use
      await _databaseService.saveAppUsageData(parsedData, DateTime.now());
      
      return parsedData;
    } catch (e) {
      // Fallback to cached data on error
      final cachedData = await _databaseService.getAppUsageData(
        startDate: start,
        endDate: end,
      );
      if (cachedData.isNotEmpty) {
        return cachedData;
      }
      throw PlatformFailure('Failed to get app usage: ${e.toString()}');
    }
  }

  @override
  Future<List<NetworkTrafficEntity>> getNetworkUsage({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      // Try to get from database first
      final cachedData = await _databaseService.getNetworkTrafficData(
        startDate: start,
        endDate: end,
      );

      // If we have recent cached data, return it
      if (cachedData.isNotEmpty) {
        return cachedData;
      }

      // Otherwise, fetch from platform and cache
      log('NetworkRepository: Fetching network traffic from platform for ${end.difference(start).inHours} hours');
      final List<dynamic>? data = await _methodChannel.invokeMethod(
        'getHistoricalNetworkUsage',
        {
          'start': start.millisecondsSinceEpoch,
          'end': end.millisecondsSinceEpoch,
        },
      );
      
      if (data == null || data.isEmpty) {
        log('NetworkRepository: No network traffic data received from platform');
        return [];
      }
      
      // Convert to map format for concurrent processing
      final rawData = data.map((item) => Map<String, dynamic>.from(item)).toList();
      log('NetworkRepository: Processing ${rawData.length} network traffic items concurrently');
      
      // Use concurrent processor for better performance
      final parsedData = await ConcurrentDataProcessor.processNetworkTrafficConcurrently(rawData);
      
      // Cache the data for future use
      await _databaseService.saveNetworkTrafficData(parsedData);
      
      return parsedData;
    } catch (e) {
      // Fallback to cached data on error
      final cachedData = await _databaseService.getNetworkTrafficData(
        startDate: start,
        endDate: end,
      );
      if (cachedData.isNotEmpty) {
        return cachedData;
      }
      throw PlatformFailure('Failed to get network usage: ${e.toString()}');
    }
  }

  @override
  Stream<RealTimeMetricsEntity> getLiveTrafficStream() {
    try {
      return _eventChannel.receiveBroadcastStream().map((event) {
        final Map<String, dynamic> metrics = Map<String, dynamic>.from(event);
        return RealTimeMetricsEntity(
          uplinkSpeed: (metrics['uplinkSpeed'] as num).toDouble(),
          downlinkSpeed: (metrics['downlinkSpeed'] as num).toDouble(),
        );
      }).handleError((error, stackTrace) {
        throw PlatformFailure('Live traffic stream error: ${error.toString()}');
      });
    } catch (e) {
      throw PlatformFailure('Failed to get live traffic stream: ${e.toString()}');
    }
  }
  
  @override
  Future<void> startContinuousMonitoring() async {
    try {
      await _methodChannel.invokeMethod('startContinuousMonitoring');
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      throw PlatformFailure('Failed to start monitoring: ${e.toString()}');
    }
  }
  
  @override
  Future<void> stopContinuousMonitoring() async {
    try {
      await _methodChannel.invokeMethod('stopContinuousMonitoring');
    } catch (e) {
      throw PlatformFailure('Failed to stop monitoring: ${e.toString()}');
    }
  }

  @override
  Future<bool?> hasUsageStatsPermission() async {
    try {
      return await _methodChannel.invokeMethod('hasUsageStatsPermission');
    } catch (e) {
      throw PermissionFailure('Failed to check permission: ${e.toString()}');
    }
  }

  @override
  Future<void> requestUsageStatsPermission() async {
    try {
      await _methodChannel.invokeMethod('requestUsageStatsPermission');
    } catch (e) {
      throw PermissionFailure('Failed to request permission: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, AppUsageEntity>> getHistoricalAppUsage({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      // Try to get from database first
      final cachedData = await _databaseService.getLatestAppUsageMap();

      // If we have recent cached data, return it
      if (cachedData.isNotEmpty) {
        return cachedData;
      }

      // Otherwise, fetch from platform and cache
      final Map<String, dynamic>? data = await _methodChannel.invokeMethod(
        'getHistoricalAppUsage',
        {
          'start': start.millisecondsSinceEpoch,
          'end': end.millisecondsSinceEpoch,
        },
      );
      
      if (data == null) {
        return {};
      }
      
      final parsedData = await Isolate.run(() => _appUsageParser.parseMap(data));
      
      // Cache the data for future use
      await _databaseService.saveAppUsageData(parsedData.values.toList(), DateTime.now());
      
      return parsedData;
    } catch (e) {
      // Fallback to cached data on error
      final cachedData = await _databaseService.getLatestAppUsageMap();
      if (cachedData.isNotEmpty) {
        return cachedData;
      }
      throw PlatformFailure('Failed to get historical app usage: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, NetworkTrafficEntity>> getAggregatedNetworkUsageByUid({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      // Try to get from database first
      final cachedData = await _databaseService.getAggregatedNetworkUsageByUid(
        startDate: start,
        endDate: end,
      );

      // If we have cached data, return it
      if (cachedData.isNotEmpty) {
        return cachedData;
      }

      // Otherwise, fetch from platform and cache
      final Map<String, dynamic>? data = await _methodChannel.invokeMethod(
        'getAggregatedNetworkUsageByUid',
        {
          'start': start.millisecondsSinceEpoch,
          'end': end.millisecondsSinceEpoch,
        },
      );
      
      if (data == null) {
        return {};
      }
      
      final parsedData = await Isolate.run(() => _networkTrafficParser.parseMap(data, aggregationTimestamp: end));
      
      // Cache the data for future use
      await _databaseService.saveNetworkTrafficData(parsedData.values.toList());
      
      return parsedData;
    } catch (e) {
      // Fallback to cached data on error
      final cachedData = await _databaseService.getAggregatedNetworkUsageByUid(
        startDate: start,
        endDate: end,
      );
      if (cachedData.isNotEmpty) {
        return cachedData;
      }
      throw PlatformFailure('Failed to get aggregated network usage: ${e.toString()}');
    }
  }


  @override
  Future<void> openBatteryOptimizationSettings() async {
    try {
      // First, try to request the specific ignore battery optimization permission
      await _methodChannel.invokeMethod('openBatteryOptimizationSettings');
    } catch (e) {
      throw PlatformFailure('Failed to open settings: ${e.toString()}');
    }
  }

  @override
  Future<bool?> hasIgnoreBatteryOptimizationPermission() async {
    try {
      return await _methodChannel.invokeMethod('hasIgnoreBatteryOptimizationPermission');
    } catch (e) {
      throw PermissionFailure('Failed to check battery optimization permission: ${e.toString()}');
    }
  }

  @override
  Future<void> requestIgnoreBatteryOptimizationPermission() async {
    try {
      await _methodChannel.invokeMethod('requestIgnoreBatteryOptimizationPermission');
    } catch (e) {
      throw PermissionFailure('Failed to request battery optimization exemption: ${e.toString()}');
    }
  }

  @override
  Future<List<NetworkTrafficEntity>> getAllHistoricalNetworkTraffic() async {
    try {
      final List<Map<String, dynamic>> rawData = await _databaseService.getAllNetworkTrafficData();
      if (rawData.isEmpty) {
        return [];
      }

      // Use concurrent processor for better performance
      final parsedData = await ConcurrentDataProcessor.processNetworkTrafficConcurrently(rawData);
      return parsedData;
    } catch (e) {
      throw DatabaseFailure('Failed to get all historical network traffic: ${e.toString()}');
    }
  }
}
