import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:apptobe/core/models/network_info.dart' as models;
import 'package:apptobe/core/services/wifi_network_service.dart';
import 'package:apptobe/core/services/mobile_network_service.dart';
import 'package:apptobe/core/services/cache_service.dart';
import 'package:apptobe/core/interfaces/network_service.dart';

class NetworkProvider with ChangeNotifier {
  final WifiNetworkService _wifiService = WifiNetworkService(CacheService<models.NetworkInfo>(const Duration(minutes: 5)));
  final MobileNetworkService _mobileService = MobileNetworkService(CacheService<models.NetworkInfo>(const Duration(minutes: 5)));
  
  StreamSubscription? _wifiSubscription;
  StreamSubscription? _mobileSubscription;
  StreamSubscription? _connectivitySubscription;

  models.NetworkInfo? _wifiNetworkInfo;
  models.NetworkInfo? _mobileNetworkInfo;
  
  bool _isMonitoring = false;
  bool _isDisposed = false;
  List<ConnectivityResult> _currentConnectivity = [];

  models.NetworkInfo? get wifiNetworkInfo => _wifiNetworkInfo;
  models.NetworkInfo? get mobileNetworkInfo => _mobileNetworkInfo;
  
  bool get hasWifiConnection => _currentConnectivity.contains(ConnectivityResult.wifi);
  bool get hasMobileConnection => _currentConnectivity.contains(ConnectivityResult.mobile);
  bool get hasAnyConnection => hasWifiConnection || hasMobileConnection;
  List<ConnectivityResult> get currentConnectivity => _currentConnectivity;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      _currentConnectivity = result;
      _safeNotifyListeners();
    });

    final initialConnectivity = await Connectivity().checkConnectivity();
    _currentConnectivity = initialConnectivity;

    _wifiSubscription = _wifiService.networkInfoStream.listen((networkInfo) {
      _wifiNetworkInfo = networkInfo;
      _safeNotifyListeners();
    });

    _mobileSubscription = _mobileService.networkInfoStream.listen((networkInfo) {
      _mobileNetworkInfo = networkInfo;
      _safeNotifyListeners();
    });

    await _wifiService.startMonitoring();
    await _mobileService.startMonitoring();

    _safeNotifyListeners();
  }

  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    _wifiSubscription?.cancel();
    _mobileSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _wifiService.stopMonitoring();
    _mobileService.stopMonitoring();
  }

  Future<void> refreshNetworkInfo() async {
    if (hasWifiConnection) {
      _wifiNetworkInfo = models.NetworkInfo.loading(models.NetworkType.wifi);
      _safeNotifyListeners();
    }
    
    if (hasMobileConnection) {
      _mobileNetworkInfo = models.NetworkInfo.loading(models.NetworkType.mobile);
      _safeNotifyListeners();
    }

    if (hasWifiConnection) {
      try {
        _wifiNetworkInfo = await _wifiService.getCurrentNetworkInfo();
      } catch (e) {
        _wifiNetworkInfo = models.NetworkInfo.error(models.NetworkType.wifi);
      }
    }

    if (hasMobileConnection) {
      try {
        _mobileNetworkInfo = await _mobileService.getCurrentNetworkInfo();
      } catch (e) {
        _mobileNetworkInfo = models.NetworkInfo.error(models.NetworkType.mobile);
      }
    }

    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    stopMonitoring();
    super.dispose();
  }
}
