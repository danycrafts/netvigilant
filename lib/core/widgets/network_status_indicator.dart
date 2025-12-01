import 'package:flutter/material.dart';
import '../models/network_info.dart';

class NetworkStatusIndicator extends StatelessWidget {
  final NetworkInfo? networkInfo;
  final String title;
  final VoidCallback? onTap;

  const NetworkStatusIndicator({
    super.key,
    required this.networkInfo,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    Color indicatorColor;
    String statusText;
    IconData icon;

    if (networkInfo == null) {
      indicatorColor = Colors.grey;
      statusText = 'Unavailable';
      icon = Icons.signal_wifi_off;
    } else {
      switch (networkInfo!.status) {
        case NetworkStatus.connected:
          indicatorColor = Colors.green;
          statusText = 'Connected';
          break;
        case NetworkStatus.connecting:
          indicatorColor = Colors.orange;
          statusText = 'Connecting...';
          break;
        case NetworkStatus.disconnected:
          indicatorColor = Colors.red;
          statusText = 'Disconnected';
          break;
      }

      icon = networkInfo!.type == NetworkType.wifi 
          ? Icons.wifi 
          : Icons.signal_cellular_alt;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: indicatorColor.withAlpha(77)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: indicatorColor,
                boxShadow: networkInfo?.status == NetworkStatus.connected
                    ? [
                        BoxShadow(
                          color: indicatorColor.withAlpha(128),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: colorScheme.onSurface),
            const SizedBox(width: 4),
            Text(
              title,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: textTheme.labelSmall?.copyWith(
                color: indicatorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}