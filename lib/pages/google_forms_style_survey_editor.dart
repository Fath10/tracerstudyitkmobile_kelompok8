import 'package:flutter/material.dart';
import '../services/backend_survey_service.dart';
import '../models/survey_section.dart';
import '../widgets/google_forms_conditional_dialog.dart';
import '../models/conditional_logic.dart';

/// Google Forms-inspired survey editor with Tracer Study color palette
class GoogleFormsStyleSurveyEditor extends StatefulWidget {
  final Map<String, dynamic> survey;
  
  const GoogleFormsStyleSurveyEditor({super.key, required this.survey});

  @override
  State<GoogleFormsStyleSurveyEditor> createState() => _GoogleFormsStyleSurveyEditorState();
}

class _GoogleFormsStyleSurveyEditorState extends State<GoogleFormsStyleSurveyEditor> 
    with SingleTickerProviderStateMixin {
  
  // Controllers and state
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _surveyService = BackendSurveyService();
  
  late TabController _tabController;
  List<SurveySection> sections = [];
  int _questionCounter = 1;
  int _focusedQuestionIndex = -1;
  int _currentSectionIndex = 0; // Track current section being edited
  bool _isLive = false;
  bool _isSaving = false;
  
  // Tracer Study color palette
  static const primaryColor = Color(0xFF1A73E8); // Blue
  static const accentColor = Color(0xFFEA4335); // Red
  static const successColor = Color(0xFF34A853); // Green
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _titleController.text = widget.survey['name'] ?? 'Untitled form';
    _descriptionController.text = widget.survey['description'] ?? '';
    _isLive = widget.survey['isLive'] ?? false;
    _loadSections();
    _initializeQuestionCounter();
  }
  
  void _initializeQuestionCounter() {
    // Find the highest question ID to set the counter properly
    int maxId = 0;
    for (var section in sections) {
      for (var question in section.questions) {
        final id = question['id'];
        if (id is int && id > maxId) {
          maxId = id;
        }
      }
    }
    _questionCounter = maxId + 1;
    print('🔢 Initialized question counter to $_questionCounter');
  }

  void _loadSections() {
    print('📋 _loadSections called');
    print('   Survey keys: ${widget.survey.keys.toList()}');
    print('   Has sections key: ${widget.survey.containsKey('sections')}');
    print('   Sections value type: ${widget.survey['sections']?.runtimeType}');
    
    if (widget.survey['sections'] != null) {
      print('📋 Loading sections from survey data...');
      final sectionsData = widget.survey['sections'] as List;
      print('   Found ${sectionsData.length} sections in data');
      
      if (sectionsData.isEmpty) {
        print('⚠️ Sections array is empty!');
      }
      
      try {
        sections = sectionsData.map((s) {
          print('   Processing section: ${s.runtimeType}');
          print('   Section keys: ${s is Map ? (s as Map).keys.toList() : 'N/A'}');
          if (s is Map && s.containsKey('questions')) {
            print('   Raw questions in section: ${s['questions']}');
            print('   Questions count in raw data: ${(s['questions'] as List?)?.length ?? 0}');
          }
          final section = SurveySection.fromJson(s);
          print('   ✓ Loaded section "${section.title}" (ID: ${section.id}) with ${section.questions.length} questions');
          // Debug first question if any
          if (section.questions.isNotEmpty) {
            final firstQ = section.questions[0];
            print('      First question: id=${firstQ['id']}, text="${firstQ['text']}", type=${firstQ['type']}');
          } else {
            print('      ⚠️ Section has NO questions!');
          }
          return section;
        }).toList();
        
        print('✅ Total sections loaded: ${sections.length}');
        print('   Total questions across all sections: ${sections.fold(0, (sum, s) => sum + s.questions.length)}');
      } catch (e, stackTrace) {
        print('❌ Error loading sections: $e');
        print('Stack trace: $stackTrace');
        sections = [];
      }
    } else {
      print('⚠️ widget.survey[\'sections\'] is null');
    }
    
    if (sections.isEmpty) {
      print('⚠️ No sections found, creating default section');
      sections.add(SurveySection(
        id: 'section_1',
        title: 'Section 1',
        description: '',
        questions: [],
        order: 0,
      ));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EBF8), // Light purple background
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuestionsTab(),
                _buildResponsesTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: primaryColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleController.text.isEmpty ? 'Untitled form' : _titleController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_isLive)
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: successColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Save button
                  if (_isSaving)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: _saveSurvey,
                      icon: const Icon(Icons.save, size: 18, color: Colors.white),
                      label: const Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  // Preview button
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.white),
                    tooltip: 'Preview',
                    onPressed: _previewSurvey,
                  ),
                  // More options
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: const [
                            Icon(Icons.content_copy, size: 18),
                            SizedBox(width: 12),
                            Text('Make a copy'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: const [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      // Handle menu options
                    },
                  ),
                ],
              ),
            ),
            // Tabs
            Container(
              color: primaryColor,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Questions'),
                  Tab(text: 'Responses'),
                  Tab(text: 'Settings'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsTab() {
    try {
      if (sections.isEmpty) {
        return const Center(child: Text('No sections available'));
      }
      
      // Ensure current section index is valid
      if (_currentSectionIndex >= sections.length) {
        _currentSectionIndex = sections.length - 1;
      }
      if (_currentSectionIndex < 0) {
        _currentSectionIndex = 0;
      }
      
      if (_currentSectionIndex >= sections.length || _currentSectionIndex < 0) {
        return const Center(child: Text('Invalid section index'));
      }
      
      final currentSection = sections[_currentSectionIndex];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Form header card (only show on first section)
              if (_currentSectionIndex == 0) ...[
                _buildFormHeader(),
                const SizedBox(height: 16),
              ],
              
              // Section navigation (if multiple sections)
              if (sections.length > 1) _buildSectionNavigator(),
              
              // Section header
              _buildSectionHeader(currentSection),
              const SizedBox(height: 16),
              
              // Questions from current section
              ...List.generate(
                currentSection.questions.length,
                (index) => _buildQuestionCard(index),
              ),
              
              // Add question button
              const SizedBox(height: 16),
              _buildAddQuestionButton(),
              
              // Navigation buttons (if multiple sections)
              if (sections.length > 1) ...[
                const SizedBox(height: 24),
                _buildSectionNavigationButtons(),
              ],
            ],
          ),
        ),
      ),
    );
    } catch (e, stackTrace) {
      print('❌ Error building questions tab: $e');
      print('Stack trace: $stackTrace');
      print('Sections count: ${sections.length}');
      print('Current section index: $_currentSectionIndex');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: accentColor),
              const SizedBox(height: 16),
              const Text(
                'Error loading questions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $e',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentSectionIndex = 0;
                    if (sections.isEmpty) {
                      sections.add(SurveySection(
                        id: 'section_1',
                        title: 'Section 1',
                        description: '',
                        questions: [],
                        order: 0,
                      ));
                    }
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  Widget _buildSectionNavigator() {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.layers, size: 20, color: primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(sections.length, (index) {
                    final isActive = index == _currentSectionIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('Section ${index + 1}'),
                        selected: isActive,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _currentSectionIndex = index;
                            });
                          }
                        },
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(
                          color: isActive ? Colors.white : Colors.black87,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(SurveySection section) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: section.title),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Section title',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        section.title = value;
                      });
                    },
                  ),
                ),
                if (_currentSectionIndex > 0)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: accentColor),
                    tooltip: 'Delete section',
                    onPressed: () => _deleteSection(_currentSectionIndex),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: section.description),
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Section description (optional)',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  section.description = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous button
        if (_currentSectionIndex > 0)
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _currentSectionIndex--;
              });
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous Section'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              elevation: 1,
            ),
          )
        else
          const SizedBox.shrink(),
        
        // Next button
        if (_currentSectionIndex < sections.length - 1)
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _currentSectionIndex++;
              });
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next Section'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildFormHeader() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          // Colored header bar
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Untitled form',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                TextField(
                  controller: _descriptionController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Form description',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    if (sections.isEmpty) return const SizedBox();
    if (_currentSectionIndex >= sections.length) {
      _currentSectionIndex = sections.length - 1;
    }
    if (_currentSectionIndex < 0) {
      _currentSectionIndex = 0;
    }
    if (sections[_currentSectionIndex].questions.isEmpty) {
      return const SizedBox();
    }
    if (index >= sections[_currentSectionIndex].questions.length) {
      return const SizedBox();
    }
    
    final question = sections[_currentSectionIndex].questions[index];
    final isFocused = _focusedQuestionIndex == index;
    final isRequired = question['required'] ?? false;
    final hasConditionalLogic = question['optionNavigations'] != null && 
                                 (question['optionNavigations'] as List).isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: isFocused ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isFocused 
              ? const BorderSide(color: primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _focusedQuestionIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question header (text and type)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Question',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey[400]),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        onChanged: (value) {
                          question['text'] = value;
                        },
                        controller: TextEditingController(text: question['text'] ?? ''),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Question type dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<String>(
                        value: question['type'] ?? 'multiple_choice',
                        underline: const SizedBox(),
                        isDense: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'text',
                            child: Row(
                              children: [
                                Icon(Icons.short_text, size: 18),
                                SizedBox(width: 8),
                                Text('Short answer'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'paragraph',
                            child: Row(
                              children: [
                                Icon(Icons.subject, size: 18),
                                SizedBox(width: 8),
                                Text('Paragraph'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'multiple_choice',
                            child: Row(
                              children: [
                                Icon(Icons.radio_button_checked, size: 18),
                                SizedBox(width: 8),
                                Text('Multiple choice'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'checkboxes',
                            child: Row(
                              children: [
                                Icon(Icons.check_box, size: 18),
                                SizedBox(width: 8),
                                Text('Checkboxes'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'dropdown',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_drop_down_circle, size: 18),
                                SizedBox(width: 8),
                                Text('Dropdown'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'rating',
                            child: Row(
                              children: [
                                Icon(Icons.star_border, size: 18),
                                SizedBox(width: 8),
                                Text('Linear scale'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            question['type'] = value;
                            _initializeQuestionDefaults(question);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Question options based on type
                _buildQuestionOptions(question, index),
                
                const SizedBox(height: 16),
                
                // Bottom toolbar
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Copy button
                      IconButton(
                        icon: const Icon(Icons.content_copy, size: 20),
                        tooltip: 'Duplicate',
                        onPressed: () => _duplicateQuestion(index),
                        color: Colors.grey[700],
                      ),
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Delete',
                        onPressed: () => _deleteQuestion(index),
                        color: Colors.grey[700],
                      ),
                      
                      const Spacer(),
                      
                      // Required toggle
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Required',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                          Transform.scale(
                            scale: 0.9,
                            child: Switch(
                              value: isRequired,
                              onChanged: (value) {
                                setState(() {
                                  question['required'] = value;
                                });
                              },
                              activeColor: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Conditional logic toggle
                if (_canHaveConditionalLogic(question['type']))
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: hasConditionalLogic ? primaryColor.withOpacity(0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(4),
                      border: hasConditionalLogic 
                          ? Border.all(color: primaryColor.withOpacity(0.3))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.call_split,
                          size: 18,
                          color: hasConditionalLogic ? primaryColor : Colors.grey[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hasConditionalLogic
                                ? 'Go to section based on answer (${(question['optionNavigations'] as List).where((n) => n['navigateTo'] != 'continue').length} rule${(question['optionNavigations'] as List).where((n) => n['navigateTo'] != 'continue').length > 1 ? 's' : ''})'
                                : 'Go to section based on answer',
                            style: TextStyle(
                              fontSize: 13,
                              color: hasConditionalLogic ? primaryColor : Colors.grey[700],
                              fontWeight: hasConditionalLogic ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.9,
                          child: Switch(
                            value: hasConditionalLogic,
                            onChanged: (value) {
                              if (value) {
                                _openConditionalLogicDialog(index);
                              } else {
                                setState(() {
                                  question.remove('optionNavigations');
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Conditional navigation removed'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            activeColor: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canHaveConditionalLogic(String? type) {
    return type == 'multiple_choice' || 
           type == 'checkboxes' || 
           type == 'dropdown' ||
           type == 'yes_no';
  }

  void _initializeQuestionDefaults(Map<String, dynamic> question) {
    final type = question['type'];
    
    switch (type) {
      case 'multiple_choice':
      case 'checkboxes':
      case 'dropdown':
        question['options'] = question['options'] ?? ['Option 1'];
        break;
      case 'rating':
        question['labels'] = question['labels'] ?? ['1', '5'];
        break;
      case 'text':
      case 'paragraph':
        question['placeholder'] = question['placeholder'] ?? 'Your answer';
        break;
    }
  }

  Widget _buildQuestionOptions(Map<String, dynamic> question, int index) {
    final type = question['type'];
    
    switch (type) {
      case 'multiple_choice':
      case 'checkboxes':
        return _buildChoiceOptions(question, type == 'checkboxes');
      case 'dropdown':
        return _buildDropdownOptions(question);
      case 'rating':
        return _buildRatingPreview(question);
      case 'text':
      case 'paragraph':
        return _buildTextPreview(question, type == 'paragraph');
      case 'date':
        return _buildDatePreview();
      case 'time':
        return _buildTimePreview();
      default:
        return const SizedBox();
    }
  }

  Widget _buildChoiceOptions(Map<String, dynamic> question, bool isCheckbox) {
    final options = question['options'] as List? ?? ['Option 1'];
    
    return Column(
      children: [
        ...List.generate(options.length, (optIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  isCheckbox ? Icons.check_box_outline_blank : Icons.radio_button_unchecked,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Option ${optIndex + 1}',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    controller: TextEditingController(text: options[optIndex].toString()),
                    onChanged: (value) {
                      options[optIndex] = value;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: options.length > 1
                      ? () {
                          setState(() {
                            options.removeAt(optIndex);
                          });
                        }
                      : null,
                  color: Colors.grey[600],
                ),
              ],
            ),
          );
        }),
        Row(
          children: [
            Icon(
              isCheckbox ? Icons.check_box_outline_blank : Icons.radio_button_unchecked,
              size: 20,
              color: Colors.grey[400],
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  options.add('Option ${options.length + 1}');
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add option'),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                // Add "Other" option
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add "Other"'),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownOptions(Map<String, dynamic> question) {
    final options = question['options'] as List? ?? ['Option 1'];
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text(
                options.isNotEmpty ? options[0].toString() : 'Choose',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Spacer(),
              Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(options.length, (optIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text('${optIndex + 1}.', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    controller: TextEditingController(text: options[optIndex].toString()),
                    onChanged: (value) {
                      options[optIndex] = value;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: options.length > 1
                      ? () {
                          setState(() {
                            options.removeAt(optIndex);
                          });
                        }
                      : null,
                  color: Colors.grey[600],
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                options.add('Option ${options.length + 1}');
              });
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add option'),
            style: TextButton.styleFrom(foregroundColor: primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingPreview(Map<String, dynamic> question) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1', style: TextStyle(color: Colors.grey[600])),
            ...List.generate(5, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.radio_button_unchecked, color: Colors.grey[400]),
              );
            }),
            Text('5', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildTextPreview(Map<String, dynamic> question, bool isParagraph) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[400]!),
        ),
      ),
      child: Text(
        question['placeholder'] ?? (isParagraph ? 'Long answer text' : 'Short answer text'),
        style: TextStyle(color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildDatePreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('Month, Day, Year', style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildTimePreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('Time', style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildAddQuestionButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Add question button
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            onTap: _addQuestion,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_circle_outline, color: primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Add question',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Add section button
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            onTap: _addSection,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.library_add, color: primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Add section',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsesTab() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No responses yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Responses will appear here once people start filling out your form',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Make form live
                  SwitchListTile(
                    title: const Text('Make form live'),
                    subtitle: const Text('Allow people to respond to this form'),
                    value: _isLive,
                    onChanged: (value) {
                      setState(() {
                        _isLive = value;
                      });
                    },
                    activeColor: primaryColor,
                  ),
                  
                  const Divider(height: 32),
                  
                  // Collect email addresses
                  SwitchListTile(
                    title: const Text('Collect email addresses'),
                    subtitle: const Text('Require respondents to provide their email'),
                    value: false,
                    onChanged: (value) {
                      // Handle email collection
                    },
                    activeColor: primaryColor,
                  ),
                  
                  const Divider(height: 32),
                  
                  // Limit to 1 response
                  SwitchListTile(
                    title: const Text('Limit to 1 response'),
                    subtitle: const Text('Respondents can only submit once'),
                    value: false,
                    onChanged: (value) {
                      // Handle response limit
                    },
                    activeColor: primaryColor,
                  ),
                  
                  const Divider(height: 32),
                  
                  // Allow response editing
                  SwitchListTile(
                    title: const Text('Allow response editing'),
                    subtitle: const Text('Let respondents edit their submissions'),
                    value: false,
                    onChanged: (value) {
                      // Handle response editing
                    },
                    activeColor: primaryColor,
                  ),
                  
                  const Divider(height: 32),
                  
                  // Show progress bar
                  SwitchListTile(
                    title: const Text('Show progress bar'),
                    subtitle: const Text('Display completion percentage'),
                    value: true,
                    onChanged: (value) {
                      // Handle progress bar
                    },
                    activeColor: primaryColor,
                  ),
                  
                  const Divider(height: 32),
                  
                  // Shuffle question order
                  SwitchListTile(
                    title: const Text('Shuffle question order'),
                    subtitle: const Text('Randomize the order of questions'),
                    value: false,
                    onChanged: (value) {
                      // Handle shuffle
                    },
                    activeColor: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addQuestion() {
    setState(() {
      final newQuestion = {
        'id': _questionCounter,
        'text': '',
        'type': 'multiple_choice',
        'required': false,
        'options': ['Option 1'],
      };
      
      if (sections.isEmpty) {
        sections.add(SurveySection(
          id: 'section_1',
          title: 'Section 1',
          description: '',
          questions: [],
          order: 0,
        ));
        _currentSectionIndex = 0;
      }
      
      // Ensure valid section index
      if (_currentSectionIndex >= sections.length) {
        _currentSectionIndex = sections.length - 1;
      }
      if (_currentSectionIndex < 0) {
        _currentSectionIndex = 0;
      }
      
      sections[_currentSectionIndex].questions.add(newQuestion);
      _questionCounter++;
      _focusedQuestionIndex = sections[_currentSectionIndex].questions.length - 1;
      print('✅ Added question to section $_currentSectionIndex. Total questions: ${sections[_currentSectionIndex].questions.length}');
    });
  }

  void _addSection() {
    try {
      setState(() {
        final newSection = SurveySection(
          id: 'section_${sections.length + 1}',
          title: 'Section ${sections.length + 1}',
          description: '',
          questions: [
            {
              'id': _questionCounter,
              'text': '',
              'type': 'multiple_choice',
              'required': false,
              'options': ['Option 1'],
            }
          ],
          order: sections.length,
        );
        
        print('🆕 Creating new section: ${newSection.title}');
        sections.add(newSection);
        _questionCounter++;
        
        // Navigate to new section after it's added
        final newIndex = sections.length - 1;
        print('   Section added. Total sections: ${sections.length}');
        print('   New section index: $newIndex');
        print('   Questions in new section: ${newSection.questions.length}');
        
        _currentSectionIndex = newIndex;
        print('✅ Successfully navigated to new section');
      });
    } catch (e, stackTrace) {
      print('❌ Error adding section: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add section: $e'),
          backgroundColor: accentColor,
        ),
      );
    }
  }

  void _duplicateQuestion(int index) {
    setState(() {
      final questionToDuplicate = Map<String, dynamic>.from(sections[_currentSectionIndex].questions[index]);
      questionToDuplicate['id'] = _questionCounter;
      questionToDuplicate['required'] = false;
      
      if (questionToDuplicate['options'] != null) {
        questionToDuplicate['options'] = List<String>.from(questionToDuplicate['options']);
      }
      
      sections[_currentSectionIndex].questions.insert(index + 1, questionToDuplicate);
      _questionCounter++;
    });
  }

  void _deleteQuestion(int index) {
    if (sections[_currentSectionIndex].questions.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the last question in a section'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete question?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                sections[_currentSectionIndex].questions.removeAt(index);
                if (_focusedQuestionIndex == index) {
                  _focusedQuestionIndex = -1;
                }
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: accentColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _deleteSection(int sectionIndex) {
    if (sections.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the last section'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete section?'),
        content: Text('This will delete "${sections[sectionIndex].title}" and all its questions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                sections.removeAt(sectionIndex);
                // Adjust current section index if needed
                if (_currentSectionIndex >= sections.length) {
                  _currentSectionIndex = sections.length - 1;
                }
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: accentColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openConditionalLogicDialog(int index) async {
    if (_currentSectionIndex >= sections.length || _currentSectionIndex < 0) {
      return;
    }
    if (index >= sections[_currentSectionIndex].questions.length) {
      return;
    }
    
    final currentQuestion = sections[_currentSectionIndex].questions[index];
    
    // Get existing option navigations
    List<OptionNavigation>? existingNavigations;
    if (currentQuestion['optionNavigations'] != null) {
      final navData = currentQuestion['optionNavigations'] as List;
      existingNavigations = navData
          .map((n) => OptionNavigation.fromJson(Map<String, dynamic>.from(n)))
          .toList();
    }
    
    final result = await showDialog<List<OptionNavigation>>(
      context: context,
      builder: (context) => GoogleFormsConditionalDialog(
        currentQuestion: currentQuestion,
        sections: sections,
        currentSectionIndex: _currentSectionIndex,
        currentQuestionIndex: index,
        existingNavigations: existingNavigations,
      ),
    );
    
    if (result != null) {
      setState(() {
        // Check if any navigation is set to something other than 'continue'
        final hasCustomNavigation = result.any((nav) => nav.navigateTo != 'continue');
        
        if (hasCustomNavigation) {
          // Save option navigations
          currentQuestion['optionNavigations'] = result.map((n) => n.toJson()).toList();
        } else {
          // Remove if all are set to continue
          currentQuestion.remove('optionNavigations');
        }
      });
    }
  }

  void _saveSurvey() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      final surveyData = {
        'id': widget.survey['id'],
        'name': _titleController.text.isNotEmpty ? _titleController.text : 'Untitled form',
        'description': _descriptionController.text,
        'isLive': _isLive,
        'sections': sections.map((s) => s.toJson()).toList(),
      };
      
      // Save to backend
      if (surveyData['id'] != null) {
        await _surveyService.updateSurvey(surveyData['id'], surveyData);
      } else {
        await _surveyService.createSurvey(surveyData);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Survey saved successfully'),
            backgroundColor: successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving survey: $e'),
            backgroundColor: accentColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _previewSurvey() {
    // Navigate to preview/take survey page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preview feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
