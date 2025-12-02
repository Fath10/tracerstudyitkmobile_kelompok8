import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await TokenService.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Handle response and refresh token if needed
  Future<http.Response> _handleResponse(
    Future<http.Response> Function() request,
  ) async {
    var response = await request();

    // If unauthorized, try to refresh token
    if (response.statusCode == 401) {
      final refreshed = await TokenService.refreshAccessToken();
      if (refreshed) {
        // Retry the request with new token
        response = await request();
      }
    }

    return response;
  }

  // GET request - can return Map or List depending on endpoint
  Future<dynamic> get(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = Uri.parse(ApiConfig.getUrl(endpoint));
      print('🌐 GET request to: $url');

      final response = await _handleResponse(
        () => http.get(url, headers: headers).timeout(
              const Duration(seconds: 15), // Reduced timeout for faster failures
            ),
      );

      print('✅ Response status: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      print('❌ Network error for $endpoint: $e');
      throw Exception('Network error: $e');
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = Uri.parse(ApiConfig.getUrl(endpoint));

      final response = await _handleResponse(
        () => http
            .post(
              url,
              headers: headers,
              body: json.encode(data),
            )
            .timeout(const Duration(seconds: 15)), // Reduced timeout
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = Uri.parse(ApiConfig.getUrl(endpoint));

      final response = await _handleResponse(
        () => http
            .put(
              url,
              headers: headers,
              body: json.encode(data),
            )
            .timeout(ApiConfig.connectionTimeout),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = Uri.parse(ApiConfig.getUrl(endpoint));

      final response = await _handleResponse(
        () => http
            .patch(
              url,
              headers: headers,
              body: json.encode(data),
            )
            .timeout(ApiConfig.connectionTimeout),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = Uri.parse(ApiConfig.getUrl(endpoint));

      final response = await _handleResponse(
        () => http.delete(url, headers: headers).timeout(
              ApiConfig.connectionTimeout,
            ),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Process HTTP response
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      // Return the decoded JSON as-is (can be Map or List)
      return json.decode(response.body);
    } else {
      String errorMessage = 'Request failed with status: ${response.statusCode}';
      try {
        final errorBody = json.decode(response.body);
        if (errorBody is Map) {
          errorMessage = errorBody['detail'] ?? 
                        errorBody['error'] ?? 
                        errorBody['message'] ?? 
                        errorMessage;
        }
      } catch (e) {
        // If response body is not JSON, use status code
      }
      throw Exception(errorMessage);
    }
  }
}
