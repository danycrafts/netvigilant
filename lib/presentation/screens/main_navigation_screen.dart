import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netvigilant/presentation/screens/home_screen.dart';
import 'package:netvigilant/presentation/screens/dashboard_screen.dart';
import 'package:netvigilant/presentation/screens/all_apps_screen.dart';
import 'package:netvigilant/presentation/screens/settings_screen.dart';
import 'package:netvigilant/presentation/providers/network_providers.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    
    // Start monitoring when app opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final hasPermission = await ref.read(networkRepositoryProvider).hasUsageStatsPermission();
        if (hasPermission == true) {
          await ref.read(networkRepositoryProvider).startContinuousMonitoring();
        }
      } catch (e) {
        // Handle permission error gracefully
        debugPrint('Error starting monitoring: $e');
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          HomeScreen(),
          DashboardScreen(),
          AllAppsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'All Apps',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // Quick access to start/stop monitoring
                _showQuickActionsBottomSheet();
              },
              child: const Icon(Icons.speed),
            )
          : null,
    );
  }

  void _showQuickActionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.play_arrow, color: Colors.green),
                title: const Text('Start Monitoring'),
                subtitle: const Text('Begin real-time network monitoring'),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  navigator.pop();
                  try {
                    await ref.read(networkRepositoryProvider).startContinuousMonitoring();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Monitoring started')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.stop, color: Colors.red),
                title: const Text('Stop Monitoring'),
                subtitle: const Text('Stop real-time network monitoring'),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  navigator.pop();
                  try {
                    await ref.read(networkRepositoryProvider).stopContinuousMonitoring();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Monitoring stopped')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.blue),
                title: const Text('Refresh Data'),
                subtitle: const Text('Update all usage statistics'),
                onTap: () {
                  Navigator.pop(context);
                  // Data refresh functionality will be implemented
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refreshing data...')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.security, color: Colors.orange),
                title: const Text('Check Permissions'),
                subtitle: const Text('Verify usage access permission'),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  navigator.pop();
                  try {
                    final hasPermission = await ref.read(networkRepositoryProvider).hasUsageStatsPermission();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          hasPermission == true
                              ? 'All permissions granted'
                              : 'Usage access permission required',
                        ),
                        action: hasPermission != true
                            ? SnackBarAction(
                                label: 'Grant',
                                onPressed: () async {
                                  await ref.read(networkRepositoryProvider).requestUsageStatsPermission();
                                },
                              )
                            : null,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error checking permissions: $e')),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}