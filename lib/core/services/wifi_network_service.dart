import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart' as network_info_plus;
import '../interfaces/network_service.dart';
import '../models/network_info.dart' as models;
import '../services/isolate_service.dart';
import 'network_data_fetcher.dart';

class WifiNetworkService implements INetworkService {
  final StreamController<models.NetworkInfo> _networkInfoController = StreamController<models.NetworkInfo>.broadcast();
  Timer? _monitoringTimer;
  StreamSubscription? _connectivitySubscription;
  bool _isDisposed = false;
  
  @override
  models.NetworkType get networkType => models.NetworkType.wifi;

  @override
  Stream<models.NetworkInfo> get networkInfoStream => _networkInfoController.stream;

  @override
  Future<void> startMonitoring() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.wifi)) {
        _fetchAndEmitNetworkInfo();
      } else {
        _safeAdd(models.NetworkInfo.error(models.NetworkType.wifi));
      }
    });

    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchAndEmitNetworkInfo();
    });

    await _fetchAndEmitNetworkInfo();
  }

  void _safeAdd(models.NetworkInfo networkInfo) {
    if (!_isDisposed && !_networkInfoController.isClosed) {
      _networkInfoController.add(networkInfo);
    }
  }

  @override
  void stopMonitoring() {
    _isDisposed = true;
    _monitoringTimer?.cancel();
    _connectivitySubscription?.cancel();
    if (!_networkInfoController.isClosed) {
      _networkInfoController.close();
    }
  }

  @override
  Future<models.NetworkInfo> getCurrentNetworkInfo() async {
    final connectivity = await Connectivity().checkConnectivity();
    
    if (!connectivity.contains(ConnectivityResult.wifi)) {
      return models.NetworkInfo.error(models.NetworkType.wifi);
    }

    return await runInIsolate(_fetchWifiNetworkInfoIsolate, null);
  }

  Future<void> _fetchAndEmitNetworkInfo() async {
    final connectivity = await Connectivity().checkConnectivity();
    
    if (!connectivity.contains(ConnectivityResult.wifi)) {
      _networkInfoController.add(models.NetworkInfo.error(models.NetworkType.wifi));
      return;
    }

    _safeAdd(models.NetworkInfo.loading(models.NetworkType.wifi));
    
    try {
      final networkInfo = await runInIsolate(_fetchWifiNetworkInfoIsolate, null);
      _safeAdd(networkInfo);
    } catch (e) {
      _networkInfoController.add(models.NetworkInfo.error(models.NetworkType.wifi));
    }
  }

  static Future<models.NetworkInfo> _fetchWifiNetworkInfoIsolate(dynamic _) async {
    try {
      // Get comprehensive network info using enhanced analyzer
      final networkData = await NetworkDataFetcher.fetchComprehensiveNetworkInfo();
      
      // Try to get WiFi-specific info
      String? ssid;
      try {
        final wifiInfo = network_info_plus.NetworkInfo();
        ssid = await wifiInfo.getWifiName();
      } catch (e) {
        // SSID detection failed, continue without it
      }

      return models.NetworkInfo(
        type: models.NetworkType.wifi,
        status: models.NetworkStatus.connected,
        localIp: networkData['localIp'] ?? 'N/A',
        localIpv6: networkData['localIpv6'],
        publicIp: networkData['publicIp'] ?? 'Error',
        ipDetails: networkData['ipDetails'] ?? 'Details unavailable',
        publicIpPosition: networkData['coordinates'],
        ssid: ssid,
        dnsServers: networkData['dnsServers'] ?? ['Unknown'],
        dnsDetectionMethod: networkData['dnsDetectionMethod'] ?? 'Unknown',
        interfaceName: networkData['interfaceName'] ?? 'Unknown',
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      return models.NetworkInfo.error(models.NetworkType.wifi);
    }
  }
}