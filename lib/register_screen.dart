import 'package:flutter/material.dart';
import 'package:apptobe/core/widgets/common_widgets.dart';
import 'package:apptobe/core/constants/app_constants.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Register',
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
            const SizedBox(height: AppConstants.defaultSpacing),
            AppTextField(
              label: 'Confirm Password',
              hintText: 'Confirm your password',
              prefixIcon: const Icon(Icons.lock),
              obscureText: true,
            ),
            const SizedBox(height: AppConstants.largeSpacing),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement register logic
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
