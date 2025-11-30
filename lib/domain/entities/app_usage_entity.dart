import 'package:equatable/equatable.dart';

class AppUsageEntity extends Equatable {
  final String appName;
  final String packageName;
  final double cpuUsage;
  final double memoryUsage;
  final double batteryUsage;
  final int totalTimeInForeground;
  final int launchCount;
  final DateTime lastTimeUsed;
  final double networkUsage;

  const AppUsageEntity({
    required this.appName,
    required this.packageName,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.batteryUsage,
    required this.totalTimeInForeground,
    required this.launchCount,
    required this.lastTimeUsed,
    required this.networkUsage,
  });

  @override
  List<Object?> get props => [
    appName,
    packageName,
    cpuUsage,
    memoryUsage,
    batteryUsage,
    totalTimeInForeground,
    launchCount,
    lastTimeUsed,
    networkUsage,
  ];

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'packageName': packageName,
      'cpuUsage': cpuUsage,
      'memoryUsage': memoryUsage,
      'batteryUsage': batteryUsage,
      'totalTimeInForeground': totalTimeInForeground,
      'launchCount': launchCount,
      'lastTimeUsed': lastTimeUsed.millisecondsSinceEpoch,
      'networkUsage': networkUsage,
    };
  }
}
