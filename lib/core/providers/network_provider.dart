import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/network_info.dart';
import '../services/wifi_network_service.dart';
import '../services/mobile_network_service.dart';

class NetworkProvider with ChangeNotifier {
  final WifiNetworkService _wifiService = WifiNetworkService();
  final MobileNetworkService _mobileService = MobileNetworkService();
  
  StreamSubscription? _wifiSubscription;
  StreamSubscription? _mobileSubscription;
  StreamSubscription? _connectivitySubscription;

  NetworkInfo? _wifiNetworkInfo;
  NetworkInfo? _mobileNetworkInfo;
  
  bool _isMonitoring = false;
  bool _isDisposed = false;
  List<ConnectivityResult> _currentConnectivity = [];

  NetworkInfo? get wifiNetworkInfo => _wifiNetworkInfo;
  NetworkInfo? get mobileNetworkInfo => _mobileNetworkInfo;
  
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
      _wifiNetworkInfo = NetworkInfo.loading(NetworkType.wifi);
      _safeNotifyListeners();
    }
    
    if (hasMobileConnection) {
      _mobileNetworkInfo = NetworkInfo.loading(NetworkType.mobile);
      _safeNotifyListeners();
    }

    if (hasWifiConnection) {
      try {
        _wifiNetworkInfo = await _wifiService.getCurrentNetworkInfo();
      } catch (e) {
        _wifiNetworkInfo = NetworkInfo.error(NetworkType.wifi);
      }
    }

    if (hasMobileConnection) {
      try {
        _mobileNetworkInfo = await _mobileService.getCurrentNetworkInfo();
      } catch (e) {
        _mobileNetworkInfo = NetworkInfo.error(NetworkType.mobile);
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