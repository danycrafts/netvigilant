import 'package:flutter/material.dart';
import 'package:apptobe/navigation/root_page.dart';
import 'package:provider/provider.dart';
import 'package:apptobe/core/providers/theme_provider.dart';
import 'package:apptobe/core/theme/app_theme.dart';
import 'package:apptobe/core/providers/user_profile_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ],
      child: const AppToBe(),
    ),
  );
}

class AppToBe extends StatelessWidget {
  const AppToBe({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'AppToBe',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const RootPage(),
        );
      },
    );
  }
}
