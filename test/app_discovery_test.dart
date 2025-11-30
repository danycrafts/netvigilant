import 'package:flutter_test/flutter_test.dart';
import 'package:netvigilant/core/services/app_discovery_service.dart';
import 'package:netvigilant/domain/entities/app_info_entity.dart';
import 'package:netvigilant/presentation/providers/app_discovery_providers.dart';

void main() {
  group('App Discovery Tests', () {
    test('AppInfoEntity should be created correctly', () {
      final app = AppInfoEntity(
        packageName: 'com.example.test',
        appName: 'Test App',
        versionName: '1.0.0',
        versionCode: 1,
        isSystemApp: false,
        isEnabled: true,
        installTime: DateTime.now(),
        lastUpdateTime: DateTime.now(),
        targetSdkVersion: 30,
        minSdkVersion: 21,
        permissions: ['android.permission.INTERNET'],
        category: 'Productivity',
        appSize: 1024000,
      );

      expect(app.packageName, 'com.example.test');
      expect(app.appName, 'Test App');
      expect(app.isSystemApp, false);
      expect(app.formattedAppSize, '1000.0KB');
    });

    test('AppSortCriteria enum should have all required values', () {
      expect(AppSortCriteria.values.length, 8);
      expect(AppSortCriteria.values, contains(AppSortCriteria.name));
      expect(AppSortCriteria.values, contains(AppSortCriteria.size));
      expect(AppSortCriteria.values, contains(AppSortCriteria.category));
    });

    test('AppDiscoveryParams should have correct defaults', () {
      const params = AppDiscoveryParams();
      expect(params.includeSystemApps, false);
      expect(params.includeIcons, false);
      expect(params.useCache, true);
    });

    test('AppInfoEntity formatting methods work correctly', () {
      final app = AppInfoEntity(
        packageName: 'test.package',
        appName: 'Test',
        versionName: '1.0',
        versionCode: 1,
        isSystemApp: false,
        isEnabled: true,
        installTime: DateTime.now().subtract(const Duration(days: 1)),
        lastUpdateTime: DateTime.now().subtract(const Duration(hours: 5)),
        targetSdkVersion: 30,
        minSdkVersion: 21,
        permissions: [],
        category: 'Test',
        appSize: 2097152, // 2MB
        cpuUsage: 25.5,
        memoryUsage: 512.0,
        networkUsage: 1048576, // 1MB
        totalTimeInForeground: 3661000, // 1 hour, 1 minute, 1 second
      );

      expect(app.formattedAppSize, '2.0MB');
      expect(app.formattedNetworkUsage, '1.0MB');
      expect(app.formattedMemoryUsage, '512.0MB');
      expect(app.formattedTimeInForeground, '1h 1m');
      expect(app.usageCategory, 'Light'); // Based on the actual calculation
    });
  });
}