import 'dart:convert';
import 'package:flutter/material.dart';
import 'take_questionnaire_page.dart';
import '../models/survey_section.dart';
import '../database/database_helper.dart';

class EditSurveyWithSectionsPage extends StatefulWidget {
  final Map<String, dynamic> survey;
  final int initialTab;
  
  const EditSurveyWithSectionsPage({super.key, required this.survey, this.initialTab = 0});

  @override
  State<EditSurveyWithSectionsPage> createState() => _EditSurveyWithSectionsPageState();
}

class _EditSurveyWithSectionsPageState extends State<EditSurveyWithSectionsPage> with SingleTickerProviderStateMixin {
  final TextEditingController _surveyNameController = TextEditingController();
  final TextEditingController _surveyDescriptionController = TextEditingController();
  final PageController _sectionPageController = PageController();
  
  List<SurveySection> sections = [];
  int _currentSectionIndex = 0;
  int _questionCounter = 1;
  int _sectionCounter = 1;
  int? _selectedQuestionIndex;
  late TabController _tabController;
  bool _isLive = false;
  
  // Controllers for questions
  final Map<String, TextEditingController> _questionControllers = {};
  final Map<String, List<TextEditingController>> _optionControllers = {};
  final Map<String, TextEditingController> _scaleControllers = {};
  final Map<String, List<TextEditingController>> _labelControllers = {};
  final Map<String, TextEditingController> _placeholderControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _surveyNameController.text = widget.survey['name'] ?? 'Survey 1';
    _surveyDescriptionController.text = widget.survey['description'] ?? 'Survey description';
    _isLive = widget.survey['isLive'] ?? false;
    
    // Initialize sections from survey data or create a default section
    print('DEBUG [INIT]: Loading survey: ${widget.survey['name']}');
    print('DEBUG [INIT]: Survey data keys: ${widget.survey.keys}');
    print('DEBUG [INIT]: Sections in survey data: ${widget.survey['sections']}');
    
    if (widget.survey['sections'] != null && (widget.survey['sections'] as List).isNotEmpty) {
      print('DEBUG [INIT]: Found ${(widget.survey['sections'] as List).length} sections to load');
      sections = (widget.survey['sections'] as List)
          .map((s) => SurveySection.fromJson(s))
          .toList();
      sections.sort((a, b) => a.order.compareTo(b.order));
      _sectionCounter = sections.length + 1;
      print('DEBUG [INIT]: Loaded ${sections.length} sections successfully');
      for (int i = 0; i < sections.length; i++) {
        print('DEBUG [INIT]: Section $i - "${sections[i].title}" with ${sections[i].questions.length} questions');
      }
    } else {
      print('DEBUG [INIT]: No sections found, creating default section');
      // Create default section with existing questions
      final defaultQuestions = widget.survey['questions'] != null && (widget.survey['questions'] as List).isNotEmpty
          ? (widget.survey['questions'] as List).map((q) => Map<String, dynamic>.from(q as Map)).toList()
          : <Map<String, dynamic>>[];
      
      sections = [
        SurveySection(
          id: 'section_1',
          title: 'Section 1',
          description: '',
          order: 0,
          questions: defaultQuestions,
        ),
      ];
      _sectionCounter = 2;
    }
    
    _initializeControllers();
    _questionCounter = _calculateQuestionCounter();
  }

  int _calculateQuestionCounter() {
    int maxCounter = 1;
    for (var section in sections) {
      for (var question in section.questions) {
        if (question['id'] != null && question['id'] is int) {
          if (question['id'] > maxCounter) {
            maxCounter = question['id'];
          }
        }
      }
    }
    return maxCounter + 1;
  }

  void _initializeControllers() {
    for (int sectionIdx = 0; sectionIdx < sections.length; sectionIdx++) {
      final section = sections[sectionIdx];
      for (int i = 0; i < section.questions.length; i++) {
        final question = section.questions[i];
        final questionKey = 'section_${sectionIdx}_question_$i';
        
        _questionControllers[questionKey] = TextEditingController(text: question['question'] ?? '');
        
        if (question['type'] == 'multiple_choice' || question['type'] == 'yes_no') {
          if (question['options'] != null) {
            _optionControllers[questionKey] = [];
            for (int j = 0; j < (question['options'] as List).length; j++) {
              _optionControllers[questionKey]!.add(
                TextEditingController(text: (question['options'] as List)[j] ?? '')
              );
            }
          }
        } else if (question['type'] == 'rating') {
          _scaleControllers[questionKey] = TextEditingController(text: (question['scale'] ?? 5).toString());
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
          _placeholderControllers[questionKey] = TextEditingController(text: question['placeholder'] ?? '');
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _surveyNameController.dispose();
    _surveyDescriptionController.dispose();
    _sectionPageController.dispose();
    
    for (var controller in _questionControllers.values) {
      controller.dispose();
    }
    for (var controllerList in _optionControllers.values) {
      for (var controller in controllerList) {
        controller.dispose();
      }
    }
    for (var controller in _scaleControllers.values) {
      controller.dispose();
    }
    for (var controllerList in _labelControllers.values) {
      for (var controller in controllerList) {
        controller.dispose();
      }
    }
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
        appBar: _buildAppBar(),
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

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () {
            // Auto-save when closing
            final sectionsData = sections.map((s) => s.toJson()).toList();
            print('DEBUG [AUTO-SAVE ON CLOSE]: Saving ${sectionsData.length} sections');
            print('DEBUG [AUTO-SAVE ON CLOSE]: Sections data: $sectionsData');
            
            final surveyData = {
              'name': _surveyNameController.text.trim(),
              'description': _surveyDescriptionController.text.trim(),
              'sections': sectionsData,
              'isLive': _isLive,
              'isDefault': widget.survey['isDefault'] ?? false,
              'updated_at': DateTime.now().toIso8601String(),
            };
            
            print('DEBUG [AUTO-SAVE ON CLOSE]: Complete survey data keys: ${surveyData.keys}');
            Navigator.pop(context, surveyData);
          },
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
                    'Edit Survey • ${sections.length} ${sections.length == 1 ? 'Section' : 'Sections'}',
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
              child: const Text('Save', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
    );
  }

  Widget _buildQuestionsTab() {
    return PageView.builder(
      controller: _sectionPageController,
      itemCount: sections.length,
      physics: const ClampingScrollPhysics(), // Better physics for nested scrolling
      onPageChanged: (index) {
        setState(() {
          _currentSectionIndex = index;
          _selectedQuestionIndex = null;
        });
      },
      itemBuilder: (context, sectionIndex) {
        return _buildSectionContent(sections[sectionIndex], sectionIndex);
      },
    );
  }

  Widget _buildSectionNavigatorInCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Section dropdown (Google Forms style) - wider to prevent overflow
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButton<int>(
                value: _currentSectionIndex,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, size: 24),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                items: List.generate(sections.length, (index) {
                  return DropdownMenuItem<int>(
                    value: index,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            sections[index].title,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${sections[index].questions.length})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                onChanged: (newIndex) {
                  if (newIndex != null && newIndex != _currentSectionIndex) {
                    setState(() {
                      _currentSectionIndex = newIndex;
                      _sectionPageController.jumpToPage(newIndex);
                    });
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Section counter badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentSectionIndex + 1}/${sections.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A73E8),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Three-dot menu for section actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[600]),
            tooltip: 'Section actions',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('Edit section name'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.content_copy, size: 18, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('Duplicate section'),
                  ],
                ),
              ),
              if (sections.length > 1)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete section', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editSectionName(_currentSectionIndex);
                  break;
                case 'duplicate':
                  _duplicateSection(_currentSectionIndex);
                  break;
                case 'delete':
                  _deleteSection(_currentSectionIndex);
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(SurveySection section, int sectionIndex) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 770),
          child: Column(
            children: [
              // Survey Header Card (show on ALL sections to maintain context)
              _buildSurveyHeaderCard(),
              const SizedBox(height: 12),
              
              // Section Header Card
              _buildSectionHeaderCard(section, sectionIndex),
              
              const SizedBox(height: 12),
              
              // Questions with drag-and-drop reordering
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: section.questions.length,
                onReorder: (oldIndex, newIndex) {
                  _reorderQuestions(sectionIndex, oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final question = section.questions[index];
                  return Padding(
                    key: ValueKey('section_${sectionIndex}_question_$index'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildQuestionCard(question, index, sectionIndex),
                  );
                },
              ),
              
              // Add Question Button
              _buildAddQuestionButton(sectionIndex),
            ],
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderCard(SurveySection section, int sectionIndex) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Navigation Slider
          _buildSectionNavigatorInCard(),
          
          // Section Title and Add Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            section.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _editSectionName(sectionIndex),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.blue[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Add Section Button
                    OutlinedButton.icon(
                      onPressed: _addSection,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Section'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A73E8),
                        side: const BorderSide(color: Color(0xFF1A73E8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                if (section.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    section.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index, int sectionIndex) {
    final bool isSelected = _selectedQuestionIndex == index && _currentSectionIndex == sectionIndex;
    final bool isRequired = question['required'] ?? false;
    final questionKey = 'section_${sectionIndex}_question_$index';
    
    return GestureDetector(
      onTap: () => setState(() {
        _selectedQuestionIndex = index;
        _currentSectionIndex = sectionIndex;
      }),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 8),
                    child: Icon(Icons.drag_indicator, color: Colors.grey[400], size: 20),
                  ),
                  
                  Expanded(
                    child: TextField(
                      controller: _questionControllers[questionKey] ?? TextEditingController(),
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
              
              _buildQuestionOptions(question, index, sectionIndex),
              
              const SizedBox(height: 16),
              
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
                    // Three-dot menu for question actions
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[600]),
                      tooltip: 'Question actions',
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.content_copy, size: 18, color: Colors.grey),
                              SizedBox(width: 12),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'duplicate':
                            _duplicateQuestion(sectionIndex, index);
                            break;
                          case 'delete':
                            _deleteQuestion(sectionIndex, index);
                            break;
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    Container(width: 1, height: 20, color: Colors.grey[300]),
                    const SizedBox(width: 4),
                    Row(
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionOptions(Map<String, dynamic> question, int index, int sectionIndex) {
    switch (question['type']) {
      case 'multiple_choice':
        return _buildMultipleChoiceOptions(question, index, sectionIndex);
      case 'yes_no':
        return _buildYesNoOptions(question);
      case 'rating':
        return _buildRatingOptions(question);
      case 'text':
        return _buildTextInputPreview(question);
      default:
        return const SizedBox();
    }
  }

  Widget _buildMultipleChoiceOptions(Map<String, dynamic> question, int index, int sectionIndex) {
    final options = question['options'] as List? ?? [];
    final questionKey = 'section_${sectionIndex}_question_$index';
    
    return Column(
      children: [
        ...List.generate(options.length, (optIndex) {
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
                Expanded(
                  child: TextField(
                    controller: (_optionControllers[questionKey] != null && 
                               optIndex < _optionControllers[questionKey]!.length) 
                               ? _optionControllers[questionKey]![optIndex] 
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
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => _addOption(question),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add option', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYesNoOptions(Map<String, dynamic> question) {
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

  Widget _buildRatingOptions(Map<String, dynamic> question) {
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

  Widget _buildTextInputPreview(Map<String, dynamic> question) {
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

  Widget _buildAddQuestionButton(int sectionIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: () => _showAddQuestionMenu(sectionIndex),
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey[700],
            elevation: 2,
            child: const Icon(Icons.add),
          ),
        ],
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

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Error loading responses'),
                Text('${snapshot.error}'),
              ],
            ),
          );
        }

        final responses = snapshot.data ?? [];
        
        if (responses.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No responses yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: responses.length,
          itemBuilder: (context, index) {
            final response = responses[index];
            
            // Parse answers with null safety
            Map<String, dynamic> answers = {};
            try {
              final answersData = response['answers'];
              if (answersData != null && answersData is String && answersData.isNotEmpty) {
                answers = Map<String, dynamic>.from(jsonDecode(answersData));
              }
            } catch (e) {
              debugPrint('Error parsing answers: $e');
            }
            
            final submittedAt = response['submittedAt'] != null
                ? DateTime.parse(response['submittedAt'])
                : DateTime.now();
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                response['userName'] ?? 'Anonymous',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                response['userEmail'] ?? '',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${submittedAt.day}/${submittedAt.month}/${submittedAt.year}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ...sections.map((section) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (sections.length > 1) ...[
                            Text(
                              section.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          ...section.questions.map((question) {
                            final questionId = question['id'].toString();
                            final answer = answers[questionId];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    question['text'] ?? question['question'] ?? 'Question',
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Text(
                                      answer?.toString() ?? 'No answer',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Survey Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Survey Name
          const Text(
            'Survey Name',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _surveyNameController,
            decoration: InputDecoration(
              hintText: 'Enter survey name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 24),
          
          // Survey Description
          const Text(
            'Survey Description',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _surveyDescriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter survey description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 24),
          
          // Survey Status
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: SwitchListTile(
              title: const Text(
                'Survey Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _isLive 
                  ? 'Survey is live and accepting responses' 
                  : 'Survey is not live - respondents cannot submit',
                style: TextStyle(
                  color: _isLive ? Colors.green : Colors.orange,
                  fontSize: 13,
                ),
              ),
              value: _isLive,
              activeColor: const Color(0xFF1A73E8),
              onChanged: (value) {
                setState(() {
                  _isLive = value;
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Survey Information
          Card(
            elevation: 0,
            color: Colors.blue[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Survey Information',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Sections', sections.length.toString()),
                  _buildInfoRow(
                    'Total Questions', 
                    sections.fold<int>(0, (sum, section) => sum + section.questions.length).toString(),
                  ),
                  _buildInfoRow('Survey Type', widget.survey['isDefault'] == true ? 'Default Survey' : 'Custom Survey'),
                  if (widget.survey['updated_at'] != null)
                    _buildInfoRow(
                      'Last Updated', 
                      DateTime.parse(widget.survey['updated_at']).toString().substring(0, 16),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // Section Management Methods
  void _addSection() {
    setState(() {
      // Copy questions from current section as template with FULL CONTENT
      List<Map<String, dynamic>> templateQuestions = [];
      if (_currentSectionIndex >= 0 && _currentSectionIndex < sections.length) {
        final currentSection = sections[_currentSectionIndex];
        if (currentSection.questions.isNotEmpty) {
          // Deep copy questions with all nested data
          templateQuestions = currentSection.questions.map((q) {
            final copiedQuestion = <String, dynamic>{};
            q.forEach((key, value) {
              if (value is List) {
                // Deep copy lists (options, labels, etc.)
                copiedQuestion[key] = List.from(value);
              } else if (value is Map) {
                // Deep copy maps
                copiedQuestion[key] = Map<String, dynamic>.from(value as Map);
              } else {
                // Copy primitive values
                copiedQuestion[key] = value;
              }
            });
            return copiedQuestion;
          }).toList();
          
          print('DEBUG: Copied ${templateQuestions.length} questions from section "${currentSection.title}" as template');
        }
      }
      
      final newSectionIndex = sections.length;
      final newSection = SurveySection(
        id: 'section_$_sectionCounter',
        title: 'Section $_sectionCounter',
        description: '',
        order: newSectionIndex,
        questions: templateQuestions,
      );
      sections.add(newSection);
      _sectionCounter++;
      
      // Initialize controllers for the new section's questions
      for (int i = 0; i < templateQuestions.length; i++) {
        final question = templateQuestions[i];
        final questionKey = 'section_${newSectionIndex}_question_$i';
        
        _questionControllers[questionKey] = TextEditingController(text: question['question'] ?? question['text'] ?? '');
        
        if (question['type'] == 'multiple_choice' || question['type'] == 'yes_no') {
          if (question['options'] != null) {
            _optionControllers[questionKey] = [];
            for (int j = 0; j < (question['options'] as List).length; j++) {
              _optionControllers[questionKey]!.add(
                TextEditingController(text: (question['options'] as List)[j] ?? '')
              );
            }
          }
        } else if (question['type'] == 'rating') {
          _scaleControllers[questionKey] = TextEditingController(text: (question['scale'] ?? 5).toString());
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
          _placeholderControllers[questionKey] = TextEditingController(text: question['placeholder'] ?? '');
        }
      }
      
      print('DEBUG: Created new section with ${templateQuestions.length} template questions and initialized controllers');
      
      // Navigate to new section
      Future.delayed(const Duration(milliseconds: 100), () {
        _sectionPageController.animateToPage(
          sections.length - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    });
  }

  void _editSectionName(int sectionIndex) {
    final section = sections[sectionIndex];
    final controller = TextEditingController(text: section.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Section Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Section name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  section.title = controller.text.trim();
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _duplicateSection(int sectionIndex) {
    setState(() {
      final sectionToDuplicate = sections[sectionIndex];
      final newSection = sectionToDuplicate.copyWith(
        id: 'section_$_sectionCounter',
        title: '${sectionToDuplicate.title} (Copy)',
        order: sections.length,
      );
      sections.add(newSection);
      _sectionCounter++;
      _initializeControllers();
    });
  }

  void _deleteSection(int sectionIndex) {
    if (sections.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the last section'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text('Are you sure you want to delete "${sections[sectionIndex].title}"? All questions in this section will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                sections.removeAt(sectionIndex);
                // Update orders
                for (int i = 0; i < sections.length; i++) {
                  sections[i].order = i;
                }
                // Navigate to previous section if needed
                if (_currentSectionIndex >= sections.length) {
                  _currentSectionIndex = sections.length - 1;
                  _sectionPageController.jumpToPage(_currentSectionIndex);
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

  void _moveSectionUp(int sectionIndex) {
    if (sectionIndex > 0) {
      setState(() {
        final section = sections.removeAt(sectionIndex);
        sections.insert(sectionIndex - 1, section);
        // Update orders
        for (int i = 0; i < sections.length; i++) {
          sections[i].order = i;
        }
        _currentSectionIndex = sectionIndex - 1;
        _sectionPageController.jumpToPage(_currentSectionIndex);
      });
    }
  }

  void _moveSectionDown(int sectionIndex) {
    if (sectionIndex < sections.length - 1) {
      setState(() {
        final section = sections.removeAt(sectionIndex);
        sections.insert(sectionIndex + 1, section);
        // Update orders
        for (int i = 0; i < sections.length; i++) {
          sections[i].order = i;
        }
        _currentSectionIndex = sectionIndex + 1;
        _sectionPageController.jumpToPage(_currentSectionIndex);
      });
    }
  }

  // Question Management Methods
  void _reorderQuestions(int sectionIndex, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final question = sections[sectionIndex].questions.removeAt(oldIndex);
      sections[sectionIndex].questions.insert(newIndex, question);
    });
  }

  void _showAddQuestionMenu(int sectionIndex) {
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
                  _addQuestion('multiple_choice', sectionIndex);
                },
              ),
              ListTile(
                leading: const Icon(Icons.short_text),
                title: const Text('Short Answer'),
                onTap: () {
                  Navigator.pop(context);
                  _addQuestion('text', sectionIndex);
                },
              ),
              ListTile(
                leading: const Icon(Icons.linear_scale),
                title: const Text('Linear Scale'),
                onTap: () {
                  Navigator.pop(context);
                  _addQuestion('rating', sectionIndex);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Yes/No'),
                onTap: () {
                  Navigator.pop(context);
                  _addQuestion('yes_no', sectionIndex);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addQuestion(String questionType, int sectionIndex) {
    setState(() {
      Map<String, dynamic> newQuestion = {
        'id': _questionCounter,
        'type': questionType,
        'question': 'Question $_questionCounter',
        'required': false,
      };
      
      switch (questionType) {
        case 'multiple_choice':
          newQuestion['options'] = ['Option 1', 'Option 2'];
          break;
        case 'yes_no':
          newQuestion['options'] = ['Yes', 'No'];
          break;
        case 'rating':
          newQuestion['scale'] = 5;
          newQuestion['labels'] = ['Poor', 'Excellent'];
          break;
        case 'text':
          newQuestion['placeholder'] = 'Enter your answer here';
          break;
      }
      
      sections[sectionIndex].questions.add(newQuestion);
      _questionCounter++;
      _initializeControllers();
    });
  }

  void _deleteQuestion(int sectionIndex, int questionIndex) {
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
                sections[sectionIndex].questions.removeAt(questionIndex);
                if (_selectedQuestionIndex == questionIndex) {
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

  void _duplicateQuestion(int sectionIndex, int questionIndex) {
    setState(() {
      final questionToDuplicate = Map<String, dynamic>.from(sections[sectionIndex].questions[questionIndex]);
      questionToDuplicate['id'] = _questionCounter;
      questionToDuplicate['required'] = false;
      
      if (questionToDuplicate['options'] != null) {
        questionToDuplicate['options'] = List<String>.from(questionToDuplicate['options']);
      }
      if (questionToDuplicate['labels'] != null) {
        questionToDuplicate['labels'] = List<String>.from(questionToDuplicate['labels']);
      }
      
      sections[sectionIndex].questions.insert(questionIndex + 1, questionToDuplicate);
      _questionCounter++;
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
    if (_surveyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a survey name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool hasQuestions = false;
    for (var section in sections) {
      if (section.questions.isNotEmpty) {
        hasQuestions = true;
        break;
      }
    }

    if (!hasQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('DEBUG [SAVE BUTTON]: Preparing to save survey...');
    print('DEBUG [SAVE BUTTON]: Total sections: ${sections.length}');
    for (int i = 0; i < sections.length; i++) {
      print('DEBUG [SAVE BUTTON]: Section $i - "${sections[i].title}" with ${sections[i].questions.length} questions');
    }
    
    final sectionsData = sections.map((s) => s.toJson()).toList();
    print('DEBUG [SAVE BUTTON]: Serialized sections data: $sectionsData');
    
    final surveyData = {
      'name': _surveyNameController.text.trim(),
      'description': _surveyDescriptionController.text.trim(),
      'sections': sectionsData,
      'isLive': _isLive,
      'isDefault': widget.survey['isDefault'] ?? false,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    print('DEBUG [SAVE BUTTON]: Complete survey data prepared with keys: ${surveyData.keys}');
    print('DEBUG [SAVE BUTTON]: Survey name: ${surveyData['name']}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Survey saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context, surveyData);
  }

  void _previewSurvey() {
    if (_surveyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a survey name to preview'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool hasQuestions = false;
    for (var section in sections) {
      if (section.questions.isNotEmpty) {
        hasQuestions = true;
        break;
      }
    }

    if (!hasQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question to preview'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Flatten all questions from all sections for preview
    final allQuestions = <Map<String, dynamic>>[];
    for (var section in sections) {
      allQuestions.addAll(section.questions);
    }

    final surveyData = {
      'name': _surveyNameController.text.trim(),
      'description': _surveyDescriptionController.text.trim(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakeQuestionnairePage(
          survey: surveyData,
          questions: allQuestions,
        ),
      ),
    );
  }
}
