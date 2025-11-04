import 'package:flutter/material.dart';
import 'dart:convert';
import 'take_questionnaire_page.dart';
import '../services/survey_storage.dart';
import '../database/database_helper.dart';

class EditSurveyPage extends StatefulWidget {
  final Map<String, dynamic> survey;
  
  const EditSurveyPage({super.key, required this.survey});

  @override
  State<EditSurveyPage> createState() => _EditSurveyPageState();
}

class _EditSurveyPageState extends State<EditSurveyPage> with SingleTickerProviderStateMixin {
  final TextEditingController _surveyNameController = TextEditingController();
  final TextEditingController _surveyDescriptionController = TextEditingController();
  final TextEditingController _sectionNameController = TextEditingController();
  
  List<Map<String, dynamic>> questions = [];
  int _questionCounter = 1;
  int? _selectedQuestionIndex;
  late TabController _tabController;
  bool _isLive = false; // Track if survey is live for response tracking
  bool _isEditingSectionName = false; // Track section name editing mode
  
  // Controllers for questions to prevent text reversal
  final Map<String, TextEditingController> _questionControllers = {};
  final Map<String, List<TextEditingController>> _optionControllers = {};
  final Map<String, TextEditingController> _scaleControllers = {};
  final Map<String, List<TextEditingController>> _labelControllers = {};
  final Map<String, TextEditingController> _placeholderControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _surveyNameController.text = widget.survey['name'] ?? 'Survey 1';
    _surveyDescriptionController.text = widget.survey['description'] ?? 'Survey description';
    _sectionNameController.text = 'Section 1'; // Default section name
    _isLive = widget.survey['isLive'] ?? false; // Initialize from survey data
    
    // Initialize questions from survey data or use default questions
    if (widget.survey['questions'] != null && widget.survey['questions'].isNotEmpty) {
      questions = List<Map<String, dynamic>>.from(widget.survey['questions']);
    } else {
      // Use default ITK questions from SurveyStorage
      questions = SurveyStorage.getDefaultQuestions().map((q) => {
        ...q,
        'isExpanded': false,
        'required': q['required'] ?? false,
      }).toList();
    }
    
    // Initialize controllers for each question
    _initializeControllers();
    _questionCounter = questions.length + 1;
  }

  void _initializeControllers() {
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final questionKey = 'question_$i';
      
      // Initialize question controller
      _questionControllers[questionKey] = TextEditingController(text: question['question'] ?? '');
      
      // Initialize controllers based on question type
      if (question['type'] == 'multiple_choice') {
        // Initialize option controllers for multiple choice questions
        if (question['options'] != null) {
          _optionControllers[questionKey] = [];
          for (int j = 0; j < (question['options'] as List).length; j++) {
            _optionControllers[questionKey]!.add(
              TextEditingController(text: (question['options'] as List)[j] ?? '')
            );
          }
        }
      } else if (question['type'] == 'yes_no') {
        // Initialize option controllers for yes/no questions
        if (question['options'] == null) {
          question['options'] = ['Yes', 'No'];
        }
        _optionControllers[questionKey] = [];
        for (int j = 0; j < (question['options'] as List).length; j++) {
          _optionControllers[questionKey]!.add(
            TextEditingController(text: (question['options'] as List)[j] ?? '')
          );
        }
      } else if (question['type'] == 'rating') {
        // Initialize scale controller
        _scaleControllers[questionKey] = TextEditingController(text: (question['scale'] ?? 5).toString());
        
        // Initialize label controllers
        if (question['labels'] != null && (question['labels'] as List).length >= 2) {
          _labelControllers[questionKey] = [
            TextEditingController(text: (question['labels'] as List)[0] ?? ''),
            TextEditingController(text: (question['labels'] as List)[1] ?? ''),
          ];
        } else {
          _labelControllers[questionKey] = [
            TextEditingController(text: 'Low'),
            TextEditingController(text: 'High'),
          ];
        }
      } else if (question['type'] == 'text') {
        // Initialize placeholder controller
        _placeholderControllers[questionKey] = TextEditingController(text: question['placeholder'] ?? '');
      } else if (question['type'] == 'yes_no') {
        // Yes/No questions don't need additional controllers, just the main question
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _surveyNameController.dispose();
    _surveyDescriptionController.dispose();
    
    // Dispose question controllers
    for (var controller in _questionControllers.values) {
      controller.dispose();
    }
    
    // Dispose option controllers
    for (var controllerList in _optionControllers.values) {
      for (var controller in controllerList) {
        controller.dispose();
      }
    }
    
    // Dispose scale controllers
    for (var controller in _scaleControllers.values) {
      controller.dispose();
    }
    
    // Dispose label controllers
    for (var controllerList in _labelControllers.values) {
      for (var controller in controllerList) {
        controller.dispose();
      }
    }
    
    // Dispose placeholder controllers
    for (var controller in _placeholderControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F3F4),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
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
                    child: const Icon(Icons.school, color: Colors.white, size: 14),
                  );
                },
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tracer Study',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Edit Survey',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 9,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _previewSurvey,
              icon: const Icon(Icons.visibility_outlined, color: Colors.black87, size: 20),
              tooltip: 'Preview',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert, color: Colors.black87, size: 20),
              tooltip: 'More',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: ElevatedButton(
                onPressed: _saveSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text('Publish', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF1A73E8),
            labelColor: const Color(0xFF1A73E8),
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Questions'),
              Tab(text: 'Responses'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildQuestionsTab(),
            _buildResponsesTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 770),
          child: Column(
            children: [
              // Survey Header Card
              _buildSurveyHeaderCard(),
              
              const SizedBox(height: 12),
              
              // Questions
              ...List.generate(questions.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildQuestionCard(questions[index], index),
                );
              }),
              
              // Add Question Button
              _buildAddQuestionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getResponsesBySurvey(widget.survey['name']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.insert_chart_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No responses yet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLive ? 'Waiting for users to complete the survey' : 'Enable "Live" in Settings to collect responses',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final responses = snapshot.data!;
        
        return Column(
          children: [
            // Response summary
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.blue[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${responses.length}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text('Total Responses'),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.grey[300],
                  ),
                  Column(
                    children: [
                      Icon(
                        _isLive ? Icons.check_circle : Icons.circle_outlined,
                        size: 32,
                        color: _isLive ? Colors.green : Colors.grey,
                      ),
                      Text(_isLive ? 'Live' : 'Not Live'),
                    ],
                  ),
                ],
              ),
            ),
            // Delete all responses button
            if (responses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => _deleteAllResponses(),
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Delete All Responses'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            // Response list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: responses.length,
                itemBuilder: (context, index) {
                  final response = responses[index];
                  final submittedAt = DateTime.parse(response['submittedAt']);
                  final answers = jsonDecode(response['answers']) as Map<String, dynamic>;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        response['userName'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${response['userEmail']} • ${submittedAt.day}/${submittedAt.month}/${submittedAt.year} ${submittedAt.hour}:${submittedAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Answers:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              ...answers.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Q${entry.key}:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry.value.toString(),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAllResponses() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Responses'),
        content: const Text('Are you sure you want to delete all responses for this survey? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper.instance.deleteAllResponses(widget.survey['name']);
        setState(() {}); // Refresh the tab
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All responses deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting responses: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildSettingsTab() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 770),
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Survey Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: Row(
                    children: [
                      const Text('Live Questionnaire'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isLive ? Colors.green : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isLive ? 'LIVE' : 'OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text('Enable response tracking in Survey Management'),
                  value: _isLive,
                  onChanged: (value) {
                    setState(() {
                      _isLive = value;
                      widget.survey['isLive'] = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.green[600],
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Collect email addresses'),
                  subtitle: const Text('Require respondents to sign in'),
                  value: false,
                  onChanged: (value) {},
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Limit to 1 response'),
                  subtitle: const Text('Requires sign in'),
                  value: false,
                  onChanged: (value) {},
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Show progress bar'),
                  value: true,
                  onChanged: (value) {},
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyHeaderCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Border Accent
          Container(
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF1A73E8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Survey Title
                TextField(
                  controller: _surveyNameController,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Untitled form',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF1A73E8), width: 2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Survey Description
                TextField(
                  controller: _surveyDescriptionController,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Form description',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF1A73E8), width: 2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                
                // Section Name with Edit Icon
                Row(
                  children: [
                    Expanded(
                      child: _isEditingSectionName
                          ? TextField(
                              controller: _sectionNameController,
                              autofocus: true,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Section name',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: InputBorder.none,
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF1A73E8), width: 2),
                                ),
                              ),
                              onSubmitted: (value) {
                                setState(() {
                                  _isEditingSectionName = false;
                                });
                              },
                            )
                          : Text(
                              _sectionNameController.text.isEmpty 
                                  ? 'Section 1' 
                                  : _sectionNameController.text,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isEditingSectionName ? Icons.check : Icons.edit,
                        color: const Color(0xFF1A73E8),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isEditingSectionName = !_isEditingSectionName;
                        });
                      },
                      tooltip: _isEditingSectionName ? 'Save section name' : 'Edit section name',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    final bool isSelected = _selectedQuestionIndex == index;
    final bool isRequired = question['required'] ?? false;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedQuestionIndex = index),
      child: Card(
        elevation: isSelected ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isSelected 
            ? const BorderSide(color: Color(0xFF1A73E8), width: 2) 
            : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question Input Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionControllers['question_$index'] ?? TextEditingController(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Untitled question',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1A73E8), width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          question['question'] = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Question Type Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButton<String>(
                      value: question['type'],
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      items: const [
                        DropdownMenuItem(
                          value: 'multiple_choice',
                          child: Text('Multiple Choice'),
                        ),
                        DropdownMenuItem(
                          value: 'text',
                          child: Text('Short Answer'),
                        ),
                        DropdownMenuItem(
                          value: 'rating',
                          child: Text('Linear Scale'),
                        ),
                        DropdownMenuItem(
                          value: 'yes_no',
                          child: Text('Yes/No'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            question['type'] = value;
                            // Reset options based on type
                            if (value == 'multiple_choice') {
                              question['options'] = ['Option 1'];
                            } else if (value == 'yes_no') {
                              question['options'] = ['Yes', 'No'];
                            } else if (value == 'rating') {
                              question['scale'] = 5;
                              question['labels'] = ['1', '5'];
                            } else if (value == 'text') {
                              question['placeholder'] = 'Your answer';
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Question Preview / Options
              _buildQuestionOptions(question, index),
              
              const SizedBox(height: 16),
              
              // Bottom Actions Bar
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Copy Question
                    IconButton(
                      icon: const Icon(Icons.content_copy, size: 18),
                      tooltip: 'Duplicate',
                      onPressed: () => _duplicateQuestion(index),
                      color: Colors.grey[700],
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    
                    // Delete Question
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Delete',
                      onPressed: () => _deleteQuestion(index),
                      color: Colors.grey[700],
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    
                    const SizedBox(width: 4),
                    Container(width: 1, height: 20, color: Colors.grey[300]),
                    const SizedBox(width: 4),
                    
                    // Required Toggle
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Required',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: isRequired,
                              onChanged: (value) {
                                setState(() {
                                  question['required'] = value;
                                });
                              },
                              activeThumbColor: const Color(0xFF1A73E8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // More Options
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey[700], size: 18),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      onSelected: (value) {
                        if (value == 'description') {
                          // Add description
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'description',
                          child: Row(
                            children: [
                              Icon(Icons.description, size: 18),
                              SizedBox(width: 12),
                              Text('Description'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'validation',
                          child: Row(
                            children: [
                              Icon(Icons.rule, size: 18),
                              SizedBox(width: 12),
                              Text('Response validation'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionOptions(Map<String, dynamic> question, int index) {
    switch (question['type']) {
      case 'multiple_choice':
        return _buildMultipleChoiceOptions(question, index);
      case 'yes_no':
        return _buildYesNoOptions(question, index);
      case 'rating':
        return _buildRatingOptions(question, index);
      case 'text':
        return _buildTextInputPreview(question, index);
      default:
        return const SizedBox();
    }
  }

  Widget _buildMultipleChoiceOptions(Map<String, dynamic> question, int index) {
    final options = question['options'] as List? ?? [];
    
    return Column(
      children: [
        ...List.generate(options.length, (optIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                // Radio button preview
                Radio<int>(
                  value: optIndex,
                  groupValue: -1,
                  onChanged: null,
                  fillColor: WidgetStateProperty.all(Colors.grey[400]),
                ),
                
                // Option input
                Expanded(
                  child: TextField(
                    controller: (_optionControllers['question_$index'] != null && 
                               optIndex < _optionControllers['question_$index']!.length) 
                               ? _optionControllers['question_$index']![optIndex] 
                               : TextEditingController(),
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Option ${optIndex + 1}',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF1A73E8), width: 2),
                      ),
                      suffixIcon: options.length > 1 
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _removeOption(question, optIndex),
                            color: Colors.grey[600],
                          )
                        : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        options[optIndex] = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        }),
        
        // Add Option Button
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Transform.scale(
                scale: 0.9,
                child: Radio<int>(
                  value: -1,
                  groupValue: -1,
                  onChanged: null,
                  fillColor: WidgetStateProperty.all(Colors.grey[400]),
                ),
              ),
              TextButton.icon(
                onPressed: () => _addOption(question),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add option', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 32),
                ),
              ),
              const Text(' or ', style: TextStyle(fontSize: 12)),
              TextButton(
                onPressed: () {
                  // Add "Other" option
                  setState(() {
                    options.add('Other');
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1A73E8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('add "Other"', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYesNoOptions(Map<String, dynamic> question, int index) {
    final options = question['options'] as List? ?? ['Yes', 'No'];
    
    return Column(
      children: List.generate(options.length, (optIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Radio<int>(
                value: optIndex,
                groupValue: -1,
                onChanged: null,
                fillColor: WidgetStateProperty.all(Colors.grey[400]),
              ),
              Text(
                options[optIndex],
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRatingOptions(Map<String, dynamic> question, int index) {
    final scale = question['scale'] ?? 5;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text('1', style: TextStyle(fontSize: 12, color: Colors.black87)),
              const SizedBox(width: 12),
              ...List.generate(scale, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Transform.scale(
                    scale: 0.9,
                    child: Radio<int>(
                      value: i,
                      groupValue: -1,
                      onChanged: null,
                      fillColor: WidgetStateProperty.all(Colors.grey[400]),
                    ),
                  ),
                );
              }),
              Text('$scale', style: const TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                question['labels']?[0] ?? '1',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
            Expanded(
              child: Text(
                question['labels']?[1] ?? '$scale',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextInputPreview(Map<String, dynamic> question, int index) {
    return TextField(
      enabled: false,
      decoration: InputDecoration(
        hintText: question['placeholder'] ?? 'Your answer',
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: const UnderlineInputBorder(),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  Widget _buildAddQuestionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: () {
              _showAddQuestionMenu();
            },
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey[700],
            elevation: 2,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _showAddQuestionMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.radio_button_checked),
                title: const Text('Multiple Choice'),
                onTap: () {
                  Navigator.pop(context);
                  _addQuestion('multiple_choice');
                },
              ),
              ListTile(
                leading: const Icon(Icons.short_text),
                title: const Text('Short Answer'),
                onTap: () {
                  Navigator.pop(context);
                  _addQuestion('text');
                },
              ),
              ListTile(
                leading: const Icon(Icons.linear_scale),
                title: const Text('Linear Scale'),
                onTap: () {
                  Navigator.pop(context);
                  _addQuestion('rating');
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Yes/No'),
                onTap: () {
                  Navigator.pop(context);
                  _addQuestion('yes_no');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addQuestion(String questionType) {
    setState(() {
      Map<String, dynamic> newQuestion = {
        'id': _questionCounter,
        'type': questionType,
        'question': 'Question $_questionCounter',
        'isExpanded': true,
      };
      
      // Add specific properties based on question type
      switch (questionType) {
        case 'multiple_choice':
          newQuestion['options'] = ['Option 1', 'Option 2'];
          break;
        case 'yes_no':
          newQuestion['options'] = ['Yes', 'No'];
          break;
        case 'rating':
          newQuestion['scale'] = 5; // 1-5 rating scale
          newQuestion['labels'] = ['Poor', 'Excellent'];
          break;
        case 'text':
          newQuestion['placeholder'] = 'Enter your answer here';
          break;
      }
      
      questions.add(newQuestion);
      _questionCounter++;
    });
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                questions.removeAt(index);
                // Update question IDs
                for (int i = 0; i < questions.length; i++) {
                  questions[i]['id'] = i + 1;
                }
                _questionCounter = questions.length + 1;
                if (_selectedQuestionIndex == index) {
                  _selectedQuestionIndex = null;
                }
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _duplicateQuestion(int index) {
    setState(() {
      final questionToDuplicate = Map<String, dynamic>.from(questions[index]);
      questionToDuplicate['id'] = _questionCounter;
      questionToDuplicate['required'] = false; // Reset required field
      
      // Deep copy options if they exist
      if (questionToDuplicate['options'] != null) {
        questionToDuplicate['options'] = List<String>.from(questionToDuplicate['options']);
      }
      if (questionToDuplicate['labels'] != null) {
        questionToDuplicate['labels'] = List<String>.from(questionToDuplicate['labels']);
      }
      
      questions.insert(index + 1, questionToDuplicate);
      _questionCounter++;
      _selectedQuestionIndex = index + 1;
      
      // Re-initialize controllers
      _initializeControllers();
    });
  }

  void _addOption(Map<String, dynamic> question) {
    setState(() {
      (question['options'] as List).add('Option ${(question['options'] as List).length + 1}');
    });
  }

  void _removeOption(Map<String, dynamic> question, int optionIndex) {
    setState(() {
      if ((question['options'] as List).length > 1) {
        (question['options'] as List).removeAt(optionIndex);
      }
    });
  }

  void _saveSurvey() {
    // Validate that survey has at least a name
    if (_surveyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a survey name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that there are questions
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Prepare survey data with updated questions
    final surveyData = {
      'name': _surveyNameController.text.trim(),
      'description': _surveyDescriptionController.text.trim(),
      'questions': questions,
      'isLive': _isLive, // Include live status
      'isDefault': widget.survey['isDefault'] ?? false,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Save to SurveyStorage based on survey type
    if (widget.survey['isTemplate'] == true) {
      // For template surveys, update their properties (especially isLive)
      SurveyStorage.updateTemplateSurvey(widget.survey['name'] ?? widget.survey['title'], surveyData);
    } else if (widget.survey['isDefault'] == true) {
      // For default surveys, update their properties (especially isLive)
      SurveyStorage.updateDefaultSurvey(widget.survey['name'], surveyData);
    } else {
      // For custom surveys, find and update in storage
      final customSurveys = SurveyStorage.customSurveys;
      for (int i = 0; i < customSurveys.length; i++) {
        if (customSurveys[i]['name'] == widget.survey['name']) {
          SurveyStorage.updateSurvey(i, surveyData);
          break;
        }
      }
    }
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Survey saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Return updated survey data
    Navigator.pop(context, surveyData);
  }

  void _previewSurvey() {
    // Validate that survey has at least a name
    if (_surveyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a survey name to preview'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that there are questions
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question to preview'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Prepare survey data for preview
    final surveyData = {
      'name': _surveyNameController.text.trim(),
      'description': _surveyDescriptionController.text.trim(),
    };

    // Navigate to preview page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakeQuestionnairePage(
          survey: surveyData,
          questions: questions,
        ),
      ),
    );
  }
}