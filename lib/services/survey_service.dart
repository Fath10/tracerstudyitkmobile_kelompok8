import 'dart:convert';
import '../database/database.dart';
import 'package:drift/drift.dart';

class SurveyService {
  final AppDatabase _database;
  
  SurveyService(this._database);

  // Survey operations
  Future<int> createSurvey({
    required String name,
    required String description,
    required int createdBy,
  }) async {
    final survey = SurveysCompanion(
      name: Value(name),
      description: Value(description),
      createdBy: Value(createdBy),
      isActive: const Value(true),
    );
    return await _database.createSurvey(survey);
  }

  Future<List<Survey>> getUserSurveys(int userId) async {
    return await _database.getSurveysByCreator(userId);
  }

  Future<List<Survey>> getAllSurveys() async {
    return await _database.getAllSurveys();
  }

  Future<Survey?> getSurvey(int surveyId) async {
    return await _database.getSurveyById(surveyId);
  }

  Future<bool> updateSurvey({
    required int surveyId,
    required String name,
    required String description,
  }) async {
    final survey = SurveysCompanion(
      id: Value(surveyId),
      name: Value(name),
      description: Value(description),
      updatedAt: Value(DateTime.now()),
    );
    return await _database.updateSurvey(survey);
  }

  Future<int> deleteSurvey(int surveyId) async {
    // Delete associated questions first
    await _database.deleteQuestionsBySurvey(surveyId);
    // Then delete the survey
    return await _database.deleteSurvey(surveyId);
  }

  // Question operations
  Future<void> saveQuestions(int surveyId, List<Map<String, dynamic>> questions) async {
    // Delete existing questions first
    await _database.deleteQuestionsBySurvey(surveyId);
    
    // Insert new questions
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final metadata = _buildQuestionMetadata(question);
      
      final questionCompanion = QuestionsCompanion(
        surveyId: Value(surveyId),
        questionText: Value(question['question'] ?? ''),
        questionType: Value(question['type'] ?? 'text'),
        orderIndex: Value(i),
        metadata: Value(metadata),
      );
      
      await _database.createQuestion(questionCompanion);
    }
  }

  Future<List<Question>> getQuestions(int surveyId) async {
    return await _database.getQuestionsBySurvey(surveyId);
  }

  String _buildQuestionMetadata(Map<String, dynamic> question) {
    final metadata = <String, dynamic>{};
    
    switch (question['type']) {
      case 'multiple_choice':
      case 'yes_no':
        metadata['options'] = question['options'] ?? [];
        break;
      case 'rating':
        metadata['scale'] = question['scale'] ?? 5;
        metadata['labels'] = question['labels'] ?? ['Poor', 'Excellent'];
        break;
      case 'text':
        metadata['placeholder'] = question['placeholder'] ?? 'Enter your answer';
        break;
    }
    
    return jsonEncode(metadata);
  }

  Map<String, dynamic> parseQuestionMetadata(String metadata) {
    try {
      return jsonDecode(metadata);
    } catch (e) {
      return {};
    }
  }

  // Response operations
  Future<int> submitResponse({
    required int surveyId,
    String? respondentName,
    String? respondentEmail,
    int? respondentId,
    required List<Map<String, dynamic>> answers,
  }) async {
    // Create response record
    final response = ResponsesCompanion(
      surveyId: Value(surveyId),
      respondentId: respondentId != null ? Value(respondentId) : const Value.absent(),
      respondentName: respondentName != null ? Value(respondentName) : const Value.absent(),
      respondentEmail: respondentEmail != null ? Value(respondentEmail) : const Value.absent(),
    );
    
    final responseId = await _database.createResponse(response);
    
    // Create answer records
    for (final answer in answers) {
      final answerCompanion = AnswersCompanion(
        responseId: Value(responseId),
        questionId: Value(answer['questionId']),
        answerText: answer['answerText'] != null ? Value(answer['answerText']) : const Value.absent(),
        answerNumber: answer['answerNumber'] != null ? Value(answer['answerNumber']) : const Value.absent(),
      );
      
      await _database.createAnswer(answerCompanion);
    }
    
    return responseId;
  }

  Future<List<Response>> getSurveyResponses(int surveyId) async {
    return await _database.getResponsesBySurvey(surveyId);
  }

  Future<List<Answer>> getResponseAnswers(int responseId) async {
    return await _database.getAnswersByResponse(responseId);
  }
}