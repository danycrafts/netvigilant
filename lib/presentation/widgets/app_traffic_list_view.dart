import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netvigilant/presentation/providers/network_providers.dart';
import 'package:netvigilant/presentation/screens/app_detail_screen.dart';

class AppTrafficListView extends ConsumerWidget {
  const AppTrafficListView({super.key});

  String _formatDataUsage(double bytes) {
    if (bytes < 1024) {
      return '${bytes.toStringAsFixed(0)} B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyUsageAsyncValue = ref.watch(weeklyNetworkUsageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'App Network Usage (7 Days)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Refresh the data
                  ref.invalidate(weeklyNetworkUsageProvider);
                },
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
        weeklyUsageAsyncValue.when(
          data: (networkUsage) {
            if (networkUsage.isEmpty) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Theme.of(context).primaryColor.withAlpha((255 * 0.6).round()),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Usage Data Available',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Make sure usage access permission is granted to view detailed app statistics.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await ref.read(networkRepositoryProvider).requestUsageStatsPermission();
                          ref.invalidate(weeklyNetworkUsageProvider);
                        },
                        child: const Text('Grant Permission'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Group usage by app
            final Map<String, Map<String, dynamic>> appUsageMap = {};
            
            for (final usage in networkUsage) {
              final appKey = usage.packageName;
              if (appUsageMap.containsKey(appKey)) {
                appUsageMap[appKey]!['totalBytes'] += (usage.rxBytes + usage.txBytes);
                appUsageMap[appKey]!['rxBytes'] += usage.rxBytes;
                appUsageMap[appKey]!['txBytes'] += usage.txBytes;
              } else {
                appUsageMap[appKey] = {
                  'appName': usage.appName,
                  'packageName': usage.packageName,
                  'totalBytes': usage.rxBytes + usage.txBytes,
                  'rxBytes': usage.rxBytes,
                  'txBytes': usage.txBytes,
                  'networkType': usage.networkType,
                  'isBackground': usage.isBackgroundTraffic,
                };
              }
            }

            // Sort apps by total data usage
            final sortedApps = appUsageMap.values.toList()
              ..sort((a, b) => (b['totalBytes'] as int).compareTo(a['totalBytes'] as int));

            // Show top 10 apps
            final topApps = sortedApps.take(10).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topApps.length,
              itemBuilder: (context, index) {
                final app = topApps[index];
                final totalBytes = app['totalBytes'] as int;
                final appName = app['appName'] as String;
                final packageName = app['packageName'] as String;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
                      child: Text(
                        appName.isNotEmpty ? appName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      appName.isNotEmpty ? appName : packageName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total: ${_formatDataUsage(totalBytes.toDouble())}'),
                        Row(
                          children: [
                            Icon(
                              Icons.download,
                              size: 12,
                              color: Colors.green,
                            ),
                            Text(
                              ' ${_formatDataUsage((app['rxBytes'] as int).toDouble())}',
                              style: TextStyle(fontSize: 12, color: Colors.green),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.upload,
                              size: 12,
                              color: Colors.orange,
                            ),
                            Text(
                              ' ${_formatDataUsage((app['txBytes'] as int).toDouble())}',
                              style: TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (app['isBackground'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withAlpha((255 * 0.2).round()),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'BG',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppDetailScreen(
                            packageName: packageName,
                            appName: appName.isNotEmpty ? appName : packageName,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Loading app usage data...'),
                ],
              ),
            ),
          ),
          error: (error, stack) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(
                    'Error Loading Data',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(weeklyNetworkUsageProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
