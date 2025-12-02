import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/backend_survey_service.dart';
import '../models/survey_section.dart';

class ViewSurveyResponsesPage extends StatefulWidget {
  final int surveyId;
  final String surveyName;
  final List<SurveySection> sections;

  const ViewSurveyResponsesPage({
    super.key,
    required this.surveyId,
    required this.surveyName,
    required this.sections,
  });

  @override
  State<ViewSurveyResponsesPage> createState() => _ViewSurveyResponsesPageState();
}

class _ViewSurveyResponsesPageState extends State<ViewSurveyResponsesPage> {
  final _surveyService = BackendSurveyService();

  Future<List<Map<String, dynamic>>> _loadResponses() async {
    try {
      final answers = await _surveyService.getSurveyAnswers(widget.surveyId);
      return answers.map((answer) => {
        'id': answer['id'],
        'answers': answer['answer_text'] ?? '{}',
        'submittedAt': answer['created_at'] ?? DateTime.now().toIso8601String(),
        'userId': answer['user'],
      }).toList();
    } catch (e) {
      debugPrint('Error loading responses: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey Responses'),
        backgroundColor: Colors.purple,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadResponses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Error loading responses'),
                  Text('${snapshot.error}'),
                ],
              ),
            );
          }

          final responses = snapshot.data ?? [];

          if (responses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No responses yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: responses.length,
            itemBuilder: (context, index) {
              final response = responses[index];

              // Parse answers
              Map<String, dynamic> answers = {};
              try {
                final answersData = response['answers'];
                if (answersData != null && answersData.isNotEmpty) {
                  answers = Map<String, dynamic>.from(jsonDecode(answersData));
                }
              } catch (e) {
                debugPrint('Error parsing answers: $e');
              }

              final submittedAt = response['submittedAt'] != null
                  ? DateTime.parse(response['submittedAt'])
                  : DateTime.now();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.purple,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  response['userName'] ?? 'Anonymous',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  response['userEmail'] ?? '',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${submittedAt.day}/${submittedAt.month}/${submittedAt.year}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      ...widget.sections.map((section) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.sections.length > 1) ...[
                              Text(
                                section.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            ...section.questions.map((question) {
                              final questionId = question['id'].toString();
                              final answer = answers[questionId];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      question['text'] ?? question['question'] ?? 'Question',
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Text(
                                        answer?.toString() ?? 'No answer',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
