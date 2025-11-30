import 'api_service.dart';
import '../config/api_config.dart';

class BackendSurveyService {
  final ApiService _apiService = ApiService();

  // ============ SURVEY MANAGEMENT ============
  
  /// Get all surveys (ordered by newest first)
  Future<List<dynamic>> getAllSurveys() async {
    try {
      final response = await _apiService.get(ApiConfig.surveys);
      return response is List ? response : (response['results'] ?? []);
    } catch (e) {
      throw Exception('Failed to fetch surveys: $e');
    }
  }

  /// Get survey by ID
  Future<Map<String, dynamic>> getSurveyById(int id) async {
    try {
      return await _apiService.get(ApiConfig.surveyDetail(id));
    } catch (e) {
      throw Exception('Failed to fetch survey: $e');
    }
  }

  /// Create new survey
  Future<Map<String, dynamic>> createSurvey(Map<String, dynamic> surveyData) async {
    try {
      return await _apiService.post(ApiConfig.surveys, surveyData);
    } catch (e) {
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
      return await _apiService.post(ApiConfig.surveySections(surveyId), sectionData);
    } catch (e) {
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
      return await _apiService.post(
        ApiConfig.surveyQuestions(surveyId, sectionId),
        questionData,
      );
    } catch (e) {
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
      final response = await _apiService.get(ApiConfig.surveyAnswers(surveyId));
      return response is List ? response : (response['results'] ?? []);
    } catch (e) {
      throw Exception('Failed to fetch answers: $e');
    }
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
      return await _apiService.post(ApiConfig.surveyAnswers(surveyId), answerData);
    } catch (e) {
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
