class SurveyStorage {
  static final List<Map<String, dynamic>> _customSurveys = [];
  static final List<Map<String, dynamic>> _defaultSurveys = [];
  static final List<Map<String, dynamic>> _templateSurveys = [];
  
  static List<Map<String, dynamic>> get customSurveys => List.from(_customSurveys);
  
  static void addSurvey(Map<String, dynamic> survey) {
    _customSurveys.add(survey);
  }
  
  static void updateSurvey(int index, Map<String, dynamic> survey) {
    if (index >= 0 && index < _customSurveys.length) {
      _customSurveys[index] = survey;
    }
  }
  
  static void updateDefaultSurvey(String surveyName, Map<String, dynamic> updates) {
    // Update default survey properties (like isLive status)
    final index = _defaultSurveys.indexWhere((s) => s['name'] == surveyName);
    if (index >= 0) {
      _defaultSurveys[index] = {..._defaultSurveys[index], ...updates};
    }
  }
  
  static void updateTemplateSurvey(String surveyTitle, Map<String, dynamic> updates) {
    // Update template survey properties (like isLive status)
    final index = _templateSurveys.indexWhere((s) => s['title'] == surveyTitle || s['name'] == surveyTitle);
    if (index >= 0) {
      _templateSurveys[index] = {..._templateSurveys[index], ...updates};
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
    // Initialize default surveys once
    if (_defaultSurveys.isEmpty) {
      _defaultSurveys.addAll([
        {
          'name': 'ITK Alumni Career Survey',
          'description': 'Survey about career development and job satisfaction after graduation from Institut Teknologi Kalimantan',
          'isDefault': true,
          'isLive': true, // Live by default for response tracking
          'questions': getDefaultQuestions(),
        },
        {
          'name': 'Academic Experience Evaluation',
          'description': 'Survey about your educational experience and academic preparation at ITK',
          'isDefault': true,
          'isLive': true, // Live by default for response tracking
          'questions': getDefaultQuestions(),
        },
        {
          'name': 'Industry Skills Assessment', 
          'description': 'Survey to assess current skills and training needs for industry readiness',
          'isDefault': true,
          'isLive': true, // Live by default for response tracking
          'questions': getDefaultQuestions(),
        },
        {
          'name': 'ITK Program Feedback',
          'description': 'Feedback on ITK programs and suggestions for curriculum improvement',
          'isDefault': true,
          'isLive': true, // Live by default for response tracking
          'questions': getDefaultQuestions(),
        },
      ]);
    }
    
    // Initialize template surveys once
    if (_templateSurveys.isEmpty) {
      _templateSurveys.addAll([
        {
          'name': 'Informatics Alumni Survey',
          'title': 'Informatics Alumni Survey',
          'description': 'Career tracking for Informatics graduates',
          'subtitle': 'Career tracking for Informatics graduates',
          'isTemplate': true,
          'isLive': false,
          'questions': getDefaultQuestions(),
        },
        {
          'name': 'Chemical Engineering Survey',
          'title': 'Chemical Engineering Survey',
          'description': 'Industry placement for Chemical Engineering alumni',
          'subtitle': 'Industry placement for Chemical Engineering alumni',
          'isTemplate': true,
          'isLive': false,
          'questions': getDefaultQuestions(),
        },
        {
          'name': 'Mathematics Alumni Survey',
          'title': 'Mathematics Alumni Survey',
          'description': 'Career development for Mathematics graduates',
          'subtitle': 'Career development for Mathematics graduates',
          'isTemplate': true,
          'isLive': false,
          'questions': getDefaultQuestions(),
        },
        {
          'name': 'Industrial Engineering Survey',
          'title': 'Industrial Engineering Survey',
          'description': 'Professional advancement tracking',
          'subtitle': 'Professional advancement tracking',
          'isTemplate': true,
          'isLive': false,
          'questions': getDefaultQuestions(),
        },
        {
          'name': 'Environmental Engineering Survey',
          'title': 'Environmental Engineering Survey',
          'description': 'Environmental sector career survey',
          'subtitle': 'Environmental sector career survey',
          'isTemplate': true,
          'isLive': false,
          'questions': getDefaultQuestions(),
        },
        {
          'name': 'Food Technology Survey',
          'title': 'Food Technology Survey',
          'description': 'Food industry career assessment',
          'subtitle': 'Food industry career assessment',
          'isTemplate': true,
          'isLive': false,
          'questions': getDefaultQuestions(),
        },
      ]);
    }
    
    // Combine all surveys: default + template + custom
    final allSurveys = List<Map<String, dynamic>>.from(_defaultSurveys);
    allSurveys.addAll(_templateSurveys);
    allSurveys.addAll(_customSurveys.map((survey) => {
      ...survey,
      'isDefault': false,
    }));
    
    return allSurveys;
  }
}