/// API Usage Examples
/// 
/// This file contains practical examples of how to use the backend API
/// services in your Flutter pages. Copy and adapt these examples as needed.

import 'package:flutter/material.dart';
import '../services/backend_survey_service.dart';
import '../services/backend_user_service.dart';
import '../services/unit_service.dart';
import '../services/period_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// ============================================================================
// EXAMPLE 1: Survey Management
// ============================================================================

class SurveyManagementExample extends StatefulWidget {
  const SurveyManagementExample({super.key});

  @override
  State<SurveyManagementExample> createState() =>
      _SurveyManagementExampleState();
}

class _SurveyManagementExampleState extends State<SurveyManagementExample> {
  final _surveyService = BackendSurveyService();
  List<dynamic> surveys = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  /// Load all surveys from backend
  Future<void> _loadSurveys() async {
    setState(() => isLoading = true);
    try {
      final data = await _surveyService.getAllSurveys();
      if (mounted) {
        setState(() {
          surveys = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading surveys: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Create a new survey
  Future<void> _createSurvey() async {
    try {
      final newSurvey = await _surveyService.createSurvey({
        'title': 'Alumni Survey 2024',
        'description': 'Annual alumni feedback survey',
        'is_active': true,
        'start_date': DateTime.now().toIso8601String().split('T')[0],
        'end_date': DateTime.now()
            .add(Duration(days: 30))
            .toIso8601String()
            .split('T')[0],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Survey created: ${newSurvey['title']}')),
        );
        await _loadSurveys(); // Reload list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating survey: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Update an existing survey
  Future<void> _updateSurvey(int surveyId) async {
    try {
      await _surveyService.updateSurvey(surveyId, {
        'title': 'Updated Survey Title',
        'description': 'Updated description',
        'is_active': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Survey updated successfully')),
        );
        await _loadSurveys();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Delete a survey
  Future<void> _deleteSurvey(int surveyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this survey?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _surveyService.deleteSurvey(surveyId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Survey deleted successfully')),
          );
          await _loadSurveys();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Survey Management')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: surveys.length,
              itemBuilder: (context, index) {
                final survey = surveys[index];
                return ListTile(
                  title: Text(survey['title'] ?? 'Untitled'),
                  subtitle: Text(survey['description'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _updateSurvey(survey['id']),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteSurvey(survey['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createSurvey,
        child: Icon(Icons.add),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 2: Working with Survey Sections and Questions
// ============================================================================

class SurveyBuilderExample {
  final _surveyService = BackendSurveyService();

  /// Create a complete survey with sections and questions
  Future<void> createCompleteSurvey() async {
    try {
      // 1. Create the survey
      final survey = await _surveyService.createSurvey({
        'title': 'Graduate Employment Survey',
        'description': 'Survey about employment after graduation',
        'is_active': true,
      });

      final surveyId = survey['id'];

      // 2. Create sections
      final section1 = await _surveyService.createSection(surveyId, {
        'title': 'Personal Information',
        'description': 'Basic information about the respondent',
        'order': 1,
      });

      final section2 = await _surveyService.createSection(surveyId, {
        'title': 'Employment Status',
        'description': 'Current employment information',
        'order': 2,
      });

      // 3. Create questions for section 1
      await _surveyService.createQuestion(surveyId, section1['id'], {
        'text': 'What is your current age?',
        'question_type': 'text',
        'is_required': true,
        'order': 1,
      });

      await _surveyService.createQuestion(surveyId, section1['id'], {
        'text': 'What year did you graduate?',
        'question_type': 'text',
        'is_required': true,
        'order': 2,
      });

      // 4. Create questions for section 2
      await _surveyService.createQuestion(surveyId, section2['id'], {
        'text': 'What is your current employment status?',
        'question_type': 'multiple_choice',
        'is_required': true,
        'options': [
          'Employed full-time',
          'Employed part-time',
          'Self-employed',
          'Unemployed',
          'Continuing education'
        ],
        'order': 1,
      });

      print('✅ Survey created successfully with sections and questions');
    } catch (e) {
      print('❌ Error creating survey: $e');
    }
  }

  /// Get complete survey with all sections and questions
  Future<Map<String, dynamic>> getCompleteSurveyData(int surveyId) async {
    try {
      // Get survey details
      final survey = await _surveyService.getSurveyById(surveyId);

      // Get all sections
      final sections = await _surveyService.getSurveySections(surveyId);

      // Get questions for each section
      for (var section in sections) {
        final questions = await _surveyService.getSectionQuestions(
          surveyId,
          section['id'],
        );
        section['questions'] = questions;
      }

      survey['sections'] = sections;
      return survey;
    } catch (e) {
      throw Exception('Failed to load complete survey: $e');
    }
  }

  /// Submit survey answers
  Future<void> submitSurveyAnswers(
    int surveyId,
    Map<int, String> answers,
  ) async {
    try {
      // Convert answers map to list format
      final answersList = answers.entries
          .map((entry) => {
                'question': entry.key,
                'answer_text': entry.value,
              })
          .toList();

      // Submit in bulk
      await _surveyService.submitSurveyAnswersBulk(surveyId, answersList);

      print('✅ Survey answers submitted successfully');
    } catch (e) {
      print('❌ Error submitting answers: $e');
      rethrow;
    }
  }
}

// ============================================================================
// EXAMPLE 3: User Management
// ============================================================================

class UserManagementExample extends StatefulWidget {
  const UserManagementExample({super.key});

  @override
  State<UserManagementExample> createState() => _UserManagementExampleState();
}

class _UserManagementExampleState extends State<UserManagementExample> {
  final _userService = BackendUserService();
  List<UserModel> users = [];
  List<RoleModel> roles = [];
  List<ProgramStudyModel> programStudies = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load all user-related data
  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final usersData = await _userService.getAllUsers();
      final rolesData = await _userService.getAllRoles();
      final programsData = await _userService.getAllProgramStudies();

      if (mounted) {
        setState(() {
          users = usersData;
          roles = rolesData;
          programStudies = programsData;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  /// Create a new user
  Future<void> _createUser() async {
    try {
      final newUser = await _userService.createUser({
        'id': '1234567890', // NIM or employee ID
        'username': 'john_doe',
        'email': 'john@example.com',
        'password': 'securePassword123',
        'phone_number': '081234567890',
        'address': 'Jl. Example No. 123',
        'role': roles.first.id, // Role ID
        'program_study': programStudies.first.id, // Program study ID
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User created: ${newUser.username}')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Update user information
  Future<void> _updateUser(String userId) async {
    try {
      await _userService.updateUser(userId, {
        'id': userId,
        'username': 'updated_username',
        'email': 'updated@example.com',
        // Include other fields as needed
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User updated successfully')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Delete a user
  Future<void> _deleteUser(String userId) async {
    try {
      await _userService.deleteUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User deleted successfully')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Management')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(user.username[0].toUpperCase()),
                  ),
                  title: Text(user.username),
                  subtitle: Text(user.email ?? 'No email'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _updateUser(user.id),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(user.id),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createUser,
        child: Icon(Icons.add),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 4: Organizational Units (Faculty/Department/Program)
// ============================================================================

class OrganizationalUnitsExample {
  final _unitService = UnitService();

  /// Load faculty hierarchy
  Future<void> loadFacultyHierarchy() async {
    try {
      final hierarchy = await _unitService.getFacultyHierarchy();

      for (var item in hierarchy) {
        final faculty = item['faculty'] as FacultyModel;
        print('Faculty: ${faculty.name}');

        final departments =
            item['departments'] as List<Map<String, dynamic>>;
        for (var dept in departments) {
          final department = dept['department'] as DepartmentModel;
          print('  Department: ${department.name}');

          final programs = dept['program_studies'] as List<ProgramStudyModel>;
          for (var program in programs) {
            print('    Program: ${program.name}');
          }
        }
      }
    } catch (e) {
      print('Error loading hierarchy: $e');
    }
  }

  /// Create complete organizational structure
  Future<void> createOrganizationalStructure() async {
    try {
      // Create faculty
      final faculty = await _unitService.createFaculty(
        name: 'Faculty of Engineering',
        description: 'Engineering and technology programs',
      );

      // Create department
      final department = await _unitService.createDepartment(
        name: 'Computer Science Department',
        facultyId: faculty.id,
      );

      // Create program studies
      await _unitService.createProgramStudy(
        name: 'Software Engineering',
        departmentId: department.id,
      );

      await _unitService.createProgramStudy(
        name: 'Data Science',
        departmentId: department.id,
      );

      print('✅ Organizational structure created successfully');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}

// ============================================================================
// EXAMPLE 5: Period Management
// ============================================================================

class PeriodManagementExample {
  final _periodService = PeriodService();

  /// Create academic periods
  Future<void> createAcademicPeriods() async {
    try {
      // Create semester 1
      await _periodService.createPeriod(
        name: '2024/2025 Semester 1',
        startDate: DateTime(2024, 8, 1),
        endDate: DateTime(2024, 12, 31),
        description: 'First semester of academic year 2024/2025',
        isActive: true,
      );

      // Create semester 2
      await _periodService.createPeriod(
        name: '2024/2025 Semester 2',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 6, 30),
        description: 'Second semester of academic year 2024/2025',
        isActive: false,
      );

      print('✅ Academic periods created');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  /// Get current active period
  Future<void> checkCurrentPeriod() async {
    try {
      final currentPeriod = await _periodService.getCurrentPeriod();

      if (currentPeriod != null) {
        print('Current Period: ${currentPeriod['name']}');
        print('Start: ${currentPeriod['start_date']}');
        print('End: ${currentPeriod['end_date']}');
      } else {
        print('No active period found');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Get periods in date range
  Future<void> getPeriodsInRange() async {
    try {
      final periods = await _periodService.getPeriodsInRange(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      print('Found ${periods.length} periods in 2024');
      for (var period in periods) {
        print('- ${period['name']}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}

// ============================================================================
// EXAMPLE 6: Authentication & Authorization
// ============================================================================

class AuthenticationExample {
  /// Login example
  Future<void> loginUser(String username, String password) async {
    try {
      final success = await AuthService.login(username, password);

      if (success) {
        print('✅ Login successful');
        print('User: ${AuthService.currentUser?.username}');
        print('Role: ${AuthService.userRole}');
        print('Is Admin: ${AuthService.isAdmin}');
        print('Can Access User Management: ${AuthService.canAccessUserManagement}');
      } else {
        print('❌ Login failed');
      }
    } catch (e) {
      print('❌ Login error: $e');
    }
  }

  /// Check permissions before showing features
  Widget buildMenuWithPermissions(BuildContext context) {
    return Column(
      children: [
        // Show user management only to admins
        if (AuthService.canAccessUserManagement)
          ListTile(
            leading: Icon(Icons.people),
            title: Text('User Management'),
            onTap: () {
              // Navigate to user management
            },
          ),

        // Show survey management to admins and surveyors
        if (AuthService.canAccessAllSurveys)
          ListTile(
            leading: Icon(Icons.assignment),
            title: Text('Survey Management'),
            onTap: () {
              // Navigate to survey management
            },
          ),

        // Show survey responses to admins, surveyors, and team prodi
        if (AuthService.canViewSurveyResponses)
          ListTile(
            leading: Icon(Icons.bar_chart),
            title: Text('View Responses'),
            onTap: () {
              // Navigate to survey responses
            },
          ),

        // Everyone can fill questionnaires
        if (AuthService.canFillQuestionnaires)
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Fill Questionnaire'),
            onTap: () {
              // Navigate to questionnaire
            },
          ),
      ],
    );
  }

  /// Logout example
  Future<void> logoutUser(BuildContext context) async {
    try {
      await AuthService.logout();
      // Navigate to login page
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}

// ============================================================================
// EXAMPLE 7: Error Handling Best Practices
// ============================================================================

class ErrorHandlingExample {
  /// Comprehensive error handling
  Future<void> fetchDataWithErrorHandling(BuildContext context) async {
    final surveyService = BackendSurveyService();

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Fetch data
      final surveys = await surveyService.getAllSurveys();

      // Hide loading indicator
      if (context.mounted) {
        Navigator.pop(context);

        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${surveys.length} surveys'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      // Hide loading indicator
      if (context.mounted) {
        Navigator.pop(context);

        // Show error
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  fetchDataWithErrorHandling(context); // Retry
                },
                child: Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }
}
