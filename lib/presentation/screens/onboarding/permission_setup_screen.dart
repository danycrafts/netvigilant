import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netvigilant/core/theme/app_theme.dart';
import 'package:netvigilant/core/services/local_storage_service.dart';
import 'package:netvigilant/core/di/service_locator.dart';
import 'package:netvigilant/presentation/providers/network_providers.dart';
import 'package:netvigilant/presentation/screens/main_navigation_screen.dart';

class PermissionSetupScreen extends ConsumerStatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  ConsumerState<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends ConsumerState<PermissionSetupScreen> {
  int _currentStep = 0;
  bool _usageStatsGranted = false;
  bool _batteryOptimizationIgnored = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Permissions'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepTapped: (step) {
          if (step < _currentStep) {
            setState(() => _currentStep = step);
          }
        },
        controlsBuilder: (context, details) {
          return Row(
            children: [
              if (details.stepIndex < 2)
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(details.stepIndex == 1 ? 'Complete Setup' : 'Next'),
                  ),
                ),
              if (details.stepIndex > 0) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ),
              ],
            ],
          );
        },
        onStepContinue: () async {
          if (_currentStep == 0) {
            await _handleUsageStatsPermission();
          } else if (_currentStep == 1) {
            await _handleBatteryOptimization();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: [
          Step(
            title: const Text('Usage Access Permission'),
            content: _buildUsageStatsStep(),
            isActive: _currentStep == 0,
            state: _getStepState(0, _usageStatsGranted),
          ),
          Step(
            title: const Text('Battery Optimization'),
            content: _buildBatteryOptimizationStep(),
            isActive: _currentStep == 1,
            state: _getStepState(1, _batteryOptimizationIgnored),
          ),
          Step(
            title: const Text('Setup Complete'),
            content: _buildCompleteStep(),
            isActive: _currentStep == 2,
            state: _getStepState(2, true),
          ),
        ],
      ),
    );
  }

  StepState _getStepState(int step, bool completed) {
    if (step < _currentStep) {
      return completed ? StepState.complete : StepState.disabled;
    } else if (step == _currentStep) {
      return StepState.indexed;
    } else {
      return StepState.disabled;
    }
  }

  Widget _buildUsageStatsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.security,
          size: 64,
          color: Colors.orange,
        ),
        const SizedBox(height: 16),
        Text(
          'Why do we need Usage Access?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'NetVigilant needs Usage Access permission to:',
        ),
        const SizedBox(height: 12),
        _buildPermissionItem(
          icon: Icons.apps,
          title: 'Monitor app-specific data usage',
          description: 'Track which apps use the most data',
        ),
        _buildPermissionItem(
          icon: Icons.access_time,
          title: 'Track app usage patterns',
          description: 'Understand your usage habits',
        ),
        _buildPermissionItem(
          icon: Icons.network_check,
          title: 'Analyze network consumption',
          description: 'Provide detailed usage analytics',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This permission is safe and only used for monitoring. No personal data is collected.',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),
        if (_usageStatsGranted) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Usage Access permission granted!',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBatteryOptimizationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.battery_saver,
          size: 64,
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        Text(
          'Disable Battery Optimization',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'To ensure continuous monitoring, NetVigilant needs to run in the background without being restricted by battery optimization.',
        ),
        const SizedBox(height: 16),
        _buildPermissionItem(
          icon: Icons.monitor,
          title: 'Continuous monitoring',
          description: 'Keep tracking data usage 24/7',
        ),
        _buildPermissionItem(
          icon: Icons.notifications,
          title: 'Real-time alerts',
          description: 'Notify you when usage limits are exceeded',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This is optional but recommended for the best experience.',
                  style: TextStyle(color: Colors.orange.shade700),
                ),
              ),
            ],
          ),
        ),
        if (_batteryOptimizationIgnored) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Battery optimization disabled!',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 100,
          color: AppColors.successGreen,
        ),
        const SizedBox(height: 24),
        Text(
          'Setup Complete!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.successGreen,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'NetVigilant is now ready to monitor your network usage. You can change these permissions anytime in the settings.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _completeSetup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Start Using NetVigilant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUsageStatsPermission() async {
    setState(() => _isLoading = true);
    
    try {
      // Check current permission status
      final hasPermission = await ref.read(networkRepositoryProvider).hasUsageStatsPermission();
      
      if (hasPermission == true) {
        setState(() {
          _usageStatsGranted = true;
          _currentStep = 1;
        });
      } else {
        // Request permission
        await ref.read(networkRepositoryProvider).requestUsageStatsPermission();
        
        // Show dialog explaining next steps
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Grant Permission'),
            content: const Text(
              'You will now be taken to the Android settings. Please find "NetVigilant" in the list and enable "Usage access" permission.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _checkPermissionAndContinue();
                },
                child: const Text('I\'ve granted the permission'),
              ),
            ],
          ),
        );
      }
      
      // Save permission status
      final localStorageService = sl<LocalStorageService>();
      await localStorageService.saveUsageStatsPermissionStatus(_usageStatsGranted);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkPermissionAndContinue() async {
    final hasPermission = await ref.read(networkRepositoryProvider).hasUsageStatsPermission();
    
    setState(() {
      _usageStatsGranted = hasPermission ?? false;
      if (_usageStatsGranted) {
        _currentStep = 1;
      }
    });
    
    // Save permission status
    final localStorageService = sl<LocalStorageService>();
    await localStorageService.saveUsageStatsPermissionStatus(_usageStatsGranted);
  }

  Future<void> _handleBatteryOptimization() async {
    setState(() => _isLoading = true);
    
    try {
      await ref.read(networkRepositoryProvider).openBatteryOptimizationSettings();
      
      // Show dialog explaining next steps
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Disable Battery Optimization'),
          content: const Text(
            'In the battery optimization settings, find "NetVigilant" and select "Don\'t optimize" to ensure continuous monitoring.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _batteryOptimizationIgnored = true;
                  _currentStep = 2;
                });
              },
              child: const Text('Done'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _currentStep = 2;
                });
              },
              child: const Text('Skip'),
            ),
          ],
        ),
      );
      
      // Save battery optimization status
      final localStorageService = sl<LocalStorageService>();
      await localStorageService.saveBatteryOptimizationIgnored(_batteryOptimizationIgnored);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      
      // Skip to next step on error
      setState(() => _currentStep = 2);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeSetup() async {
    setState(() => _isLoading = true);
    
    try {
      final localStorageService = sl<LocalStorageService>();
      await localStorageService.setFirstLaunchComplete();
      
      // Start monitoring if permission is granted
      if (_usageStatsGranted) {
        await ref.read(networkRepositoryProvider).startContinuousMonitoring();
      }
      
      if (!mounted) return;
      
      // Navigate to main app
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        (route) => false,
      );
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}