import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Simple in-memory response tracker for demo surveys
/// This stores sample responses for the Quick Alumni Survey template
class ResponseTracker {
  static final ResponseTracker _instance = ResponseTracker._internal();
  factory ResponseTracker() => _instance;
  ResponseTracker._internal();

  // In-memory storage for demo responses
  final List<Map<String, dynamic>> _responses = [];
  
  // Initialize with some sample responses
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    
    // Add 15 sample responses for Quick Alumni Survey
    _responses.addAll(_generateSampleResponses());
    debugPrint('✅ ResponseTracker initialized with ${_responses.length} sample responses');
  }

  List<Map<String, dynamic>> _generateSampleResponses() {
    return [
      // Response 1
      {
        'id': 1,
        'survey_name': 'Quick Alumni Survey 2024',
        'created_at': '2024-01-15T10:30:00',
        'answers': {
          'q1': 'Bekerja',
          'q2': 'Sangat Relevan',
          'q3': 'Rp 5.000.000 - Rp 7.000.000',
          'q4': 4, // Rating 4/5
          'q5': 5, // Rating 5/5
          'q6': '3-6 bulan',
          'q7': 4,
          'q8': 5,
          'q9': 'Melanjutkan di perusahaan yang sama',
          'q10': 5,
        }
      },
      // Response 2
      {
        'id': 2,
        'survey_name': 'Quick Alumni Survey 2024',
        'created_at': '2024-01-16T14:20:00',
        'answers': {
          'q1': 'Bekerja',
          'q2': 'Relevan',
          'q3': 'Rp 7.000.000 - Rp 10.000.000',
          'q4': 5,
          'q5': 4,
          'q6': 'Kurang dari 3 bulan',
          'q7': 5,
          'q8': 4,
          'q9': 'Melanjutkan pendidikan',
          'q10': 4,
        }
      },
      // Response 3
      {
        'id': 3,
        'survey_name': 'Quick Alumni Survey 2024',
        'created_at': '2024-01-17T09:15:00',
        'answers': {
          'q1': 'Wiraswasta',
          'q2': 'Sangat Relevan',
          'q3': 'Rp 7.000.000 - Rp 10.000.000',
          'q4': 5,
          'q5': 5,
          'q6': 'Tidak ada masa tunggu',
          'q7': 5,
          'q8': 5,
          'q9': 'Mengembangkan bisnis sendiri',
          'q10': 5,
        }
      },
      // Response 4
      {
        'id': 4,
        'survey_name': 'Quick Alumni Survey 2024',
        'created_at': '2024-01-18T16:45:00',
        'answers': {
          'q1': 'Melanjutkan Pendidikan',
          'q2': 'Sangat Relevan',
          'q3': 'Belum berpenghasilan',
          'q4': 5,
          'q5': 5,
          'q6': 'Tidak mencari kerja',
          'q7': 4,
          'q8': 5,
          'q9': 'Menyelesaikan studi lanjut',
          'q10': 5,
        }
      },
      // Response 5
      {
        'id': 5,
        'survey_name': 'Quick Alumni Survey 2024',
        'created_at': '2024-01-19T11:00:00',
        'answers': {
          'q1': 'Bekerja',
          'q2': 'Cukup Relevan',
          'q3': 'Rp 5.000.000 - Rp 7.000.000',
          'q4': 4,
          'q5': 4,
          'q6': '3-6 bulan',
          'q7': 4,
          'q8': 4,
          'q9': 'Mencari peluang karir yang lebih baik',
          'q10': 4,
        }
      },
      // Response 6
      {
        'id': 6,
        'survey_name': 'Quick Alumni Survey 2024',
        'created_at': '2024-01-20T13:30:00',
        'answers': {
          'q1': 'Bekerja',
          'q2': 'Sangat Relevan',
          'q3': 'Lebih dari Rp 10.000.000',
          'q4': 5,
          'q5': 5,
          'q6': 'Kurang dari 3 bulan',
          'q7': 5,
          'q8': 5,
          'q9': 'Melanjutkan di perusahaan yang sama',
          'q10': 5,
        }
      },
      // Response 7
      {
        'id': 7,
        'survey_name': 'Quick Alumni Survey 2024',
        'created_at': '2024-01-21T10:00:00',
        'answers': {
          'q1': 'Bekerja',
          'q2': 'Relevan',
          'q3': 'Rp 5.000.000 - Rp 7.000.000',
          'q4': 4,
          'q5': 4,
          'q6': '6-12 bulan',
          'q7': 3,
          'q8': 4,
          'q9': 'Melanjutkan di perusahaan yang sama',
          'q10': 4,
        }
      },
      // Response 8
      {
        'id': 8,
        'survey_name': 'Quick Alumni Survey 2024',
        'created_at': '2024-01-22T15:20:00',
        'answers': {
          'q1': 'Mencari Kerja',
          'q2': 'Cukup Relevan',
          'q3': 'Belum berpenghasilan',
          'q4': 3,
          'q5': 3,
          'q6': 'Lebih dari 12 bulan',
          'q7': 3,
          'q8': 3,
          'q9': 'Mencari peluang kerja',
          'q10': 3,
        }
      },
      // Response 9
      {
        'id': 9,
        'survey_name': 'Quick Alumni Survey 2024',
        'created_at': '2024-01-23T09:45:00',
        'answers': {
          'q1': 'Bekerja',
          'q2': 'Sangat Relevan',
          'q3': 'Rp 7.000.000 - Rp 10.000.000',
          'q4': 5,
          'q5': 5,
          'q6': 'Kurang dari 3 bulan',
          'q7': 5,
          'q8': 4,
          'q9': 'Melanjutkan di perusahaan yang sama',
          'q10': 5,
        }
      },
      // Response 10
      {
        'id': 10,
        'survey_name': 'Quick Alumni Survey 2024',
        'created_at': '2024-01-24T14:15:00',
        'answers': {
          'q1': 'Wiraswasta',
          'q2': 'Relevan',
          'q3': 'Rp 5.000.000 - Rp 7.000.000',
          'q4': 4,
          'q5': 4,
          'q6': 'Tidak ada masa tunggu',
          'q7': 4,
          'q8': 4,
          'q9': 'Mengembangkan bisnis sendiri',
          'q10': 4,
        }
      },
      // Response 11
      {
        'id': 11,
        'survey_name': 'Quick Alumni Survey 2024',
        'created_at': '2024-01-25T11:30:00',
        'answers': {
          'q1': 'Bekerja',
          'q2': 'Sangat Relevan',
          'q3': 'Rp 7.000.000 - Rp 10.000.000',
          'q4': 5,
          'q5': 5,
          'q6': '3-6 bulan',
          'q7': 5,
          'q8': 5,
          'q9': 'Melanjutkan di perusahaan yang sama',
          'q10': 5,
        }
      },
      // Response 12
      {
        'id': 12,
        'survey_name': 'Quick Alumni Survey 2024',
        'created_at': '2024-01-26T10:00:00',
        'answers': {
          'q1': 'Bekerja',
          'q2': 'Relevan',
          'q3': 'Rp 5.000.000 - Rp 7.000.000',
          'q4': 4,
          'q5': 4,
          'q6': '3-6 bulan',
          'q7': 4,
          'q8': 4,
          'q9': 'Mencari peluang karir yang lebih baik',
          'q10': 4,
        }
      },
      // Response 13
      {
        'id': 13,
        'survey_name': 'Quick Alumni Survey 2024',
        'created_at': '2024-01-27T13:00:00',
        'answers': {
          'q1': 'Melanjutkan Pendidikan',
          'q2': 'Sangat Relevan',
          'q3': 'Belum berpenghasilan',
          'q4': 5,
          'q5': 5,
          'q6': 'Tidak mencari kerja',
          'q7': 5,
          'q8': 5,
          'q9': 'Menyelesaikan studi lanjut',
          'q10': 5,
        }
      },
      // Response 14
      {
        'id': 14,
        'survey_name': 'Quick Alumni Survey 2024',
        'created_at': '2024-01-28T16:30:00',
        'answers': {
          'q1': 'Bekerja',
          'q2': 'Cukup Relevan',
          'q3': 'Rp 5.000.000 - Rp 7.000.000',
          'q4': 3,
          'q5': 4,
          'q6': '6-12 bulan',
          'q7': 4,
          'q8': 3,
          'q9': 'Melanjutkan di perusahaan yang sama',
          'q10': 4,
        }
      },
      // Response 15
      {
        'id': 15,
        'survey_name': 'Quick Alumni Survey 2024',
        'created_at': '2024-01-29T12:00:00',
        'answers': {
          'q1': 'Bekerja',
          'q2': 'Sangat Relevan',
          'q3': 'Lebih dari Rp 10.000.000',
          'q4': 5,
          'q5': 5,
          'q6': 'Kurang dari 3 bulan',
          'q7': 5,
          'q8': 5,
          'q9': 'Melanjutkan di perusahaan yang sama',
          'q10': 5,
        }
      },
    ];
  }

  /// Get all responses (optionally filtered by survey name)
  List<Map<String, dynamic>> getResponses({String? surveyName}) {
    if (surveyName == null) {
      return List.from(_responses);
    }
    return _responses.where((r) => r['survey_name'] == surveyName).toList();
  }

  /// Add a new response
  void addResponse(Map<String, dynamic> response) {
    _responses.add({
      'id': _responses.length + 1,
      ...response,
      'created_at': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Response added. Total: ${_responses.length}');
  }

  /// Clear all responses (for testing)
  void clearResponses() {
    _responses.clear();
    _initialized = false;
    debugPrint('🗑️ All responses cleared');
  }

  /// Get aggregated statistics
  Map<String, dynamic> getStatistics() {
    if (_responses.isEmpty) {
      return {
        'totalResponden': 0,
        'persenBekerja': 0.0,
        'relevansiPendidikan': 0.0,
        'rataSatisfaction': 0.0,
        'rataCompetency': 0.0,
        'rataRecommendation': 0.0,
      };
    }

    int totalResponden = _responses.length;
    int jumlahBekerja = 0;
    int relevanPendidikan = 0;
    double totalSatisfaction = 0;
    double totalCompetency = 0;
    double totalRecommendation = 0;

    for (var response in _responses) {
      final answers = response['answers'] as Map<String, dynamic>;
      
      // Q1: Employment status
      final employment = answers['q1']?.toString() ?? '';
      if (employment.contains('Bekerja') || employment.contains('Wiraswasta')) {
        jumlahBekerja++;
      }
      
      // Q2: Education relevance
      final relevance = answers['q2']?.toString() ?? '';
      if (relevance.contains('Sangat Relevan') || relevance.contains('Relevan')) {
        relevanPendidikan++;
      }
      
      // Q4: Satisfaction rating
      final satisfaction = answers['q4'];
      if (satisfaction is int) {
        totalSatisfaction += satisfaction.toDouble();
      }
      
      // Q7: Competency rating
      final competency = answers['q7'];
      if (competency is int) {
        totalCompetency += competency.toDouble();
      }
      
      // Q10: Recommendation rating
      final recommendation = answers['q10'];
      if (recommendation is int) {
        totalRecommendation += recommendation.toDouble();
      }
    }

    return {
      'totalResponden': totalResponden,
      'persenBekerja': (jumlahBekerja / totalResponden * 100),
      'relevansiPendidikan': (relevanPendidikan / totalResponden * 100),
      'rataSatisfaction': totalSatisfaction / totalResponden,
      'rataCompetency': totalCompetency / totalResponden,
      'rataRecommendation': totalRecommendation / totalResponden,
    };
  }

  /// Get chart data for a specific question
  Map<String, int> getChartData(String questionId) {
    Map<String, int> chartData = {};
    
    for (var response in _responses) {
      final answers = response['answers'] as Map<String, dynamic>;
      final answer = answers[questionId];
      
      if (answer != null) {
        final answerStr = answer.toString();
        chartData[answerStr] = (chartData[answerStr] ?? 0) + 1;
      }
    }
    
    return chartData;
  }
}
