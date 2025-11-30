import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netvigilant/core/platform/platform_channel_wrappers.dart';
import 'package:netvigilant/presentation/screens/dashboard_screen.dart'; // Assuming this is the main screen after onboarding

// StateNotifier for managing permission state
class PermissionNotifier extends StateNotifier<bool> {
  PermissionNotifier() : super(false) {
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    state = await PermissionChecker.hasUsageStatsPermission();
  }

  Future<void> requestPermission() async {
    await PermissionChecker.requestUsageStatsPermission();
    await _checkPermissionStatus(); // Re-check after request
  }
}

final permissionProvider = StateNotifierProvider<PermissionNotifier, bool>((ref) {
  return PermissionNotifier();
});

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(permissionProvider);

    ref.listen<bool>(permissionProvider, (previous, next) {
      if (next) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to NetVigilant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.security,
              size: 100,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              'NetVigilant requires access to Usage Stats to monitor network and app usage on your device.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            if (!hasPermission)
              ElevatedButton(
                onPressed: () {
                  ref.read(permissionProvider.notifier).requestPermission();
                },
                child: const Text('Grant Usage Stats Permission'),
              )
            else
              const Column(
                children: [
                  Text(
                    'Permission Granted!',
                    style: TextStyle(fontSize: 18, color: Colors.green),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Redirecting to the app...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            const SizedBox(height: 40),
            const Text(
              'This permission is crucial for the app\'s core functionality. Without it, NetVigilant cannot provide detailed usage statistics.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
