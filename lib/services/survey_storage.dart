class SurveyStorage {
  static final List<Map<String, dynamic>> _customSurveys = [];
  
  static List<Map<String, dynamic>> get customSurveys => List.from(_customSurveys);
  
  static void addSurvey(Map<String, dynamic> survey) {
    _customSurveys.add(survey);
  }
  
  static void updateSurvey(int index, Map<String, dynamic> survey) {
    if (index >= 0 && index < _customSurveys.length) {
      _customSurveys[index] = survey;
    }
  }
  
  static void removeSurvey(int index) {
    if (index >= 0 && index < _customSurveys.length) {
      _customSurveys.removeAt(index);
    }
  }
  
  // Get default ITK questions
  static List<Map<String, dynamic>> getDefaultQuestions() {
    return [
      {
        'id': 1,
        'type': 'multiple_choice',
        'question': 'What is your current employment status after graduating from ITK?',
        'options': ['Employed Full-time', 'Employed Part-time', 'Self-employed/Entrepreneur', 'Pursuing Higher Education', 'Unemployed/Job Seeking'],
      },
      {
        'id': 2,
        'type': 'rating',
        'question': 'How would you rate the relevance of your ITK education to your current career?',
        'scale': 5,
        'labels': ['Not Relevant', 'Highly Relevant'],
      },
      {
        'id': 3,
        'type': 'multiple_choice',
        'question': 'Which ITK program did you graduate from?',
        'options': ['Informatics', 'Chemical Engineering', 'Mathematics', 'Industrial Engineering', 'Environmental Engineering', 'Food Technology'],
      },
      {
        'id': 4,
        'type': 'yes_no',
        'question': 'Are you currently working in a field related to your ITK studies?',
        'options': ['Yes', 'No'],
      },
      {
        'id': 5,
        'type': 'text',
        'question': 'What skills or knowledge areas would you like ITK to emphasize more in the curriculum?',
        'placeholder': 'Please describe skills or areas for curriculum improvement...',
      },
    ];
  }
  
  static List<Map<String, dynamic>> getAllAvailableSurveys() {
    // Default ITK surveys with questions
    final defaultSurveys = [
      {
        'name': 'ITK Alumni Career Survey',
        'description': 'Survey about career development and job satisfaction after graduation from Institut Teknologi Kalimantan',
        'isDefault': true,
        'questions': getDefaultQuestions(),
      },
      {
        'name': 'Academic Experience Evaluation',
        'description': 'Survey about your educational experience and academic preparation at ITK',
        'isDefault': true,
        'questions': getDefaultQuestions(),
      },
      {
        'name': 'Industry Skills Assessment', 
        'description': 'Survey to assess current skills and training needs for industry readiness',
        'isDefault': true,
        'questions': getDefaultQuestions(),
      },
      {
        'name': 'ITK Program Feedback',
        'description': 'Feedback on ITK programs and suggestions for curriculum improvement',
        'isDefault': true,
        'questions': getDefaultQuestions(),
      },
    ];
    
    // Combine with custom surveys
    final allSurveys = List<Map<String, dynamic>>.from(defaultSurveys);
    allSurveys.addAll(_customSurveys.map((survey) => {
      ...survey,
      'isDefault': false,
    }));
    
    return allSurveys;
  }
}