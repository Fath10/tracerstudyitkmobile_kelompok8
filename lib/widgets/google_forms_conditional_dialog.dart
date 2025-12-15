import 'package:flutter/material.dart';
import '../models/conditional_logic.dart';
import '../models/survey_section.dart';

/// Google Forms-style conditional logic dialog
/// Shows a dropdown for EACH option to set where it should navigate
class GoogleFormsConditionalDialog extends StatefulWidget {
  final Map<String, dynamic> currentQuestion;
  final List<SurveySection> sections;
  final int currentSectionIndex;
  final int currentQuestionIndex; // Index within section
  final List<OptionNavigation>? existingNavigations;

  const GoogleFormsConditionalDialog({
    super.key,
    required this.currentQuestion,
    required this.sections,
    required this.currentSectionIndex,
    required this.currentQuestionIndex,
    this.existingNavigations,
  });

  @override
  State<GoogleFormsConditionalDialog> createState() => _GoogleFormsConditionalDialogState();
}

class _GoogleFormsConditionalDialogState extends State<GoogleFormsConditionalDialog> {
  late Map<String, OptionNavigation> _optionNavigations;
  
  @override
  void initState() {
    super.initState();
    _initializeNavigations();
  }

  void _initializeNavigations() {
    _optionNavigations = {};
    
    // Get options from current question
    final options = widget.currentQuestion['options'];
    if (options != null && options is List) {
      for (var option in options) {
        final optionText = option.toString();
        
        // Check if existing navigation exists for this option
        final existingNav = widget.existingNavigations?.firstWhere(
          (nav) => nav.optionText == optionText,
          orElse: () => OptionNavigation(
            optionText: optionText,
            navigateTo: 'continue',
          ),
        );
        
        _optionNavigations[optionText] = existingNav ?? OptionNavigation(
          optionText: optionText,
          navigateTo: 'continue',
        );
      }
    }
  }

  List<DropdownMenuItem<String>> _buildNavigationOptions() {
    final items = <DropdownMenuItem<String>>[];
    
    // Continue to next question (default)
    items.add(const DropdownMenuItem(
      value: 'continue',
      child: Text('Continue to next question'),
    ));
    
    // Questions in current section (after this question)
    final currentSection = widget.sections[widget.currentSectionIndex];
    final questionsAfter = currentSection.questions
        .asMap()
        .entries
        .where((e) => e.key > widget.currentQuestionIndex)
        .toList();
    
    if (questionsAfter.isNotEmpty) {
      for (var entry in questionsAfter) {
        final questionNum = entry.key + 1;
        final questionText = entry.value['text'] ?? 'Question $questionNum';
        items.add(DropdownMenuItem(
          value: 'question_${entry.key}',
          child: Text(
            'Go to question $questionNum: ${questionText.length > 30 ? questionText.substring(0, 30) + '...' : questionText}',
            overflow: TextOverflow.ellipsis,
          ),
        ));
      }
    }
    
    // Sections
    for (int i = 0; i < widget.sections.length; i++) {
      if (i != widget.currentSectionIndex) {
        items.add(DropdownMenuItem(
          value: 'section_$i',
          child: Text('Go to section ${i + 1}: ${widget.sections[i].title}'),
        ));
      }
    }
    
    // Submit form
    items.add(const DropdownMenuItem(
      value: 'submit',
      child: Text('Submit form'),
    ));
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.call_split, color: Color(0xFF1A73E8)),
          SizedBox(width: 12),
          Text(
            'Question Logic',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose where to go for each answer option',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              
              ..._optionNavigations.entries.map((entry) {
                return _buildOptionNavigationRow(entry.key, entry.value);
              }).toList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Return the list of option navigations
            final navigations = _optionNavigations.values.toList();
            Navigator.pop(context, navigations);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildOptionNavigationRow(String optionText, OptionNavigation navigation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.radio_button_checked,
                size: 18,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  optionText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.arrow_forward,
                size: 16,
                color: Color(0xFF1A73E8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: navigation.navigateTo,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  isExpanded: true,
                  items: _buildNavigationOptions(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        int? targetIndex;
                        
                        // Extract target index from value
                        if (value.startsWith('section_')) {
                          targetIndex = int.parse(value.substring(8));
                        } else if (value.startsWith('question_')) {
                          targetIndex = int.parse(value.substring(9));
                        }
                        
                        _optionNavigations[optionText] = OptionNavigation(
                          optionText: optionText,
                          navigateTo: value,
                          targetIndex: targetIndex,
                        );
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
