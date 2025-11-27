import 'api_service.dart';
import '../config/api_config.dart';

class BackendSurveyService {
  final ApiService _apiService = ApiService();

  // Get all surveys
  Future<List<dynamic>> getAllSurveys() async {
    try {
      final response = await _apiService.get(ApiConfig.surveys);
      return response['results'] ?? response as List;
    } catch (e) {
      throw Exception('Failed to fetch surveys: $e');
    }
  }

  // Get survey by ID
  Future<Map<String, dynamic>> getSurveyById(int id) async {
    try {
      return await _apiService.get(ApiConfig.surveyDetail(id));
    } catch (e) {
      throw Exception('Failed to fetch survey: $e');
    }
  }

  // Create new survey
  Future<Map<String, dynamic>> createSurvey(Map<String, dynamic> surveyData) async {
    try {
      return await _apiService.post(ApiConfig.surveys, surveyData);
    } catch (e) {
      throw Exception('Failed to create survey: $e');
    }
  }

  // Update survey
  Future<Map<String, dynamic>> updateSurvey(int id, Map<String, dynamic> surveyData) async {
    try {
      return await _apiService.put(ApiConfig.surveyDetail(id), surveyData);
    } catch (e) {
      throw Exception('Failed to update survey: $e');
    }
  }

  // Delete survey
  Future<void> deleteSurvey(int id) async {
    try {
      await _apiService.delete(ApiConfig.surveyDetail(id));
    } catch (e) {
      throw Exception('Failed to delete survey: $e');
    }
  }

  // Get sections for a survey
  Future<List<dynamic>> getSurveySections(int surveyId) async {
    try {
      final response = await _apiService.get(ApiConfig.surveySections(surveyId));
      return response['results'] ?? response as List;
    } catch (e) {
      throw Exception('Failed to fetch sections: $e');
    }
  }

  // Create section
  Future<Map<String, dynamic>> createSection(int surveyId, Map<String, dynamic> sectionData) async {
    try {
      return await _apiService.post(ApiConfig.surveySections(surveyId), sectionData);
    } catch (e) {
      throw Exception('Failed to create section: $e');
    }
  }

  // Get questions for a section
  Future<List<dynamic>> getSectionQuestions(int surveyId, int sectionId) async {
    try {
      final response = await _apiService.get(ApiConfig.surveyQuestions(surveyId, sectionId));
      return response['results'] ?? response as List;
    } catch (e) {
      throw Exception('Failed to fetch questions: $e');
    }
  }

  // Create question
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

  // Submit survey answers (bulk)
  Future<Map<String, dynamic>> submitSurveyAnswers(
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

  // Get survey answers
  Future<List<dynamic>> getSurveyAnswers(int surveyId) async {
    try {
      final response = await _apiService.get(ApiConfig.surveyAnswers(surveyId));
      return response['results'] ?? response as List;
    } catch (e) {
      throw Exception('Failed to fetch answers: $e');
    }
  }
}
