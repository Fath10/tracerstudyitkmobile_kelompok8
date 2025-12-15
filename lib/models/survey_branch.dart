/// Survey Branch Model for conditional navigation
/// Based on Frontend conditional logic where options can have branches
class SurveyBranch {
  final int id;
  final String answerValue;  // The answer text that triggers this branch
  final int nextSection;     // The section ID to navigate to
  final String? condition;   // Optional: "equals", "contains", etc.

  SurveyBranch({
    required this.id,
    required this.answerValue,
    required this.nextSection,
    this.condition,
  });

  factory SurveyBranch.fromJson(Map<String, dynamic> json) {
    return SurveyBranch(
      id: json['id'] as int? ?? 0,
      answerValue: json['answer_value']?.toString() ?? json['answerValue']?.toString() ?? '',
      nextSection: json['next_section'] as int? ?? json['nextSection'] as int? ?? 0,
      condition: json['condition']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'answer_value': answerValue,
      'next_section': nextSection,
      if (condition != null) 'condition': condition,
    };
  }

  /// Check if this branch matches the given answer
  bool matches(String answer) {
    if (condition == null || condition == 'equals') {
      return answerValue.toLowerCase() == answer.toLowerCase();
    } else if (condition == 'contains') {
      return answer.toLowerCase().contains(answerValue.toLowerCase());
    }
    return false;
  }
}

/// Question with optional branches for conditional navigation
class QuestionWithBranches {
  final int id;
  final String text;
  final String type;
  final bool required;
  final List<String>? options;
  final List<SurveyBranch>? branches;
  
  QuestionWithBranches({
    required this.id,
    required this.text,
    required this.type,
    this.required = false,
    this.options,
    this.branches,
  });

  factory QuestionWithBranches.fromJson(Map<String, dynamic> json) {
    List<SurveyBranch>? branches;
    if (json['branches'] != null && json['branches'] is List) {
      branches = (json['branches'] as List)
          .map((b) => SurveyBranch.fromJson(b as Map<String, dynamic>))
          .toList();
    }

    List<String>? options;
    if (json['options'] != null) {
      if (json['options'] is List) {
        options = (json['options'] as List)
            .map((opt) {
              if (opt is String) return opt;
              if (opt is Map) return opt['label']?.toString() ?? opt['text']?.toString() ?? '';
              return opt.toString();
            })
            .toList();
      } else if (json['options'] is String) {
        // Try to parse JSON string
        try {
          final List<dynamic> parsed = (json['options'] as String).split(',');
          options = parsed.map((e) => e.toString().trim()).toList();
        } catch (e) {
          options = [];
        }
      }
    }

    return QuestionWithBranches(
      id: json['id'] as int? ?? 0,
      text: json['text']?.toString() ?? json['question']?.toString() ?? '',
      type: json['type']?.toString() ?? json['question_type']?.toString() ?? 'text',
      required: json['required'] as bool? ?? json['is_required'] as bool? ?? false,
      options: options,
      branches: branches,
    );
  }

  /// Find the branch that should be taken based on the selected answer
  int? findNextSection(String selectedAnswer) {
    if (branches == null || branches!.isEmpty) return null;
    
    for (final branch in branches!) {
      if (branch.matches(selectedAnswer)) {
        return branch.nextSection;
      }
    }
    
    return null;  // No branch matched, continue sequentially
  }
}
