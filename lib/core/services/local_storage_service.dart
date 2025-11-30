import 'package:shared_preferences/shared_preferences.dart';
import 'package:netvigilant/core/interfaces/storage.dart';

class LocalStorageService implements IPreferencesStorage {
  final SharedPreferences _prefs;

  // Private constructor to enforce singleton-like behavior with async init
  LocalStorageService._(this._prefs);

  // Factory constructor for asynchronous initialization
  static Future<LocalStorageService> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService._(prefs);
  }

  static const String _backgroundMonitoringKey = 'background_monitoring_active';
  static const String _themePreferenceKey = 'theme_preference';
  static const String _dataRetentionDaysKey = 'data_retention_days';
  static const String _refreshIntervalKey = 'refresh_interval_seconds';
  static const String _usageStatsPermissionKey = 'usage_stats_permission_granted';
  static const String _batteryOptimizationIgnoredKey = 'battery_optimization_ignored';
  static const String _firstLaunchKey = 'is_first_launch';
  static const String _alertThresholdKey = 'data_usage_alert_threshold';
  static const String _alertsEnabledKey = 'data_usage_alerts_enabled';
  static const String _lastPermissionReminderTimestampKey = 'last_permission_reminder_timestamp'; // New key
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _realTimeMonitoringEnabledKey = 'real_time_monitoring_enabled';

  Future<void> saveBackgroundMonitoringStatus(bool isActive) async {
    await _prefs.setBool(_backgroundMonitoringKey, isActive);
  }

  Future<bool> getBackgroundMonitoringStatus() async {
    return _prefs.getBool(_backgroundMonitoringKey) ?? false;
  }

  Future<void> saveThemePreference(int themeMode) async {
    await _prefs.setInt(_themePreferenceKey, themeMode);
  }

  Future<int> getThemePreference() async {
    return _prefs.getInt(_themePreferenceKey) ?? 2; // Default to system
  }

  Future<void> saveDataRetentionDays(int days) async {
    await _prefs.setInt(_dataRetentionDaysKey, days);
  }

  Future<int> getDataRetentionDays() async {
    return _prefs.getInt(_dataRetentionDaysKey) ?? 30; // Default 30 days
  }

  Future<void> saveRefreshInterval(int seconds) async {
    await _prefs.setInt(_refreshIntervalKey, seconds);
  }

  Future<int> getRefreshInterval() async {
    return _prefs.getInt(_refreshIntervalKey) ?? 5; // Default 5 seconds
  }

  // Permission state persistence
  Future<void> saveUsageStatsPermissionStatus(bool isGranted) async {
    await _prefs.setBool(_usageStatsPermissionKey, isGranted);
  }

  Future<bool> getUsageStatsPermissionStatus() async {
    return _prefs.getBool(_usageStatsPermissionKey) ?? false;
  }

  Future<void> saveBatteryOptimizationIgnored(bool isIgnored) async {
    await _prefs.setBool(_batteryOptimizationIgnoredKey, isIgnored);
  }

  Future<bool> getBatteryOptimizationIgnored() async {
    return _prefs.getBool(_batteryOptimizationIgnoredKey) ?? false;
  }

  // First launch detection
  Future<void> setFirstLaunchComplete() async {
    await _prefs.setBool(_firstLaunchKey, false);
  }

  Future<bool> isFirstLaunch() async {
    return _prefs.getBool(_firstLaunchKey) ?? true; // Default to true for first launch
  }

  // Alert settings
  Future<void> saveAlertThreshold(double threshold) async {
    await _prefs.setDouble(_alertThresholdKey, threshold);
  }

  Future<double> getAlertThreshold() async {
    return _prefs.getDouble(_alertThresholdKey) ?? 1000.0; // Default 1GB
  }

  Future<void> saveAlertsEnabled(bool enabled) async {
    await _prefs.setBool(_alertsEnabledKey, enabled);
  }

  Future<bool> getAlertsEnabled() async {
    return _prefs.getBool(_alertsEnabledKey) ?? true; // Default enabled
  }

  // New: Last permission reminder timestamp
  Future<void> saveLastPermissionReminderTimestamp(DateTime timestamp) async {
    await _prefs.setInt(_lastPermissionReminderTimestampKey, timestamp.millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastPermissionReminderTimestamp() async {
    final timestampMillis = _prefs.getInt(_lastPermissionReminderTimestampKey);
    return timestampMillis != null ? DateTime.fromMillisecondsSinceEpoch(timestampMillis) : null;
  }

  // Settings persistence for UI state

  Future<void> clearAllData() async {
    await _prefs.clear();
  }

  // Background task support methods
  Future<void> storeHourlySummary({
    required DateTime timestamp,
    required double totalDownloadBytes,
    required double totalUploadBytes,
    required double avgDownloadSpeed,
    required double avgUploadSpeed,
    required double maxDownloadSpeed,
    required double maxUploadSpeed,
    required int totalAppsUsed,
  }) async {
    final key = 'hourly_summary_${timestamp.millisecondsSinceEpoch}';
    final summaryData = {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'totalDownloadBytes': totalDownloadBytes,
      'totalUploadBytes': totalUploadBytes,
      'avgDownloadSpeed': avgDownloadSpeed,
      'avgUploadSpeed': avgUploadSpeed,
      'maxDownloadSpeed': maxDownloadSpeed,
      'maxUploadSpeed': maxUploadSpeed,
      'totalAppsUsed': totalAppsUsed,
    };
    await _prefs.setString(key, summaryData.toString());
  }

  Future<int> getDataRetentionPeriod() async {
    return getDataRetentionDays();
  }

  // Onboarding completion tracking
  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_onboardingCompletedKey, completed);
  }

  Future<bool> isOnboardingCompleted() async {
    return _prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> saveRealTimeMonitoringEnabled(bool enabled) async {
    await _prefs.setBool(_realTimeMonitoringEnabledKey, enabled);
  }

  Future<bool> getRealTimeMonitoringEnabled() async {
    return _prefs.getBool(_realTimeMonitoringEnabledKey) ?? true;
  }

  Future<void> clearUserData() async {
    // Clear only user-generated settings, keep permission states and first launch flag
    await _prefs.remove(_backgroundMonitoringKey);
    await _prefs.remove(_dataRetentionDaysKey);
    await _prefs.remove(_refreshIntervalKey);
    await _prefs.remove(_alertThresholdKey);
    await _prefs.remove(_alertsEnabledKey);
  }

  // Interface implementation methods
  @override
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    return _prefs.getBool(key) ?? defaultValue;
  }

  @override
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    return _prefs.getInt(key) ?? defaultValue;
  }

  @override
  Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  @override
  Future<String> getString(String key, {String defaultValue = ''}) async {
    return _prefs.getString(key) ?? defaultValue;
  }

  @override
  Future<List<String>> getStringList(String key, {List<String> defaultValue = const []}) async {
    return _prefs.getStringList(key) ?? defaultValue;
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}