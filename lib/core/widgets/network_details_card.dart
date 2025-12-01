import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../models/network_info.dart';

class NetworkDetailsCard extends StatefulWidget {
  final NetworkInfo networkInfo;
  final VoidCallback? onRefresh;

  const NetworkDetailsCard({
    super.key,
    required this.networkInfo,
    this.onRefresh,
  });

  @override
  State<NetworkDetailsCard> createState() => _NetworkDetailsCardState();
}

class _NetworkDetailsCardState extends State<NetworkDetailsCard> {
  String _downloadSpeed = '0.00 Mbps';
  String _uploadSpeed = '0.00 Mbps';
  Timer? _speedTestTimer;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    // Initial speed test only, no auto-refresh
    if (widget.networkInfo.isConnected) {
      _runSpeedTests();
    }
  }

  @override
  void dispose() {
    _speedTestTimer?.cancel();
    _dio.close();
    super.dispose();
  }

  Future<void> _runSpeedTests() async {
    await _runDownloadTest();
    await _runUploadTest();
  }

  void refreshSpeedTests() {
    if (widget.networkInfo.isConnected) {
      _runSpeedTests();
    }
  }

  Future<void> _runDownloadTest() async {
    const downloadUrl = 'https://proof.ovh.net/files/5Mb.dat';
    final stopwatch = Stopwatch()..start();
    try {
      await _dio.get(
        downloadUrl,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1 && stopwatch.elapsed.inSeconds > 0 && mounted) {
            final speedBps = (received * 8) / stopwatch.elapsed.inSeconds;
            final speedMbps = speedBps / (1024 * 1024);
            setState(() {
              _downloadSpeed = '${speedMbps.toStringAsFixed(2)} Mbps';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadSpeed = '0.00 Mbps';
        });
      }
    } finally {
      stopwatch.stop();
    }
  }

  Future<void> _runUploadTest() async {
    const uploadUrl = 'https://httpbin.org/post';
    const uploadSizeMb = 2;
    final dataToUpload = Uint8List(uploadSizeMb * 1024 * 1024);

    final stopwatch = Stopwatch()..start();
    try {
      await _dio.post(
        uploadUrl,
        data: Stream.fromIterable(dataToUpload.map((e) => [e])),
        options: Options(
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Length': dataToUpload.length.toString(),
          },
        ),
        onSendProgress: (sent, total) {
          if (stopwatch.elapsed.inSeconds > 0 && mounted) {
            final speedBps = (sent * 8) / stopwatch.elapsed.inSeconds;
            final speedMbps = speedBps / (1024 * 1024);
            setState(() {
              _uploadSpeed = '${speedMbps.toStringAsFixed(2)} Mbps';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadSpeed = '0.00 Mbps';
        });
      }
    } finally {
      stopwatch.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.networkInfo.isConnected) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _buildSpeedIndicator(
                      'DOWNLOAD',
                      _downloadSpeed,
                      Icons.arrow_downward,
                      context,
                      isLoading: widget.networkInfo.isLoading,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSpeedIndicator(
                      'UPLOAD',
                      _uploadSpeed,
                      Icons.arrow_upward,
                      context,
                      isLoading: widget.networkInfo.isLoading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            _buildInfoRow('Local IP:', widget.networkInfo.localIp, isLoading: widget.networkInfo.isLoading),
            if (widget.networkInfo.localIpv6 != null)
              _buildInfoRow('Local IPv6:', widget.networkInfo.localIpv6!, isLoading: widget.networkInfo.isLoading),
            _buildInfoRow('DNS Servers:', _formatDnsServers(widget.networkInfo.dnsServers), isLoading: widget.networkInfo.isLoading, isMultiLine: widget.networkInfo.dnsServers.length > 1),
            _buildInfoRow('DNS Detection:', widget.networkInfo.dnsDetectionMethod, isLoading: widget.networkInfo.isLoading),
            _buildInfoRow('Public IP:', widget.networkInfo.publicIp, isLoading: widget.networkInfo.isLoading),
            if (widget.networkInfo.publicIpPosition != null)
              _buildInfoRow(
                'Coordinates:',
                '${widget.networkInfo.publicIpPosition!.latitude.toStringAsFixed(4)}, ${widget.networkInfo.publicIpPosition!.longitude.toStringAsFixed(4)}',
                isLoading: widget.networkInfo.isLoading,
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    final coordinates = '${widget.networkInfo.publicIpPosition!.latitude},${widget.networkInfo.publicIpPosition!.longitude}';
                    Clipboard.setData(ClipboardData(text: coordinates));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coordinates copied to clipboard!')),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            _buildInfoRow('IP Details (ARIN):', widget.networkInfo.ipDetails, isMultiLine: true, isLoading: widget.networkInfo.isLoading),
            _buildInfoRow('Interface:', widget.networkInfo.interfaceName, isLoading: widget.networkInfo.isLoading),
            if (widget.networkInfo.ssid != null)
              _buildInfoRow('SSID:', widget.networkInfo.ssid!, isLoading: false),
            if (widget.networkInfo.operatorName != null)
              _buildInfoRow('Operator:', widget.networkInfo.operatorName!, isLoading: false),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMultiLine = false, required bool isLoading, Widget? trailing}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: isLoading
                ? Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    highlightColor: Theme.of(context).colorScheme.onSurface.withAlpha(26),
                    child: Container(
                      height: isMultiLine ? 32 : 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )
                : Text(value, style: textTheme.bodyMedium),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSpeedIndicator(String label, String speed, IconData icon, BuildContext context, {required bool isLoading}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(51),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(label, style: textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 8),
          isLoading
              ? Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.surfaceVariant,
                  highlightColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  child: Container(
                    width: 100,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
              : Text(speed, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDnsServers(List<String> dnsServers) {
    if (dnsServers.isEmpty) {
      return 'None detected';
    }
    
    if (dnsServers.length == 1) {
      return dnsServers.first;
    }
    
    // Format multiple DNS servers nicely
    return dnsServers.join('\n');
  }
}