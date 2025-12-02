import 'package:latlong2/latlong.dart';
import 'package:apptobe/core/services/cache_service.dart';
import 'package:apptobe/core/services/location_service.dart';

class CachedLocationService {
  static final CachedLocationService _instance = CachedLocationService._internal();
  factory CachedLocationService() => _instance;
  CachedLocationService._internal();

  final CacheService _cache = CacheService();
  final ILocationService _locationService = LocationService();

  static const String _currentPositionKey = 'current_position';

  Future<LatLng?> getCurrentPosition({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await _cache.remove(_currentPositionKey);
    }

    return await _cache.getOrFetch<LatLng?>(
      _currentPositionKey,
      () => _locationService.getCurrentPosition(),
      ttl: const Duration(minutes: 10),
      persistToDisk: false,
      fromJson: (data) {
        if (data == null) return null;
        if (data is Map<String, dynamic>) {
          return _latLngFromJson(data);
        }
        return null;
      },
    );
  }

  Future<void> invalidateLocationCache() async {
    await _cache.remove(_currentPositionKey);
  }

  static LatLng _latLngFromJson(Map<String, dynamic> data) {
    return LatLng(
      data['latitude']?.toDouble() ?? 0.0,
      data['longitude']?.toDouble() ?? 0.0,
    );
  }

  static Map<String, dynamic> _latLngToJson(LatLng latLng) {
    return {
      'latitude': latLng.latitude,
      'longitude': latLng.longitude,
    };
  }
}