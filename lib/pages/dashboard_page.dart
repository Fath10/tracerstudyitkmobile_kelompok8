import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/backend_survey_service.dart';
import '../services/response_tracker.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _surveyService = BackendSurveyService();
  final _responseTracker = ResponseTracker();
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _responses = [];

  @override
  void initState() {
    super.initState();
    _responseTracker.initialize();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      debugPrint('📊 Loading dashboard data...');
      
      // First, try to load responses from ResponseTracker (for demo Quick Alumni Survey)
      _responses = _responseTracker.getResponses(surveyName: 'Quick Alumni Survey 2024');
      debugPrint('   Loaded ${_responses.length} responses from ResponseTracker');
      
      // Also try to load backend responses (if authenticated)
      try {
        final surveys = await _surveyService.getAllSurveys();
        debugPrint('   Loaded ${surveys.length} surveys from backend');
        
        if (surveys.isNotEmpty) {
          for (var survey in surveys) {
            try {
              final surveyId = survey['id'] as int;
              final answers = await _surveyService.getSurveyAnswers(surveyId);
              
              // Convert answers to the expected format and add to responses
              for (var answer in answers) {
                _responses.add({
                  'survey_id': surveyId,
                  'survey_name': survey['name'] ?? 'Unknown Survey',
                  'answers': answer['answer_text'] ?? '{}',
                  'created_at': answer['created_at'] ?? DateTime.now().toIso8601String(),
                });
              }
            } catch (e) {
              debugPrint('⚠️ Skipping responses for survey (auth issue)');
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Backend unavailable, using ResponseTracker data only');
      }
      
      if (!mounted) return;
      // Calculate statistics
      _calculateStatistics();
      debugPrint('✅ Dashboard data loaded successfully with ${_responses.length} total responses');
    } catch (e) {
      debugPrint('❌ Dashboard error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateStatistics() {
    if (_responses.isEmpty) {
      _statistics = {
        'totalResponden': 0,
        'persenBekerja': 0.0,
        'rataWaktuTunggu': 0.0,
        'relevansiPendidikan': 0.0,
        'rataPendapatan': 0.0,
        'rataSatisfaction': 0.0,
        'rataCompetency': 0.0,
        'rataRecommendation': 0.0,
        'responseRate': 0.0,
      };
      return;
    }

    int totalResponden = _responses.length;
    int jumlahBekerja = 0;
    double totalWaktuTunggu = 0;
    int countWaktuTunggu = 0;
    int relevanPendidikan = 0;
    int countRelevansi = 0;
    double totalPendapatan = 0;
    int countPendapatan = 0;
    double totalSatisfaction = 0;
    int countSatisfaction = 0;
    double totalCompetency = 0;
    int countCompetency = 0;
    double totalRecommendation = 0;
    int countRecommendation = 0;

    for (var response in _responses) {
      try {
        // Handle both JSON string and direct Map
        Map<String, dynamic> answers;
        if (response['answers'] is String) {
          answers = jsonDecode(response['answers']) as Map<String, dynamic>;
        } else {
          answers = response['answers'] as Map<String, dynamic>;
        }
        
        // Quick Alumni Survey fields (q1-q10)
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
        if (relevance.isNotEmpty) {
          countRelevansi++;
        }
        
        // Q4: Satisfaction rating
        final satisfaction = answers['q4'];
        if (satisfaction != null) {
          final rating = satisfaction is int ? satisfaction.toDouble() : double.tryParse(satisfaction.toString());
          if (rating != null) {
            totalSatisfaction += rating;
            countSatisfaction++;
          }
        }
        
        // Q6: Job search duration
        final jobSearch = answers['q6']?.toString() ?? '';
        if (jobSearch.contains('Kurang dari 3 bulan')) {
          totalWaktuTunggu += 2.0;
          countWaktuTunggu++;
        } else if (jobSearch.contains('3-6 bulan')) {
          totalWaktuTunggu += 4.5;
          countWaktuTunggu++;
        } else if (jobSearch.contains('6-12 bulan')) {
          totalWaktuTunggu += 9.0;
          countWaktuTunggu++;
        } else if (jobSearch.contains('Lebih dari 12 bulan')) {
          totalWaktuTunggu += 15.0;
          countWaktuTunggu++;
        }
        
        // Q7: Competency rating
        final competency = answers['q7'];
        if (competency != null) {
          final rating = competency is int ? competency.toDouble() : double.tryParse(competency.toString());
          if (rating != null) {
            totalCompetency += rating;
            countCompetency++;
          }
        }
        
        // Q10: Recommendation rating
        final recommendation = answers['q10'];
        if (recommendation != null) {
          final rating = recommendation is int ? recommendation.toDouble() : double.tryParse(recommendation.toString());
          if (rating != null) {
            totalRecommendation += rating;
            countRecommendation++;
          }
        }
        
        // Legacy fields (f8, f14, f502, f505) - for backward compatibility
        final statusAlumni = answers['8']?.toString() ?? '';
        if (statusAlumni.contains('Bekerja') || statusAlumni.contains('bekerja')) {
          jumlahBekerja++;
        }
        
        final relevansi = answers['14']?.toString() ?? '';
        if (relevansi.contains('Sangat erat') || relevansi.contains('Erat')) {
          relevanPendidikan++;
        }
        if (relevansi.isNotEmpty) {
          countRelevansi++;
        }
        
        final waktuTunggu = answers['502']?.toString() ?? '';
        if (waktuTunggu.isNotEmpty) {
          final bulan = double.tryParse(waktuTunggu.replaceAll(RegExp(r'[^0-9.]'), ''));
          if (bulan != null) {
            totalWaktuTunggu += bulan;
            countWaktuTunggu++;
          }
        }
        
        final pendapatan = answers['505']?.toString() ?? '';
        if (pendapatan.isNotEmpty) {
          final nilai = double.tryParse(pendapatan.replaceAll(RegExp(r'[^0-9.]'), ''));
          if (nilai != null) {
            totalPendapatan += nilai;
            countPendapatan++;
          }
        }
      } catch (e) {
        debugPrint('Error processing response: $e');
      }
    }

    _statistics = {
      'totalResponden': totalResponden,
      'persenBekerja': totalResponden > 0 ? (jumlahBekerja / totalResponden * 100) : 0.0,
      'rataWaktuTunggu': countWaktuTunggu > 0 ? (totalWaktuTunggu / countWaktuTunggu) : 0.0,
      'relevansiPendidikan': countRelevansi > 0 ? (relevanPendidikan / countRelevansi * 100) : 0.0,
      'rataPendapatan': countPendapatan > 0 ? (totalPendapatan / countPendapatan) : 0.0,
      'rataSatisfaction': countSatisfaction > 0 ? (totalSatisfaction / countSatisfaction) : 0.0,
      'rataCompetency': countCompetency > 0 ? (totalCompetency / countCompetency) : 0.0,
      'rataRecommendation': countRecommendation > 0 ? (totalRecommendation / countRecommendation) : 0.0,
      'responseRate': 100.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Cards Section
                    _buildKPICards(),
                    
                    const SizedBox(height: 24),
                    
                    // Charts Section
                    _buildChartsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKPICards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Performance Indicators',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildKPICard(
              'Total Responden',
              _statistics['totalResponden'].toString(),
              Icons.people,
              Colors.blue,
            ),
            _buildKPICard(
              '% Bekerja',
              '${_statistics['persenBekerja']?.toStringAsFixed(1) ?? '0.0'}%',
              Icons.work,
              Colors.green,
            ),
            _buildKPICard(
              '% Relevansi Pendidikan',
              '${_statistics['relevansiPendidikan']?.toStringAsFixed(1) ?? '0.0'}%',
              Icons.school,
              Colors.purple,
            ),
            _buildKPICard(
              'Kepuasan (1-5)',
              '${_statistics['rataSatisfaction']?.toStringAsFixed(1) ?? '0.0'}',
              Icons.sentiment_satisfied_alt,
              Colors.amber,
            ),
            _buildKPICard(
              'Kompetensi (1-5)',
              '${_statistics['rataCompetency']?.toStringAsFixed(1) ?? '0.0'}',
              Icons.star,
              Colors.deepOrange,
            ),
            _buildKPICard(
              'Rekomendasi (1-5)',
              '${_statistics['rataRecommendation']?.toStringAsFixed(1) ?? '0.0'}',
              Icons.recommend,
              Colors.indigo,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Detail',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Quick Alumni Survey 2024 (NEW)
        if (_responses.isNotEmpty)
          _buildQuickSurveySection(),
        
        if (_responses.isNotEmpty)
          const SizedBox(height: 16),
        
        // Status dan Kondisi Kerja Alumni
        _buildSectionCard(
          '1. Status dan Kondisi Kerja Alumni',
          [
            _buildChartPlaceholder('Status Alumni (f8)', 'Pie Chart'),
            _buildChartPlaceholder('Pekerjaan ≤6 Bulan/Sebelum Lulus (f504)', 'Donut Chart'),
            _buildChartPlaceholder('Waktu Tunggu Kerja (f502)', 'Bar Chart'),
            _buildChartPlaceholder('Distribusi Pendapatan (f505)', 'Histogram'),
            _buildChartPlaceholder('Lokasi Kerja (f5a1, f5a2)', 'Heat Map'),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Profil Pekerjaan
        _buildSectionCard(
          '2. Profil Pekerjaan',
          [
            _buildChartPlaceholder('Jenis Institusi (f1101)', 'Donut Chart'),
            _buildChartPlaceholder('Nama Perusahaan (f5b)', 'Table/List'),
            _buildChartPlaceholder('Posisi Wiraswasta (f5c)', 'Word Cloud'),
            _buildChartPlaceholder('Tingkat Tempat Kerja (f5d)', 'Stacked Bar Chart'),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Relevansi Pendidikan
        _buildSectionCard(
          '3. Relevansi Pendidikan',
          [
            _buildChartPlaceholder('Relevansi Bidang Studi (f14)', 'Stacked Bar Chart'),
            _buildChartPlaceholder('Kesesuaian Tingkat Pendidikan (f15)', 'Pie Chart'),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Kompetensi Alumni
        _buildSectionCard(
          '4. Kompetensi Alumni',
          [
            _buildChartPlaceholder('Gap Analysis Kompetensi (f1761-f1774)', 'Radar Chart'),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Metode Pembelajaran
        _buildSectionCard(
          '5. Metode Pembelajaran',
          [
            _buildChartPlaceholder('Efektivitas Metode Pembelajaran (f21-f27)', 'Horizontal Bar Chart'),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Proses Pencarian Kerja
        _buildSectionCard(
          '6. Proses Pencarian Kerja',
          [
            _buildChartPlaceholder('Timeline Pencari Kerja (f301-f303)', 'Bar Chart'),
            _buildChartPlaceholder('Strategi Pencarian Kerja (f401-f415)', 'Horizontal Bar Chart'),
            _buildChartPlaceholder('Efektivitas Lamaran (f6-f7a)', 'Funnel Chart'),
            _buildChartPlaceholder('Status Aktif Pencarian Kerja (f1001)', 'Pie Chart'),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Pembiayaan Pendidikan
        _buildSectionCard(
          '7. Pembiayaan Pendidikan',
          [
            _buildChartPlaceholder('Sumber Dana Kuliah (f1201)', 'Pie Chart'),
            _buildChartPlaceholder('Sumber Biaya Studi Lanjut (f18a)', 'Pie Chart'),
            _buildChartPlaceholder('Detail Studi Lanjut (f18b-f18d)', 'Table'),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Analisis Ketidaksesuaian Pekerjaan
        _buildSectionCard(
          '8. Analisis Ketidaksesuaian Pekerjaan',
          [
            _buildChartPlaceholder('Alasan Mengambil Pekerjaan Tidak Sesuai (f1601-f1614)', 'Horizontal Bar Chart'),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder(String title, String chartType) {
    // Check if we have responses to display
    final hasData = _responses.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasData ? Icons.insert_chart : Icons.bar_chart_outlined,
                    size: 32,
                    color: hasData ? Colors.blue[300] : Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chartType,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hasData ? Colors.blue[600] : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasData 
                        ? 'Grafik akan ditampilkan berdasarkan ${_responses.length} responden'
                        : 'Belum ada data responden',
                    style: TextStyle(
                      fontSize: 10,
                      color: hasData ? Colors.blue[400] : Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} rb';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
  Widget _buildQuickSurveySection() {
    return _buildSectionCard(
      '📊 Quick Alumni Survey 2024',
      [
        _buildSimpleBarChart(
          'Status Pekerjaan',
          _responseTracker.getChartData('q1'),
          Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildSimpleBarChart(
          'Relevansi Pendidikan',
          _responseTracker.getChartData('q2'),
          Colors.green,
        ),
        const SizedBox(height: 16),
        _buildSimpleBarChart(
          'Rentang Pendapatan',
          _responseTracker.getChartData('q3'),
          Colors.amber,
        ),
        const SizedBox(height: 16),
        _buildRatingChart(
          'Kepuasan Alumni',
          'q4',
          Colors.purple,
        ),
        const SizedBox(height: 16),
        _buildRatingChart(
          'Kompetensi yang Diperoleh',
          'q7',
          Colors.deepOrange,
        ),
        const SizedBox(height: 16),
        _buildRatingChart(
          'Rekomendasi Institusi',
          'q10',
          Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildSimpleBarChart(String title, Map<String, int> data, Color color) {
    if (data.isEmpty) {
      return _buildChartPlaceholder(title, 'No Data');
    }

    // Find max value for scaling
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    final total = data.values.reduce((a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...data.entries.map((entry) {
          final percentage = (entry.value / total * 100);
          final barWidth = (entry.value / maxValue);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: barWidth,
                                  child: Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 70,
                            child: Text(
                              '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRatingChart(String title, String questionId, Color color) {
    final data = _responseTracker.getChartData(questionId);
    if (data.isEmpty) {
      return _buildChartPlaceholder(title, 'No Data');
    }

    // Convert to rating scale 1-5
    Map<int, int> ratingCounts = {};
    double totalRating = 0;
    int totalCount = 0;

    data.forEach((key, count) {
      final rating = int.tryParse(key);
      if (rating != null && rating >= 1 && rating <= 5) {
        ratingCounts[rating] = (ratingCounts[rating] ?? 0) + count;
        totalRating += rating * count;
        totalCount += count;
      }
    });

    final average = totalCount > 0 ? totalRating / totalCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    average.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            final count = ratingCounts[rating] ?? 0;
            final maxCount = ratingCounts.values.isNotEmpty 
                ? ratingCounts.values.reduce((a, b) => a > b ? a : b) 
                : 1;
            final heightFactor = maxCount > 0 ? count / maxCount : 0.0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 80,
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: heightFactor,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(
                          rating.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }}
