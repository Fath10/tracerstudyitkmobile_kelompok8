import 'dart:io';

class ApiConfig {
  // Base URL - Automatically configured based on platform
  // Android Emulator: http://10.0.2.2:8000
  // iOS Simulator: http://localhost:8000
  // Physical device: Use your computer's IP address
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine's localhost
      // return 'http://10.0.2.2:8000';
      // For physical device, uncomment below and use your computer's IP:
      return 'http://192.168.0.105:8000';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return 'http://localhost:8000';
    } else {
      // Default for desktop/web
      return 'http://localhost:8000';
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
  
  // Helper to build full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  // Timeout durations (optimized for mobile devices)
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration shortTimeout = Duration(seconds: 8);
}
