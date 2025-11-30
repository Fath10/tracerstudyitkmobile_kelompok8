import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'token_service.dart';

class AuthService {
  static UserModel? _currentUser;

  static UserModel? get currentUser => _currentUser;
  static Map<String, dynamic>? get currentUserMap => _currentUser != null 
      ? _currentUser!.toJson() 
      : null;

  static void setCurrentUser(Map<String, dynamic> user) {
    // Check if this is local database format (has 'role' as string)
    if (user['role'] is String) {
      final transformed = _transformLocalUserData(user);
      _currentUser = UserModel.fromJson(transformed);
    } else {
      _currentUser = UserModel.fromJson(user);
    }
  }

  // Save local database user to persistent storage
  static Future<void> saveLocalUser(Map<String, dynamic> user) async {
    // Transform local database format to backend format
    final transformedUser = _transformLocalUserData(user);
    await TokenService.saveUserData(transformedUser);
  }

  // Transform local database user data to match backend format
  static Map<String, dynamic> _transformLocalUserData(Map<String, dynamic> user) {
    final roleName = user['role']?.toString() ?? 'user';
    
    return {
      'id': user['id']?.toString() ?? '',
      'username': user['name'] ?? user['username'] ?? '',
      'email': user['email'],
      'nim': user['nikKtp'],
      'address': user['placeOfBirth'],
      'phone_number': user['phone'],
      'last_survey': 'none',
      'role': {
        'id': _getRoleId(roleName),
        'name': roleName,
        'program_study': null,
        'program_study_name': user['prodi'],
      },
      'program_study': user['prodi'] != null ? {
        'id': 1,
        'name': user['prodi'],
        'department': null,
        'department_name': null,
        'faculty_name': null,
      } : null,
    };
  }

  // Get role ID based on role name
  static int _getRoleId(String roleName) {
    switch (roleName) {
      case 'admin':
        return 1;
      case 'surveyor':
        return 2;
      case 'team_prodi':
        return 3;
      case 'user':
        return 4;
      default:
        return 4;
    }
  }

  // Login with backend
  static Future<bool> login(String username, String password) async {
    try {
      final url = Uri.parse(ApiConfig.getUrl(ApiConfig.login));
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': username,  // Backend expects 'id' as USERNAME_FIELD
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 5), // Reduced timeout for faster response
        onTimeout: () {
          throw TimeoutException('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Save tokens
        await TokenService.saveTokens(
          accessToken: data['access'],
          refreshToken: data['refresh'],
        );

        // Save user data
        final userData = data['user'] ?? {};
        await TokenService.saveUserData(userData);
        
        // Set current user
        _currentUser = UserModel.fromJson(userData);
        
        return true;
      }
      return false;
    } on TimeoutException {
      print('Backend login timeout - will try local database');
      return false;
    } catch (e) {
      print('Backend login error: $e');
      return false;
    }
  }

  // Register with backend
  static Future<bool> register({
    required String id,
    required String username,
    required String password,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.getUrl(ApiConfig.register));
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': id,
          'username': username,
          'password': password,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  // Load user from stored token
  static Future<void> loadUser() async {
    final userData = await TokenService.getUserData();
    if (userData != null) {
      _currentUser = UserModel.fromJson(userData);
      print('✅ Loaded user: ${_currentUser!.username}, Role: ${_currentUser!.role?.name}');
    }
  }

  // Logout
  static Future<void> logout() async {
    print('🚪 Logging out user: ${_currentUser?.username}');
    await TokenService.clearAll();
    _currentUser = null;
    print('✅ Logout complete, user cleared');
  }

  static bool get isLoggedIn => _currentUser != null;

  // Get user role
  static String get userRole {
    if (_currentUser == null) return 'guest';
    return (_currentUser!.role?.name ?? 'user').toLowerCase();
  }

  // Get account type (legacy - kept for compatibility)
  static String get accountType {
    if (_currentUser == null) return 'guest';
    final role = userRole;
    // Admin, surveyor, and team_prodi are employees; others are users
    if (role == 'admin' || role == 'surveyor' || role == 'team_prodi') {
      return 'employee';
    }
    return 'user';
  }

  // Get prodi (for team prodi)
  static String? get userProdi {
    if (_currentUser == null) return null;
    return _currentUser!.programStudy?.name;
  }

  // Permission checks
  static bool get isAdmin => userRole.toLowerCase() == 'admin';
  static bool get isSurveyor => userRole.toLowerCase() == 'surveyor';
  static bool get isTeamProdi => userRole.toLowerCase() == 'team_prodi';
  static bool get isUser => userRole.toLowerCase() == 'user' || userRole.toLowerCase() == 'alumni';

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
