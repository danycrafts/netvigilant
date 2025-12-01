import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'network_interface_analyzer.dart';

class NetworkDataFetcher {
  static const Duration _timeout = Duration(seconds: 10);

  /// Enhanced network data fetching with comprehensive information
  static Future<Map<String, dynamic>> fetchComprehensiveNetworkInfo() async {
    final results = <String, dynamic>{};
    
    // Fetch all data concurrently for better performance
    final futures = await Future.wait([
      _fetchPublicIpInfo(),
      _fetchLocalNetworkInfo(),
      _fetchDnsInfo(),
    ]);
    
    final publicIpInfo = futures[0];
    final localNetworkInfo = futures[1];
    final dnsInfo = futures[2];
    
    // Merge all results
    results.addAll(publicIpInfo);
    results.addAll(localNetworkInfo);
    results.addAll(dnsInfo);
    
    return results;
  }

  /// Legacy method for backward compatibility
  static Future<Map<String, dynamic>> fetchPublicIpInfo() async {
    return await _fetchPublicIpInfo();
  }

  static Future<Map<String, dynamic>> _fetchPublicIpInfo() async {
    try {
      // Try multiple IP detection services for reliability
      final ipSources = [
        'https://api.ipify.org?format=json',
        'https://httpbin.org/ip',
        'https://icanhazip.com',
      ];
      
      String? publicIp;
      
      for (final source in ipSources) {
        try {
          final response = await http.get(Uri.parse(source)).timeout(_timeout);
          
          if (response.statusCode == 200) {
            if (source.contains('ipify')) {
              publicIp = json.decode(response.body)['ip'] as String;
            } else if (source.contains('httpbin')) {
              publicIp = json.decode(response.body)['origin'] as String;
            } else if (source.contains('icanhazip')) {
              publicIp = response.body.trim();
            }
            
            if (publicIp != null && publicIp.isNotEmpty) break;
          }
        } catch (e) {
          continue; // Try next source
        }
      }

      if (publicIp != null) {
        // Fetch detailed geolocation and ISP info
        final detailsResponse = await http.get(
          Uri.parse('http://ip-api.com/json/$publicIp?fields=status,message,country,countryCode,region,regionName,city,zip,lat,lon,timezone,isp,org,as,query'),
        ).timeout(_timeout);

        if (detailsResponse.statusCode == 200) {
          final details = json.decode(detailsResponse.body);
          
          if (details['status'] == 'success') {
            final locationInfo = _buildLocationString(details);
            final ispInfo = _buildIspString(details);
            
            return {
              'publicIp': publicIp,
              'ipDetails': '$ispInfo\n$locationInfo',
              'coordinates': LatLng(details['lat'], details['lon']),
              'timezone': details['timezone'] ?? 'Unknown',
              'city': details['city'] ?? 'Unknown',
              'country': details['country'] ?? 'Unknown',
              'isp': details['isp'] ?? 'Unknown',
              'org': details['org'] ?? 'Unknown',
            };
          }
        }
        
        // Fallback with basic info if detailed lookup fails
        return {
          'publicIp': publicIp,
          'ipDetails': 'ISP: Unknown\nLocation: Unknown',
          'coordinates': null,
        };
      }
    } catch (e) {
      // Log error if needed
    }
    
    return {
      'publicIp': 'Error',
      'ipDetails': 'Details unavailable',
      'coordinates': null,
    };
  }

  static Future<Map<String, dynamic>> _fetchLocalNetworkInfo() async {
    try {
      final interfaceInfo = await NetworkInterfaceAnalyzer.getActiveNetworkInterface();
      
      if (interfaceInfo != null) {
        return {
          'localIp': interfaceInfo.ipv4,
          'localIpv6': interfaceInfo.ipv6,
          'interfaceName': interfaceInfo.interfaceName,
          'interfaceType': interfaceInfo.interfaceType,
          'isInterfaceActive': interfaceInfo.isActive,
        };
      }
    } catch (e) {
      // Log error if needed
    }
    
    return {
      'localIp': 'Error detecting local IP',
      'localIpv6': null,
      'interfaceName': 'Unknown',
      'interfaceType': 'Unknown',
      'isInterfaceActive': false,
    };
  }

  static Future<Map<String, dynamic>> _fetchDnsInfo() async {
    try {
      final dnsInfo = await NetworkInterfaceAnalyzer.detectDnsServers();
      
      return {
        'dnsServers': dnsInfo.dnsServers,
        'dnsDetectionMethod': dnsInfo.detectionMethod,
        'dnsAdditionalInfo': dnsInfo.additionalInfo,
      };
    } catch (e) {
      // Log error if needed
      return {
        'dnsServers': ['Error detecting DNS'],
        'dnsDetectionMethod': 'Error',
        'dnsAdditionalInfo': 'Failed to detect DNS servers',
      };
    }
  }

  static String _buildLocationString(Map<String, dynamic> details) {
    final parts = <String>[];
    
    if (details['city'] != null && details['city'].isNotEmpty) {
      parts.add(details['city']);
    }
    if (details['regionName'] != null && details['regionName'].isNotEmpty) {
      parts.add(details['regionName']);
    }
    if (details['country'] != null && details['country'].isNotEmpty) {
      parts.add(details['country']);
    }
    if (details['zip'] != null && details['zip'].isNotEmpty) {
      parts.add('(${details['zip']})');
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'Location unknown';
  }

  static String _buildIspString(Map<String, dynamic> details) {
    final isp = details['isp'] ?? details['org'] ?? 'Unknown ISP';
    final as = details['as']?.toString().split(' ').first ?? '';
    
    if (as.isNotEmpty) {
      return '$isp ($as)';
    }
    return isp;
  }

  /// Get network performance metrics
  static Future<Map<String, dynamic>> getNetworkMetrics() async {
    final results = <String, dynamic>{};
    
    try {
      // Measure latency to multiple servers
      final latencies = await Future.wait([
        _measureLatency('8.8.8.8', 'Google DNS'),
        _measureLatency('1.1.1.1', 'Cloudflare DNS'),
        _measureLatency('8.8.4.4', 'Google DNS Secondary'),
      ]);
      
      results['latencies'] = latencies;
      
      // Get route trace information (simplified)
      final routeInfo = await _getRouteInfo();
      results.addAll(routeInfo);
      
    } catch (e) {
      results['error'] = 'Failed to get network metrics';
    }
    
    return results;
  }

  static Future<Map<String, dynamic>> _measureLatency(String host, String name) async {
    try {
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect(host, 53, timeout: const Duration(seconds: 3));
      stopwatch.stop();
      await socket.close();
      
      return {
        'host': host,
        'name': name,
        'latency': stopwatch.elapsedMilliseconds,
        'success': true,
      };
    } catch (e) {
      return {
        'host': host,
        'name': name,
        'latency': -1,
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _getRouteInfo() async {
    try {
      // Get basic routing information
      final localInterface = await NetworkInterfaceAnalyzer.getActiveNetworkInterface();
      
      if (localInterface != null) {
        return {
          'hopCount': 'Unknown', // Could be enhanced with traceroute
          'gateway': 'Auto-detected',
          'mtu': 'Standard',
        };
      }
    } catch (e) {
      // Ignore
    }
    
    return {
      'hopCount': 'N/A',
      'gateway': 'N/A',
      'mtu': 'N/A',
    };
  }
}