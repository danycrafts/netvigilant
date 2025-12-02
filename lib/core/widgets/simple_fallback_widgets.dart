import 'package:flutter/material.dart';
import 'package:apptobe/core/constants/app_constants.dart';

class SimpleFallbackWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;

  const SimpleFallbackWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.apps,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleQuickAppsWidget extends StatelessWidget {
  const SimpleQuickAppsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleFallbackWidget(
      title: 'Quick Access',
      message: 'Your most used apps will appear here\nonce usage data is available',
      icon: Icons.flash_on,
    );
  }
}

class SimpleAnalyticsWidget extends StatelessWidget {
  const SimpleAnalyticsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleFallbackWidget(
      title: 'Usage Analytics',
      message: 'Detailed app usage statistics\nwill be shown here',
      icon: Icons.analytics,
    );
  }
}