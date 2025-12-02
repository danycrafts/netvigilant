import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apptobe/core/providers/auth_provider.dart';
import 'package:apptobe/navigation/root_page.dart';
import 'package:apptobe/welcome_screen.dart';
import 'package:apptobe/core/services/permission_manager.dart';
import 'dart:io';

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

        if (authProvider.isLoggedIn || authProvider.isGuestMode) {
          return const RootPage();
        } else {
          return const WelcomeScreen();
        }
      },
    );
  }
}
