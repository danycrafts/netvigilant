import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apptobe/core/providers/auth_provider.dart';
import 'package:apptobe/login_screen.dart';
import 'package:apptobe/register_screen.dart';
import 'package:apptobe/navigation/root_page.dart';

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
            Text(
              'Welcome to NetVigilant',
              style: Theme.of(context).textTheme.displayLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Monitor your digital habits and stay secure',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
              onPressed: () async {
                try {
                  // Set guest mode in AuthProvider before navigating
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.setGuestMode();

                  // Navigate after setting guest mode
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const RootPage()),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}
