import 'package:latlong2/latlong.dart';
import 'package:apptobe/core/services/cache_service.dart';
import 'package:apptobe/core/services/location_service.dart';

class CachedLocationService {
  static final CachedLocationService _instance = CachedLocationService._internal();
  factory CachedLocationService() => _instance;
  CachedLocationService._internal();

  final CacheService<LatLng?> _cache = CacheService<LatLng?>(const Duration(minutes: 10));
  final ILocationService _locationService = LocationService();

  static const String _currentPositionKey = 'current_position';

  Future<LatLng?> getCurrentPosition({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _cache.remove(_currentPositionKey);
    }

    return await _cache.getOrFetch(
      _currentPositionKey,
      () => _locationService.getCurrentPosition(),
    );
  }

  Future<void> invalidateLocationCache() async {
    _cache.remove(_currentPositionKey);
  }
}
