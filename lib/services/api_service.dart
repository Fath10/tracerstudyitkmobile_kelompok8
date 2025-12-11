import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Get headers with auth token and keep-alive
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Connection': 'keep-alive',
      'Keep-Alive': 'timeout=60',
    };

    if (includeAuth) {
      final token = await TokenService.getAccessToken();
      debugPrint('🔑 Token check: ${token != null ? "exists (${token.length} chars)" : "null"}');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        debugPrint('✅ Authorization header added');
      } else {
        debugPrint('⚠️ No valid token available');
      }
    } else {
      debugPrint('🚫 Auth explicitly disabled - no token will be sent');
    }

    return headers;
  }

  // Handle response and refresh token if needed
  Future<http.Response> _handleResponse(
    Future<http.Response> Function() request,
    bool shouldRetryAuth,
  ) async {
    var response = await request();

    // If unauthorized and auth is enabled, try to refresh token
    if (response.statusCode == 401) {
      debugPrint('⚠️ 401 Unauthorized - shouldRetryAuth: $shouldRetryAuth');
      if (shouldRetryAuth) {
        debugPrint('🔄 Attempting to refresh access token...');
        final refreshed = await TokenService.refreshAccessToken();
        if (refreshed) {
          debugPrint('✅ Token refreshed, retrying request');
          // Retry the request with new token
          response = await request();
        } else {
          debugPrint('❌ Token refresh failed, clearing tokens');
          await TokenService.clearTokens();
        }
      } else {
        debugPrint('ℹ️ Auth disabled for this request, not retrying');
      }
    }

    return response;
  }

  // GET request with retry logic - can return Map or List depending on endpoint
  Future<dynamic> get(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < ApiConfig.maxRetries) {
      try {
        // Ensure backend is discovered before making request
        final baseUrl = await ApiConfig.getBaseUrl();
        final url = Uri.parse('$baseUrl$endpoint');
        
        // Build headers WITHOUT token system for public endpoints
        Map<String, String> headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
        
        // Only add auth if explicitly requested AND token exists
        if (includeAuth) {
          final token = await TokenService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            headers['Authorization'] = 'Bearer $token';
          }
        }
        
        debugPrint('🌐 GET $endpoint (auth: $includeAuth)');

        final response = await http.get(url, headers: headers).timeout(
          ApiConfig.connectionTimeout,
        );

        debugPrint('✅ GET $endpoint → ${response.statusCode}');
        return _processResponse(response);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        retryCount++;
        
        if (retryCount < ApiConfig.maxRetries) {
          debugPrint('⚠️ Retry $retryCount: $e');
          await Future.delayed(ApiConfig.retryDelay);
        } else {
          debugPrint('❌ FAILED after ${ApiConfig.maxRetries} attempts: $e');
        }
      }
    }

    throw lastException ?? Exception('Network error');
  }

  // POST request with retry logic
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < ApiConfig.maxRetries) {
      try {
        // Ensure backend is discovered before making request
        final baseUrl = await ApiConfig.getBaseUrl();
        final headers = await _getHeaders(includeAuth: includeAuth);
        final url = Uri.parse('$baseUrl$endpoint');
        print('🌐 POST request to: $url (attempt ${retryCount + 1}/${ApiConfig.maxRetries})');

        final response = await _handleResponse(
          () => http
              .post(
                url,
                headers: headers,
                body: json.encode(data),
              )
              .timeout(ApiConfig.connectionTimeout),
          includeAuth,
        );

        print('✅ POST response status: ${response.statusCode}');
        return _processResponse(response);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        retryCount++;
        
        if (retryCount < ApiConfig.maxRetries) {
          print('⚠️ Retry POST ${retryCount}/${ApiConfig.maxRetries} for $endpoint');
          await Future.delayed(ApiConfig.retryDelay);
        } else {
          print('❌ All POST retries failed for $endpoint: $e');
        }
      }
    }

    throw lastException ?? Exception('Network error after ${ApiConfig.maxRetries} retries');
  }

  // PUT request with retry logic
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < ApiConfig.maxRetries) {
      try {
        // Ensure backend is discovered before making request
        final baseUrl = await ApiConfig.getBaseUrl();
        final headers = await _getHeaders(includeAuth: includeAuth);
        final url = Uri.parse('$baseUrl$endpoint');

        final response = await _handleResponse(
          () => http
              .put(
                url,
                headers: headers,
                body: json.encode(data),
              )
              .timeout(ApiConfig.connectionTimeout),
          includeAuth,
        );

        return _processResponse(response);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        retryCount++;
        if (retryCount < ApiConfig.maxRetries) {
          await Future.delayed(ApiConfig.retryDelay);
        }
      }
    }

    throw lastException ?? Exception('Network error after ${ApiConfig.maxRetries} retries');
  }

  // PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    try {
      // Ensure backend is discovered before making request
      final baseUrl = await ApiConfig.getBaseUrl();
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = Uri.parse('$baseUrl$endpoint');

        final response = await _handleResponse(
          () => http
            .patch(
              url,
              headers: headers,
              body: json.encode(data),
            )
            .timeout(ApiConfig.connectionTimeout),
          includeAuth,
        );      return _processResponse(response);
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
      // Ensure backend is discovered before making request
      final baseUrl = await ApiConfig.getBaseUrl();
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = Uri.parse('$baseUrl$endpoint');

      final response = await _handleResponse(
        () => http.delete(url, headers: headers).timeout(
              ApiConfig.connectionTimeout,
            ),
        includeAuth,
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
          // Check for token validation errors
          final detail = errorBody['detail']?.toString() ?? '';
          if (detail.contains('token') && detail.contains('not valid')) {
            // Token error - clear it to prevent future errors
            debugPrint('⚠️ Invalid token detected, clearing stored tokens');
            TokenService.clearTokens();
          }
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
