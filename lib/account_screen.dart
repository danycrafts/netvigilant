import 'package:apptobe/edit_profile_screen.dart';
import 'package:apptobe/login_screen.dart';
import 'package:apptobe/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apptobe/core/providers/theme_provider.dart';
import 'package:apptobe/core/providers/user_profile_provider.dart';
import 'package:apptobe/core/providers/auth_provider.dart';
import 'package:apptobe/core/widgets/common_widgets.dart';
import 'package:apptobe/core/constants/app_constants.dart';
import 'package:apptobe/core/architecture/base_widgets/base_screen.dart';

class AccountScreen extends BaseScreen {
  const AccountScreen({super.key});

  @override
  String get title => 'Account & Settings';

  @override
  Widget buildBody(BuildContext context) {
    return const _AccountScreenBody();
  }

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> 
    with ErrorHandlingMixin {

  @override
  Widget build(BuildContext context) {
    return Container(); // Placeholder, body will be handled by BaseScreen
  }
}

// SOLID - Separate body widget with single responsibility
class _AccountScreenBody extends StatelessWidget {
  const _AccountScreenBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
        children: <Widget>[
          const SizedBox(height: AppConstants.defaultSpacing),
          const _ProfileSection(),
          const _ProfileActionSection(),
          const Divider(),
          const _ThemeSection(),
          const Divider(),
          const AppSectionHeader(title: 'Notification Settings'),
          const _NotificationSection(),
          const _LogoutSection(),
        ],
      );
  }
}

// SOLID - Single responsibility widget for profile display
class _ProfileSection extends StatelessWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoggedIn) {
                return const _LoggedInProfile();
              } else {
                return const _GuestProfile();
              }
            },
          );
  }
}

// DRY - Reusable logged in profile widget
class _LoggedInProfile extends StatelessWidget {
  const _LoggedInProfile();

  @override
  Widget build(BuildContext context) {
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
  }
}

// DRY - Reusable guest profile widget
class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) {
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
}

// SOLID - Single responsibility widget for profile actions
class _ProfileActionSection extends StatelessWidget {
  const _ProfileActionSection();

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, UserProfileProvider>(
      builder: (context, authProvider, userProfileProvider, child) {
        if (authProvider.isLoggedIn) {
          return AppListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () => _handleEditProfile(context, userProfileProvider),
          );
        } else {
          return Column(
            children: [
              AppListTile(
                leading: const Icon(Icons.login),
                title: const Text('Login'),
                onTap: () => _navigateToLogin(context),
              ),
              AppListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Register'),
                onTap: () => _navigateToRegister(context),
              ),
            ],
          );
        }
      },
    );
  }

  // DRY - Extract navigation logic
  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  // DRY - Extract edit profile logic
  Future<void> _handleEditProfile(BuildContext context, UserProfileProvider userProfileProvider) async {
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
  }
}

// SOLID - Single responsibility widget for theme switching
class _ThemeSection extends StatelessWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
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
    );
  }
}

// SOLID - Single responsibility widget for notification settings
class _NotificationSection extends StatelessWidget {
  const _NotificationSection();

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, UserProfileProvider>(
      builder: (context, authProvider, userProfileProvider, child) {
        return Column(
          children: [
            _buildEmailNotificationTile(context, authProvider, userProfileProvider),
            _buildPhoneNotificationTile(context, authProvider, userProfileProvider),
            _buildPushNotificationTile(context, userProfileProvider),
          ],
        );
      },
    );
  }

  // DRY - Extract notification tile builders
  Widget _buildEmailNotificationTile(
    BuildContext context,
    AuthProvider authProvider,
    UserProfileProvider userProfileProvider,
  ) {
    return AppSwitchListTile(
      title: const Text('Email Notifications'),
      subtitle: authProvider.isLoggedIn ? null : const Text('Login required'),
      value: authProvider.isLoggedIn ? userProfileProvider.emailNotifications : false,
      onChanged: authProvider.isLoggedIn ? userProfileProvider.updateEmailNotifications : null,
      secondary: Icon(
        Icons.email_outlined,
        color: authProvider.isLoggedIn ? null : Theme.of(context).disabledColor,
      ),
    );
  }

  Widget _buildPhoneNotificationTile(
    BuildContext context,
    AuthProvider authProvider,
    UserProfileProvider userProfileProvider,
  ) {
    return AppSwitchListTile(
      title: const Text('Phone Notifications'),
      subtitle: authProvider.isLoggedIn ? null : const Text('Login required'),
      value: authProvider.isLoggedIn ? userProfileProvider.phoneNotifications : false,
      onChanged: authProvider.isLoggedIn ? userProfileProvider.updatePhoneNotifications : null,
      secondary: Icon(
        Icons.phone_android_outlined,
        color: authProvider.isLoggedIn ? null : Theme.of(context).disabledColor,
      ),
    );
  }

  Widget _buildPushNotificationTile(
    BuildContext context,
    UserProfileProvider userProfileProvider,
  ) {
    return AppSwitchListTile(
      title: const Text('Push Notifications'),
      value: userProfileProvider.pushNotifications,
      onChanged: userProfileProvider.updatePushNotifications,
      secondary: const Icon(Icons.notifications_active_outlined),
    );
  }
}

// SOLID - Single responsibility widget for logout functionality
class _LogoutSection extends StatelessWidget {
  const _LogoutSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoggedIn) {
          return AppListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _showLogoutDialog(context, authProvider),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  // DRY - Extract logout dialog logic
  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () => _performLogout(context, authProvider),
            ),
          ],
        );
      },
    );
  }

  // DRY - Extract logout logic
  Future<void> _performLogout(BuildContext context, AuthProvider authProvider) async {
    await authProvider.logout();
    if (context.mounted) {
      Provider.of<UserProfileProvider>(context, listen: false).clearProfile();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    }
  }
}