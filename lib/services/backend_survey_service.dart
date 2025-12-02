import 'api_service.dart';
import '../config/api_config.dart';

class BackendSurveyService {
  final ApiService _apiService = ApiService();

  // ============ SURVEY MANAGEMENT ============
  
  /// Get all surveys (ordered by newest first)
  Future<List<dynamic>> getAllSurveys() async {
    try {
      // Try with auth first, fallback to no-auth if 401
      List<dynamic> surveys;
      try {
        final response = await _apiService.get(ApiConfig.surveys);
        surveys = response is List ? response : (response['results'] ?? []);
      } catch (e) {
        // If auth fails, try without auth
        if (e.toString().contains('401')) {
          final response = await _apiService.get(ApiConfig.surveys, includeAuth: false);
          surveys = response is List ? response : (response['results'] ?? []);
        } else {
          rethrow;
        }
      }
      
      // Transform backend format to frontend format
      return surveys.map((survey) {
        final s = Map<String, dynamic>.from(survey);
        return <String, dynamic>{
          ...s,
          'name': s['title'] ?? s['name'], // Ensure 'name' field exists
          'isLive': s['is_active'] ?? false,
          'isTemplate': false, // Backend surveys are not templates
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch surveys: $e');
    }
  }

  /// Get survey by ID
  Future<Map<String, dynamic>> getSurveyById(int id) async {
    try {
      print('📋 Fetching survey $id with all sections and questions...');
      
      // Fetch base survey
      final survey = await _apiService.get(ApiConfig.surveyDetail(id));
      final surveyData = Map<String, dynamic>.from(survey);
      
      // Fetch all sections for this survey
      final sections = await getSurveySections(id);
      print('   Found ${sections.length} sections');
      
      // Fetch questions for each section
      for (var i = 0; i < sections.length; i++) {
        final section = sections[i];
        final sectionId = section['id'];
        
        try {
          final questions = await getSectionQuestions(id, sectionId);
          section['questions'] = questions;
          print('      Section ${i + 1}: ${questions.length} questions');
        } catch (e) {
          print('      ⚠️ Failed to load questions for section $sectionId: $e');
          section['questions'] = [];
        }
      }
      
      surveyData['sections'] = sections;
      print('✅ Loaded complete survey with ${sections.length} sections');
      
      return surveyData;
    } catch (e) {
      print('❌ Failed to fetch survey: $e');
      throw Exception('Failed to fetch survey: $e');
    }
  }

  /// Create new survey
  Future<Map<String, dynamic>> createSurvey(Map<String, dynamic> surveyData) async {
    try {
      print('🔧 Creating survey: ${surveyData['name']}');
      print('   Original survey data: $surveyData');
      
      // Transform frontend format to backend format
      final backendData = {
        'title': surveyData['name'] ?? surveyData['title'] ?? 'Untitled Survey',
        'description': surveyData['description'] ?? '',
        'is_active': surveyData['isLive'] ?? false,
        'survey_type': surveyData['survey_type'] ?? 'exit',
      };
      
      // Add optional fields if present
      if (surveyData['periode_id'] != null) {
        backendData['periode_id'] = surveyData['periode_id'];
      }
      if (surveyData['start_at'] != null) {
        backendData['start_at'] = surveyData['start_at'];
      }
      if (surveyData['end_at'] != null) {
        backendData['end_at'] = surveyData['end_at'];
      }
      
      print('   Transformed backend data: $backendData');
      
      final response = await _apiService.post(ApiConfig.surveys, backendData, includeAuth: true);
      final surveyResponse = Map<String, dynamic>.from(response);
      print('✅ Survey created successfully with ID: ${surveyResponse['id']}');
      
      // If sections were provided, create them separately with their questions
      if (surveyData['sections'] != null && surveyData['sections'] is List) {
        final surveyId = surveyResponse['id'];
        final sections = surveyData['sections'] as List;
        print('   Creating ${sections.length} sections for survey $surveyId');
        
        for (var i = 0; i < sections.length; i++) {
          final section = sections[i];
          try {
            final sectionResponse = await createSection(surveyId, {
              'title': section['title'] ?? 'Section ${i + 1}',
              'description': section['description'] ?? '',
              'order': section['order'] ?? i,
            });
            final sectionId = sectionResponse['id'];
            print('      ✓ Section ${i + 1} created with ID: $sectionId');
            
            // Create questions for this section if they exist
            if (section['questions'] != null && section['questions'] is List) {
              final questions = section['questions'] as List;
              print('         Creating ${questions.length} questions for section $sectionId');
              
              for (var j = 0; j < questions.length; j++) {
                final question = questions[j];
                final questionData = {
                  'text': question['text'] ?? question['label'] ?? 'Question ${j + 1}',
                  'question_type': _mapQuestionType(question['type']),
                  'options': question['options'] ?? '',
                  'is_required': question['required'] ?? true,
                  'order': j,
                };
                
                print('            Question ${j + 1} data: $questionData');
                
                try {
                  final createdQuestion = await createQuestion(surveyId, sectionId, questionData);
                  print('            ✓ Question ${j + 1} created with ID: ${createdQuestion['id']}');
                } catch (e) {
                  print('            ✗ Failed to create question ${j + 1}: $e');
                  print('            Question data was: $questionData');
                }
              }
            } else {
              print('         ⚠️ No questions found in section data');
            }
          } catch (e) {
            print('      ✗ Failed to create section ${i + 1}: $e');
          }
        }
      }
      
      return surveyResponse;
    } catch (e) {
      print('❌ Error creating survey: $e');
      throw Exception('Failed to create survey: $e');
    }
  }

  /// Update survey (full update)
  Future<Map<String, dynamic>> updateSurvey(int id, Map<String, dynamic> surveyData) async {
    try {
      return await _apiService.put(ApiConfig.surveyDetail(id), surveyData);
    } catch (e) {
      throw Exception('Failed to update survey: $e');
    }
  }

  /// Partially update survey
  Future<Map<String, dynamic>> patchSurvey(int id, Map<String, dynamic> updates) async {
    try {
      return await _apiService.patch(ApiConfig.surveyDetail(id), updates);
    } catch (e) {
      throw Exception('Failed to patch survey: $e');
    }
  }

  /// Delete survey
  Future<void> deleteSurvey(int id) async {
    try {
      await _apiService.delete(ApiConfig.surveyDetail(id));
    } catch (e) {
      throw Exception('Failed to delete survey: $e');
    }
  }

  // ============ SECTION MANAGEMENT ============
  
  /// Get all sections for a survey
  Future<List<dynamic>> getSurveySections(int surveyId) async {
    try {
      final response = await _apiService.get(ApiConfig.surveySections(surveyId));
      return response is List ? response : (response['results'] ?? []);
    } catch (e) {
      throw Exception('Failed to fetch sections: $e');
    }
  }

  /// Get specific section details
  Future<Map<String, dynamic>> getSectionById(int surveyId, int sectionId) async {
    try {
      return await _apiService.get(ApiConfig.sectionDetail(surveyId, sectionId));
    } catch (e) {
      throw Exception('Failed to fetch section: $e');
    }
  }

  /// Create section for a survey
  Future<Map<String, dynamic>> createSection(int surveyId, Map<String, dynamic> sectionData) async {
    try {
      print('📄 Creating section for survey $surveyId: ${sectionData['title']}');
      final response = await _apiService.post(ApiConfig.surveySections(surveyId), sectionData, includeAuth: true);
      print('✅ Section created with ID: ${response['id']}');
      return response;
    } catch (e) {
      print('❌ Failed to create section: $e');
      throw Exception('Failed to create section: $e');
    }
  }

  /// Update section (full update)
  Future<Map<String, dynamic>> updateSection(
    int surveyId,
    int sectionId,
    Map<String, dynamic> sectionData,
  ) async {
    try {
      return await _apiService.put(
        ApiConfig.sectionDetail(surveyId, sectionId),
        sectionData,
      );
    } catch (e) {
      throw Exception('Failed to update section: $e');
    }
  }

  /// Partially update section
  Future<Map<String, dynamic>> patchSection(
    int surveyId,
    int sectionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      return await _apiService.patch(
        ApiConfig.sectionDetail(surveyId, sectionId),
        updates,
      );
    } catch (e) {
      throw Exception('Failed to patch section: $e');
    }
  }

  /// Delete section
  Future<void> deleteSection(int surveyId, int sectionId) async {
    try {
      await _apiService.delete(ApiConfig.sectionDetail(surveyId, sectionId));
    } catch (e) {
      throw Exception('Failed to delete section: $e');
    }
  }

  // ============ QUESTION MANAGEMENT ============
  
  /// Get all questions for a section
  Future<List<dynamic>> getSectionQuestions(int surveyId, int sectionId) async {
    try {
      final response = await _apiService.get(ApiConfig.surveyQuestions(surveyId, sectionId));
      return response is List ? response : (response['results'] ?? []);
    } catch (e) {
      throw Exception('Failed to fetch questions: $e');
    }
  }

  /// Get specific question details
  Future<Map<String, dynamic>> getQuestionById(
    int surveyId,
    int sectionId,
    int questionId,
  ) async {
    try {
      return await _apiService.get(
        ApiConfig.questionDetail(surveyId, sectionId, questionId),
      );
    } catch (e) {
      throw Exception('Failed to fetch question: $e');
    }
  }

  /// Create question in a section
  Future<Map<String, dynamic>> createQuestion(
    int surveyId,
    int sectionId,
    Map<String, dynamic> questionData,
  ) async {
    try {
      print('❓ Creating question in section $sectionId: ${questionData['text']}');
      final response = await _apiService.post(
        ApiConfig.surveyQuestions(surveyId, sectionId),
        questionData,
        includeAuth: true,
      );
      print('✅ Question created with ID: ${response['id']}');
      return response;
    } catch (e) {
      print('❌ Failed to create question: $e');
      throw Exception('Failed to create question: $e');
    }
  }

  /// Update question (full update)
  Future<Map<String, dynamic>> updateQuestion(
    int surveyId,
    int sectionId,
    int questionId,
    Map<String, dynamic> questionData,
  ) async {
    try {
      return await _apiService.put(
        ApiConfig.questionDetail(surveyId, sectionId, questionId),
        questionData,
      );
    } catch (e) {
      throw Exception('Failed to update question: $e');
    }
  }

  /// Partially update question
  Future<Map<String, dynamic>> patchQuestion(
    int surveyId,
    int sectionId,
    int questionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      return await _apiService.patch(
        ApiConfig.questionDetail(surveyId, sectionId, questionId),
        updates,
      );
    } catch (e) {
      throw Exception('Failed to patch question: $e');
    }
  }

  /// Delete question
  Future<void> deleteQuestion(int surveyId, int sectionId, int questionId) async {
    try {
      await _apiService.delete(
        ApiConfig.questionDetail(surveyId, sectionId, questionId),
      );
    } catch (e) {
      throw Exception('Failed to delete question: $e');
    }
  }

  // ============ PROGRAM-SPECIFIC QUESTION MANAGEMENT ============
  
  /// Get program-specific questions
  Future<List<dynamic>> getProgramSpecificQuestions(
    int surveyId,
    int programStudyId,
  ) async {
    try {
      final response = await _apiService.get(
        ApiConfig.programSpecificQuestions(surveyId, programStudyId),
      );
      return response is List ? response : (response['results'] ?? []);
    } catch (e) {
      throw Exception('Failed to fetch program-specific questions: $e');
    }
  }

  /// Get specific program-specific question
  Future<Map<String, dynamic>> getProgramSpecificQuestionById(
    int surveyId,
    int programStudyId,
    int questionId,
  ) async {
    try {
      return await _apiService.get(
        ApiConfig.programSpecificQuestionDetail(surveyId, programStudyId, questionId),
      );
    } catch (e) {
      throw Exception('Failed to fetch program-specific question: $e');
    }
  }

  /// Create program-specific question
  Future<Map<String, dynamic>> createProgramSpecificQuestion(
    int surveyId,
    int programStudyId,
    Map<String, dynamic> questionData,
  ) async {
    try {
      return await _apiService.post(
        ApiConfig.programSpecificQuestions(surveyId, programStudyId),
        questionData,
      );
    } catch (e) {
      throw Exception('Failed to create program-specific question: $e');
    }
  }

  /// Update program-specific question
  Future<Map<String, dynamic>> updateProgramSpecificQuestion(
    int surveyId,
    int programStudyId,
    int questionId,
    Map<String, dynamic> questionData,
  ) async {
    try {
      return await _apiService.put(
        ApiConfig.programSpecificQuestionDetail(surveyId, programStudyId, questionId),
        questionData,
      );
    } catch (e) {
      throw Exception('Failed to update program-specific question: $e');
    }
  }

  /// Delete program-specific question
  Future<void> deleteProgramSpecificQuestion(
    int surveyId,
    int programStudyId,
    int questionId,
  ) async {
    try {
      await _apiService.delete(
        ApiConfig.programSpecificQuestionDetail(surveyId, programStudyId, questionId),
      );
    } catch (e) {
      throw Exception('Failed to delete program-specific question: $e');
    }
  }

  // ============ ANSWER MANAGEMENT ============
  
  /// Get all answers for a survey
  Future<List<dynamic>> getSurveyAnswers(int surveyId) async {
    try {
      print('📥 Fetching answers for survey $surveyId');
      final response = await _apiService.get(ApiConfig.surveyAnswers(surveyId), includeAuth: true);
      final answers = response is List ? response : (response['results'] ?? []);
      print('✅ Fetched ${answers.length} answers');
      return answers;
    } catch (e) {
      print('❌ Error fetching answers: $e');
      throw Exception('Failed to fetch answers: $e');
    }
  }

  /// Map frontend question types to backend question types
  String _mapQuestionType(dynamic type) {
    if (type == null) return 'text';
    final typeStr = type.toString().toLowerCase();
    
    if (typeStr.contains('text') || typeStr.contains('input')) return 'text';
    if (typeStr.contains('number')) return 'number';
    if (typeStr.contains('radio') || typeStr.contains('single')) return 'radio';
    if (typeStr.contains('checkbox') || typeStr.contains('multiple')) return 'checkbox';
    if (typeStr.contains('dropdown') || typeStr.contains('select')) return 'dropdown';
    if (typeStr.contains('scale') || typeStr.contains('rating')) return 'scale';
    
    return 'text'; // default
  }

  /// Get specific answer by ID
  Future<Map<String, dynamic>> getAnswerById(int surveyId, int answerId) async {
    try {
      return await _apiService.get(ApiConfig.answerDetail(surveyId, answerId));
    } catch (e) {
      throw Exception('Failed to fetch answer: $e');
    }
  }

  /// Create single answer
  Future<Map<String, dynamic>> createAnswer(
    int surveyId,
    Map<String, dynamic> answerData,
  ) async {
    try {
      print('📤 Submitting answer for survey $surveyId');
      print('   Answer data: $answerData');
      final response = await _apiService.post(ApiConfig.surveyAnswers(surveyId), answerData, includeAuth: true);
      final answerResponse = Map<String, dynamic>.from(response);
      print('✅ Answer submitted successfully: ${answerResponse['id']}');
      return answerResponse;
    } catch (e) {
      print('❌ Error submitting answer: $e');
      throw Exception('Failed to create answer: $e');
    }
  }

  /// Update answer
  Future<Map<String, dynamic>> updateAnswer(
    int surveyId,
    int answerId,
    Map<String, dynamic> answerData,
  ) async {
    try {
      return await _apiService.put(
        ApiConfig.answerDetail(surveyId, answerId),
        answerData,
      );
    } catch (e) {
      throw Exception('Failed to update answer: $e');
    }
  }

  /// Delete answer
  Future<void> deleteAnswer(int surveyId, int answerId) async {
    try {
      await _apiService.delete(ApiConfig.answerDetail(surveyId, answerId));
    } catch (e) {
      throw Exception('Failed to delete answer: $e');
    }
  }

  /// Get answers by question
  Future<List<dynamic>> getAnswersByQuestion(
    int surveyId,
    int sectionId,
    int questionId,
  ) async {
    try {
      final response = await _apiService.get(
        ApiConfig.answersByQuestion(surveyId, sectionId, questionId),
      );
      return response is List ? response : (response['results'] ?? []);
    } catch (e) {
      throw Exception('Failed to fetch answers by question: $e');
    }
  }

  /// Get answers by program-specific question
  Future<List<dynamic>> getAnswersByProgramQuestion(
    int surveyId,
    int programStudyId,
    int questionId,
  ) async {
    try {
      final response = await _apiService.get(
        ApiConfig.answersByProgramQuestion(surveyId, programStudyId, questionId),
      );
      return response is List ? response : (response['results'] ?? []);
    } catch (e) {
      throw Exception('Failed to fetch answers by program question: $e');
    }
  }

  /// Submit survey answers in bulk
  Future<Map<String, dynamic>> submitSurveyAnswersBulk(
    int surveyId,
    List<Map<String, dynamic>> answers,
  ) async {
    try {
      return await _apiService.post(
        ApiConfig.surveyAnswersBulk(surveyId),
        {'answers': answers},
      );
    } catch (e) {
      throw Exception('Failed to submit answers: $e');
    }
  }
}
