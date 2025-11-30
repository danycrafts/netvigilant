import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netvigilant/presentation/screens/splash_screen.dart';
import 'package:netvigilant/core/di/service_locator.dart';
import 'package:netvigilant/core/theme/app_theme.dart';
import 'package:netvigilant/core/theme/theme_provider.dart' as theme_provider;
import 'package:netvigilant/core/utils/logger.dart';
import 'package:netvigilant/presentation/screens/onboarding_screen.dart';
import 'package:netvigilant/core/services/local_storage_service.dart';
import 'package:netvigilant/core/platform/platform_channel_wrappers.dart';
import 'package:netvigilant/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  setupServiceLocator();
  
  log("NetVigilant: Application starting...");

  runApp(const ProviderScope(child: NetVigilantApp()));
}

class NetVigilantApp extends ConsumerWidget {
  const NetVigilantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(theme_provider.themeProvider.notifier);

    return MaterialApp(
      title: 'NetVigilant',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.flutterThemeMode,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: PermissionChecker.hasUsageStatsPermission(), // Check permission status
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            if (snapshot.data == true) {
              // Permission granted, proceed to splash screen
              return const SplashScreen();
            } else {
              // Permission not granted, show onboarding screen
              _showPermissionReminder(context); // Call reminder logic
              return const OnboardingScreen();
            }
          }
        },
      ),
    );
  }

  // Helper method to show permission reminder notification
  void _showPermissionReminder(BuildContext context) async {
    final localStorageService = sl<LocalStorageService>();
    final notificationService = sl<NotificationService>();
    
    final lastReminderTimestamp = await localStorageService.getLastPermissionReminderTimestamp();
    final now = DateTime.now();
    
    // Send reminder if never sent or if 24 hours have passed since last reminder
    if (lastReminderTimestamp == null || now.difference(lastReminderTimestamp).inHours >= 24) {
      notificationService.showBasicNotification(
        id: 1002, // Unique ID for permission reminder
        title: 'Permission Required for NetVigilant',
        body: 'Please grant "Usage Access" permission to enable all features. Tap here to open settings.',
        payload: 'permission_reminder',
      );
      await localStorageService.saveLastPermissionReminderTimestamp(now);
      log('Permission reminder notification sent.');
    }
  }
}