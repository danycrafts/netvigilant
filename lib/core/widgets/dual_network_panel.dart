import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/network_info.dart';
import '../providers/network_provider.dart';
import 'network_status_indicator.dart';
import 'network_details_card.dart';

class DualNetworkPanel extends StatelessWidget {
  const DualNetworkPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, child) {
        final hasWifi = networkProvider.hasWifiConnection;
        final hasMobile = networkProvider.hasMobileConnection;
        
        if (!hasWifi && !hasMobile) {
          return const _NoNetworkWidget();
        }

        return Column(
          children: [
            _buildNetworkStatusHeader(networkProvider),
            _buildRefreshHeader(context, networkProvider),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (hasWifi && networkProvider.wifiNetworkInfo != null) ...[
                      _buildNetworkSection(
                        context,
                        'WiFi Network',
                        networkProvider.wifiNetworkInfo!,
                        Icons.wifi,
                        networkProvider,
                      ),
                      if (hasMobile && networkProvider.mobileNetworkInfo != null)
                        const SizedBox(height: 16),
                    ],
                    if (hasMobile && networkProvider.mobileNetworkInfo != null) ...[
                      _buildNetworkSection(
                        context,
                        'Mobile Network',
                        networkProvider.mobileNetworkInfo!,
                        Icons.signal_cellular_alt,
                        networkProvider,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNetworkStatusHeader(NetworkProvider networkProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (networkProvider.hasWifiConnection)
            Expanded(
              child: NetworkStatusIndicator(
                networkInfo: networkProvider.wifiNetworkInfo,
                title: 'WiFi',
                onTap: () => networkProvider.refreshNetworkInfo(),
              ),
            ),
          if (networkProvider.hasWifiConnection && networkProvider.hasMobileConnection)
            const SizedBox(width: 12),
          if (networkProvider.hasMobileConnection)
            Expanded(
              child: NetworkStatusIndicator(
                networkInfo: networkProvider.mobileNetworkInfo,
                title: 'Mobile',
                onTap: () => networkProvider.refreshNetworkInfo(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRefreshHeader(BuildContext context, NetworkProvider networkProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Network Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => networkProvider.refreshNetworkInfo(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSection(
    BuildContext context,
    String title,
    NetworkInfo networkInfo,
    IconData icon,
    NetworkProvider networkProvider,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                'Updated: ${_formatTime(networkInfo.lastUpdated)}',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          NetworkDetailsCard(
            networkInfo: networkInfo,
            onRefresh: () => networkProvider.refreshNetworkInfo(),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _NoNetworkWidget extends StatelessWidget {
  const _NoNetworkWidget();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.signal_wifi_off,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Network Connection',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your WiFi or mobile data connection',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}