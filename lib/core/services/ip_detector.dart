import 'dart:io';

/// Single Responsibility: Handle IP detection efficiently
/// Open/Closed: Easy to extend with new detection methods
/// Interface Segregation: Clean public API
/// Dependency Inversion: No concrete dependencies
class IpDetector {
  static const List<String> _privateRanges = [
    '192.168.',
    '10.',
    '172.16.',
    '172.17.',
    '172.18.',
    '172.19.',
    '172.20.',
    '172.21.',
    '172.22.',
    '172.23.',
    '172.24.',
    '172.25.',
    '172.26.',
    '172.27.',
    '172.28.',
    '172.29.',
    '172.30.',
    '172.31.',
  ];

  /// KISS: One method, one purpose - get the best local IP
  static Future<String> getBestLocalIp() async {
    // Strategy 1: Socket connection (fastest, most reliable)
    final socketIp = await _getIpViaSocket();
    if (socketIp != null) return socketIp;

    // Strategy 2: Interface enumeration (fallback)
    final interfaceIp = await _getIpViaInterfaces();
    if (interfaceIp != null) return interfaceIp;

    return 'Unable to detect';
  }

  /// DRY: Reusable socket-based detection
  static Future<String?> _getIpViaSocket() async {
    try {
      final socket = await Socket.connect('8.8.8.8', 80, timeout: Duration(seconds: 3));
      final ip = socket.address.address;
      await socket.close();
      
      return _isValidLocalIp(ip) ? ip : null;
    } catch (_) {
      return null;
    }
  }

  /// DRY: Reusable interface-based detection
  static Future<String?> _getIpViaInterfaces() async {
    try {
      final interfaces = await NetworkInterface.list(includeLoopback: false);
      
      // Prioritize private IPs
      for (final interface in interfaces) {
        final privateIp = _findPrivateIp(interface);
        if (privateIp != null) return privateIp;
      }
      
      // Fallback to any valid IPv4
      for (final interface in interfaces) {
        final publicIp = _findAnyValidIp(interface);
        if (publicIp != null) return publicIp;
      }
    } catch (_) {
      // Silent fail
    }
    return null;
  }

  /// SOLID: Helper focused on private IP detection
  static String? _findPrivateIp(NetworkInterface interface) {
    for (final addr in interface.addresses) {
      if (!_isValidAddress(addr)) continue;
      
      final ip = addr.address;
      if (_isPrivateIp(ip)) return ip;
    }
    return null;
  }

  /// SOLID: Helper focused on any valid IP detection
  static String? _findAnyValidIp(NetworkInterface interface) {
    for (final addr in interface.addresses) {
      if (!_isValidAddress(addr)) continue;
      return addr.address;
    }
    return null;
  }

  /// KISS: Simple validation
  static bool _isValidAddress(InternetAddress addr) {
    return addr.type == InternetAddressType.IPv4 && 
           !addr.isLoopback && 
           !addr.isLinkLocal;
  }

  /// KISS: Simple private IP check
  static bool _isPrivateIp(String ip) {
    return _privateRanges.any((range) => ip.startsWith(range));
  }

  /// KISS: Simple IP validation
  static bool _isValidLocalIp(String? ip) {
    return ip != null && 
           ip.isNotEmpty && 
           ip != '127.0.0.1' && 
           !ip.contains(':');
  }
}