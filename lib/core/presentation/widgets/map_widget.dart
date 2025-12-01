import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:netvigilant/core/providers/map_provider.dart';

class MapWidget extends StatelessWidget {
  final LatLng? currentPosition;
  final LatLng? publicIpPosition;

  const MapWidget({
    super.key,
    this.currentPosition,
    this.publicIpPosition,
  });

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);

    if (currentPosition == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Could not determine location. Please enable location services and grant permission.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentPosition != null && publicIpPosition != null) {
        mapProvider.fitBounds(currentPosition!, publicIpPosition!);
      }
    });

    return Stack(
      children: [
        FlutterMap(
          mapController: mapProvider.mapController,
          options: MapOptions(
            initialCenter: currentPosition!,
            initialZoom: 13.0,
            minZoom: 2.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.danycrafts.netvigilant',
              retinaMode: RetinaMode.isHighDensity(context),
            ),
            MarkerLayer(
              markers: [
                if (currentPosition != null)
                  Marker(
                    width: 60.0,
                    height: 60.0,
                    point: currentPosition!,
                    child: const AnimatedLocationMarker(
                      color: Colors.green,
                    ),
                  ),
                if (publicIpPosition != null)
                  Marker(
                    width: 60.0,
                    height: 60.0,
                    point: publicIpPosition!,
                    child: const AnimatedLocationMarker(
                      color: Colors.blue,
                    ),
                  ),
              ],
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
                onPressed: mapProvider.zoomIn,
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: "zoomOutBtn",
                onPressed: mapProvider.zoomOut,
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: "recenterBtn",
                onPressed: () => mapProvider.recenter(currentPosition!),
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class AnimatedLocationMarker extends StatefulWidget {
  final Color color;

  const AnimatedLocationMarker({
    super.key,
    this.color = Colors.green,
  });

  @override
  State<AnimatedLocationMarker> createState() => _AnimatedLocationMarkerState();
}

class _AnimatedLocationMarkerState extends State<AnimatedLocationMarker>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final size = 50.0 * _controller.value;
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(1.0 - _controller.value),
                ),
              ),
              Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
