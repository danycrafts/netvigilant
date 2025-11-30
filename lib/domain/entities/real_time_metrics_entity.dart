import 'package:equatable/equatable.dart';

class RealTimeMetricsEntity extends Equatable {
  final double uplinkSpeed; // in bytes per second
  final double downlinkSpeed; // in bytes per second

  const RealTimeMetricsEntity({
    required this.uplinkSpeed,
    required this.downlinkSpeed,
  });

  @override
  List<Object?> get props => [uplinkSpeed, downlinkSpeed];
}
