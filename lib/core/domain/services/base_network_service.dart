import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../models/network_info.dart';
import '../../interfaces/network_service.dart';

abstract class BaseNetworkService implements INetworkService {
  final StreamController<NetworkInfo> _networkInfoController = 
      StreamController<NetworkInfo>.broadcast();
  Timer? _monitoringTimer;
  StreamSubscription? _connectivitySubscription;
  bool _isDisposed = false;
  
  @protected
  Duration get monitoringInterval => const Duration(seconds: 30);
  
  @protected
  List<ConnectivityResult> get supportedConnections;

  @override
  Stream<NetworkInfo> get networkInfoStream => _networkInfoController.stream;

  @override
  Future<void> startMonitoring() async {
    if (_isDisposed) return;

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (!_isDisposed) {
        if (_shouldMonitor(result)) {
          _fetchAndEmitNetworkInfo();
        } else {
          _safeAdd(NetworkInfo.error(networkType));
        }
      }
    });

    _monitoringTimer = Timer.periodic(monitoringInterval, (timer) {
      if (!_isDisposed) {
        _fetchAndEmitNetworkInfo();
      } else {
        timer.cancel();
      }
    });

    await _fetchAndEmitNetworkInfo();
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

  void _safeAdd(NetworkInfo networkInfo) {
    if (!_isDisposed && !_networkInfoController.isClosed) {
      _networkInfoController.add(networkInfo);
    }
  }

  bool _shouldMonitor(List<ConnectivityResult> currentConnections) {
    return currentConnections.any((connection) => 
        supportedConnections.contains(connection));
  }

  Future<void> _fetchAndEmitNetworkInfo() async {
    if (_isDisposed) return;
    
    final connectivity = await Connectivity().checkConnectivity();
    
    if (!_shouldMonitor(connectivity)) {
      _safeAdd(NetworkInfo.error(networkType));
      return;
    }

    _safeAdd(NetworkInfo.loading(networkType));
    
    try {
      final networkInfo = await fetchNetworkInfo();
      _safeAdd(networkInfo);
    } catch (e) {
      _safeAdd(NetworkInfo.error(networkType));
    }
  }

  @protected
  Future<NetworkInfo> fetchNetworkInfo();

  @override
  Future<NetworkInfo> getCurrentNetworkInfo() async {
    final connectivity = await Connectivity().checkConnectivity();
    
    if (!_shouldMonitor(connectivity)) {
      return NetworkInfo.error(networkType);
    }

    return fetchNetworkInfo();
  }
}