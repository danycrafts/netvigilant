import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netvigilant/core/theme/app_theme.dart';
import 'package:netvigilant/core/services/local_storage_service.dart';
import 'package:netvigilant/core/di/service_locator.dart';
import 'package:netvigilant/presentation/screens/onboarding/welcome_screen.dart';
import 'package:netvigilant/presentation/screens/main_navigation_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunchAndNavigate();
  }

  Future<void> _checkFirstLaunchAndNavigate() async {
    // Show splash for at least 2 seconds for better UX
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      final localStorageService = sl<LocalStorageService>();
      final isFirstLaunch = await localStorageService.isFirstLaunch();
      
      if (!mounted) return;
      
      if (isFirstLaunch) {
        // Navigate to onboarding flow
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      } else {
        // Navigate to main app
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      // On error, go to main app to prevent user from being stuck
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryCyan,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.network_check,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App Name
              const Text(
                'NetVigilant',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                'Network Monitoring Made Simple',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Loading indicator
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}