import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapProvider with ChangeNotifier {
  final MapController _mapController = MapController();
  MapController get mapController => _mapController;

  void fitBounds(LatLng currentPosition, LatLng publicIpPosition) {
    final distance = const Distance().as(
      LengthUnit.Kilometer,
      currentPosition,
      publicIpPosition,
    );

    if (distance < 1.0) {
      _mapController.move(currentPosition, 15.0);
      return;
    }

    final bounds = LatLngBounds.fromPoints([
      currentPosition,
      publicIpPosition,
    ]);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80.0),
        maxZoom: 15.0,
        minZoom: 2.0,
      ),
    );
  }

  void zoomIn() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom + 1,
    );
  }

  void zoomOut() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom - 1,
    );
  }

  void recenter(LatLng currentPosition) {
    if (currentPosition != null) {
      _mapController.move(currentPosition, 15.0);
    }
  }
}
