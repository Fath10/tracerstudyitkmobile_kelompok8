class ApiConfig {
  // Base URL - Change this to your backend server address
  // For Android Emulator use: http://10.0.2.2:8000
  // For iOS Simulator use: http://localhost:8000
  // For physical device use: http://YOUR_IP_ADDRESS:8000
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  // Authentication endpoints
  static const String login = '/accounts/login/';
  static const String register = '/accounts/register/';
  static const String refreshToken = '/accounts/refresh/';
  
  // Survey endpoints
  static const String surveys = '/api/surveys/';
  static String surveyDetail(int id) => '/api/surveys/$id/';
  static String surveySections(int surveyId) => '/api/surveys/$surveyId/sections/';
  static String surveyQuestions(int surveyId, int sectionId) => 
      '/api/surveys/$surveyId/sections/$sectionId/questions/';
  static String surveyAnswers(int surveyId) => '/api/surveys/$surveyId/answers/';
  static String surveyAnswersBulk(int surveyId) => '/api/surveys/$surveyId/answers/bulk/';
  
  // Faculty endpoints
  static const String faculties = '/api/unit/faculties/';
  static String facultyDetail(int id) => '/api/unit/faculties/$id/';
  
  // Department endpoints
  static const String departments = '/api/unit/departments/';
  static String departmentDetail(int id) => '/api/unit/departments/$id/';
  
  // Program Study endpoints
  static const String programStudies = '/api/unit/program-studies/';
  static String programStudyDetail(int id) => '/api/unit/program-studies/$id/';
  
  // Periode endpoints
  static const String periodes = '/api/periodes/';
  static String periodeDetail(int id) => '/api/periodes/$id/';
  
  // User role endpoints
  static const String users = '/api/users/';
  static String userDetail(int id) => '/api/users/$id/';
  static const String roles = '/api/roles/';
  static String roleDetail(int id) => '/api/roles/$id/';
  
  // Helper to build full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
