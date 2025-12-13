import 'package:flutter/material.dart';
import '../models/conditional_logic.dart';
import '../models/survey_section.dart';

class ConditionalLogicDialog extends StatefulWidget {
  final List<Map<String, dynamic>> allQuestions;
  final int currentQuestionIndex;
  final List<QuestionCondition>? existingConditions;
  final List<SurveySection> sections;

  const ConditionalLogicDialog({
    super.key,
    required this.allQuestions,
    required this.currentQuestionIndex,
    this.existingConditions,
    required this.sections,
  });

  @override
  State<ConditionalLogicDialog> createState() => _ConditionalLogicDialogState();
}

class _ConditionalLogicDialogState extends State<ConditionalLogicDialog> {
  late List<QuestionCondition> _conditions;
  
  @override
  void initState() {
    super.initState();
    _conditions = widget.existingConditions != null 
        ? List.from(widget.existingConditions!)
        : [];
  }

  void _addCondition() {
    // Find first question with options
    int? firstQuestionWithOptions;
    String? firstOption;
    
    for (int i = 0; i < widget.currentQuestionIndex && i < widget.allQuestions.length; i++) {
      final q = widget.allQuestions[i];
      final options = q['options'];
      if (options != null && options is List && options.isNotEmpty) {
        firstQuestionWithOptions = i;
        firstOption = options[0].toString();
        break;
      }
    }
    
    setState(() {
      _conditions.add(QuestionCondition(
        questionIndex: firstQuestionWithOptions ?? 0,
        selectedOption: firstOption ?? '',
        action: 'go_to_section',
        targetSectionIndex: 0,
      ));
    });
  }

  void _removeCondition(int index) {
    setState(() {
      _conditions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Go to section based on answer'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose where to go based on the answer to this question',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              
              if (_conditions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No rules yet.\nAdd rules to navigate based on answers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              
              ...List.generate(_conditions.length, (index) {
                return _buildConditionCard(index);
              }),
              
              const SizedBox(height: 8),
              
              OutlinedButton.icon(
                onPressed: _addCondition,
                icon: const Icon(Icons.add),
                label: const Text('Add Rule'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
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
          onPressed: () => Navigator.pop(context, _conditions),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildConditionCard(int index) {
    final condition = _conditions[index];
    
    // Get current question to show its options
    final currentQuestion = widget.allQuestions[widget.currentQuestionIndex];
    final options = currentQuestion['options'];
    final hasOptions = options != null && options is List && options.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'If answer is:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _removeCondition(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.grey,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Option selector - dropdown of current question's options
            if (hasOptions)
              DropdownButtonFormField<String>(
                value: options.contains(condition.selectedOption) 
                    ? condition.selectedOption 
                    : options[0].toString(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: options.map<DropdownMenuItem<String>>((option) {
                  return DropdownMenuItem(
                    value: option.toString(),
                    child: Text(option.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _conditions[index] = QuestionCondition(
                        questionIndex: condition.questionIndex,
                        selectedOption: value,
                        action: condition.action,
                        targetSectionIndex: condition.targetSectionIndex,
                      );
                    });
                  }
                },
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'This question has no options. Add multiple choice, checkbox, or dropdown options first.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            
            const SizedBox(height: 16),
            
            Text(
              'Go to:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Section selector
            DropdownButtonFormField<int>(
              value: condition.targetSectionIndex != null &&
                     condition.targetSectionIndex! < widget.sections.length
                  ? condition.targetSectionIndex
                  : 0,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: [
                ...widget.sections.asMap().entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text('Section ${entry.key + 1}: ${entry.value.title}'),
                  );
                }),
                const DropdownMenuItem(
                  value: -1,
                  child: Text('Submit form'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _conditions[index] = QuestionCondition(
                      questionIndex: condition.questionIndex,
                      selectedOption: condition.selectedOption,
                      action: 'go_to_section',
                      targetSectionIndex: value,
                    );
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
