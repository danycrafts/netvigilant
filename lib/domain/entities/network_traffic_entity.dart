import 'package:equatable/equatable.dart';

enum NetworkType { wifi, mobile, unknown }

class NetworkTrafficEntity extends Equatable {
  final String appName;
  final String packageName;
  final int uid; // Added UID
  final int txBytes;
  final int rxBytes;
  final DateTime timestamp;
  final NetworkType networkType;
  final bool isBackgroundTraffic;

  const NetworkTrafficEntity({
    required this.appName,
    required this.packageName,
    required this.uid, // Added to constructor
    required this.txBytes,
    required this.rxBytes,
    required this.timestamp,
    required this.networkType,
    required this.isBackgroundTraffic,
  });

  @override
  List<Object?> get props => [
        appName,
        packageName,
        uid, // Added to props
        txBytes,
        rxBytes,
        timestamp,
        networkType,
        isBackgroundTraffic,
      ];

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'packageName': packageName,
      'uid': uid,
      'txBytes': txBytes,
      'rxBytes': rxBytes,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'networkType': networkType.toString().split('.').last,
      'isBackgroundTraffic': isBackgroundTraffic,
    };
  }
}
