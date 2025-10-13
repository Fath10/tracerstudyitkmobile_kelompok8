import 'package:flutter/material.dart';
import 'take_questionnaire_page.dart';
import '../services/survey_storage.dart';

class EditSurveyPage extends StatefulWidget {
  final Map<String, dynamic> survey;
  
  const EditSurveyPage({super.key, required this.survey});

  @override
  State<EditSurveyPage> createState() => _EditSurveyPageState();
}

class _EditSurveyPageState extends State<EditSurveyPage> {
  final TextEditingController _surveyNameController = TextEditingController();
  final TextEditingController _surveyDescriptionController = TextEditingController();
  
  List<Map<String, dynamic>> questions = [];
  int _questionCounter = 1;
  
  // Controllers for questions to prevent text reversal
  final Map<String, TextEditingController> _questionControllers = {};
  final Map<String, List<TextEditingController>> _optionControllers = {};
  final Map<String, TextEditingController> _scaleControllers = {};
  final Map<String, List<TextEditingController>> _labelControllers = {};
  final Map<String, TextEditingController> _placeholderControllers = {};

  @override
  void initState() {
    super.initState();
    _surveyNameController.text = widget.survey['name'] ?? 'Survey 1';
    _surveyDescriptionController.text = widget.survey['description'] ?? 'Survey description';
    
    // Initialize questions from survey data or use default questions
    if (widget.survey['questions'] != null && widget.survey['questions'].isNotEmpty) {
      questions = List<Map<String, dynamic>>.from(widget.survey['questions']);
    } else {
      // Use default ITK questions from SurveyStorage
      questions = SurveyStorage.getDefaultQuestions().map((q) => {
        ...q,
        'isExpanded': false,
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
        backgroundColor: Colors.white,
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
            // Preview Button
            IconButton(
              onPressed: _previewSurvey,
              icon: const Icon(Icons.visibility_outlined),
              tooltip: 'Preview',
            ),
            
            // Save Button
            IconButton(
              onPressed: _saveSurvey,
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Save',
            ),
          ],
        ),
        body: Column(
          children: [
            // Survey Header Section
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Survey Name Input
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _surveyNameController,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Survey Name',
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Survey Description Input
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _surveyDescriptionController,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Survey Description',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action Buttons Row
                  Row(
                    children: [
                      // Add Question Button with Dropdown
                      PopupMenuButton<String>(
                        onSelected: (String questionType) {
                          _addQuestion(questionType);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'multiple_choice',
                            child: Row(
                              children: [
                                Icon(Icons.radio_button_checked, size: 18),
                                SizedBox(width: 8),
                                Text('Multiple Choice'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'text',
                            child: Row(
                              children: [
                                Icon(Icons.text_fields, size: 18),
                                SizedBox(width: 8),
                                Text('Text Input'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'rating',
                            child: Row(
                              children: [
                                Icon(Icons.star_rate, size: 18),
                                SizedBox(width: 8),
                                Text('Rating Scale'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'yes_no',
                            child: Row(
                              children: [
                                Icon(Icons.check_box, size: 18),
                                SizedBox(width: 8),
                                Text('Yes/No'),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Add Question',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Questions List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return _buildQuestionCard(question, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: question['isExpanded'] ?? false,
        onExpansionChanged: (expanded) {
          setState(() {
            question['isExpanded'] = expanded;
          });
        },
        title: Row(
          children: [
            // Question Number Icon
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${question['id']}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Question Text
            Expanded(
              child: Text(
                question['question'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Question Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getQuestionTypeLabel(question['type']),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 4),
            
            // Delete Button
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 16),
              onPressed: () => _deleteQuestion(index),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            
            // Expand Icon
            Icon(
              question['isExpanded'] == true ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey[600],
              size: 18,
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Input
                TextField(
                  controller: _questionControllers['question_$index'] ?? TextEditingController(),
                  decoration: InputDecoration(
                    labelText: 'Question',
                    hintText: 'Enter your question',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      question['question'] = value;
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Question-specific fields based on type
                if (question['type'] == 'multiple_choice' || question['type'] == 'yes_no') ...[
                  const Text(
                    'Options:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  ...List.generate(
                    (question['options'] as List).length,
                    (optIndex) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: (_optionControllers['question_$index'] != null && 
                                         optIndex < _optionControllers['question_$index']!.length) 
                                         ? _optionControllers['question_$index']![optIndex] 
                                         : TextEditingController(),
                              decoration: InputDecoration(
                                hintText: 'Option ${optIndex + 1}',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  (question['options'] as List)[optIndex] = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (question['type'] == 'multiple_choice') // Only allow removing options for multiple choice
                            SizedBox(
                              width: 32,
                              child: IconButton(
                                icon: Icon(Icons.remove_circle_outline, color: Colors.red[400], size: 16),
                                onPressed: () => _removeOption(question, optIndex),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Add Option Button (only for multiple choice)
                  if (question['type'] == 'multiple_choice')
                    TextButton.icon(
                      onPressed: () => _addOption(question),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Option'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[600],
                      ),
                    ),
                ] else if (question['type'] == 'rating') ...[
                  const Text(
                    'Rating Scale:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      const Text('Scale: 1 to '),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _scaleControllers['question_$index'] ?? TextEditingController(),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onChanged: (value) {
                            setState(() {
                              question['scale'] = int.tryParse(value) ?? 5;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: (_labelControllers['question_$index'] != null && 
                                     _labelControllers['question_$index']!.isNotEmpty) 
                                     ? _labelControllers['question_$index']![0] 
                                     : TextEditingController(),
                          decoration: InputDecoration(
                            labelText: 'Low Label',
                            hintText: 'e.g., Poor',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (question['labels'] == null) question['labels'] = ['', ''];
                              (question['labels'] as List)[0] = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: (_labelControllers['question_$index'] != null && 
                                     _labelControllers['question_$index']!.length > 1) 
                                     ? _labelControllers['question_$index']![1] 
                                     : TextEditingController(),
                          decoration: InputDecoration(
                            labelText: 'High Label',
                            hintText: 'e.g., Excellent',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (question['labels'] == null) question['labels'] = ['', ''];
                              (question['labels'] as List)[1] = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ] else if (question['type'] == 'text') ...[
                  const Text(
                    'Text Input Settings:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  TextField(
                    controller: _placeholderControllers['question_$index'] ?? TextEditingController(),
                    decoration: InputDecoration(
                      labelText: 'Placeholder Text',
                      hintText: 'Enter placeholder text',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        question['placeholder'] = value;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
    setState(() {
      questions.removeAt(index);
      // Update question IDs
      for (int i = 0; i < questions.length; i++) {
        questions[i]['id'] = i + 1;
      }
      _questionCounter = questions.length + 1;
    });
  }

  void _addOption(Map<String, dynamic> question) {
    setState(() {
      (question['options'] as List).add('New Option');
    });
  }

  void _removeOption(Map<String, dynamic> question, int optionIndex) {
    setState(() {
      if ((question['options'] as List).length > 1) {
        (question['options'] as List).removeAt(optionIndex);
      }
    });
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'MC';
      case 'text':
        return 'TEXT';
      case 'rating':
        return 'RATING';
      case 'yes_no':
        return 'Y/N';
      default:
        return 'OTHER';
    }
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
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Save to SurveyStorage if this is a custom survey
    if (widget.survey['isDefault'] != true) {
      // Find the survey in storage and update it
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