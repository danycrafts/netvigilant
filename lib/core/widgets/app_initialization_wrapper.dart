import 'package:flutter/material.dart';

class AppInitializationWrapper extends StatefulWidget {
  final Widget child;

  const AppInitializationWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AppInitializationWrapper> createState() => _AppInitializationWrapperState();
}

class _AppInitializationWrapperState extends State<AppInitializationWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Give the providers time to initialize
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF121217),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF33B1FF)
                        : const Color(0xFF33B1FF),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'NetVigilant',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF121217),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}