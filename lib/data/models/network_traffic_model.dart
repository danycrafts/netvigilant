import 'package:netvigilant/domain/entities/network_traffic_entity.dart';

class NetworkTrafficModel extends NetworkTrafficEntity {
  NetworkTrafficModel({
    required super.appName,
    required super.packageName,
    required super.uid,
    required super.txBytes,
    required super.rxBytes,
  }) : super(
          timestamp: DateTime.now(), // Placeholder
          networkType: NetworkType.unknown, // Placeholder
          isBackgroundTraffic: false, // Placeholder
        );

  factory NetworkTrafficModel.fromMap(Map<dynamic, dynamic> map) {
    return NetworkTrafficModel(
      appName: map['appName'],
      packageName: map['packageName'],
      uid: map['uid'] ?? 0,
      rxBytes: map['rxBytes'],
      txBytes: map['txBytes'],
    );
  }
}
