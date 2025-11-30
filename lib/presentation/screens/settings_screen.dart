import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netvigilant/presentation/providers/network_providers.dart';
import 'package:netvigilant/presentation/providers/database_providers.dart';
import 'package:netvigilant/core/theme/theme_provider.dart' as theme_provider;
import 'package:netvigilant/core/theme/app_theme.dart';
import 'package:netvigilant/core/services/local_storage_service.dart';
import 'package:netvigilant/core/di/service_locator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _realTimeMonitoring = true;
  bool _backgroundMonitoring = false;
  bool _dataUsageAlerts = true;
  double _alertThreshold = 1000; // MB
  String _refreshInterval = '5 seconds';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final localStorageService = sl<LocalStorageService>();
    
    _backgroundMonitoring = await localStorageService.getBackgroundMonitoringStatus(); // Directly use localStorageService
    _realTimeMonitoring = await localStorageService.getRealTimeMonitoringEnabled();
    _dataUsageAlerts = await localStorageService.getAlertsEnabled();
    _alertThreshold = await localStorageService.getAlertThreshold();
    
    final refreshIntervalSeconds = await localStorageService.getRefreshInterval();
    _refreshInterval = '$refreshIntervalSeconds second${refreshIntervalSeconds == 1 ? '' : 's'}';
    
    setState(() {});
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Settings',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Theme Section
                  _buildSectionHeader('Appearance'),
                  _buildThemeCard(),
                  const SizedBox(height: 24),

                  // Permissions Section
                  _buildSectionHeader('Permissions'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Usage Access Permission'),
                  subtitle: const Text('Required for app-specific data monitoring'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final hasPermission = await ref.read(networkRepositoryProvider).hasUsageStatsPermission();
                      if (hasPermission == false) {
                        await ref.read(networkRepositoryProvider).requestUsageStatsPermission();
                      } else {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Permission already granted')),
                        );
                      }
                    },
                    child: const Text('Grant'),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.battery_saver),
                  title: const Text('Battery Optimization'),
                  subtitle: const Text('Disable to ensure continuous monitoring'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _showBatteryOptimizationDialog();
                    },
                    child: const Text('Configure'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Monitoring Settings
          _buildSectionHeader('Monitoring'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.timeline),
                  title: const Text('Real-time Monitoring'),
                  subtitle: const Text('Monitor network speeds in real-time'),
                  value: _realTimeMonitoring,
                  onChanged: (bool value) async {
                    setState(() => _realTimeMonitoring = value);
                    
                    // Persist the setting
                    final localStorageService = sl<LocalStorageService>();
                    await localStorageService.saveRealTimeMonitoringEnabled(value);
                    
                    // Apply the setting
                    if (value) {
                      await ref.read(networkRepositoryProvider).startContinuousMonitoring();
                    } else {
                      await ref.read(networkRepositoryProvider).stopContinuousMonitoring();
                    }
                  },
                ),
                const Divider(),
                SwitchListTile(
                  secondary: const Icon(Icons.work),
                  title: const Text('Background Monitoring'),
                  subtitle: const Text('Continue monitoring when app is in background'),
                  value: _backgroundMonitoring,
                  onChanged: (bool value) async {
                    setState(() => _backgroundMonitoring = value);
                    final dashboardNotifier = ref.read(dashboardProvider.notifier);
                    if (value) {
                      await dashboardNotifier.startBackgroundMonitoring();
                    } else {
                      await dashboardNotifier.stopBackgroundMonitoring();
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Refresh Interval'),
                  subtitle: Text('Update frequency: $_refreshInterval'),
                  trailing: DropdownButton<String>(
                    value: _refreshInterval,
                    items: const [
                      DropdownMenuItem(value: '1 second', child: Text('1 second')),
                      DropdownMenuItem(value: '5 seconds', child: Text('5 seconds')),
                      DropdownMenuItem(value: '10 seconds', child: Text('10 seconds')),
                      DropdownMenuItem(value: '30 seconds', child: Text('30 seconds')),
                    ],
                    onChanged: (String? value) async {
                      if (value != null) {
                        setState(() => _refreshInterval = value);
                        
                        // Persist the setting
                        final localStorageService = sl<LocalStorageService>();
                        final seconds = int.parse(value.split(' ').first);
                        await localStorageService.saveRefreshInterval(seconds);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Alerts & Notifications
          _buildSectionHeader('Alerts & Notifications'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text('Data Usage Alerts'),
                  subtitle: const Text('Get notified when usage exceeds threshold'),
                  value: _dataUsageAlerts,
                  onChanged: (bool value) async {
                    setState(() => _dataUsageAlerts = value);
                    
                    // Persist the setting
                    final localStorageService = sl<LocalStorageService>();
                    await localStorageService.saveAlertsEnabled(value);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.data_usage),
                  title: const Text('Alert Threshold'),
                  subtitle: Text('${_alertThreshold.toInt()} MB'),
                  trailing: SizedBox(
                    width: 150,
                    child: Slider(
                      value: _alertThreshold,
                      min: 100,
                      max: 5000,
                      divisions: 49,
                      label: '${_alertThreshold.toInt()} MB',
                      onChanged: (double value) async {
                        setState(() => _alertThreshold = value);
                        
                        // Persist the setting
                        final localStorageService = sl<LocalStorageService>();
                        await localStorageService.saveAlertThreshold(value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Data Management
          _buildSectionHeader('Data Management'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Data Retention'),
                  subtitle: const Text('Keep data for 30 days'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showDataRetentionDialog();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Export Data'),
                  subtitle: const Text('Export usage data to CSV'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _exportData();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Permanently delete all usage data'),
                  onTap: () {
                    _showClearDataDialog();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // App Information
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('App Version'),
                  subtitle: const Text('NetVigilant v1.0.0'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Report Issue'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _launchUrl('https://github.com/danycrafts/NetVigilant/issues'); // Placeholder URL
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _launchUrl('https://www.example.com/privacy'); // Placeholder URL
                  },
                ),
              ],
            ),
          ),

                  const SizedBox(height: 100), // Extra space at bottom
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard() {
    return Consumer(
      builder: (context, ref, child) {
        final currentTheme = ref.watch(theme_provider.themeProvider);
        final themeNotifier = ref.read(theme_provider.themeProvider.notifier);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.palette,
                        color: AppColors.primaryCyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Choose your preferred appearance',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildThemeOption(
                        context,
                        'Light',
                        Icons.light_mode,
                        currentTheme == theme_provider.AppThemeMode.light,
                        () => themeNotifier.setTheme(theme_provider.AppThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildThemeOption(
                        context,
                        'Dark',
                        Icons.dark_mode,
                        currentTheme == theme_provider.AppThemeMode.dark,
                        () => themeNotifier.setTheme(theme_provider.AppThemeMode.dark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildThemeOption(
                        context,
                        'System',
                        Icons.settings_system_daydream,
                        currentTheme == theme_provider.AppThemeMode.system,
                        () => themeNotifier.setTheme(theme_provider.AppThemeMode.system),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryCyan.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryCyan 
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? AppColors.primaryCyan 
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected 
                    ? AppColors.primaryCyan 
                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  void _showBatteryOptimizationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Battery Optimization'),
          content: const Text(
            'To ensure continuous monitoring, NetVigilant needs to be excluded from battery optimization.\n\n'
            'This allows the app to run in the background and provide real-time data usage alerts.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                // Check if already granted
                final isIgnoring = await ref.read(networkRepositoryProvider).hasIgnoreBatteryOptimizationPermission();
                if (isIgnoring == true) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Battery optimization already ignored.')),
                  );
                  return;
                }

                // Try to request specific ignore battery optimization
                try {
                  await ref.read(networkRepositoryProvider).requestIgnoreBatteryOptimizationPermission();
                } catch (e) {
                  // Fallback to general settings if specific request fails
                  await ref.read(networkRepositoryProvider).openBatteryOptimizationSettings();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Could not directly request, opened general settings.')),
                  );
                }
                navigator.pop();
              },
              child: const Text('Configure'),
            ),
          ],
        );
      },
    );
  }

  void _showDataRetentionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedRetentionPeriod = '30 days'; // Initial value

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Data Retention'),
              content: StatefulBuilder(
                builder: (context, setStateDialog) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (String period in ['7 days', '30 days', '90 days'])
                      // ignore: deprecated_member_use
                      RadioListTile<String>(
                        value: period,
                        // ignore: deprecated_member_use  
                        groupValue: selectedRetentionPeriod,
                        // ignore: deprecated_member_use
                        onChanged: (String? value) {
                          setStateDialog(() {
                            selectedRetentionPeriod = value!;
                          });
                        },
                        title: Text(period),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    // Save the retention period
                    final localStorageService = sl<LocalStorageService>();
                    final days = int.parse(selectedRetentionPeriod.split(' ').first);
                    await localStorageService.saveDataRetentionDays(days);
                    
                    if (!mounted) return;
                    navigator.pop();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Data retention set to $selectedRetentionPeriod')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _exportData() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Exporting data...')),
    );

    try {
      final networkData = await ref.read(networkRepositoryProvider).getAllHistoricalNetworkTraffic();

      if (networkData.isEmpty) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(content: Text('No data to export.')),
        );
        return;
      }

      // Prepare data for CSV
      List<List<dynamic>> csvData = [];
      // Add header row
      csvData.add([
        'Timestamp',
        'Package Name',
        'App Name',
        'Rx Bytes',
        'Tx Bytes',
        'Network Type',
        'Is Background Traffic',
      ]);

      // Add data rows
      for (var traffic in networkData) {
        csvData.add([
          traffic.timestamp.toIso8601String(),
          traffic.packageName,
          traffic.appName,
          traffic.rxBytes,
          traffic.txBytes,
          traffic.networkType.toString().split('.').last,
          traffic.isBackgroundTraffic,
        ]);
      }

      String csv = const ListToCsvConverter().convert(csvData);

      // Get directory for saving the file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/netvigilant_network_traffic_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
      final file = File(filePath);

      await file.writeAsString(csv);

      if (!mounted) return;
      messenger.hideCurrentSnackBar(); // Hide "Exporting data..."
      messenger.showSnackBar(
        SnackBar(content: Text('Data exported to $filePath')),
      );

    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar(); // Hide "Exporting data..."
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to export data: ${e.toString()}')),
      );
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'Are you sure you want to permanently delete all usage data? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                
                // Clear all user data from database and local storage
                final localStorageService = sl<LocalStorageService>();
                final databaseService = ref.read(databaseServiceProvider);
                
                await localStorageService.clearUserData();
                await databaseService.clearAllData();
                
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
                
                // Reload settings to reflect cleared state
                _loadSettings();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}