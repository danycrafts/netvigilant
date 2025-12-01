import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';

class NetworkInfoPanel extends StatefulWidget {
  final String publicIp;
  final String ipDetails;
  final String localIp;
  final String connectionType;
  final bool isLoading;
  final LatLng? publicIpPosition;

  const NetworkInfoPanel({
    super.key,
    required this.publicIp,
    required this.ipDetails,
    required this.localIp,
    required this.connectionType,
    required this.isLoading,
    this.publicIpPosition,
  });

  @override
  State<NetworkInfoPanel> createState() => _NetworkInfoPanelState();
}

class _NetworkInfoPanelState extends State<NetworkInfoPanel> {
  String _downloadSpeed = '0.00 Mbps';
  String _uploadSpeed = 'N/A'; // Upload speed is more complex to measure reliably
  Timer? _speedTestTimer;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _speedTestTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        // Run tests sequentially to avoid interference
        _runSpeedTests();
      }
    });
  }

  @override
  void dispose() {
    _speedTestTimer?.cancel();
    super.dispose();
  }

  Future<void> _runSpeedTests() async {
    await _runDownloadTest();
    await _runUploadTest();
  }

  Future<void> _runDownloadTest() async {
    const downloadUrl =
        'https://proof.ovh.net/files/10Mb.dat'; // 10MB test file
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
      // Handle exceptions
    } finally {
      stopwatch.stop();
    }
  }

  Future<void> _runUploadTest() async {
    const uploadUrl = 'https://httpbin.org/post'; // This endpoint accepts POST data
    const uploadSizeMb = 5;
    final dataToUpload = Uint8List(uploadSizeMb * 1024 * 1024); // Create 5MB of dummy data

    final stopwatch = Stopwatch()..start();
    try {
      await _dio.post(
        uploadUrl,
        data: Stream.fromIterable(dataToUpload.map((e) => [e])), // Stream the data
        options: Options(
          headers: {
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
      // Handle exceptions
    } finally {
      stopwatch.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildSpeedIndicator('DOWNLOAD', _downloadSpeed, Icons.arrow_downward, context, isLoading: widget.isLoading)),
              const SizedBox(width: 16),
              Expanded(child: _buildSpeedIndicator('UPLOAD', _uploadSpeed, Icons.arrow_upward, context, isLoading: widget.isLoading)),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow('Local IP:', widget.localIp, isLoading: widget.isLoading),
                  _buildInfoRow('DNS:', 'System Default', isLoading: false), // Stable placeholder
                  _buildInfoRow(
                    'Public IP:',
                    widget.publicIp,
                    isLoading: widget.isLoading,
                  ),
                  if (widget.publicIpPosition != null)
                    _buildInfoRow(
                      'Coordinates:',
                      '${widget.publicIpPosition!.latitude.toStringAsFixed(4)}, ${widget.publicIpPosition!.longitude.toStringAsFixed(4)}',
                      isLoading: widget.isLoading,
                      trailing: IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          final coordinates = '${widget.publicIpPosition!.latitude},${widget.publicIpPosition!.longitude}';
                          Clipboard.setData(ClipboardData(text: coordinates));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coordinates copied to clipboard!')),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  _buildInfoRow('IP Details (ARIN):', widget.ipDetails, isMultiLine: true, isLoading: widget.isLoading),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {bool isMultiLine = false, required bool isLoading, Widget? trailing}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment:
            isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
              width: 120,
              child: Text(label, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
          Expanded(
            child: isLoading
                ? Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.surfaceVariant,
                    highlightColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
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
            color: colorScheme.primary.withOpacity(0.2),
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
}