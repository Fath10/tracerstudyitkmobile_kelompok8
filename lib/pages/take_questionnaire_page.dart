import 'package:flutter/material.dart';
import 'dart:convert';
import 'home_page.dart';
import '../auth/login_page.dart';
import 'user_profile_page.dart';
import '../services/survey_storage.dart';
import '../services/backend_survey_service.dart';
import '../services/auth_service.dart';
import '../models/conditional_logic.dart';

class TakeQuestionnairePage extends StatefulWidget {
  final Map<String, dynamic> survey;
  final List<Map<String, dynamic>>? questions;
  final Map<String, dynamic>? employee;
  
  const TakeQuestionnairePage({
    super.key, 
    required this.survey,
    this.questions,
    this.employee,
  });

  @override
  State<TakeQuestionnairePage> createState() => _TakeQuestionnairePageState();
}

class _TakeQuestionnairePageState extends State<TakeQuestionnairePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final PageController _sectionPageController = PageController();
  
  // Store answers for each question
  final Map<int, dynamic> _answers = {};
  bool _isSubmitting = false;
  int _currentSectionIndex = 0;
  
  // Store backend survey data with question IDs
  Map<String, dynamic>? _backendSurvey;
  bool _loadingBackendSurvey = false;
  
  // Track visible questions and sections based on conditional logic
  final Set<int> _visibleQuestions = {};
  final Set<String> _visibleSections = {};
  
  // Track conditional logic for questions
  final Map<int, List<QuestionCondition>> _questionConditions = {};

  // Get sections for this survey
  List<Map<String, dynamic>> get _surveySections {
    if (widget.survey['sections'] != null && (widget.survey['sections'] as List).isNotEmpty) {
      return List<Map<String, dynamic>>.from(widget.survey['sections']);
    }
    
    // If no sections but has questions, create a default section
    final questions = _getSurveyQuestions();
    return [
      {
        'id': 'section_1',
        'title': 'Section 1',
        'description': '',
        'order': 0,
        'questions': questions,
      }
    ];
  }

  // Get questions for this survey (backward compatibility)
  List<Map<String, dynamic>> _getSurveyQuestions() {
    if (widget.questions != null) {
      return widget.questions!;
    }
    
    // If survey has questions stored, use those
    if (widget.survey['questions'] != null) {
      return List<Map<String, dynamic>>.from(widget.survey['questions']);
    }
    
    // Otherwise, use default ITK questions
    return SurveyStorage.getDefaultQuestions();
  }

  // Get all questions across all sections (for validation and submission)
  List<Map<String, dynamic>> get _allQuestions {
    final allQuestions = <Map<String, dynamic>>[];
    for (var section in _surveySections) {
      allQuestions.addAll(List<Map<String, dynamic>>.from(section['questions'] ?? []));
    }
    return allQuestions;
  }

  @override
  void initState() {
    super.initState();
    // Autofill user information from logged in user
    _nameController.text = AuthService.currentUser?.username ?? '';
    _nimController.text = AuthService.currentUser?.nim ?? AuthService.currentUser?.id ?? '';
    
    // Initialize visible questions and sections
    _initializeConditionalLogic();
    
    // Load backend survey with questions if this is a backend survey
    if (widget.survey['id'] != null) {
      _loadBackendSurvey();
    }
  }
  
  void _initializeConditionalLogic() {
    // Initially all sections are visible
    for (var section in _surveySections) {
      _visibleSections.add(section['id'] ?? 'section_${_surveySections.indexOf(section)}');
    }
    
    // Initially all questions are visible
    for (int i = 0; i < _allQuestions.length; i++) {
      _visibleQuestions.add(i);
      
      // Load conditional logic for this question if exists
      final question = _allQuestions[i];
      if (question['conditionalLogic'] != null) {
        final conditions = (question['conditionalLogic'] as List)
            .map((c) => QuestionCondition.fromJson(c))
            .toList();
        _questionConditions[i] = conditions;
      }
    }
  }
  
  void _evaluateConditionalLogic(int changedQuestionIndex) {
    // In Google Forms style, conditional logic is handled during navigation
    // This method is kept for compatibility but navigation is now handled
    // when user clicks "Next" button - checking the current question's conditions
    // No real-time evaluation needed
  }
  
  Future<void> _loadBackendSurvey() async {
    final surveyId = widget.survey['id'];
    if (surveyId == null) return;
    
    setState(() {
      _loadingBackendSurvey = true;
    });
    
    try {
      int id;
      if (surveyId is int) {
        id = surveyId;
      } else if (surveyId is String) {
        id = int.tryParse(surveyId) ?? 0;
      } else {
        return;
      }
      
      final surveyService = BackendSurveyService();
      final backendSurvey = await surveyService.getSurveyById(id);
      
      if (mounted) {
        setState(() {
          _backendSurvey = backendSurvey;
          _loadingBackendSurvey = false;
        });
        print('✅ Loaded backend survey with ${backendSurvey['sections']?.length ?? 0} sections');
      }
    } catch (e) {
      print('❌ Error loading backend survey: $e');
      if (mounted) {
        setState(() {
          _loadingBackendSurvey = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _sectionPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  'assets/images/Logo ITK.png',
                  height: 24,
                  width: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 16),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tracer Study',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Sistem Tracking Lulusan',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.black87, size: 22),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87, size: 22),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
          ],
        ),
        endDrawer: Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[400]!, Colors.blue[600]!],
              ),
            ),
            child: Column(
              children: [
                // Close button
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 40, right: 16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),

                // User profile section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            (AuthService.currentUser?.username ?? 'U').substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // User name
                      Text(
                        AuthService.currentUser?.username ?? 'Your Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // User ID/Email
                      Text(
                        AuthService.currentUser?.nim ?? AuthService.currentUser?.email ?? '11221044',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Menu items
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      children: [
                        // Dashboard for employees
                        if (AuthService.isAdmin || AuthService.isSurveyor || AuthService.isTeamProdi)
                          _buildDrawerItem(
                            icon: Icons.dashboard,
                            title: 'Dashboard',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const HomePage()),
                              );
                            },
                          ),

                        // Users (alumni) - show Take Questionnaire option
                        if (AuthService.isUser)
                          _buildDrawerItem(
                            icon: Icons.assignment_outlined,
                            title: 'Take Questionnaire',
                            onTap: () {
                              Navigator.pop(context);
                              // Already on questionnaire page
                            },
                          ),

                        const Divider(height: 32),
                        
                        // Profile
                        _buildDrawerItem(
                          icon: Icons.person,
                          title: 'My Profile',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UserProfilePage(),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Logout
                        _buildDrawerItem(
                          icon: Icons.logout,
                          title: 'Logout',
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            // Section Navigation Slider (if multiple sections)
            if (_surveySections.length > 1) _buildSectionNavigator(),
            
            // Main Content
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView.builder(
                  controller: _sectionPageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _surveySections.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentSectionIndex = index;
                    });
                  },
                  itemBuilder: (context, sectionIndex) {
                    final section = _surveySections[sectionIndex];
                    final sectionId = section['id'] ?? 'section_$sectionIndex';
                    
                    // Skip section if not visible due to conditional logic
                    if (!_visibleSections.contains(sectionId)) {
                      return const Center(
                        child: Text('This section is hidden based on your previous answers'),
                      );
                    }
                    
                    final sectionQuestions = List<Map<String, dynamic>>.from(section['questions'] ?? []);
                    
                    // Calculate cumulative question number offset for this section
                    int questionOffset = 0;
                    for (int i = 0; i < sectionIndex; i++) {
                      questionOffset += (_surveySections[i]['questions'] as List?)?.length ?? 0;
                    }
                    
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Survey Header Card (only on first section)
                          if (sectionIndex == 0) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border(
                                  top: BorderSide(color: Colors.blue[600]!, width: 4),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.survey['name'] ?? 'Survey',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (widget.survey['description'] != null && 
                                      widget.survey['description'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.survey['description'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                          ],
                          
                          // Section Header (if not first section or if multiple sections)
                          if (sectionIndex > 0 || _surveySections.length > 1) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    section['title'] ?? 'Section ${sectionIndex + 1}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (section['description'] != null && 
                                      section['description'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      section['description'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                          ],
                
                          // Respondent Information Card (only on first section)
                          if (sectionIndex == 0) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'Enter your full name',
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue[600]!),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // NIM Field
                      TextFormField(
                        controller: _nimController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: 'NIM (Nomor Induk Mahasiswa) *',
                          hintText: 'Enter your NIM',
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue[600]!),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your NIM';
                          }
                          if (value.trim().length < 8) {
                            return 'Please enter a valid NIM (at least 8 characters)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                            
                            const SizedBox(height: 16),
                          ],
                          
                          // Questions for this section (only visible ones)
                          ...List.generate(sectionQuestions.length, (index) {
                            final question = sectionQuestions[index];
                            final questionId = question['id'] ?? index;
                            
                            // Skip if question is not visible due to conditional logic
                            if (!_visibleQuestions.contains(questionOffset + index)) {
                              return const SizedBox.shrink();
                            }
                            
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Question Text
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${questionOffset + index + 1}. ',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        TextSpan(
                                          text: question['question'] ?? 'Question ${questionOffset + index + 1}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: ' *',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Question Input based on type
                                  _buildQuestionInput(question, questionId),
                                ],
                              ),
                            );
                          }),
                          
                          const SizedBox(height: 24),
                
                          // Navigation buttons for sections
                          if (_surveySections.length > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (sectionIndex > 0)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _sectionPageController.previousPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    icon: const Icon(Icons.arrow_back, size: 18),
                                    label: const Text('Previous'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  ),
                                const Spacer(),
                                if (sectionIndex < _surveySections.length - 1)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Check for option-based navigation (Google Forms style)
                                      int targetSection = sectionIndex + 1;
                                      bool shouldSubmit = false;
                                      
                                      // Get all questions in current section
                                      final section = _surveySections[sectionIndex];
                                      final sectionQuestions = section['questions'] as List? ?? [];
                                      
                                      // Check each question for option navigations
                                      for (var question in sectionQuestions) {
                                        final questionId = question['id'];
                                        final optionNavigations = question['optionNavigations'];
                                        
                                        if (optionNavigations != null && _answers.containsKey(questionId)) {
                                          final navigations = (optionNavigations as List)
                                              .map((n) => OptionNavigation.fromJson(n))
                                              .toList();
                                          
                                          final currentAnswer = _answers[questionId];
                                          
                                          // Find navigation for this answer
                                          final navigation = navigations.cast<OptionNavigation?>().firstWhere(
                                            (nav) => nav!.optionText.toLowerCase() == currentAnswer.toString().toLowerCase(),
                                            orElse: () => null,
                                          );
                                          
                                          if (navigation != null && navigation.navigateTo != 'continue') {
                                            if (navigation.navigateTo == 'submit') {
                                              shouldSubmit = true;
                                              break;
                                            } else if (navigation.navigateTo.startsWith('section_')) {
                                              targetSection = navigation.targetIndex ?? (sectionIndex + 1);
                                              break;
                                            } else if (navigation.navigateTo.startsWith('question_')) {
                                              // For now, continue to next section
                                              // Question-level navigation within section will be handled later
                                              break;
                                            }
                                          }
                                        }
                                      }
                                      
                                      if (shouldSubmit) {
                                        _submitSurvey();
                                        return;
                                      }
                                      
                                      // Navigate to target section
                                      _sectionPageController.animateToPage(
                                        targetSection,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    icon: const Icon(Icons.arrow_forward, size: 18),
                                    label: const Text('Next'),
                                    iconAlignment: IconAlignment.end,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  ),
                              ],
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Submit Button (only on last section)
                          if (sectionIndex == _surveySections.length - 1) ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitSurvey,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Submit',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Clear Form Button
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: _clearForm,
                                child: Text(
                                  'Clear form',
                                  style: TextStyle(
                                    color: Colors.blue[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput(Map<String, dynamic> question, int questionId) {
    final questionType = question['type'] ?? 'text';
    
    switch (questionType) {
      case 'multiple_choice':
        return _buildMultipleChoiceInput(question, questionId);
      case 'yes_no':
        return _buildYesNoInput(question, questionId);
      case 'rating':
        return _buildRatingInput(question, questionId);
      case 'text':
      default:
        return _buildTextInput(question, questionId);
    }
  }

  Widget _buildMultipleChoiceInput(Map<String, dynamic> question, int questionId) {
    final options = List<String>.from(question['options'] ?? []);
    
    return Column(
      children: options.map((option) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<String>(
            title: Text(
              option,
              style: const TextStyle(fontSize: 14),
            ),
            value: option,
            groupValue: _answers[questionId] as String?,
            onChanged: (value) {
              setState(() {
                _answers[questionId] = value;
                // Evaluate conditional logic when answer changes
                _evaluateConditionalLogic(questionId);
              });
            },
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.blue[600],
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildYesNoInput(Map<String, dynamic> question, int questionId) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<String>(
            title: const Text(
              'Yes',
              style: TextStyle(fontSize: 14),
            ),
            value: 'Yes',
            groupValue: _answers[questionId] as String?,
            onChanged: (value) {
              setState(() {
                _answers[questionId] = value;
              });
            },
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.blue[600],
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<String>(
            title: const Text(
              'No',
              style: TextStyle(fontSize: 14),
            ),
            value: 'No',
            groupValue: _answers[questionId] as String?,
            onChanged: (value) {
              setState(() {
                _answers[questionId] = value;
              });
            },
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.blue[600],
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingInput(Map<String, dynamic> question, int questionId) {
    final scale = question['scale'] ?? 5;
    final labels = List<String>.from(question['labels'] ?? ['Poor', 'Excellent']);
    
    return Column(
      children: [
        // Scale labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1 - ${labels.isNotEmpty ? labels[0] : 'Poor'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '$scale - ${labels.length > 1 ? labels[1] : 'Excellent'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Rating buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(scale, (index) {
            final value = index + 1;
            final isSelected = _answers[questionId] == value;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _answers[questionId] = value;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.blue[600] : Colors.grey[200],
                  border: Border.all(
                    color: isSelected ? Colors.blue[600]! : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTextInput(Map<String, dynamic> question, int questionId) {
    final placeholder = question['placeholder'] ?? 'Enter your answer';
    
    return TextFormField(
      maxLines: 3,
      decoration: InputDecoration(
        hintText: placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      onChanged: (value) {
        _answers[questionId] = value;
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _nimController.clear();
      _answers.clear();
    });
  }

  Widget _buildSectionNavigator() {
    return Container(
      height: 60,
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _surveySections.length,
              itemBuilder: (context, index) {
                final section = _surveySections[index];
                final isSelected = _currentSectionIndex == index;
                
                return GestureDetector(
                  onTap: () {
                    _sectionPageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[600] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        section['title'] ?? 'Section ${index + 1}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_surveySections.length, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= _currentSectionIndex
                          ? Colors.blue[600]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSurvey() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if survey is live (accepting responses)
    final isLive = widget.survey['isLive'] ?? false;
    if (!isLive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This survey is not currently accepting responses'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if all questions are answered
    for (int i = 0; i < _allQuestions.length; i++) {
      final questionId = _allQuestions[i]['id'] ?? i;
      if (!_answers.containsKey(questionId) || _answers[questionId] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please answer all questions in all sections'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare answers in a serializable format
      final Map<String, dynamic> serializableAnswers = {};
      _answers.forEach((key, value) {
        // Convert each answer to a simple string representation
        if (value is List) {
          serializableAnswers[key.toString()] = value.join(', ');
        } else {
          serializableAnswers[key.toString()] = value.toString();
        }
      });
      
      // Check if this is a local survey or backend survey
      final surveyIdRaw = widget.survey['id'];
      final surveyName = widget.survey['name'] ?? widget.survey['title'] ?? 'Unknown Survey';
      
      // Debug: Check survey data
      print('🔍 Survey submission data:');
      print('   Survey keys: ${widget.survey.keys}');
      print('   Survey ID raw: $surveyIdRaw (type: ${surveyIdRaw.runtimeType})');
      print('   Survey name: $surveyName');
      
      // Handle survey submission
      if (surveyIdRaw == null || surveyIdRaw == 0) {
        // This is a local survey from SurveyStorage (no backend ID)
        print('📝 Survey submitted locally: $surveyName');
        print('   User: ${AuthService.currentUser?.username}');
        print('   Answers: ${serializableAnswers.length} questions');
        
        // For local surveys, just show success message
        // Backend integration can be added later when surveys are created via backend
      } else {
        // This is a backend survey - submit to API
        final surveyService = BackendSurveyService();
        int surveyId;
        
        if (surveyIdRaw is int) {
          surveyId = surveyIdRaw;
        } else if (surveyIdRaw is String) {
          surveyId = int.tryParse(surveyIdRaw) ?? 0;
          if (surveyId == 0) {
            throw Exception('Invalid survey ID format: "$surveyIdRaw"');
          }
        } else {
          throw Exception('Invalid survey ID type: ${surveyIdRaw.runtimeType}');
        }
        
        // Get all questions with their backend IDs
        final backendQuestions = <Map<String, dynamic>>[];
        if (_backendSurvey != null && _backendSurvey!['sections'] != null) {
          for (var section in (_backendSurvey!['sections'] as List)) {
            if (section['questions'] != null) {
              backendQuestions.addAll(List<Map<String, dynamic>>.from(section['questions']));
            }
          }
        }
        
        print('📤 Submitting ${_answers.length} answers to backend');
        print('   Backend survey loaded: ${_backendSurvey != null}');
        print('   Found ${backendQuestions.length} backend questions');
        
        // If no backend questions exist, show error
        if (backendQuestions.isEmpty) {
          print('❌ ERROR: No questions found in backend for survey $surveyId!');
          print('   This survey may not have questions created in the database.');
          print('   Questions must be created when the survey is created for answers to be tracked.');
          throw Exception('This survey has no questions in the database. Answers cannot be tracked. Please recreate the survey with questions.');
        }
        
        // Submit individual answers mapped to actual Question IDs
        int successCount = 0;
        int failCount = 0;
        
        for (var entry in _answers.entries) {
          final localQuestionIndex = entry.key;
          final answerValue = entry.value;
          
          // Skip if no answer provided
          if (answerValue == null || (answerValue is String && answerValue.isEmpty)) {
            continue;
          }
          
          // Find the backend question ID for this local question index
          int? backendQuestionId;
          if (localQuestionIndex < backendQuestions.length) {
            backendQuestionId = backendQuestions[localQuestionIndex]['id'];
          }
          
          if (backendQuestionId == null) {
            print('   ⚠️ No backend question ID for local index $localQuestionIndex');
            failCount++;
            continue;
          }
          
          // Convert answer value to string for backend
          String answerStr;
          if (answerValue is List) {
            answerStr = jsonEncode(answerValue);
          } else {
            answerStr = answerValue.toString();
          }
          
          try {
            final answerData = {
              'survey': surveyId,
              'question': backendQuestionId,
              'answer_value': answerStr,
            };
            
            await surveyService.createAnswer(surveyId, answerData);
            print('   ✓ Answer for question $backendQuestionId (local index $localQuestionIndex) submitted');
            successCount++;
          } catch (e) {
            print('   ✗ Failed to submit answer for question $backendQuestionId: $e');
            failCount++;
          }
        }
        
        print('✅ Answer submission complete: $successCount success, $failCount failed');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Survey submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate back to home page and clear the stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(employee: widget.employee),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting survey: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}