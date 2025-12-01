import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../constants/app_constants.dart';

abstract class BaseAuthScreen extends StatefulWidget {
  const BaseAuthScreen({super.key});
}

abstract class BaseAuthScreenState<T extends BaseAuthScreen> extends State<T> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @protected
  String get screenTitle;
  
  @protected
  String get submitButtonText;
  
  @protected
  List<Widget> get formFields;
  
  @protected
  Future<void> onSubmit();

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
    }
  }

  Future<void> handleSubmit() async {
    if (!formKey.currentState!.validate()) return;
    
    try {
      await onSubmit();
    } catch (e) {
      showMessage('An error occurred: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: screenTitle,
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...formFields,
              const SizedBox(height: AppConstants.largeSpacing),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : handleSubmit,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(submitButtonText),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEmailField() {
    return AppTextField(
      label: 'Email',
      hintText: 'Enter your email',
      prefixIcon: const Icon(Icons.email),
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      validator: validateEmail,
    );
  }

  Widget buildPasswordField() {
    return AppTextField(
      label: 'Password',
      hintText: 'Enter your password',
      prefixIcon: const Icon(Icons.lock),
      controller: passwordController,
      obscureText: true,
      validator: validatePassword,
    );
  }
}