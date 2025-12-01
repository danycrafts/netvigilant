import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:netvigilant/core/services/location_service.dart';
import 'package:netvigilant/core/providers/network_provider.dart';
import 'package:netvigilant/core/widgets/dual_network_panel.dart';
import 'package:netvigilant/core/presentation/widgets/map_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_networkProvider == null) {
      _networkProvider = Provider.of<NetworkProvider>(context);
      _networkProvider!.addListener(_updatePublicIpPosition);
      // Initial fetch
      _updatePublicIpPosition();
    }
  }

  void _updatePublicIpPosition() {
    if (!mounted) return;

    final newPosition = _networkProvider!.publicIpPosition;
    if (newPosition != _publicIpPosition) {
      setState(() {
        _publicIpPosition = newPosition;
      });
    }
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

  @override
  void dispose() {
    _networkProvider?.removeListener(_updatePublicIpPosition);
    super.dispose();
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
