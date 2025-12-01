import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apptobe/core/presentation/base/base_auth_screen.dart';
import 'package:apptobe/core/providers/auth_provider.dart';
import 'package:apptobe/core/constants/app_constants.dart';
import 'package:apptobe/core/widgets/common_widgets.dart';

class RegisterScreen extends BaseAuthScreen {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends BaseAuthScreenState<RegisterScreen> {
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  String get screenTitle => 'Register';

  @override
  String get submitButtonText => 'Register';

  @override
  List<Widget> get formFields => [
        buildEmailField(),
        const SizedBox(height: AppConstants.defaultSpacing),
        buildPasswordField(),
        const SizedBox(height: AppConstants.defaultSpacing),
        _buildConfirmPasswordField(),
      ];

  Widget _buildConfirmPasswordField() {
    return AppTextField(
      label: 'Confirm Password',
      hintText: 'Confirm your password',
      prefixIcon: const Icon(Icons.lock),
      controller: _confirmPasswordController,
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  @override
  Future<void> onSubmit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      emailController.text.trim(),
      passwordController.text,
      _confirmPasswordController.text,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        showMessage('Registration successful!');
      } else {
        showMessage('Registration failed. Please try again.', isError: true);
      }
    }
  }
}
