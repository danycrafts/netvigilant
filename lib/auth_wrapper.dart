import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:netvigilant/core/providers/auth_provider.dart';
import 'package:netvigilant/login_screen.dart';
import 'package:netvigilant/register_screen.dart';
import 'package:netvigilant/navigation/root_page.dart';
import 'package:netvigilant/core/services/permission_manager.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasCheckedPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }

    if (!Platform.isAndroid) {
      setState(() => _hasCheckedPermissions = true);
      return;
    }

    final shouldRequest = await PermissionManager.shouldRequestUsagePermission();
    if (shouldRequest && mounted) {
      await _showPermissionDialog();
    }
    
    if (mounted) {
      setState(() => _hasCheckedPermissions = true);
    }
  }

  Future<void> _showPermissionDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('App Usage Permission Required'),
          content: const Text(
            'This app needs usage access permission to track app usage statistics. '
            'This helps provide insights about your digital habits.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Skip'),
              onPressed: () async {
                Navigator.of(context).pop();
                await PermissionManager.markUsagePermissionAsked();
              },
            ),
            TextButton(
              child: const Text('Grant Permission'),
              onPressed: () async {
                Navigator.of(context).pop();
                await PermissionManager.requestAndStoreUsagePermission();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading || !_hasCheckedPermissions) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.isLoggedIn) {
          return const RootPage();
        } else {
          return const WelcomeScreen();
        }
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.security,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 32),
            const Text(
              'Welcome to NetVigilant',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Monitor your digital habits and stay secure',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text('Register'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const RootPage()),
                );
              },
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}