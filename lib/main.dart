import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:netvigilant/core/providers/theme_provider.dart';
import 'package:netvigilant/core/theme/app_theme.dart';
import 'package:netvigilant/core/providers/user_profile_provider.dart';
import 'package:netvigilant/core/providers/network_provider.dart';
import 'package:netvigilant/core/providers/auth_provider.dart';
import 'package:netvigilant/core/providers/map_provider.dart';
import 'package:netvigilant/auth_wrapper.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
      ],
      child: const NetVigilant(),
    ),
  );
}

class NetVigilant extends StatelessWidget {
  const NetVigilant({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'NetVigilant',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}
