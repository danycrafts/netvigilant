import '../interfaces/service_interfaces.dart';
import '../interfaces/repository_interfaces.dart';
import '../models/analytics_models.dart';

// SOLID - Single Responsibility: Only handles analytics calculations
class AnalyticsServiceImpl implements IAnalyticsService {
  final IUsageRepository _usageRepository;

  const AnalyticsServiceImpl({
    required IUsageRepository usageRepository,
  }) : _usageRepository = usageRepository;

  @override
  Future<T> calculateUsageStatistics<T>() async {
    final usageStats = await _usageRepository.getAllUsageStats<dynamic>();
    
    if (usageStats.isEmpty) {
      return const UsageStatistics.empty() as T;
    }

    int totalScreenTime = 0;
    int totalLaunches = 0;
    String mostUsedApp = '';
    int maxUsageTime = 0;

    for (final stat in usageStats) {
      final screenTime = _extractScreenTime(stat);
      final launches = _extractLaunches(stat);
      
      totalScreenTime += screenTime;
      totalLaunches += launches;

      if (screenTime > maxUsageTime) {
        maxUsageTime = screenTime;
        mostUsedApp = _extractPackageName(stat);
      }
    }

    return UsageStatistics(
      totalScreenTime: totalScreenTime,
      totalLaunches: totalLaunches,
      mostUsedApp: mostUsedApp,
      appsCount: usageStats.length,
    ) as T;
  }

  @override
  Future<List<T>> getTopUsedApps<T>(int limit) async {
    final usageStats = await _usageRepository.getAllUsageStats<dynamic>();
    
    final apps = <Map<String, dynamic>>[];
    for (final stat in usageStats) {
      apps.add({
        'packageName': _extractPackageName(stat),
        'screenTime': _extractScreenTime(stat),
        'launches': _extractLaunches(stat),
      });
    }

    apps.sort((a, b) => b['screenTime'].compareTo(a['screenTime']));
    return apps.take(limit).cast<T>().toList();
  }

  @override
  Future<List<T>> getRecentlyUsedApps<T>(int limit) async {
    final usageStats = await _usageRepository.getAllUsageStats<dynamic>();
    
    final apps = <Map<String, dynamic>>[];
    for (final stat in usageStats) {
      apps.add({
        'packageName': _extractPackageName(stat),
        'lastUsed': _extractLastUsed(stat),
        'screenTime': _extractScreenTime(stat),
      });
    }

    apps.sort((a, b) => b['lastUsed'].compareTo(a['lastUsed']));
    return apps.take(limit).cast<T>().toList();
  }

  // DRY - Common extraction methods
  int _extractScreenTime(dynamic stat) {
    if (stat.toString().contains('totalTimeInForeground')) {
      return int.tryParse(stat.toString().split(':')[1]) ?? 0;
    }
    return 0;
  }

  int _extractLaunches(dynamic stat) {
    if (stat.toString().contains('activations')) {
      return int.tryParse(stat.toString().split(':')[1]) ?? 0;
    }
    return 0;
  }

  String _extractPackageName(dynamic stat) {
    if (stat.toString().contains('packageName')) {
      return stat.toString().split(':')[1].trim();
    }
    return 'unknown';
  }

  int _extractLastUsed(dynamic stat) {
    if (stat.toString().contains('lastTimeUsed')) {
      return int.tryParse(stat.toString().split(':')[1]) ?? 0;
    }
    return 0;
  }
}