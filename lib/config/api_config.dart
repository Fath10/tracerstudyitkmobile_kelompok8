import 'package:flutter/foundation.dart';

import '../services/network_discovery.dart';

class ApiConfig {
  // ============================================================================
  // DEPLOYMENT CONFIGURATION
  // ============================================================================
  
  /// Set this to true for production deployment
  /// Set to false for local development
  static const bool isProduction = false;
  
  /// Your production backend URL (ngrok, Heroku, AWS, etc.)
  /// Example: 'https://your-app.ngrok-free.app'
  /// Example: 'https://your-app.herokuapp.com'
  /// Example: 'https://api.yourdomain.com'
  static const String productionUrl = 'https://your-backend-url.ngrok-free.app';
  
  /// Local development fallback (when auto-discovery fails)
  /// Use 10.0.2.2 for Android emulator (refers to host machine's localhost)
  /// Use 127.0.0.1 for web/desktop development
  static const String developmentFallback = 'http://10.0.2.2:8000';
  
  // ============================================================================
  
  static String? _discoveredBaseUrl;
  static bool _isDiscovering = false;

  /// Gets the base URL based on configuration
  static Future<String> getBaseUrl() async {
    // PRODUCTION MODE: Use fixed production URL
    if (isProduction) {
      _discoveredBaseUrl = productionUrl;
      debugPrint('🌍 Production mode: $productionUrl');
      return productionUrl;
    }
    
    // DEVELOPMENT MODE: Auto-discover or use manual setting
    
    // Return cached URL if available
    if (_discoveredBaseUrl != null) {
      debugPrint('📦 Using cached backend: $_discoveredBaseUrl');
      return _discoveredBaseUrl!;
    }

    // Prevent multiple simultaneous discoveries
    if (_isDiscovering) {
      debugPrint('⏳ Discovery in progress, waiting...');
      int waitCount = 0;
      while (_isDiscovering && waitCount < 150) {
        await Future.delayed(const Duration(milliseconds: 200));
        waitCount++;
      }
      if (_discoveredBaseUrl != null) {
        return _discoveredBaseUrl!;
      }
      debugPrint('⚠️ Wait timeout, using fallback');
      _discoveredBaseUrl = developmentFallback;
      return developmentFallback;
    }

    _isDiscovering = true;
    try {
      debugPrint('🔍 Auto-discovering backend...');
      
      // Try to discover backend automatically
      final discovered = await NetworkDiscovery.discoverBackend().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⏱️ Discovery timeout, using fallback');
          return null;
        },
      );
      
      if (discovered != null) {
        _discoveredBaseUrl = discovered;
        debugPrint('✅ Backend found: $discovered');
        return discovered;
      }

      // Discovery failed, use fallback
      debugPrint('⚠️ Auto-discovery failed, using fallback: $developmentFallback');
      _discoveredBaseUrl = developmentFallback;
      return developmentFallback;
    } catch (e) {
      debugPrint('❌ Discovery error: $e, using fallback');
      _discoveredBaseUrl = developmentFallback;
      return developmentFallback;
    } finally {
      _isDiscovering = false;
    }
  }

  /// Synchronous getter
  static String get baseUrl {
    if (isProduction) return productionUrl;
    return _discoveredBaseUrl ?? developmentFallback;
  }

  /// Clears cached backend URL
  static void resetBackendUrl() {
    if (!isProduction) {
      _discoveredBaseUrl = null;
      NetworkDiscovery.clearCache();
      debugPrint('🔄 Backend URL reset');
    }
  }
  
  /// Force rediscovery
  static Future<String> forceRediscover() async {
    if (isProduction) return productionUrl;
    resetBackendUrl();
    return await getBaseUrl();
  }
  
  /// Manually set backend URL
  static void setManualUrl(String url) {
    if (!isProduction) {
      _discoveredBaseUrl = url;
      debugPrint('🔧 Manual URL set: $url');
    }
  }
  
  // Authentication endpoints
  static const String login = '/accounts/login/';
  static const String register = '/accounts/register/';
  static const String refreshToken = '/accounts/refresh/';
  
  // Survey endpoints
  static const String surveys = '/api/surveys/';
  static String surveyDetail(int id) => '/api/surveys/$id/';
  
  // Section endpoints
  static String surveySections(int surveyId) => '/api/surveys/$surveyId/sections/';
  static String sectionDetail(int surveyId, int sectionId) => 
      '/api/surveys/$surveyId/sections/$sectionId/';
  
  // Question endpoints
  static String surveyQuestions(int surveyId, int sectionId) => 
      '/api/surveys/$surveyId/sections/$sectionId/questions/';
  static String questionDetail(int surveyId, int sectionId, int questionId) =>
      '/api/surveys/$surveyId/sections/$sectionId/questions/$questionId/';
  
  // Program-specific question endpoints
  static String programSpecificQuestions(int surveyId, int programStudyId) =>
      '/api/surveys/$surveyId/programs/$programStudyId/questions/';
  static String programSpecificQuestionDetail(int surveyId, int programStudyId, int questionId) =>
      '/api/surveys/$surveyId/programs/$programStudyId/questions/$questionId/';
  
  // Answer endpoints
  static String surveyAnswers(int surveyId) => '/api/surveys/$surveyId/answers/';
  static String answerDetail(int surveyId, int answerId) => 
      '/api/surveys/$surveyId/answers/$answerId/';
  static String answersByQuestion(int surveyId, int sectionId, int questionId) =>
      '/api/surveys/$surveyId/sections/$sectionId/questions/$questionId/answers/';
  static String answersByProgramQuestion(int surveyId, int programStudyId, int questionId) =>
      '/api/surveys/$surveyId/programs/$programStudyId/questions/$questionId/answers/';
  static String surveyAnswersBulk(int surveyId) => '/api/surveys/$surveyId/answers/bulk/';
  
  // Faculty endpoints
  static const String faculties = '/api/unit/faculties/';
  static String facultyDetail(int id) => '/api/unit/faculties/$id/';
  
  // Department endpoints
  static const String departments = '/api/unit/departments/';
  static String departmentDetail(int id) => '/api/unit/departments/$id/';
  
  // Program Studi endpoints
  static const String programStudies = '/api/unit/program-studies/';
  static String programStudyDetail(int id) => '/api/unit/program-studies/$id/';
  
  // Periode endpoints
  static const String periodes = '/api/periodes/';
  static String periodeDetail(int id) => '/api/periodes/$id/';
  
  // User role endpoints
  static const String users = '/api/users/';
  static const String roles = '/api/roles/';
  
  // Timeout durations (increased for network stability)
  static const Duration connectionTimeout = Duration(seconds: 45);
  static const Duration receiveTimeout = Duration(seconds: 45);
  static const Duration shortTimeout = Duration(seconds: 30);
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
