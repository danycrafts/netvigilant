import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:apptobe/core/services/location_service.dart';
import 'package:apptobe/network_info_panel.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:apptobe/core/services/isolate_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Data class to hold network info results from the isolate
class NetworkInfoResult {
  final String localIp;
  final String publicIp;
  final String ipDetails;
  final LatLng? publicIpPosition;

  NetworkInfoResult({
    required this.localIp,
    required this.publicIp,
    required this.ipDetails,
    this.publicIpPosition,
  });
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final ILocationService _locationService = LocationService();
  LatLng? _currentPosition;
  LatLng? _publicIpPosition;
  bool _isLoading = true;

  // Network Info Panel State
  String _publicIp = 'Fetching...';
  String _ipDetails = 'Fetching...';
  String _localIp = 'Fetching...';
  String _connectionType = '...';
  bool _isNetworkInfoLoading = true;

  late final AnimationController _greenMarkerController;
  late final AnimationController _blueMarkerController;

  @override
  void initState() {
    super.initState();
    _greenMarkerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _blueMarkerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2, milliseconds: 500), // Offset animation
    )..repeat();
    _determinePosition();
  }

  @override
  void dispose() {
    _greenMarkerController.dispose();
    _blueMarkerController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    final position = await _locationService.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    }

    // Fetch local and public IP info
    await _fetchNetworkInfo();

    // Adjust camera if both points are available
    if (_currentPosition != null && _publicIpPosition != null) {
      _fitBounds();
    }
  }

  Future<void> _fetchNetworkInfo() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (mounted) {
      setState(() {
        _connectionType = connectivityResult.contains(ConnectivityResult.wifi) ? 'WiFi' : (connectivityResult.contains(ConnectivityResult.mobile) ? 'Mobile' : 'Offline');
      });
    }
    
    // Run network fetching in a background isolate
    final result = await runInIsolate(_fetchNetworkDataIsolate, connectivityResult);

    if (mounted) {
      setState(() {
        _localIp = result.localIp;
        _publicIp = result.publicIp;
        _ipDetails = result.ipDetails;
        _publicIpPosition = result.publicIpPosition;
        _isNetworkInfoLoading = false;
      });
    }
  }

  // This static function will be sent to the isolate.
  // It cannot access any instance members of _HomeScreenState.
  static Future<NetworkInfoResult> _fetchNetworkDataIsolate(List<ConnectivityResult> connectivityResult) async {
    String localIp = 'Error';
    String publicIp = 'Error';
    String ipDetails = 'N/A';
    LatLng? publicIpPosition;

    try {
      // This will fetch the device's IP on the local network.
      // It works primarily on WiFi. If not on WiFi, it will result in a null,
      // which is the correct behavior for non-local network types like Mobile Data.
      final networkInfo = NetworkInfo();
      localIp = await networkInfo.getWifiIP() ?? 'N/A (Not on WiFi)';
    } catch (e) {
      // If there's an error fetching, we'll report it.
      localIp = 'Error';
    }

    try {
      final ipResponse = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (ipResponse.statusCode == 200) {
        publicIp = json.decode(ipResponse.body)['ip'];

        final detailsResponse = await http.get(Uri.parse('http://ip-api.com/json/$publicIp'));
        if (detailsResponse.statusCode == 200) {
          final details = json.decode(detailsResponse.body);
          ipDetails = '${details['org'] ?? 'N/A'}\n${details['isp'] ?? 'N/A'}\n${details['country'] ?? 'N/A'}';
          publicIpPosition = LatLng(details['lat'], details['lon']);
        } else {
          ipDetails = 'Details unavailable';
        }
      }
    } catch (e) {
      // ignore
    }

    return NetworkInfoResult(
      localIp: localIp,
      publicIp: publicIp,
      ipDetails: ipDetails,
      publicIpPosition: publicIpPosition,
    );
  }

  void _zoomIn() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom - 1);
  }

  void _recenter() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15.0);
    }
  }

  void _fitBounds() {
    if (_currentPosition == null || _publicIpPosition == null) return;

    var bounds = LatLngBounds(
      _currentPosition!,
      _publicIpPosition!,
    );

    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentPosition == null
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "Could not determine location. Please enable location services and grant permission.",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentPosition!,
                              initialZoom: 13.0, // A reasonable default before fitting
                              minZoom: 2.0, // Allow zooming out to see the globe
                              maxZoom: 18.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                subdomains: const ['a', 'b', 'c', 'd'],
                                userAgentPackageName: 'com.example.apptobe',
                              ),
                              MarkerLayer(markers: [
                                // Green marker for user's physical location
                                Marker(
                                  width: 60.0,
                                  height: 60.0,
                                  point: _currentPosition!,
                                  child: AnimatedLocationMarker(
                                    animation: _greenMarkerController,
                                  ),
                                ),
                                // Blue marker for public IP location
                                if (_publicIpPosition != null)
                                  Marker(
                                    width: 60.0,
                                    height: 60.0,
                                    point: _publicIpPosition!,
                                    child: AnimatedLocationMarker(
                                      animation: _blueMarkerController,
                                      color: Colors.blue,
                                    ),
                                  ),
                              ]
                                  // Filter out null markers before building
                                  .where((m) => m.point.latitude != 0)
                                  .toList(),
                              ),
                            ],
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: Column(
                              children: [
                                FloatingActionButton.small(
                                  heroTag: "zoomInBtn",
                                  onPressed: _zoomIn,
                                  child: const Icon(Icons.add),
                                ),
                                const SizedBox(height: 8),
                                FloatingActionButton.small(
                                  heroTag: "zoomOutBtn",
                                  onPressed: _zoomOut,
                                  child: const Icon(Icons.remove),
                                ),
                                const SizedBox(height: 8),
                                FloatingActionButton.small(
                                  heroTag: "recenterBtn",
                                  onPressed: _recenter,
                                  child: const Icon(Icons.my_location),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
          ),
          Expanded(
            child: Container(
              child: NetworkInfoPanel(
                publicIp: _publicIp,
                ipDetails: _ipDetails,
                localIp: _localIp,
                connectionType: _connectionType,
                isLoading: _isNetworkInfoLoading,
                publicIpPosition: _publicIpPosition,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedLocationMarker extends AnimatedWidget {
  final Color color;

  const AnimatedLocationMarker({
    super.key,
    required Animation<double> animation,
    this.color = Colors.green,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final size = 50.0 * animation.value;


    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Pulsating "breathing" circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(1.0 - animation.value),
            ),
          ),
          // Solid center dot
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}