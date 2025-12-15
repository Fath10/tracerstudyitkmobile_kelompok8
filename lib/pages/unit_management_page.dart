import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

/// Unit Management Page - Manage Academic Units (Faculties, Departments, Program Studies)
/// Based on Frontend/caps-fe/src/app/unit/page.tsx
class UnitManagementPage extends StatefulWidget {
  const UnitManagementPage({super.key});

  @override
  State<UnitManagementPage> createState() => _UnitManagementPageState();
}

class _UnitManagementPageState extends State<UnitManagementPage>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  late TabController _tabController;
  
  bool _isLoading = true;
  List<Faculty> _faculties = [];
  List<Department> _departments = [];
  List<ProgramStudy> _programStudies = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _apiService.get('/api/unit/faculties/'),
        _apiService.get('/api/unit/departments/'),
        _apiService.get('/api/unit/program-studies/'),
      ]);
      
      setState(() {
        // Parse faculties
        if (results[0] is List) {
          _faculties = (results[0] as List)
              .map((json) => Faculty.fromJson(json))
              .toList();
        }
        
        // Parse departments
        if (results[1] is List) {
          _departments = (results[1] as List)
              .map((json) => Department.fromJson(json))
              .toList();
        }
        
        // Parse program studies
        if (results[2] is List) {
          _programStudies = (results[2] as List)
              .map((json) => ProgramStudy.fromJson(json))
              .toList();
        }
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading unit data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
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
              'Academic Units',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Dashboard / Academic Units',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary700,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary700,
          tabs: const [
            Tab(text: 'Faculties'),
            Tab(text: 'Departments'),
            Tab(text: 'Program Studies'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFacultiesTab(),
                _buildDepartmentsTab(),
                _buildProgramStudiesTab(),
              ],
            ),
    );
  }

  Widget _buildFacultiesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Faculties', _faculties.length),
        const SizedBox(height: 16),
        if (_faculties.isEmpty)
          _buildEmptyState('No faculties found')
        else
          ..._faculties.map((faculty) => _buildFacultyCard(faculty)),
      ],
    );
  }

  Widget _buildDepartmentsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Departments', _departments.length),
        const SizedBox(height: 16),
        if (_departments.isEmpty)
          _buildEmptyState('No departments found')
        else
          ..._departments.map((department) => _buildDepartmentCard(department)),
      ],
    );
  }

  Widget _buildProgramStudiesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Program Studies', _programStudies.length),
        const SizedBox(height: 16),
        if (_programStudies.isEmpty)
          _buildEmptyState('No program studies found')
        else
          ..._programStudies.map((prodi) => _buildProgramStudyCard(prodi)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$title ($count)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacultyCard(Faculty faculty) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary100,
          child: Icon(
            Icons.account_balance,
            color: AppTheme.primary700,
            size: 20,
          ),
        ),
        title: Text(
          faculty.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('ID: ${faculty.id}'),
      ),
    );
  }

  Widget _buildDepartmentCard(Department department) {
    // Find faculty name
    final faculty = _faculties.firstWhere(
      (f) => f.id == department.facultyId,
      orElse: () => Faculty(id: 0, name: 'Unknown'),
    );
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.info50,
          child: Icon(
            Icons.business,
            color: AppTheme.info700,
            size: 20,
          ),
        ),
        title: Text(
          department.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Faculty: ${faculty.name}'),
            Text('ID: ${department.id}', style: TextStyle(color: AppTheme.gray600)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildProgramStudyCard(ProgramStudy prodi) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.success50,
          child: Icon(
            Icons.school,
            color: AppTheme.success700,
            size: 20,
          ),
        ),
        title: Text(
          prodi.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Department: ${prodi.departmentName}'),
            Text('Faculty: ${prodi.facultyName}'),
            Text('ID: ${prodi.id}', style: TextStyle(color: AppTheme.gray600)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

// Data Models
class Faculty {
  final int id;
  final String name;

  Faculty({required this.id, required this.name});

  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
    );
  }
}

class Department {
  final int id;
  final String name;
  final int facultyId;

  Department({
    required this.id,
    required this.name,
    required this.facultyId,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      facultyId: json['faculty'] as int,
    );
  }
}

class ProgramStudy {
  final int id;
  final String name;
  final String departmentName;
  final String facultyName;
  final int departmentId;

  ProgramStudy({
    required this.id,
    required this.name,
    required this.departmentName,
    required this.facultyName,
    required this.departmentId,
  });

  factory ProgramStudy.fromJson(Map<String, dynamic> json) {
    return ProgramStudy(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      departmentName: json['department_name']?.toString() ?? '',
      facultyName: json['faculty_name']?.toString() ?? '',
      departmentId: json['department'] as int,
    );
  }
}
