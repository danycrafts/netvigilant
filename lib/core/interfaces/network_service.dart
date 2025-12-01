import '../models/network_info.dart';

abstract class INetworkService {
  Stream<NetworkInfo> get networkInfoStream;
  Future<NetworkInfo> getCurrentNetworkInfo();
  Future<void> startMonitoring();
  void stopMonitoring();
  NetworkType get networkType;
}