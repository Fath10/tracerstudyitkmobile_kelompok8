import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

// ignore_for_file: unused_import

class NetworkDiscovery {
  static const int _backendPort = 8000;
  static String? _cachedBackendUrl;
  static DateTime? _lastDiscoveryTime;

  /// Discovers the backend server automatically by checking common IP patterns
  static Future<String?> discoverBackend() async {
    print('🔍 Starting backend discovery...');
    
    // Return cached URL if available and still valid (within 5 minutes)
    if (_cachedBackendUrl != null && _lastDiscoveryTime != null) {
      final timeSinceLastDiscovery = DateTime.now().difference(_lastDiscoveryTime!);
      if (timeSinceLastDiscovery.inMinutes < 5) {
        if (await _isBackendReachable(_cachedBackendUrl!)) {
          print('✅ Using cached backend: $_cachedBackendUrl');
          return _cachedBackendUrl;
        } else {
          print('⚠️ Cached backend unreachable, rediscovering...');
          _cachedBackendUrl = null;
        }
      }
    }

    // Get device's local IP to determine subnet
    final localIp = await _getLocalIpAddress();
    print('📱 Device IP: $localIp');
    
    // Build list of candidate IPs to scan
    final candidateIps = <String>[];
    
    if (localIp != null) {
      final subnet = _getSubnet(localIp);
      print('🌐 Scanning subnet: $subnet*');
      
      // Priority: Most common server IPs first
      final priorityIps = [
        '${subnet}106', // Current known IP
        '${subnet}105',
        '${subnet}100',
        '${subnet}1',   // Router
        '${subnet}170',
      ];
      
      candidateIps.addAll(priorityIps);
      
      // Extended scan (reduced range for faster discovery)
      for (int i = 2; i <= 30; i++) {
        if (!priorityIps.contains('$subnet$i')) {
          candidateIps.add('$subnet$i');
        }
      }
      for (int i = 101; i <= 120; i++) {
        if (!priorityIps.contains('$subnet$i')) {
          candidateIps.add('$subnet$i');
        }
      }
    } else {
      // No local IP detected, try common subnets
      print('⚠️ No device IP, trying common subnets...');
      final commonSubnets = ['192.168.0.', '192.168.1.', '10.0.0.', '172.16.0.'];
      for (final subnet in commonSubnets) {
        candidateIps.addAll([
          '${subnet}106',
          '${subnet}105',
          '${subnet}100',
          '${subnet}1',
          '${subnet}170',
        ]);
      }
    }
    
    print('📡 Scanning ${candidateIps.length} IP addresses in batches...');
    
    // Scan in batches of 20 for better performance
    for (int i = 0; i < candidateIps.length; i += 20) {
      final batchEnd = (i + 20 < candidateIps.length) ? i + 20 : candidateIps.length;
      final batch = candidateIps.sublist(i, batchEnd);
      
      print('📡 Batch ${(i ~/ 20) + 1}: Testing IPs ${i + 1}-$batchEnd...');
      
      try {
        final futures = batch.map((ip) => _tryIp(ip));
        final results = await Future.wait(futures).timeout(
          const Duration(seconds: 3),
          onTimeout: () => List.filled(batch.length, null),
        );
        
        final found = results.firstWhere((url) => url != null, orElse: () => null);
        if (found != null) {
          _cachedBackendUrl = found;
          _lastDiscoveryTime = DateTime.now();
          print('✅ Backend discovered at: $found');
          return found;
        }
      } catch (e) {
        print('⚠️ Batch error: $e');
      }
    }
    
    print('❌ No backend found after scanning ${candidateIps.length} IPs');

    // Fallback to emulator addresses
    if (Platform.isAndroid) {
      print('🔄 Trying emulator address...');
      const url = 'http://10.0.2.2:$_backendPort';
      if (await _isBackendReachable(url)) {
        _cachedBackendUrl = url;
        _lastDiscoveryTime = DateTime.now();
        print('✅ Using emulator address: $url');
        return url;
      }
    }

    // Final fallback to known IP
    print('🔄 Trying known backend IP as last resort...');
    const fallbackUrl = 'http://192.168.0.106:$_backendPort';
    if (await _isBackendReachable(fallbackUrl)) {
      _cachedBackendUrl = fallbackUrl;
      _lastDiscoveryTime = DateTime.now();
      print('✅ Using fallback address: $fallbackUrl');
      return fallbackUrl;
    }

    print('❌ Backend discovery failed completely');
    return null;
  }
  
  /// Try a single IP address
  static Future<String?> _tryIp(String ip) async {
    final url = 'http://$ip:$_backendPort';
    try {
      if (await _isBackendReachable(url)) {
        print('✅ Found backend at: $url');
        return url;
      }
    } catch (e) {
      // Silent fail for individual IPs
    }
    return null;
  }

  /// Gets the device's local IP address
  static Future<String?> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          // Skip loopback and link-local addresses
          if (!ip.startsWith('127.') && !ip.startsWith('169.254.')) {
            return ip;
          }
        }
      }
    } catch (e) {
      print('Error getting local IP: $e');
    }
    return null;
  }

  /// Extracts subnet from IP address (e.g., "192.168.1.100" -> "192.168.1.")
  static String _getSubnet(String ip) {
    final parts = ip.split('.');
    return '${parts[0]}.${parts[1]}.${parts[2]}.';
  }

  /// Checks if backend is reachable at given URL
  static Future<bool> _isBackendReachable(String baseUrl) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/surveys/'))
          .timeout(const Duration(seconds: 2)); // Reduced timeout for faster scanning
      // Accept 200 (success), 401 (unauthorized - means server exists), 403 (forbidden)
      final isReachable = response.statusCode == 200 || 
                          response.statusCode == 401 || 
                          response.statusCode == 403;
      if (isReachable) {
        print('✅ Backend reachable at $baseUrl (${response.statusCode})');
      }
      return isReachable;
    } catch (e) {
      // Silent fail for scanning
      return false;
    }
  }

  /// Clears cached backend URL (useful when network changes)
  static void clearCache() {
    _cachedBackendUrl = null;
    _lastDiscoveryTime = null;
    print('🔄 Backend cache cleared');
  }
  
  /// Force rediscovery (useful when network changes)
  static Future<String?> forceRediscover() async {
    clearCache();
    return discoverBackend();
  }
}
