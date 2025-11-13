import 'package:flutter/material.dart';
import 'dart:convert';
import '../database/database_helper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _responses = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all survey responses
      _responses = await DatabaseHelper.instance.getAllResponses();
      
      // Calculate statistics
      _calculateStatistics();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
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

    for (var response in _responses) {
      try {
        final answers = jsonDecode(response['answers'] ?? '{}') as Map<String, dynamic>;
        
        // Status Alumni (f8)
        final statusAlumni = answers['8']?.toString() ?? '';
        if (statusAlumni.contains('Bekerja') || statusAlumni.contains('bekerja')) {
          jumlahBekerja++;
        }
        
        // Waktu Tunggu Kerja (f502)
        final waktuTunggu = answers['502']?.toString() ?? '';
        if (waktuTunggu.isNotEmpty) {
          try {
            final bulan = double.tryParse(waktuTunggu.replaceAll(RegExp(r'[^0-9.]'), ''));
            if (bulan != null) {
              totalWaktuTunggu += bulan;
              countWaktuTunggu++;
            }
          } catch (e) {
            debugPrint('Error parsing waktu tunggu: $e');
          }
        }
        
        // Relevansi Bidang Studi (f14)
        final relevansi = answers['14']?.toString() ?? '';
        if (relevansi.contains('Sangat erat') || relevansi.contains('Erat') || relevansi.contains('sangat erat') || relevansi.contains('erat')) {
          relevanPendidikan++;
        }
        if (relevansi.isNotEmpty) {
          countRelevansi++;
        }
        
        // Pendapatan (f505)
        final pendapatan = answers['505']?.toString() ?? '';
        if (pendapatan.isNotEmpty) {
          try {
            final nilai = double.tryParse(pendapatan.replaceAll(RegExp(r'[^0-9.]'), ''));
            if (nilai != null) {
              totalPendapatan += nilai;
              countPendapatan++;
            }
          } catch (e) {
            debugPrint('Error parsing pendapatan: $e');
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
      'responseRate': 100.0, // This should be calculated based on total target respondents
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
              'Rata-rata Waktu Tunggu',
              '${_statistics['rataWaktuTunggu']?.toStringAsFixed(1) ?? '0.0'} bulan',
              Icons.access_time,
              Colors.orange,
            ),
            _buildKPICard(
              '% Relevansi Pendidikan',
              '${_statistics['relevansiPendidikan']?.toStringAsFixed(1) ?? '0.0'}%',
              Icons.school,
              Colors.purple,
            ),
            _buildKPICard(
              'Rata-rata Pendapatan',
              'Rp ${_formatCurrency(_statistics['rataPendapatan'] ?? 0.0)}',
              Icons.attach_money,
              Colors.teal,
            ),
            _buildKPICard(
              '% Response Rate',
              '${_statistics['responseRate']?.toStringAsFixed(1) ?? '0.0'}%',
              Icons.rate_review,
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
                  Icon(Icons.insert_chart, size: 32, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    chartType,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Data akan ditampilkan di sini',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[400],
                    ),
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
}
