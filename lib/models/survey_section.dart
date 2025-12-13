class SurveySection {
  String id;
  String title;
  String description;
  int order;
  List<Map<String, dynamic>> questions;

  SurveySection({
    required this.id,
    required this.title,
    this.description = '',
    required this.order,
    List<Map<String, dynamic>>? questions,
  }) : questions = questions ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'questions': questions,
    };
  }

  factory SurveySection.fromJson(Map<String, dynamic> json) {
    return SurveySection(
      id: json['id']?.toString() ?? 'section_${json['order'] ?? 0}', // Backend returns int, convert to string
      title: json['title'] as String? ?? 'Section',
      description: json['description'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      questions: (json['questions'] as List?)
              ?.map((q) => Map<String, dynamic>.from(q))
              .toList() ??
          [],
    );
  }

  SurveySection copyWith({
    String? id,
    String? title,
    String? description,
    int? order,
    List<Map<String, dynamic>>? questions,
  }) {
    return SurveySection(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      questions: questions ?? List.from(this.questions),
    );
  }
}
