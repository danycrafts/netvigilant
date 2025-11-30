class NetworkTrafficModel {
  final String id;
  final String sourceIp;
  final String destinationIp;
  final int port;
  final String protocol;
  final int size;
  final DateTime timestamp;

  NetworkTrafficModel({
    required this.id,
    required this.sourceIp,
    required this.destinationIp,
    required this.port,
    required this.protocol,
    required this.size,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}