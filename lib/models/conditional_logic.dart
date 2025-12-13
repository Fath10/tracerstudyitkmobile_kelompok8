// Conditional logic for questions (Google Forms style - exact replica)
// Each option can have its own navigation rule
class OptionNavigation {
  final String optionText; // The option text
  final String navigateTo; // 'continue', 'submit', 'section_X', 'question_X'
  final int? targetIndex; // Index of target section or question

  OptionNavigation({
    required this.optionText,
    required this.navigateTo,
    this.targetIndex,
  });

  Map<String, dynamic> toJson() => {
    'optionText': optionText,
    'navigateTo': navigateTo,
    'targetIndex': targetIndex,
  };

  factory OptionNavigation.fromJson(Map<String, dynamic> json) =>
      OptionNavigation(
        optionText: json['optionText'],
        navigateTo: json['navigateTo'] ?? 'continue',
        targetIndex: json['targetIndex'],
      );
}

// Question-level conditional logic (contains all option navigations)
class QuestionCondition {
  final int questionIndex; // Index of the question
  final List<OptionNavigation> optionNavigations; // Navigation for each option

  QuestionCondition({
    required this.questionIndex,
    required this.optionNavigations,
  });

  Map<String, dynamic> toJson() => {
    'questionIndex': questionIndex,
    'optionNavigations': optionNavigations.map((o) => o.toJson()).toList(),
  };

  factory QuestionCondition.fromJson(Map<String, dynamic> json) =>
      QuestionCondition(
        questionIndex: json['questionIndex'],
        optionNavigations: (json['optionNavigations'] as List?)
            ?.map((o) => OptionNavigation.fromJson(o))
            .toList() ?? [],
      );

  // Find navigation for a specific answer
  OptionNavigation? getNavigationForAnswer(dynamic answer) {
    if (answer == null) return null;
    
    final answerStr = answer.toString().toLowerCase();
    
    return optionNavigations.cast<OptionNavigation?>().firstWhere(
      (nav) => nav!.optionText.toLowerCase() == answerStr,
      orElse: () => null,
    );
  }
}
