import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:apptobe/core/services/location_service.dart';
import 'package:apptobe/core/providers/network_provider.dart';
import 'package:apptobe/core/widgets/dual_network_panel.dart';
import 'package:apptobe/core/presentation/widgets/map_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ILocationService _locationService = LocationService();
  LatLng? _currentPosition;
  LatLng? _publicIpPosition;
  bool _isLoading = true;
  NetworkProvider? _networkProvider;
  VoidCallback? _networkProviderListener;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupNetworkProviderIfNeeded();
  }

  @override
  void dispose() {
    _cleanupNetworkProvider();
    super.dispose();
  }

  void _setupNetworkProviderIfNeeded() {
    if (_networkProvider == null) {
      _networkProvider = context.read<NetworkProvider>();
      _networkProvider!.startMonitoring();
      _setupNetworkProviderListener();
    }
  }

  void _cleanupNetworkProvider() {
    if (_networkProviderListener != null && _networkProvider != null) {
      _networkProvider!.removeListener(_networkProviderListener!);
    }
    _networkProvider?.stopMonitoring();
  }

  Future<void> _determinePosition() async {
    final position = await _locationService.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    }
  }

  void _setupNetworkProviderListener() {
    if (_networkProvider == null) return;
    
    _networkProviderListener = () {
      if (!mounted) return;
      
      final newPublicIpPosition = _getPublicIpPosition();
      
      if (newPublicIpPosition != null && newPublicIpPosition != _publicIpPosition) {
        setState(() {
          _publicIpPosition = newPublicIpPosition;
        });
      }
    };
    
    _networkProvider!.addListener(_networkProviderListener!);
  }

  LatLng? _getPublicIpPosition() {
    if (_networkProvider!.wifiNetworkInfo?.publicIpPosition != null) {
      return _networkProvider!.wifiNetworkInfo!.publicIpPosition;
    } else if (_networkProvider!.mobileNetworkInfo?.publicIpPosition != null) {
      return _networkProvider!.mobileNetworkInfo!.publicIpPosition;
    }
    return null;
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
                : MapWidget(
                    currentPosition: _currentPosition,
                    publicIpPosition: _publicIpPosition,
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