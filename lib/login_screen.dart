import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apptobe/core/presentation/base/base_auth_screen.dart';
import 'package:apptobe/core/providers/auth_provider.dart';
import 'package:apptobe/core/constants/app_constants.dart';

class LoginScreen extends BaseAuthScreen {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends BaseAuthScreenState<LoginScreen> {
  @override
  String get screenTitle => 'Login';

  @override
  String get submitButtonText => 'Login';

  @override
  List<Widget> get formFields => [
        buildEmailField(),
        const SizedBox(height: AppConstants.defaultSpacing),
        buildPasswordField(),
      ];

  @override
  Future<void> onSubmit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      emailController.text.trim(),
      passwordController.text,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        showMessage('Login successful!');
      } else {
        showMessage('Invalid email or password', isError: true);
      }
    }
  }
}
