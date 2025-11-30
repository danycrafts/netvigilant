import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netvigilant/core/theme/app_theme.dart';
import 'package:netvigilant/presentation/providers/network_providers.dart';
import 'package:netvigilant/core/services/local_storage_service.dart';
import 'package:netvigilant/core/di/service_locator.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _usageStatsGranted = false;
  bool _batteryOptimizationConfigured = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final hasUsageStats = await ref.read(networkRepositoryProvider).hasUsageStatsPermission();
    final hasBatteryOptimization = await ref.read(networkRepositoryProvider).hasIgnoreBatteryOptimizationPermission();
    
    setState(() {
      _usageStatsGranted = hasUsageStats ?? false;
      _batteryOptimizationConfigured = hasBatteryOptimization ?? false;
    });
  }

  Future<void> _completeOnboarding() async {
    final localStorage = sl<LocalStorageService>();
    await localStorage.setOnboardingCompleted(true);
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildFeaturePage(),
                  _buildUsageStatsPermissionPage(),
                  _buildBatteryOptimizationPage(),
                  _buildCompletePage(),
                ],
              ),
            ),
            
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: List.generate(5, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
              decoration: BoxDecoration(
                color: index <= _currentPage 
                    ? AppColors.primaryCyan 
                    : Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App icon/logo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.network_check,
              size: 60,
              color: AppColors.primaryCyan,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Welcome to NetVigilant',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryCyan,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Your comprehensive network monitoring companion',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFeatureItem(Icons.speed, 'Real-time monitoring', 'Track network speeds and app usage live'),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.analytics, 'Detailed insights', 'Comprehensive usage statistics and trends'),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.security, 'Privacy focused', 'All data stays on your device'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.featured_play_list,
            size: 80,
            color: AppColors.primaryCyan,
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Powerful Features',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          _buildFeatureCard(
            Icons.network_wifi,
            'Network Monitoring',
            'Track data usage, speeds, and network quality in real-time',
            AppColors.primaryCyan,
          ),
          
          const SizedBox(height: 16),
          
          _buildFeatureCard(
            Icons.apps,
            'App Usage Tracking',
            'Monitor which apps use the most data, CPU, memory, and battery',
            AppColors.accentGreen,
          ),
          
          const SizedBox(height: 16),
          
          _buildFeatureCard(
            Icons.notifications,
            'Smart Alerts',
            'Get notified when usage thresholds are exceeded',
            AppColors.warningOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStatsPermissionPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _usageStatsGranted ? Icons.check_circle : Icons.security,
            size: 80,
            color: _usageStatsGranted ? AppColors.successGreen : AppColors.warningOrange,
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Usage Access Permission',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'NetVigilant needs access to usage statistics to provide detailed app monitoring.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          Card(
            color: _usageStatsGranted ? AppColors.successGreen.withValues(alpha: 0.1) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.primaryCyan,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Why this permission is needed:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPermissionReason('• Track which apps use data'),
                  _buildPermissionReason('• Monitor app usage patterns'),
                  _buildPermissionReason('• Provide detailed statistics'),
                  _buildPermissionReason('• Calculate usage trends'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _usageStatsGranted ? null : _requestUsageStatsPermission,
              icon: Icon(_usageStatsGranted ? Icons.check : Icons.settings),
              label: Text(_usageStatsGranted ? 'Permission Granted' : 'Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _usageStatsGranted ? AppColors.successGreen : AppColors.primaryCyan,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryOptimizationPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _batteryOptimizationConfigured ? Icons.check_circle : Icons.battery_saver,
            size: 80,
            color: _batteryOptimizationConfigured ? AppColors.successGreen : AppColors.warningOrange,
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Battery Optimization',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'For continuous monitoring, NetVigilant should be excluded from battery optimization.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          Card(
            color: _batteryOptimizationConfigured ? AppColors.successGreen.withValues(alpha: 0.1) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.battery_charging_full,
                        color: AppColors.primaryCyan,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Benefits of excluding from battery optimization:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPermissionReason('• Continuous background monitoring'),
                  _buildPermissionReason('• Real-time usage alerts'),
                  _buildPermissionReason('• Accurate data collection'),
                  _buildPermissionReason('• Consistent performance'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _batteryOptimizationConfigured ? null : _configureBatteryOptimization,
                  icon: Icon(_batteryOptimizationConfigured ? Icons.check : Icons.settings),
                  label: Text(_batteryOptimizationConfigured ? 'Already Configured' : 'Configure Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _batteryOptimizationConfigured ? AppColors.successGreen : AppColors.primaryCyan,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              TextButton(
                onPressed: () {
                  setState(() {
                    _batteryOptimizationConfigured = true;
                  });
                },
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: AppColors.successGreen,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'All Set!',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.successGreen,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'NetVigilant is ready to monitor your network usage and provide detailed insights.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.tips_and_updates,
                        color: AppColors.primaryCyan,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Getting Started Tips',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('Check the dashboard for real-time metrics'),
                  _buildTip('View app-specific usage in the Apps tab'),
                  _buildTip('Configure alerts in Settings'),
                  _buildTip('Export data when needed'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryCyan, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionReason(String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        reason,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: const BoxDecoration(
              color: AppColors.primaryCyan,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Back'),
              ),
            ),
          
          if (_currentPage > 0) const SizedBox(width: 16),
          
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _getNextButtonAction(),
              child: Text(_getNextButtonText()),
            ),
          ),
        ],
      ),
    );
  }

  String _getNextButtonText() {
    switch (_currentPage) {
      case 0:
      case 1:
        return 'Continue';
      case 2:
        return _usageStatsGranted ? 'Continue' : 'Grant Permission';
      case 3:
        return _batteryOptimizationConfigured ? 'Continue' : 'Configure';
      case 4:
        return 'Get Started';
      default:
        return 'Continue';
    }
  }

  VoidCallback? _getNextButtonAction() {
    switch (_currentPage) {
      case 0:
      case 1:
        return () {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        };
      case 2:
        if (_usageStatsGranted) {
          return () {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          };
        } else {
          return _requestUsageStatsPermission;
        }
      case 3:
        if (_batteryOptimizationConfigured) {
          return () {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          };
        } else {
          return _configureBatteryOptimization;
        }
      case 4:
        return _completeOnboarding;
      default:
        return null;
    }
  }

  Future<void> _requestUsageStatsPermission() async {
    try {
      await ref.read(networkRepositoryProvider).requestUsageStatsPermission();
      // Wait a bit for the user to potentially grant permission
      await Future.delayed(const Duration(seconds: 1));
      await _checkPermissions();
      
      if (_usageStatsGranted && mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting permission: $e')),
        );
      }
    }
  }

  Future<void> _configureBatteryOptimization() async {
    try {
      await ref.read(networkRepositoryProvider).requestIgnoreBatteryOptimizationPermission();
      // Wait a bit for the user to potentially configure
      await Future.delayed(const Duration(seconds: 1));
      await _checkPermissions();
      
      if (_batteryOptimizationConfigured && mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      // Fallback to general settings
      await ref.read(networkRepositoryProvider).openBatteryOptimizationSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please configure battery optimization manually.')),
        );
      }
    }
  }
}