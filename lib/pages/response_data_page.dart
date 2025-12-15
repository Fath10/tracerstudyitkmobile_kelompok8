import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

/// Response Data Page - Shows survey responses from all users
/// Based on Frontend/caps-fe/src/app/response/page.tsx
class ResponseDataPage extends StatefulWidget {
  const ResponseDataPage({super.key});

  @override
  State<ResponseDataPage> createState() => _ResponseDataPageState();
}

class _ResponseDataPageState extends State<ResponseDataPage> {
  final _apiService = ApiService();
  List<UserWithDetails> _users = [];
  List<UserWithDetails> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch users and program studies
      final usersData = await _apiService.get('/accounts/users/');
      final programStudiesData = await _apiService.get('/api/program-studies/detailed/');
      
      List<UserWithDetails> users = [];
      
      if (usersData is List) {
        for (var userData in usersData) {
          final programStudyId = userData['program_study'];
          
          // Find program study details
          Map<String, dynamic>? programStudy;
          if (programStudiesData is List) {
            try {
              programStudy = programStudiesData.firstWhere(
                (ps) => ps['id'] == programStudyId,
                orElse: () => null,
              );
            } catch (e) {
              programStudy = null;
            }
          }
          
          users.add(UserWithDetails(
            id: userData['id']?.toString() ?? '',
            username: userData['username']?.toString() ?? '-',
            email: userData['email']?.toString() ?? '-',
            role: userData['role']?.toString() ?? '-',
            programStudy: programStudyId?.toString() ?? '-',
            lastSurvey: userData['last_survey']?.toString(),
            programStudyName: programStudy?['name']?.toString() ?? '-',
            facultyName: programStudy?['faculty_name']?.toString() ?? '-',
            departmentName: programStudy?['department_name']?.toString() ?? '-',
          ));
        }
      }
      
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading response data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredUsers = _users.where((user) {
          return user.username.toLowerCase().contains(lowerQuery) ||
                 user.email.toLowerCase().contains(lowerQuery) ||
                 user.programStudyName.toLowerCase().contains(lowerQuery) ||
                 user.facultyName.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  int _calculateProgress(String? lastSurvey) {
    if (lastSurvey == null || lastSurvey == 'none') return 0;
    if (lastSurvey == 'exit') return 33;
    if (lastSurvey == 'lv1') return 66;
    if (lastSurvey == 'lv2') return 100;
    return 0;
  }

  String _getProgressLabel(String? lastSurvey) {
    if (lastSurvey == null || lastSurvey == 'none') return 'None';
    if (lastSurvey == 'exit') return 'Exit Survey';
    if (lastSurvey == 'lv1') return 'Tracer Lvl 1';
    if (lastSurvey == 'lv2') return 'Tracer Lvl 2';
    return 'None';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Response Data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Dashboard / Response Data',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterUsers,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or program...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterUsers('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredUsers.length} respondents',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Data Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: AppTheme.gray400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No responses yet'
                                  : 'No results found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Faculty')),
                              DataColumn(label: Text('Department')),
                              DataColumn(label: Text('Program Study')),
                              DataColumn(label: Text('Last Survey')),
                              DataColumn(label: Text('Progress')),
                            ],
                            rows: _filteredUsers.map((user) {
                              final progress = _calculateProgress(user.lastSurvey);
                              final progressLabel = _getProgressLabel(user.lastSurvey);
                              
                              return DataRow(
                                cells: [
                                  DataCell(Text(user.id)),
                                  DataCell(Text(user.username)),
                                  DataCell(Text(user.email)),
                                  DataCell(Text(user.facultyName)),
                                  DataCell(Text(user.departmentName)),
                                  DataCell(Text(user.programStudyName)),
                                  DataCell(Text(progressLabel)),
                                  DataCell(
                                    SizedBox(
                                      width: 120,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          LinearProgressIndicator(
                                            value: progress / 100,
                                            backgroundColor: AppTheme.gray200,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              progress == 0
                                                  ? AppTheme.gray400
                                                  : progress < 50
                                                      ? AppTheme.warning500
                                                      : progress < 100
                                                          ? AppTheme.info500
                                                          : AppTheme.success500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$progress%',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// User data model with program study details
class UserWithDetails {
  final String id;
  final String username;
  final String email;
  final String role;
  final String programStudy;
  final String? lastSurvey;
  final String programStudyName;
  final String facultyName;
  final String departmentName;

  UserWithDetails({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.programStudy,
    this.lastSurvey,
    required this.programStudyName,
    required this.facultyName,
    required this.departmentName,
  });
}
