import 'package:equatable/equatable.dart';

/// Comprehensive entity representing an installed application
/// Contains metadata, usage information, and runtime metrics
class AppInfoEntity extends Equatable {
  final String packageName;
  final String appName;
  final String versionName;
  final int versionCode;
  final bool isSystemApp;
  final bool isEnabled;
  final DateTime installTime;
  final DateTime lastUpdateTime;
  final int targetSdkVersion;
  final int minSdkVersion;
  final List<String> permissions;
  final String category;
  final int appSize; // in bytes
  final String? iconBase64;
  
  // Runtime metrics
  final bool isRunning;
  final double cpuUsage;
  final double memoryUsage;
  final double batteryUsage;
  final int networkUsage; // in bytes
  final DateTime lastUsedTime;
  final int totalTimeInForeground; // in milliseconds

  const AppInfoEntity({
    required this.packageName,
    required this.appName,
    required this.versionName,
    required this.versionCode,
    required this.isSystemApp,
    required this.isEnabled,
    required this.installTime,
    required this.lastUpdateTime,
    required this.targetSdkVersion,
    required this.minSdkVersion,
    required this.permissions,
    required this.category,
    required this.appSize,
    this.iconBase64,
    this.isRunning = false,
    this.cpuUsage = 0.0,
    this.memoryUsage = 0.0,
    this.batteryUsage = 0.0,
    this.networkUsage = 0,
    DateTime? lastUsedTime,
    this.totalTimeInForeground = 0,
  }) : lastUsedTime = lastUsedTime ?? installTime;

  /// Create AppInfoEntity from platform data map
  factory AppInfoEntity.fromMap(Map<String, dynamic> map) {
    return AppInfoEntity(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      versionName: map['versionName'] ?? '',
      versionCode: (map['versionCode'] as num?)?.toInt() ?? 0,
      isSystemApp: map['isSystemApp'] ?? false,
      isEnabled: map['isEnabled'] ?? true,
      installTime: DateTime.fromMillisecondsSinceEpoch(
        (map['installTime'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
      lastUpdateTime: DateTime.fromMillisecondsSinceEpoch(
        (map['lastUpdateTime'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
      targetSdkVersion: (map['targetSdkVersion'] as num?)?.toInt() ?? 0,
      minSdkVersion: (map['minSdkVersion'] as num?)?.toInt() ?? 0,
      permissions: (map['permissions'] as List?)?.cast<String>() ?? [],
      category: map['category'] ?? 'Unknown',
      appSize: (map['appSize'] as num?)?.toInt() ?? 0,
      iconBase64: map['iconBase64'] as String?,
      isRunning: map['isRunning'] ?? false,
      cpuUsage: (map['cpuUsage'] as num?)?.toDouble() ?? 0.0,
      memoryUsage: (map['memoryUsage'] as num?)?.toDouble() ?? 0.0,
      batteryUsage: (map['batteryUsage'] as num?)?.toDouble() ?? 0.0,
      networkUsage: (map['networkUsage'] as num?)?.toInt() ?? 0,
      lastUsedTime: DateTime.fromMillisecondsSinceEpoch(
        (map['lastUsedTime'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
      totalTimeInForeground: (map['totalTimeInForeground'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'versionName': versionName,
      'versionCode': versionCode,
      'isSystemApp': isSystemApp,
      'isEnabled': isEnabled,
      'installTime': installTime.millisecondsSinceEpoch,
      'lastUpdateTime': lastUpdateTime.millisecondsSinceEpoch,
      'targetSdkVersion': targetSdkVersion,
      'minSdkVersion': minSdkVersion,
      'permissions': permissions,
      'category': category,
      'appSize': appSize,
      'iconBase64': iconBase64,
      'isRunning': isRunning,
      'cpuUsage': cpuUsage,
      'memoryUsage': memoryUsage,
      'batteryUsage': batteryUsage,
      'networkUsage': networkUsage,
      'lastUsedTime': lastUsedTime.millisecondsSinceEpoch,
      'totalTimeInForeground': totalTimeInForeground,
    };
  }

  /// Create a copy with updated values
  AppInfoEntity copyWith({
    String? packageName,
    String? appName,
    String? versionName,
    int? versionCode,
    bool? isSystemApp,
    bool? isEnabled,
    DateTime? installTime,
    DateTime? lastUpdateTime,
    int? targetSdkVersion,
    int? minSdkVersion,
    List<String>? permissions,
    String? category,
    int? appSize,
    String? iconBase64,
    bool? isRunning,
    double? cpuUsage,
    double? memoryUsage,
    double? batteryUsage,
    int? networkUsage,
    DateTime? lastUsedTime,
    int? totalTimeInForeground,
  }) {
    return AppInfoEntity(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      isEnabled: isEnabled ?? this.isEnabled,
      installTime: installTime ?? this.installTime,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      targetSdkVersion: targetSdkVersion ?? this.targetSdkVersion,
      minSdkVersion: minSdkVersion ?? this.minSdkVersion,
      permissions: permissions ?? this.permissions,
      category: category ?? this.category,
      appSize: appSize ?? this.appSize,
      iconBase64: iconBase64 ?? this.iconBase64,
      isRunning: isRunning ?? this.isRunning,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      batteryUsage: batteryUsage ?? this.batteryUsage,
      networkUsage: networkUsage ?? this.networkUsage,
      lastUsedTime: lastUsedTime ?? this.lastUsedTime,
      totalTimeInForeground: totalTimeInForeground ?? this.totalTimeInForeground,
    );
  }

  /// Get human-readable app size
  String get formattedAppSize {
    if (appSize < 1024) {
      return '${appSize}B';
    } else if (appSize < 1024 * 1024) {
      return '${(appSize / 1024).toStringAsFixed(1)}KB';
    } else if (appSize < 1024 * 1024 * 1024) {
      return '${(appSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(appSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  /// Get human-readable network usage
  String get formattedNetworkUsage {
    if (networkUsage < 1024) {
      return '${networkUsage}B';
    } else if (networkUsage < 1024 * 1024) {
      return '${(networkUsage / 1024).toStringAsFixed(1)}KB';
    } else if (networkUsage < 1024 * 1024 * 1024) {
      return '${(networkUsage / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(networkUsage / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  /// Get human-readable memory usage
  String get formattedMemoryUsage {
    if (memoryUsage < 1) {
      return '${(memoryUsage * 1024).toStringAsFixed(0)}KB';
    } else if (memoryUsage < 1024) {
      return '${memoryUsage.toStringAsFixed(1)}MB';
    } else {
      return '${(memoryUsage / 1024).toStringAsFixed(1)}GB';
    }
  }

  /// Get human-readable time in foreground
  String get formattedTimeInForeground {
    final seconds = totalTimeInForeground ~/ 1000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    final days = hours ~/ 24;

    if (days > 0) {
      return '${days}d ${hours % 24}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes % 60}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds % 60}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Get time since last update
  String get timeSinceLastUpdate {
    final now = DateTime.now();
    final difference = now.difference(lastUpdateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if app is recently used (within last 24 hours)
  bool get isRecentlyUsed {
    final dayAgo = DateTime.now().subtract(const Duration(days: 1));
    return lastUsedTime.isAfter(dayAgo);
  }

  /// Check if app is recently updated (within last week)
  bool get isRecentlyUpdated {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return lastUpdateTime.isAfter(weekAgo);
  }

  /// Check if app is newly installed (within last 3 days)
  bool get isNewlyInstalled {
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    return installTime.isAfter(threeDaysAgo);
  }

  /// Get app usage intensity (combination of CPU, memory, and network)
  double get usageIntensity {
    // Weighted calculation of overall usage
    return (cpuUsage * 0.4) + (memoryUsage * 0.0001 * 0.3) + (networkUsage * 0.000001 * 0.3);
  }

  /// Get app usage category based on intensity
  String get usageCategory {
    final intensity = usageIntensity;
    if (intensity > 50) {
      return 'Heavy';
    } else if (intensity > 20) {
      return 'Moderate';
    } else if (intensity > 5) {
      return 'Light';
    } else {
      return 'Minimal';
    }
  }

  /// Check if app has dangerous permissions
  bool get hasDangerousPermissions {
    const dangerousPermissions = [
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.ACCESS_COARSE_LOCATION',
      'android.permission.CAMERA',
      'android.permission.RECORD_AUDIO',
      'android.permission.READ_CONTACTS',
      'android.permission.WRITE_CONTACTS',
      'android.permission.READ_SMS',
      'android.permission.SEND_SMS',
      'android.permission.READ_PHONE_STATE',
      'android.permission.CALL_PHONE',
      'android.permission.READ_EXTERNAL_STORAGE',
      'android.permission.WRITE_EXTERNAL_STORAGE',
    ];

    return permissions.any((permission) => dangerousPermissions.contains(permission));
  }

  @override
  List<Object?> get props => [
    packageName,
    appName,
    versionName,
    versionCode,
    isSystemApp,
    isEnabled,
    installTime,
    lastUpdateTime,
    targetSdkVersion,
    minSdkVersion,
    permissions,
    category,
    appSize,
    iconBase64,
    isRunning,
    cpuUsage,
    memoryUsage,
    batteryUsage,
    networkUsage,
    lastUsedTime,
    totalTimeInForeground,
  ];

  @override
  String toString() {
    return 'AppInfoEntity(packageName: $packageName, appName: $appName, category: $category, isRunning: $isRunning)';
  }
}