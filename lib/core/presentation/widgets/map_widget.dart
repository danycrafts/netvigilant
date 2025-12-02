import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatefulWidget {
  final LatLng? currentPosition;
  final LatLng? publicIpPosition;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onRecenter;

  const MapWidget({
    super.key,
    this.currentPosition,
    this.publicIpPosition,
    this.onZoomIn,
    this.onZoomOut,
    this.onRecenter,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
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
      duration: const Duration(seconds: 2, milliseconds: 500),
    )..repeat();
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPosition != oldWidget.currentPosition ||
        widget.publicIpPosition != oldWidget.publicIpPosition) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds();
      });
    }
  }

  @override
  void dispose() {
    _greenMarkerController.dispose();
    _blueMarkerController.dispose();
    super.dispose();
  }

  void _fitBounds() {
    final positions = <LatLng>[];
    
    if (widget.currentPosition != null) {
      positions.add(widget.currentPosition!);
    }
    if (widget.publicIpPosition != null) {
      positions.add(widget.publicIpPosition!);
    }

    if (positions.isEmpty) return;

    if (positions.length == 1) {
      _mapController.move(positions.first, 15.0);
      return;
    }

    final distance = const Distance().as(
      LengthUnit.Kilometer,
      positions[0],
      positions[1],
    );

    if (distance < 1.0) {
      _mapController.move(positions[0], 15.0);
      return;
    }

    final bounds = LatLngBounds.fromPoints(positions);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80.0),
        maxZoom: 15.0,
        minZoom: 2.0,
      ),
    );
  }

  void _zoomIn() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom + 1,
    );
  }

  void _zoomOut() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom - 1,
    );
  }

  void _recenter() {
    if (widget.currentPosition != null) {
      _mapController.move(widget.currentPosition!, 15.0);
    }
  }

  Widget _buildMapControlButton({
    required String heroTag,
    required VoidCallback onPressed,
    required IconData icon,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentPosition == null) {
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

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.currentPosition!,
            initialZoom: 13.0,
            minZoom: 2.0,
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
            MarkerLayer(
              markers: [
                // Green marker for user's physical location
                Marker(
                  width: 60.0,
                  height: 60.0,
                  point: widget.currentPosition!,
                  child: AnimatedLocationMarker(
                    animation: _greenMarkerController,
                  ),
                ),
                // Blue marker for public IP location
                if (widget.publicIpPosition != null)
                  Marker(
                    width: 60.0,
                    height: 60.0,
                    point: widget.publicIpPosition!,
                    child: AnimatedLocationMarker(
                      animation: _blueMarkerController,
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
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapControlButton(
                  heroTag: "zoomInBtn",
                  onPressed: widget.onZoomIn ?? _zoomIn,
                  icon: Icons.add,
                  tooltip: 'Zoom In',
                ),
                const Divider(height: 1),
                _buildMapControlButton(
                  heroTag: "zoomOutBtn",
                  onPressed: widget.onZoomOut ?? _zoomOut,
                  icon: Icons.remove,
                  tooltip: 'Zoom Out',
                ),
                const Divider(height: 1),
                _buildMapControlButton(
                  heroTag: "recenterBtn",
                  onPressed: widget.onRecenter ?? _recenter,
                  icon: Icons.my_location,
                  tooltip: 'Recenter',
                ),
              ],
            ),
          ),
        )
      ],
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
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(1.0 - animation.value),
            ),
          ),
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