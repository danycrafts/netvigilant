import 'package:netvigilant/edit_profile_screen.dart';
import 'package:netvigilant/login_screen.dart';
import 'package:netvigilant/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:netvigilant/core/providers/theme_provider.dart';
import 'package:netvigilant/core/providers/user_profile_provider.dart';
import 'package:netvigilant/core/providers/auth_provider.dart';
import 'package:netvigilant/core/widgets/common_widgets.dart';
import 'package:netvigilant/core/constants/app_constants.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Account & Settings',
      body: ListView(
        children: <Widget>[
          const SizedBox(height: AppConstants.defaultSpacing),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoggedIn) {
                return Consumer<UserProfileProvider>(
                  builder: (context, userProfileProvider, child) {
                    final profile = userProfileProvider.userProfile;
                    return Column(
                      children: [
                        CircleAvatar(
                          radius: AppConstants.avatarRadius,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          backgroundImage: profile.profileImage != null 
                              ? FileImage(profile.profileImage!) 
                              : null,
                          child: profile.profileImage == null
                              ? Icon(
                                  Icons.person, 
                                  size: 50,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                        const SizedBox(height: AppConstants.smallSpacing),
                        Text(
                          profile.fullName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@${profile.username}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: AppConstants.defaultSpacing),
                        const Divider(),
                      ],
                    );
                  },
                );
              } else {
                // Show app logo/icon when not logged in
                return Column(
                  children: [
                    CircleAvatar(
                      radius: AppConstants.avatarRadius,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: Icon(
                        Icons.security,
                        size: 50,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.smallSpacing),
                    Text(
                      'NetVigilant',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Guest User',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: AppConstants.defaultSpacing),
                    const Divider(),
                  ],
                );
              }
            },
          ),
          Consumer2<AuthProvider, UserProfileProvider>(
            builder: (context, authProvider, userProfileProvider, child) {
              if (authProvider.isLoggedIn) {
                return AppListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Profile'),
                  onTap: () async {
                    if (!mounted) return;
                    final profile = userProfileProvider.userProfile;
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          firstName: profile.firstName,
                          lastName: profile.lastName,
                          username: profile.username,
                          email: profile.email,
                          phone: profile.phone,
                          profileImage: profile.profileImage,
                        ),
                      ),
                    );
                    if (result != null) {
                      userProfileProvider.updateProfile(
                        profile.copyWith(
                          firstName: result['firstName'],
                          lastName: result['lastName'],
                          username: result['username'],
                          email: result['email'],
                          phone: result['phone'],
                          profileImage: result['profileImage'],
                        ),
                      );
                    }
                  },
                );
              } else {
                return Column(
                  children: [
                    AppListTile(
                      leading: const Icon(Icons.login),
                      title: const Text('Login'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                    ),
                    AppListTile(
                      leading: const Icon(Icons.person_add),
                      title: const Text('Register'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                    ),
                  ],
                );
              }
            },
          ),
          const Divider(),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return AppSwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: Text(
                  themeProvider.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                value: themeProvider.isDarkMode,
                onChanged: (bool value) {
                  themeProvider.toggleTheme();
                },
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
              );
            },
          ),
          const Divider(),
          const AppSectionHeader(title: 'Notification Settings'),
          Consumer<UserProfileProvider>(
            builder: (context, userProfileProvider, child) {
              return Column(
                children: [
                  AppSwitchListTile(
                    title: const Text('Email Notifications'),
                    value: userProfileProvider.emailNotifications,
                    onChanged: userProfileProvider.updateEmailNotifications,
                    secondary: const Icon(Icons.email_outlined),
                  ),
                  AppSwitchListTile(
                    title: const Text('Phone Notifications'),
                    value: userProfileProvider.phoneNotifications,
                    onChanged: userProfileProvider.updatePhoneNotifications,
                    secondary: const Icon(Icons.phone_android_outlined),
                  ),
                  AppSwitchListTile(
                    title: const Text('Push Notifications'),
                    value: userProfileProvider.pushNotifications,
                    onChanged: userProfileProvider.updatePushNotifications,
                    secondary: const Icon(Icons.notifications_active_outlined),
                  ),
                ],
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoggedIn) {
                return AppListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text('Logout'),
                              onPressed: () async {
                                if (!mounted) return;
                                await authProvider.logout();
                                Provider.of<UserProfileProvider>(context, listen: false).clearProfile();
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Logged out successfully')),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }
}
