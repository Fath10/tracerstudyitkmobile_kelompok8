import 'dart:convert';
import 'api_service.dart';

/// Survey Service - Handles survey operations with backend API
/// All data is now fetched from Django backend, no local Drift database
class SurveyService {
  final ApiService _apiService = ApiService();

  // Survey operations - All connected to backend API
  
  Future<Map<String, dynamic>> createSurvey({
    required String title,
    required String description,
    bool isActive = true,
  }) async {
    final data = {
      'title': title,
      'description': description,
      'is_active': isActive,
      'survey_type': 'exit',
    };
    return await _apiService.post('/api/surveys/', data);
  }

  Future<List<dynamic>> getAllSurveys() async {
    return await _apiService.get('/api/surveys/');
  }

  Future<Map<String, dynamic>> getSurvey(int surveyId) async {
    return await _apiService.get('/api/surveys/$surveyId/');
  }

  Future<Map<String, dynamic>> updateSurvey({
    required int surveyId,
    required String title,
    String? description,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{
      'title': title,
    };
    if (description != null) data['description'] = description;
    if (isActive != null) data['is_active'] = isActive;
    
    return await _apiService.put('/api/surveys/$surveyId/', data);
  }

  Future<void> deleteSurvey(int surveyId) async {
    await _apiService.delete('/api/surveys/$surveyId/');
  }

  // Question operations - Backend API
  
  Future<List<dynamic>> getQuestions(int surveyId) async {
    return await _apiService.get('/api/surveys/$surveyId/questions/');
  }
  
  Future<Map<String, dynamic>> createQuestion(int surveyId, Map<String, dynamic> questionData) async {
    return await _apiService.post('/api/surveys/$surveyId/questions/', questionData);
  }
  
  Future<void> updateQuestion(int surveyId, int questionId, Map<String, dynamic> questionData) async {
    await _apiService.put('/api/surveys/$surveyId/questions/$questionId/', questionData);
  }
  
  Future<void> deleteQuestion(int surveyId, int questionId) async {
    await _apiService.delete('/api/surveys/$surveyId/questions/$questionId/');
  }

  // Response operations - Backend API
  
  Future<Map<String, dynamic>> submitResponse({
    required int surveyId,
    required int userId,
    required Map<String, dynamic> answers,
  }) async {
    final data = {
      'survey': surveyId,
      'user': userId,
      'answers': answers,
    };
    return await _apiService.post('/api/responses/', data);
  }

  Future<List<dynamic>> getSurveyResponses(int surveyId) async {
    return await _apiService.get('/api/surveys/$surveyId/responses/');
  }
  
  Future<Map<String, dynamic>> getResponse(int responseId) async {
    return await _apiService.get('/api/responses/$responseId/');
  }
}