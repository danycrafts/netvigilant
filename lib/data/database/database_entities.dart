class AppUsageRecord {
  final int? id;
  final String packageName;
  final String appName;
  final double networkUsage;
  final int totalTimeInForeground;
  final double cpuUsage;
  final double memoryUsage;
  final double batteryUsage;
  final int launchCount;
  final DateTime lastTimeUsed;
  final DateTime recordDate;

  AppUsageRecord({
    this.id,
    required this.packageName,
    required this.appName,
    required this.networkUsage,
    required this.totalTimeInForeground,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.batteryUsage,
    required this.launchCount,
    required this.lastTimeUsed,
    required this.recordDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'networkUsage': networkUsage,
      'totalTimeInForeground': totalTimeInForeground,
      'cpuUsage': cpuUsage,
      'memoryUsage': memoryUsage,
      'batteryUsage': batteryUsage,
      'launchCount': launchCount,
      'lastTimeUsed': lastTimeUsed.millisecondsSinceEpoch,
      'recordDate': recordDate.millisecondsSinceEpoch,
    };
  }

  static AppUsageRecord fromMap(Map<String, dynamic> map) {
    return AppUsageRecord(
      id: map['id'],
      packageName: map['packageName'],
      appName: map['appName'],
      networkUsage: map['networkUsage'],
      totalTimeInForeground: map['totalTimeInForeground'],
      cpuUsage: map['cpuUsage'],
      memoryUsage: map['memoryUsage'],
      batteryUsage: map['batteryUsage'],
      launchCount: map['launchCount'],
      lastTimeUsed: DateTime.fromMillisecondsSinceEpoch(map['lastTimeUsed']),
      recordDate: DateTime.fromMillisecondsSinceEpoch(map['recordDate']),
    );
  }
}

class NetworkTrafficRecord {
  final int? id;
  final String packageName;
  final String appName;
  final int uid;
  final int rxBytes;
  final int txBytes;
  final DateTime timestamp;
  final String networkType;
  final bool isBackgroundTraffic;

  NetworkTrafficRecord({
    this.id,
    required this.packageName,
    required this.appName,
    required this.uid,
    required this.rxBytes,
    required this.txBytes,
    required this.timestamp,
    required this.networkType,
    required this.isBackgroundTraffic,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'uid': uid,
      'rxBytes': rxBytes,
      'txBytes': txBytes,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'networkType': networkType,
      'isBackgroundTraffic': isBackgroundTraffic ? 1 : 0,
    };
  }

  static NetworkTrafficRecord fromMap(Map<String, dynamic> map) {
    return NetworkTrafficRecord(
      id: map['id'],
      packageName: map['packageName'],
      appName: map['appName'],
      uid: map['uid'],
      rxBytes: map['rxBytes'],
      txBytes: map['txBytes'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      networkType: map['networkType'],
      isBackgroundTraffic: map['isBackgroundTraffic'] == 1,
    );
  }
}

class RealTimeMetricsRecord {
  final int? id;
  final double uplinkSpeed;
  final double downlinkSpeed;
  final DateTime timestamp;

  RealTimeMetricsRecord({
    this.id,
    required this.uplinkSpeed,
    required this.downlinkSpeed,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uplinkSpeed': uplinkSpeed,
      'downlinkSpeed': downlinkSpeed,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  static RealTimeMetricsRecord fromMap(Map<String, dynamic> map) {
    return RealTimeMetricsRecord(
      id: map['id'],
      uplinkSpeed: map['uplinkSpeed'],
      downlinkSpeed: map['downlinkSpeed'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}

class DailySummaryRecord {
  final int? id;
  final DateTime date;
  final double totalDataUsage;
  final int activeAppsCount;
  final double peakDownloadSpeed;
  final double peakUploadSpeed;
  final int totalForegroundTime;

  DailySummaryRecord({
    this.id,
    required this.date,
    required this.totalDataUsage,
    required this.activeAppsCount,
    required this.peakDownloadSpeed,
    required this.peakUploadSpeed,
    required this.totalForegroundTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'totalDataUsage': totalDataUsage,
      'activeAppsCount': activeAppsCount,
      'peakDownloadSpeed': peakDownloadSpeed,
      'peakUploadSpeed': peakUploadSpeed,
      'totalForegroundTime': totalForegroundTime,
    };
  }

  static DailySummaryRecord fromMap(Map<String, dynamic> map) {
    return DailySummaryRecord(
      id: map['id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      totalDataUsage: map['totalDataUsage'],
      activeAppsCount: map['activeAppsCount'],
      peakDownloadSpeed: map['peakDownloadSpeed'],
      peakUploadSpeed: map['peakUploadSpeed'],
      totalForegroundTime: map['totalForegroundTime'],
    );
  }
}