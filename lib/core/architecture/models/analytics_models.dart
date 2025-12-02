// SOLID - Single Responsibility: Data models for analytics
class UsageStatistics {
  final int totalScreenTime;
  final int totalLaunches;
  final String mostUsedApp;
  final int appsCount;

  const UsageStatistics({
    required this.totalScreenTime,
    required this.totalLaunches,
    required this.mostUsedApp,
    required this.appsCount,
  });

  const UsageStatistics.empty()
      : totalScreenTime = 0,
        totalLaunches = 0,
        mostUsedApp = '',
        appsCount = 0;

  String get formattedScreenTime {
    final hours = totalScreenTime ~/ 3600000;
    final minutes = (totalScreenTime % 3600000) ~/ 60000;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  bool get isEmpty => totalScreenTime == 0 && totalLaunches == 0;
}

class TopApp {
  final String packageName;
  final String displayName;
  final int screenTime;
  final int launches;

  const TopApp({
    required this.packageName,
    required this.displayName,
    required this.screenTime,
    required this.launches,
  });

  String get formattedScreenTime {
    final hours = screenTime ~/ 3600000;
    final minutes = (screenTime % 3600000) ~/ 60000;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class RecentApp {
  final String packageName;
  final String displayName;
  final DateTime lastUsed;
  final int screenTime;

  const RecentApp({
    required this.packageName,
    required this.displayName,
    required this.lastUsed,
    required this.screenTime,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class AnalyticsCard {
  final String title;
  final String value;
  final String subtitle;
  final String icon;

  const AnalyticsCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });
}