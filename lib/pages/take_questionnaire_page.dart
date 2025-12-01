import 'package:flutter/material.dart';
import 'dart:convert';
import 'home_page.dart';
import 'login_page.dart';
import '../services/survey_storage.dart';
import '../database/database_helper.dart';
import '../services/auth_service.dart';

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
              Image.asset(
                'assets/images/logo.png',
                height: 32,
                width: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 20),
                  );
                },
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile page coming soon')),
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
                          
                          // Questions for this section
                          ...List.generate(sectionQuestions.length, (index) {
                            final question = sectionQuestions[index];
                            final questionId = question['id'] ?? index;
                            
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
                                      _sectionPageController.nextPage(
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
      
      // Save response to database
      final response = {
        'surveyName': widget.survey['name'],
        'userId': AuthService.currentUser?.id,
        'userEmail': AuthService.currentUser?.email ?? 'unknown',
        'userName': AuthService.currentUser?.username ?? 'Unknown User',
        'answers': jsonEncode(serializableAnswers), // Convert to JSON string
      };
      
      await DatabaseHelper.instance.saveResponse(response);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Survey submitted successfully!'),
            backgroundColor: Colors.green,
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