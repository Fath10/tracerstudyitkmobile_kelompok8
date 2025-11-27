import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/backend_survey_service.dart';
import '../services/backend_user_service.dart';

/// Example Usage of Backend Integration
/// 
/// This file demonstrates how to use the backend API services
/// in your Flutter application.

class BackendIntegrationExamples {
  
  // Example 1: User Login
  static Future<void> exampleLogin(BuildContext context) async {
    try {
      bool success = await AuthService.login('username', 'password');
      
      if (success) {
        // User is logged in
        final currentUser = AuthService.currentUser;
        print('Logged in as: ${currentUser?['username']}');
        
        // Navigate to home page
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // Login failed
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid credentials')),
          );
        }
      }
    } catch (e) {
      print('Login error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Example 2: User Registration
  static Future<void> exampleRegister(BuildContext context) async {
    try {
      bool success = await AuthService.register(
        id: '12345678',
        username: 'John Doe',
        password: 'secure_password',
      );
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        // Navigate to login
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Registration error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Example 3: Fetch All Surveys
  static Future<void> exampleFetchSurveys() async {
    try {
      final surveyService = BackendSurveyService();
      List<dynamic> surveys = await surveyService.getAllSurveys();
      
      for (var survey in surveys) {
        print('Survey: ${survey['title']} - ${survey['description']}');
      }
    } catch (e) {
      print('Error fetching surveys: $e');
    }
  }

  // Example 4: Get Survey Details with Sections and Questions
  static Future<void> exampleGetSurveyDetails(int surveyId) async {
    try {
      final surveyService = BackendSurveyService();
      
      // Get survey
      Map<String, dynamic> survey = await surveyService.getSurveyById(surveyId);
      print('Survey: ${survey['title']}');
      
      // Get sections
      List<dynamic> sections = await surveyService.getSurveySections(surveyId);
      
      for (var section in sections) {
        print('  Section: ${section['title']}');
        
        // Get questions for this section
        List<dynamic> questions = await surveyService.getSectionQuestions(
          surveyId,
          section['id'],
        );
        
        for (var question in questions) {
          print('    Question: ${question['text']}');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Example 5: Create a New Survey
  static Future<void> exampleCreateSurvey() async {
    try {
      final surveyService = BackendSurveyService();
      
      Map<String, dynamic> newSurvey = await surveyService.createSurvey({
        'title': 'Alumni Survey 2024',
        'description': 'Annual tracer study for ITK alumni',
        'is_active': true,
        'start_date': '2024-01-01',
        'end_date': '2024-12-31',
      });
      
      print('Created survey with ID: ${newSurvey['id']}');
    } catch (e) {
      print('Error creating survey: $e');
    }
  }

  // Example 6: Submit Survey Answers
  static Future<void> exampleSubmitAnswers(int surveyId) async {
    try {
      final surveyService = BackendSurveyService();
      
      List<Map<String, dynamic>> answers = [
        {
          'question_id': 1,
          'answer_text': 'Software Engineer',
        },
        {
          'question_id': 2,
          'answer_text': '3 months',
        },
        {
          'question_id': 3,
          'answer_text': 'Google',
        },
      ];
      
      await surveyService.submitSurveyAnswers(surveyId, answers);
      print('Answers submitted successfully!');
    } catch (e) {
      print('Error submitting answers: $e');
    }
  }

  // Example 7: Fetch Users and Roles
  static Future<void> exampleFetchUsersAndRoles() async {
    try {
      final userService = BackendUserService();
      
      // Get all users
      List<dynamic> users = await userService.getAllUsers();
      print('Total users: ${users.length}');
      
      // Get all roles
      List<dynamic> roles = await userService.getAllRoles();
      print('Available roles:');
      for (var role in roles) {
        print('  - ${role['name']}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Example 8: Update Survey
  static Future<void> exampleUpdateSurvey(int surveyId) async {
    try {
      final surveyService = BackendSurveyService();
      
      await surveyService.updateSurvey(surveyId, {
        'title': 'Updated Survey Title',
        'is_active': false,
      });
      
      print('Survey updated successfully!');
    } catch (e) {
      print('Error updating survey: $e');
    }
  }

  // Example 9: Check User Permissions
  static void exampleCheckPermissions() {
    if (AuthService.isAdmin) {
      print('User is admin - full access');
    } else if (AuthService.isSurveyor) {
      print('User is surveyor - can manage general surveys');
    } else if (AuthService.isTeamProdi) {
      print('User is team prodi - can manage ${AuthService.userProdi} surveys');
    } else {
      print('User is alumni - can fill surveys');
    }
    
    // Check specific permissions
    if (AuthService.canAccessEmployeeDirectory) {
      print('Can access employee directory');
    }
    
    if (AuthService.canEditGeneralSurveys) {
      print('Can edit general surveys');
    }
  }

  // Example 10: Logout
  static Future<void> exampleLogout(BuildContext context) async {
    await AuthService.logout();
    
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Example 11: Complete Flow - Login, Fetch Survey, Submit Answers
  static Future<void> exampleCompleteFlow(BuildContext context) async {
    try {
      // Step 1: Login
      bool loginSuccess = await AuthService.login('user@itk.ac.id', 'password');
      if (!loginSuccess) {
        throw Exception('Login failed');
      }
      
      // Step 2: Fetch available surveys
      final surveyService = BackendSurveyService();
      List<dynamic> surveys = await surveyService.getAllSurveys();
      
      if (surveys.isEmpty) {
        throw Exception('No surveys available');
      }
      
      // Step 3: Get first survey details
      int surveyId = surveys[0]['id'];
      List<dynamic> sections = await surveyService.getSurveySections(surveyId);
      
      // Step 4: Collect answers (example with hardcoded values)
      List<Map<String, dynamic>> answers = [];
      for (var section in sections) {
        List<dynamic> questions = await surveyService.getSectionQuestions(
          surveyId,
          section['id'],
        );
        
        for (var question in questions) {
          answers.add({
            'question_id': question['id'],
            'answer_text': 'Sample answer for question ${question['id']}',
          });
        }
      }
      
      // Step 5: Submit answers
      await surveyService.submitSurveyAnswers(surveyId, answers);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Survey completed successfully!')),
        );
      }
    } catch (e) {
      print('Complete flow error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

/// Widget Example: Using Backend in a StatefulWidget
class SurveyListScreen extends StatefulWidget {
  const SurveyListScreen({super.key});

  @override
  State<SurveyListScreen> createState() => _SurveyListScreenState();
}

class _SurveyListScreenState extends State<SurveyListScreen> {
  final BackendSurveyService _surveyService = BackendSurveyService();
  List<dynamic> _surveys = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final surveys = await _surveyService.getAllSurveys();
      setState(() {
        _surveys = surveys;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surveys'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : ListView.builder(
                  itemCount: _surveys.length,
                  itemBuilder: (context, index) {
                    final survey = _surveys[index];
                    return ListTile(
                      title: Text(survey['title'] ?? 'Untitled'),
                      subtitle: Text(survey['description'] ?? ''),
                      onTap: () {
                        // Navigate to survey details
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadSurveys,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
