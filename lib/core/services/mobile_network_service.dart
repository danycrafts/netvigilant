import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../interfaces/network_service.dart';
import '../models/network_info.dart' as models;
import 'network_data_fetcher.dart';

import 'cache_service.dart';

class MobileNetworkService implements INetworkService {
  final StreamController<models.NetworkInfo> _networkInfoController = StreamController<models.NetworkInfo>.broadcast();
  Timer? _monitoringTimer;
  StreamSubscription? _connectivitySubscription;
  bool _isDisposed = false;
  final CacheService<models.NetworkInfo> _cache = CacheService<models.NetworkInfo>(const Duration(minutes: 5));
  
  @override
  models.NetworkType get networkType => models.NetworkType.mobile;

  @override
  Stream<models.NetworkInfo> get networkInfoStream => _networkInfoController.stream;

  @override
  Future<void> startMonitoring() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (!_isDisposed) {
        if (result.contains(ConnectivityResult.mobile)) {
          _fetchAndEmitNetworkInfo();
        } else {
          _safeAdd(models.NetworkInfo.error(models.NetworkType.mobile));
        }
      }
    });

    // Removed auto-refresh timer - only manual refresh now
    // _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
    //   if (!_isDisposed) {
    //     _fetchAndEmitNetworkInfo();
    //   } else {
    //     timer.cancel();
    //   }
    // });

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
    final cachedInfo = _cache.get('mobile_info');
    if (cachedInfo != null) {
      return cachedInfo;
    }

    final connectivity = await Connectivity().checkConnectivity();
    
    if (!connectivity.contains(ConnectivityResult.mobile)) {
      return models.NetworkInfo.error(models.NetworkType.mobile);
    }

    final networkInfo = await compute(_fetchMobileNetworkInfoIsolate, null);
    _cache.set('mobile_info', networkInfo);
    return networkInfo;
  }

  Future<void> _fetchAndEmitNetworkInfo() async {
    if (_isDisposed) return; // Early return if disposed
    
    final cachedInfo = _cache.get('mobile_info');
    if (cachedInfo != null) {
      _safeAdd(cachedInfo);
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    
    if (!connectivity.contains(ConnectivityResult.mobile)) {
      _safeAdd(models.NetworkInfo.error(models.NetworkType.mobile));
      return;
    }

    _safeAdd(models.NetworkInfo.loading(models.NetworkType.mobile));
    
    try {
      final networkInfo = await compute(_fetchMobileNetworkInfoIsolate, null);
      _cache.set('mobile_info', networkInfo);
      _safeAdd(networkInfo);
    } catch (e) {
      _safeAdd(models.NetworkInfo.error(models.NetworkType.mobile));
    }
  }

  static Future<models.NetworkInfo> _fetchMobileNetworkInfoIsolate(dynamic _) async {
    try {
      // Get comprehensive network info using enhanced analyzer
      final networkData = await NetworkDataFetcher.fetchComprehensiveNetworkInfo();
      
      // For mobile, we might not have a traditional "local IP" on the LAN
      // but we can show the interface IP if detected
      final localIp = networkData['localIp'] ?? 'N/A (Mobile Data)';
      
      // Detect carrier name if possible (simplified for now)
      String operatorName = 'Mobile Carrier';
      if (networkData['isp'] != null && networkData['isp'] != 'Unknown') {
        operatorName = networkData['isp'];
      }

      return models.NetworkInfo(
        type: models.NetworkType.mobile,
        status: models.NetworkStatus.connected,
        localIp: localIp,
        localIpv6: networkData['localIpv6'],
        publicIp: networkData['publicIp'] ?? 'Error',
        ipDetails: networkData['ipDetails'] ?? 'Details unavailable',
        publicIpPosition: networkData['coordinates'],
        operatorName: operatorName,
        dnsServers: networkData['dnsServers'] ?? ['Unknown'],
        dnsDetectionMethod: networkData['dnsDetectionMethod'] ?? 'Unknown',
        interfaceName: networkData['interfaceName'] ?? 'Unknown',
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      return models.NetworkInfo.error(models.NetworkType.mobile);
    }
  }
}