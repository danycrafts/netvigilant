import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/network_info.dart';
import '../../interfaces/network_service.dart';

class SimplifiedNetworkProvider with ChangeNotifier {
  final INetworkService _wifiService;
  final INetworkService _mobileService;
  
  StreamSubscription? _wifiSubscription;
  StreamSubscription? _mobileSubscription;
  StreamSubscription? _connectivitySubscription;

  NetworkInfo? _wifiNetworkInfo;
  NetworkInfo? _mobileNetworkInfo;
  
  bool _isMonitoring = false;
  bool _isDisposed = false;
  List<ConnectivityResult> _currentConnectivity = [];

  SimplifiedNetworkProvider({
    required INetworkService wifiService,
    required INetworkService mobileService,
  }) : _wifiService = wifiService,
       _mobileService = mobileService;

  // Getters
  NetworkInfo? get wifiNetworkInfo => _wifiNetworkInfo;
  NetworkInfo? get mobileNetworkInfo => _mobileNetworkInfo;
  bool get hasWifiConnection => _currentConnectivity.contains(ConnectivityResult.wifi);
  bool get hasMobileConnection => _currentConnectivity.contains(ConnectivityResult.mobile);
  bool get hasAnyConnection => hasWifiConnection || hasMobileConnection;
  List<ConnectivityResult> get currentConnectivity => _currentConnectivity;

  Future<void> startMonitoring() async {
    if (_isMonitoring || _isDisposed) return;
    
    _isMonitoring = true;
    await _setupConnectivityListener();
    await _setupServiceListeners();
    await _startServices();
    _notifyListeners();
  }

  Future<void> _setupConnectivityListener() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      _currentConnectivity = result;
      _notifyListeners();
    });

    _currentConnectivity = await Connectivity().checkConnectivity();
  }

  Future<void> _setupServiceListeners() async {
    _wifiSubscription = _wifiService.networkInfoStream.listen((networkInfo) {
      _wifiNetworkInfo = networkInfo;
      _notifyListeners();
    });

    _mobileSubscription = _mobileService.networkInfoStream.listen((networkInfo) {
      _mobileNetworkInfo = networkInfo;
      _notifyListeners();
    });
  }

  Future<void> _startServices() async {
    await Future.wait([
      _wifiService.startMonitoring(),
      _mobileService.startMonitoring(),
    ]);
  }

  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    _cleanupSubscriptions();
    _stopServices();
  }

  void _cleanupSubscriptions() {
    _wifiSubscription?.cancel();
    _mobileSubscription?.cancel();
    _connectivitySubscription?.cancel();
  }

  void _stopServices() {
    _wifiService.stopMonitoring();
    _mobileService.stopMonitoring();
  }

  Future<void> refreshNetworkInfo() async {
    if (!_isMonitoring) return;

    if (hasWifiConnection) {
      _wifiNetworkInfo = NetworkInfo.loading(NetworkType.wifi);
      _notifyListeners();
    }
    
    if (hasMobileConnection) {
      _mobileNetworkInfo = NetworkInfo.loading(NetworkType.mobile);
      _notifyListeners();
    }

    await _refreshServices();
    _notifyListeners();
  }

  Future<void> _refreshServices() async {
    final futures = <Future>[];
    
    if (hasWifiConnection) {
      futures.add(_refreshWifiInfo());
    }
    
    if (hasMobileConnection) {
      futures.add(_refreshMobileInfo());
    }
    
    await Future.wait(futures);
  }

  Future<void> _refreshWifiInfo() async {
    try {
      _wifiNetworkInfo = await _wifiService.getCurrentNetworkInfo();
    } catch (e) {
      _wifiNetworkInfo = NetworkInfo.error(NetworkType.wifi);
    }
  }

  Future<void> _refreshMobileInfo() async {
    try {
      _mobileNetworkInfo = await _mobileService.getCurrentNetworkInfo();
    } catch (e) {
      _mobileNetworkInfo = NetworkInfo.error(NetworkType.mobile);
    }
  }

  void _notifyListeners() {
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