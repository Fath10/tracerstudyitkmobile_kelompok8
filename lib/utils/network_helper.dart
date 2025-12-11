import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NetworkHelper {
  /// Check if backend is reachable
  static Future<bool> isBackendReachable() async {
    try {
      final url = Uri.parse(ApiConfig.getUrl('/api/surveys/'));
      final response = await http.head(url).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode < 500;
    } catch (e) {
      print('❌ Backend unreachable: $e');
      return false;
    }
  }

  /// Test backend connectivity with detailed info
  static Future<Map<String, dynamic>> testConnection() async {
    final startTime = DateTime.now();
    
    try {
      final url = Uri.parse(ApiConfig.getUrl('/api/surveys/'));
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );
      
      final duration = DateTime.now().difference(startTime);
      
      return {
        'success': true,
        'statusCode': response.statusCode,
        'responseTime': duration.inMilliseconds,
        'message': 'Backend connected successfully',
      };
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      
      return {
        'success': false,
        'statusCode': -1,
        'responseTime': duration.inMilliseconds,
        'message': 'Connection failed: $e',
        'error': e.toString(),
      };
    }
  }

  /// Get network quality indicator
  static String getNetworkQuality(int responseTimeMs) {
    if (responseTimeMs < 500) return 'Excellent';
    if (responseTimeMs < 1000) return 'Good';
    if (responseTimeMs < 2000) return 'Fair';
    if (responseTimeMs < 5000) return 'Poor';
    return 'Very Poor';
  }
}
