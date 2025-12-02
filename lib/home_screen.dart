import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:apptobe/core/services/cached_location_service.dart';
import 'package:apptobe/core/providers/network_provider.dart';
import 'package:apptobe/core/widgets/dual_network_panel.dart';
import 'package:apptobe/core/presentation/widgets/map_widget.dart';
import 'package:apptobe/core/widgets/adaptive_quick_apps_widget.dart';
import 'package:apptobe/core/widgets/adaptive_analytics_widget.dart';
import 'package:apptobe/core/architecture/base_widgets/base_screen.dart';
import 'package:apptobe/core/architecture/dependency_injection/service_locator.dart';
import 'package:apptobe/core/interfaces/location_repository.dart';
import 'package:apptobe/core/interfaces/cache_repository.dart';

class HomeScreen extends BaseScreen {
  const HomeScreen({super.key, required this.title});

  @override
  final String title;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => refresh(),
        tooltip: 'Refresh data',
      ),
    ];
  }


  @override
  Widget buildBody(BuildContext context) {
    return const _HomeScreenBody();
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with LoadingScreenMixin, ErrorHandlingMixin {
  final CachedLocationService _locationService = CachedLocationService();
  late final ILocationRepository _locationRepository;
  late final ICacheRepository _cacheRepository;
  LatLng? _currentPosition;
  LatLng? _publicIpPosition;
  NetworkProvider? _networkProvider;
  VoidCallback? _networkProviderListener;

  // SOLID - Use injected services

  @override
  void initState() {
    super.initState();
    // SOLID - Initialize dependencies through service locator
    _locationRepository = getIt<ILocationRepository>();
    _cacheRepository = getIt<ICacheRepository>();
    _initializeScreen();
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

  Future<void> _initializeScreen() async {
    setLoading(true);
    try {
      await _determinePosition();
    } catch (error) {
      handleError(error);
    } finally {
      setLoading(false);
    }
  }

  Future<void> _determinePosition() async {
    final position = await _locationService.getCurrentPosition();
    if (mounted) {
      setState(() => _currentPosition = position);
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
    // Use mixin for loading overlay
    return buildWithLoading(
      const _HomeScreenBody(),
    );
  }
}

// SOLID - Separate body widget with single responsibility
class _HomeScreenBody extends StatelessWidget {
  const _HomeScreenBody();

  @override
  Widget build(BuildContext context) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMapSection(context, homeState),
          const SizedBox(height: 8),
          const AdaptiveQuickAppsWidget(),
          const SizedBox(height: 16),
          const AdaptiveAnalyticsWidget(),
          const SizedBox(height: 16),
          const DualNetworkPanel(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // DRY - Reusable map section widget
  Widget _buildMapSection(BuildContext context, _HomeScreenState? homeState) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: homeState?.isLoading == true
            ? const Center(child: CircularProgressIndicator())
            : MapWidget(
                currentPosition: homeState?._currentPosition,
                publicIpPosition: homeState?._publicIpPosition,
              ),
      ),
    );
  }
}
