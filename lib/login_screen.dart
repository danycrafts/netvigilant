import 'package:flutter/material.dart';
import 'package:apptobe/core/widgets/common_widgets.dart';
import 'package:apptobe/core/constants/app_constants.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Login',
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppTextField(
              label: 'Email',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email),
            ),
            const SizedBox(height: AppConstants.defaultSpacing),
            AppTextField(
              label: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock),
              obscureText: true,
            ),
            const SizedBox(height: AppConstants.largeSpacing),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement login logic
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
