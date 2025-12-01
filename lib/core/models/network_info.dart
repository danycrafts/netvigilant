import 'package:latlong2/latlong.dart';

enum NetworkType { wifi, mobile, offline }

enum NetworkStatus { connected, disconnected, connecting }

class NetworkInfo {
  final NetworkType type;
  final NetworkStatus status;
  final String localIp;
  final String? localIpv6;
  final String publicIp;
  final String ipDetails;
  final LatLng? publicIpPosition;
  final String? ssid;
  final String? operatorName;
  final List<String> dnsServers;
  final String dnsDetectionMethod;
  final String interfaceName;
  final DateTime lastUpdated;

  const NetworkInfo({
    required this.type,
    required this.status,
    required this.localIp,
    this.localIpv6,
    required this.publicIp,
    required this.ipDetails,
    this.publicIpPosition,
    this.ssid,
    this.operatorName,
    this.dnsServers = const [],
    this.dnsDetectionMethod = 'Unknown',
    this.interfaceName = 'Unknown',
    required this.lastUpdated,
  });

  NetworkInfo copyWith({
    NetworkType? type,
    NetworkStatus? status,
    String? localIp,
    String? localIpv6,
    String? publicIp,
    String? ipDetails,
    LatLng? publicIpPosition,
    String? ssid,
    String? operatorName,
    List<String>? dnsServers,
    String? dnsDetectionMethod,
    String? interfaceName,
    DateTime? lastUpdated,
  }) {
    return NetworkInfo(
      type: type ?? this.type,
      status: status ?? this.status,
      localIp: localIp ?? this.localIp,
      localIpv6: localIpv6 ?? this.localIpv6,
      publicIp: publicIp ?? this.publicIp,
      ipDetails: ipDetails ?? this.ipDetails,
      publicIpPosition: publicIpPosition ?? this.publicIpPosition,
      ssid: ssid ?? this.ssid,
      operatorName: operatorName ?? this.operatorName,
      dnsServers: dnsServers ?? this.dnsServers,
      dnsDetectionMethod: dnsDetectionMethod ?? this.dnsDetectionMethod,
      interfaceName: interfaceName ?? this.interfaceName,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory NetworkInfo.loading(NetworkType type) {
    return NetworkInfo(
      type: type,
      status: NetworkStatus.connecting,
      localIp: 'Loading...',
      publicIp: 'Loading...',
      ipDetails: 'Loading...',
      dnsServers: const ['Loading...'],
      dnsDetectionMethod: 'Loading...',
      interfaceName: 'Loading...',
      lastUpdated: DateTime.now(),
    );
  }

  factory NetworkInfo.error(NetworkType type) {
    return NetworkInfo(
      type: type,
      status: NetworkStatus.disconnected,
      localIp: 'N/A',
      publicIp: 'N/A',
      ipDetails: 'N/A',
      dnsServers: const ['N/A'],
      dnsDetectionMethod: 'Error',
      interfaceName: 'N/A',
      lastUpdated: DateTime.now(),
    );
  }

  bool get isConnected => status == NetworkStatus.connected;
  bool get isLoading => status == NetworkStatus.connecting;
}