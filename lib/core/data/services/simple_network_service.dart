import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart' as network_info_plus;
import '../../models/network_info.dart';
import '../../domain/services/base_network_service.dart';
import '../../services/network_data_fetcher.dart';

class SimpleWifiNetworkService extends BaseNetworkService {
  @override
  NetworkType get networkType => NetworkType.wifi;
  
  @override
  List<ConnectivityResult> get supportedConnections => [ConnectivityResult.wifi];

  @override
  Future<NetworkInfo> fetchNetworkInfo() async {
    try {
      final networkData = await NetworkDataFetcher.fetchComprehensiveNetworkInfo();
      
      String? ssid;
      try {
        final wifiInfo = network_info_plus.NetworkInfo();
        ssid = await wifiInfo.getWifiName();
        ssid = ssid?.replaceAll('"', ''); // Remove quotes from SSID
      } catch (e) {
        ssid = null;
      }
      
      return NetworkInfo(
        type: NetworkType.wifi,
        status: NetworkStatus.connected,
        ssid: ssid ?? 'Unknown WiFi',
        publicIp: networkData['publicIp'] as String? ?? 'N/A',
        localIp: networkData['localIp'] as String? ?? 'N/A',
        ipDetails: networkData['ipDetails'] as String? ?? 'N/A',
        publicIpPosition: networkData['coordinates'],
        dnsServers: networkData['dnsServers'] as List<String>? ?? ['N/A'],
        dnsDetectionMethod: networkData['dnsDetectionMethod'] as String? ?? 'Unknown',
        interfaceName: networkData['interfaceName'] as String? ?? 'Unknown',
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      return NetworkInfo.error(NetworkType.wifi);
    }
  }
}

class SimpleMobileNetworkService extends BaseNetworkService {
  @override
  NetworkType get networkType => NetworkType.mobile;
  
  @override
  List<ConnectivityResult> get supportedConnections => [ConnectivityResult.mobile];

  @override
  Future<NetworkInfo> fetchNetworkInfo() async {
    try {
      final networkData = await NetworkDataFetcher.fetchComprehensiveNetworkInfo();
      
      return NetworkInfo(
        type: NetworkType.mobile,
        status: NetworkStatus.connected,
        operatorName: 'Mobile Data',
        publicIp: networkData['publicIp'] as String? ?? 'N/A',
        localIp: networkData['localIp'] as String? ?? 'N/A',
        ipDetails: networkData['ipDetails'] as String? ?? 'N/A',
        publicIpPosition: networkData['coordinates'],
        dnsServers: networkData['dnsServers'] as List<String>? ?? ['N/A'],
        dnsDetectionMethod: networkData['dnsDetectionMethod'] as String? ?? 'Unknown',
        interfaceName: networkData['interfaceName'] as String? ?? 'Unknown',
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      return NetworkInfo.error(NetworkType.mobile);
    }
  }
}