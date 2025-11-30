import 'package:netvigilant/domain/entities/app_usage_entity.dart';
import 'package:netvigilant/domain/entities/network_traffic_entity.dart';

abstract class DataParser<T> {
  T parse(Map<String, dynamic> json);
  List<T> parseList(List<dynamic> data);
  Map<String, T> parseMap(Map<String, dynamic> data, {DateTime? aggregationTimestamp});
}

class NetworkTrafficParser implements DataParser<NetworkTrafficEntity> {
  @override
  NetworkTrafficEntity parse(Map<String, dynamic> json) {
    final networkType = _parseNetworkType(json['networkType']);
    
    return NetworkTrafficEntity(
      appName: json['appName'] ?? 'Unknown',
      packageName: json['packageName'] ?? 'unknown',
      uid: json['uid'] as int? ?? 0, // Added UID parsing
      txBytes: (json['txBytes'] as num?)?.toInt() ?? 0,
      rxBytes: (json['rxBytes'] as num?)?.toInt() ?? 0,
      timestamp: json['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch((json['timestamp'] as num).toInt())
          : DateTime.now(),
      networkType: networkType,
      isBackgroundTraffic: json['isBackgroundTraffic'] ?? false,
    );
  }

  @override
  List<NetworkTrafficEntity> parseList(List<dynamic> data) {
    return data.map((json) => parse(Map<String, dynamic>.from(json))).toList();
  }

  @override
  Map<String, NetworkTrafficEntity> parseMap(Map<String, dynamic> data, {DateTime? aggregationTimestamp}) {
    final Map<String, NetworkTrafficEntity> result = {};
    
    data.forEach((uidKey, value) { // Renamed uid to uidKey to avoid conflict
      if (value is Map<String, dynamic>) {
        final networkTypes = value['networkTypes'] as Set<String>? ?? <String>{};
        final networkType = _parseNetworkTypeFromSet(networkTypes);
        
        result[uidKey] = NetworkTrafficEntity(
          appName: value['appName'] ?? 'Unknown',
          packageName: value['packageName'] ?? 'unknown',
          uid: int.tryParse(uidKey) ?? 0, // Parse UID from key for aggregated data
          txBytes: (value['totalTxBytes'] as num?)?.toInt() ?? 0,
          rxBytes: (value['totalRxBytes'] as num?)?.toInt() ?? 0,
          timestamp: aggregationTimestamp ?? DateTime.now(),
          networkType: networkType,
          isBackgroundTraffic: false,
        );
      }
    });
    
    return result;
  }

  NetworkType _parseNetworkType(dynamic networkTypeData) {
    if (networkTypeData is int) {
      return _parseNetworkTypeFromInt(networkTypeData);
    } else if (networkTypeData is String) {
      return NetworkType.values.firstWhere(
        (e) => e.toString().split('.').last == networkTypeData,
        orElse: () => NetworkType.unknown,
      );
    }
    return NetworkType.unknown;
  }

  NetworkType _parseNetworkTypeFromInt(int value) {
    switch (value) {
      case 1:
      case 17:
      case 9:
        return NetworkType.wifi;
      case 0:
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
      case 10:
      case 11:
      case 12:
      case 13:
      case 14:
      case 15:
      case 16:
        return NetworkType.mobile;
      default:
        return NetworkType.unknown;
    }
  }

  NetworkType _parseNetworkTypeFromSet(Set<String> networkTypes) {
    if (networkTypes.contains('wifi')) {
      return NetworkType.wifi;
    } else if (networkTypes.contains('mobile')) {
      return NetworkType.mobile;
    }
    return NetworkType.unknown;
  }
}

class AppUsageParser implements DataParser<AppUsageEntity> {
  @override
  AppUsageEntity parse(Map<String, dynamic> json) {
    return AppUsageEntity(
      appName: json['appName'] ?? 'Unknown',
      packageName: json['packageName'] ?? 'unknown',
      cpuUsage: (json['cpuUsage'] as num?)?.toDouble() ?? 0.0,
      memoryUsage: (json['memoryUsage'] as num?)?.toDouble() ?? 0.0,
      batteryUsage: (json['batteryUsage'] as num?)?.toDouble() ?? 0.0,
      totalTimeInForeground: (json['totalTimeInForeground'] as num?)?.toInt() ?? 0,
      launchCount: (json['launchCount'] as num?)?.toInt() ?? 0,
      lastTimeUsed: json['lastTimeUsed'] != null 
          ? DateTime.fromMillisecondsSinceEpoch((json['lastTimeUsed'] as num).toInt())
          : DateTime.now(),
      networkUsage: (json['networkUsage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<AppUsageEntity> parseList(List<dynamic> data) {
    return data.map((json) => parse(Map<String, dynamic>.from(json))).toList();
  }

  @override
  Map<String, AppUsageEntity> parseMap(Map<String, dynamic> data, {DateTime? aggregationTimestamp}) {
    final Map<String, AppUsageEntity> result = {};
    
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        // Pass aggregationTimestamp down if parse also supports it, or handle here
        result[key] = parse(value);
      }
    });
    
    return result;
  }
}