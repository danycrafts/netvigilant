import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:apptobe/core/services/location_service.dart';
import 'package:apptobe/core/providers/network_provider.dart';
import 'package:apptobe/core/widgets/dual_network_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final ILocationService _locationService = LocationService();
  LatLng? _currentPosition;
  LatLng? _publicIpPosition;
  bool _isLoading = true;
  NetworkProvider? _networkProvider;
  VoidCallback? _networkProviderListener;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Safely get reference to NetworkProvider
    if (_networkProvider == null) {
      _networkProvider = context.read<NetworkProvider>();
      _networkProvider!.startMonitoring();
      _setupNetworkProviderListener();
    }
  }

  @override
  void dispose() {
    _greenMarkerController.dispose();
    _blueMarkerController.dispose();
    
    // Safely clean up NetworkProvider
    if (_networkProviderListener != null && _networkProvider != null) {
      _networkProvider!.removeListener(_networkProviderListener!);
    }
    _networkProvider?.stopMonitoring();
    
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

    // Network provider listener is set up in didChangeDependencies
  }

  void _setupNetworkProviderListener() {
    if (_networkProvider == null) return;
    
    _networkProviderListener = () {
      if (!mounted) return;
      
      LatLng? newPublicIpPosition;
      
      // Get public IP position from either WiFi or Mobile network info
      if (_networkProvider!.wifiNetworkInfo?.publicIpPosition != null) {
        newPublicIpPosition = _networkProvider!.wifiNetworkInfo!.publicIpPosition;
      } else if (_networkProvider!.mobileNetworkInfo?.publicIpPosition != null) {
        newPublicIpPosition = _networkProvider!.mobileNetworkInfo!.publicIpPosition;
      }
      
      if (newPublicIpPosition != null && newPublicIpPosition != _publicIpPosition) {
        setState(() {
          _publicIpPosition = newPublicIpPosition;
        });
        
        // Adjust camera if both points are available
        if (_currentPosition != null) {
          _fitBounds();
        }
      }
    };
    
    _networkProvider!.addListener(_networkProviderListener!);
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
                                retinaMode: RetinaMode.isHighDensity(context),
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
          const Expanded(
            child: DualNetworkPanel(),
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