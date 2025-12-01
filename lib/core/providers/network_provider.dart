import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/network_info.dart';
import '../services/wifi_network_service.dart';
import '../services/mobile_network_service.dart';
import 'package:flutter/foundation.dart';

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

  NetworkProvider() {
    _loadCachedNetworkInfo();
  }

  NetworkInfo? get wifiNetworkInfo => _wifiNetworkInfo;
  NetworkInfo? get mobileNetworkInfo => _mobileNetworkInfo;
  
  LatLng? get publicIpPosition {
    if (hasWifiConnection && _wifiNetworkInfo?.publicIpPosition != null) {
      return _wifiNetworkInfo!.publicIpPosition;
    }
    if (hasMobileConnection && _mobileNetworkInfo?.publicIpPosition != null) {
      return _mobileNetworkInfo!.publicIpPosition;
    }
    return null;
  }

  bool get hasWifiConnection => _currentConnectivity.contains(ConnectivityResult.wifi);
  bool get hasMobileConnection => _currentConnectivity.contains(ConnectivityResult.mobile);
  bool get hasAnyConnection => hasWifiConnection || hasMobileConnection;
  List<ConnectivityResult> get currentConnectivity => _currentConnectivity;

  Future<void> _loadCachedNetworkInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final wifiInfoJson = prefs.getString('wifi_network_info');
    if (wifiInfoJson != null) {
      _wifiNetworkInfo = NetworkInfo.fromJson(json.decode(wifiInfoJson));
    }
    final mobileInfoJson = prefs.getString('mobile_network_info');
    if (mobileInfoJson != null) {
      _mobileNetworkInfo = NetworkInfo.fromJson(json.decode(mobileInfoJson));
    }
    _safeNotifyListeners();
  }

  Future<void> _cacheNetworkInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (_wifiNetworkInfo != null) {
      await prefs.setString('wifi_network_info', json.encode(_wifiNetworkInfo!.toJson()));
    }
    if (_mobileNetworkInfo != null) {
      await prefs.setString('mobile_network_info', json.encode(_mobileNetworkInfo!.toJson()));
    }
  }

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
      _cacheNetworkInfo();
      _safeNotifyListeners();
    });

    _mobileSubscription = _mobileService.networkInfoStream.listen((networkInfo) {
      _mobileNetworkInfo = networkInfo;
      _cacheNetworkInfo();
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
      _wifiNetworkInfo = await compute(_getWifiInfo, null);
    }

    if (hasMobileConnection) {
      _mobileNetworkInfo = await compute(_getMobileInfo, null);
    }

    _cacheNetworkInfo();
    _safeNotifyListeners();
  }

  static Future<NetworkInfo> _getWifiInfo(void _) async {
    try {
      return await WifiNetworkService().getCurrentNetworkInfo();
    } catch (e) {
      return NetworkInfo.error(NetworkType.wifi);
    }
  }

  static Future<NetworkInfo> _getMobileInfo(void _) async {
    try {
      return await MobileNetworkService().getCurrentNetworkInfo();
    } catch (e) {
      return NetworkInfo.error(NetworkType.mobile);
    }
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
