class AuthService {
  static Map<String, dynamic>? _currentUser;

  static Map<String, dynamic>? get currentUser => _currentUser;

  static void setCurrentUser(Map<String, dynamic> user) {
    _currentUser = user;
  }

  static void logout() {
    _currentUser = null;
  }

  static bool get isLoggedIn => _currentUser != null;

  // Get user role
  static String get userRole {
    if (_currentUser == null) return 'guest';
    // If it's an employee without a role field, default to 'surveyor'
    // If it's a user (alumni), return 'user'
    if (accountType == 'employee') {
      return _currentUser!['role'] ?? 'surveyor';
    }
    return _currentUser!['role'] ?? 'user';
  }

  // Get account type (employee or user)
  static String get accountType {
    if (_currentUser == null) return 'guest';
    return _currentUser!['accountType'] ?? 'user';
  }

  // Get prodi (for team prodi)
  static String? get userProdi {
    if (_currentUser == null || accountType != 'employee') return null;
    return _currentUser!['prodi'];
  }

  // Permission checks
  static bool get isAdmin => userRole == 'admin';
  static bool get isSurveyor => userRole == 'surveyor';
  static bool get isTeamProdi => userRole == 'team_prodi';
  static bool get isUser => userRole == 'user';

  // Access permissions
  static bool get canAccessUserManagement => isAdmin;
  static bool get canAccessEmployeeDirectory => isAdmin;
  static bool get canAccessAllSurveys => isAdmin || isSurveyor;
  static bool get canEditGeneralSurveys => isAdmin || isSurveyor;
  static bool get canViewSurveyResponses => isAdmin || isSurveyor || isTeamProdi;
  static bool get canFillQuestionnaires => true; // Everyone can fill
  
  static bool canEditProdiSurvey(String? surveyProdi) {
    if (isAdmin) return true;
    if (isSurveyor) return surveyProdi == null || surveyProdi.isEmpty;
    if (isTeamProdi && userProdi != null && surveyProdi != null) {
      return userProdi == surveyProdi;
    }
    return false;
  }

  static bool canViewSurvey(String? surveyProdi) {
    if (isAdmin || isSurveyor) return true;
    if (isTeamProdi && userProdi != null && surveyProdi != null) {
      return userProdi == surveyProdi;
    }
    if (isUser) return true; // Users can view all to fill
    return false;
  }

  // Get display name for role
  static String getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'surveyor':
        return 'Team Tracer';
      case 'team_prodi':
        return 'Team Prodi';
      case 'user':
        return 'Alumni';
      default:
        return 'Unknown';
    }
  }

  // Get available prodis
  static List<String> getAvailableProdis() {
    return ['Informatics', 'Mathematics', 'Chemistry'];
  }
}
