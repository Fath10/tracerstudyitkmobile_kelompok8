import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Service for managing organizational units (Faculties, Departments, Program Studies)
class UnitService {
  final ApiService _apiService = ApiService();

  // ============ FACULTY MANAGEMENT ============
  
  /// Get all faculties
  Future<List<FacultyModel>> getAllFaculties() async {
    try {
      final response = await _apiService.get(ApiConfig.faculties);
      final List<dynamic> data = response is List ? response : (response['results'] ?? []);
      return data.map((json) => FacultyModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch faculties: $e');
    }
  }

  /// Get faculty by ID
  Future<FacultyModel> getFacultyById(int id) async {
    try {
      final response = await _apiService.get(ApiConfig.facultyDetail(id));
      return FacultyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch faculty: $e');
    }
  }

  /// Create new faculty
  Future<FacultyModel> createFaculty({
    required String name,
    String? description,
  }) async {
    try {
      final facultyData = {
        'name': name,
        if (description != null) 'description': description,
      };
      final response = await _apiService.post(ApiConfig.faculties, facultyData);
      return FacultyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create faculty: $e');
    }
  }

  /// Update faculty
  Future<FacultyModel> updateFaculty({
    required int id,
    required String name,
    String? description,
  }) async {
    try {
      final facultyData = {
        'name': name,
        if (description != null) 'description': description,
      };
      final response = await _apiService.put(
        ApiConfig.facultyDetail(id),
        facultyData,
      );
      return FacultyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update faculty: $e');
    }
  }

  /// Delete faculty
  Future<void> deleteFaculty(int id) async {
    try {
      await _apiService.delete(ApiConfig.facultyDetail(id));
    } catch (e) {
      throw Exception('Failed to delete faculty: $e');
    }
  }

  // ============ DEPARTMENT MANAGEMENT ============
  
  /// Get all departments (optionally filtered by faculty)
  Future<List<DepartmentModel>> getAllDepartments({int? facultyId}) async {
    try {
      String endpoint = ApiConfig.departments;
      if (facultyId != null) {
        endpoint += '?faculty_id=$facultyId';
      }
      final response = await _apiService.get(endpoint);
      final List<dynamic> data = response is List ? response : (response['results'] ?? []);
      return data.map((json) => DepartmentModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch departments: $e');
    }
  }

  /// Get department by ID
  Future<DepartmentModel> getDepartmentById(int id) async {
    try {
      final response = await _apiService.get(ApiConfig.departmentDetail(id));
      return DepartmentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch department: $e');
    }
  }

  /// Create new department
  Future<DepartmentModel> createDepartment({
    required String name,
    required int facultyId,
    String? description,
  }) async {
    try {
      final departmentData = {
        'name': name,
        'faculty': facultyId,
        if (description != null) 'description': description,
      };
      final response = await _apiService.post(
        ApiConfig.departments,
        departmentData,
      );
      return DepartmentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create department: $e');
    }
  }

  /// Update department
  Future<DepartmentModel> updateDepartment({
    required int id,
    required String name,
    required int facultyId,
    String? description,
  }) async {
    try {
      final departmentData = {
        'name': name,
        'faculty': facultyId,
        if (description != null) 'description': description,
      };
      final response = await _apiService.put(
        ApiConfig.departmentDetail(id),
        departmentData,
      );
      return DepartmentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update department: $e');
    }
  }

  /// Delete department
  Future<void> deleteDepartment(int id) async {
    try {
      await _apiService.delete(ApiConfig.departmentDetail(id));
    } catch (e) {
      throw Exception('Failed to delete department: $e');
    }
  }

  // ============ PROGRAM STUDY MANAGEMENT ============
  
  /// Get all program studies (optionally filtered by faculty)
  Future<List<ProgramStudyModel>> getAllProgramStudies({int? facultyId}) async {
    try {
      String endpoint = ApiConfig.programStudies;
      if (facultyId != null) {
        endpoint += '?faculty_id=$facultyId';
      }
      final response = await _apiService.get(endpoint);
      final List<dynamic> data = response is List ? response : (response['results'] ?? []);
      return data.map((json) => ProgramStudyModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch program studies: $e');
    }
  }

  /// Get program study by ID
  Future<ProgramStudyModel> getProgramStudyById(int id) async {
    try {
      final response = await _apiService.get(ApiConfig.programStudyDetail(id));
      return ProgramStudyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch program study: $e');
    }
  }

  /// Create new program study
  Future<ProgramStudyModel> createProgramStudy({
    required String name,
    int? departmentId,
    String? description,
  }) async {
    try {
      final programStudyData = {
        'name': name,
        if (departmentId != null) 'department': departmentId,
        if (description != null) 'description': description,
      };
      final response = await _apiService.post(
        ApiConfig.programStudies,
        programStudyData,
      );
      return ProgramStudyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create program study: $e');
    }
  }

  /// Update program study
  Future<ProgramStudyModel> updateProgramStudy({
    required int id,
    required String name,
    int? departmentId,
    String? description,
  }) async {
    try {
      final programStudyData = {
        'name': name,
        if (departmentId != null) 'department': departmentId,
        if (description != null) 'description': description,
      };
      final response = await _apiService.put(
        ApiConfig.programStudyDetail(id),
        programStudyData,
      );
      return ProgramStudyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update program study: $e');
    }
  }

  /// Delete program study
  Future<void> deleteProgramStudy(int id) async {
    try {
      await _apiService.delete(ApiConfig.programStudyDetail(id));
    } catch (e) {
      throw Exception('Failed to delete program study: $e');
    }
  }

  // ============ UTILITY METHODS ============
  
  /// Get hierarchical structure of faculties with their departments and program studies
  Future<List<Map<String, dynamic>>> getFacultyHierarchy() async {
    try {
      final faculties = await getAllFaculties();
      List<Map<String, dynamic>> hierarchy = [];

      for (var faculty in faculties) {
        final departments = await getAllDepartments(facultyId: faculty.id);
        List<Map<String, dynamic>> departmentList = [];

        for (var department in departments) {
          final programStudies = await getAllProgramStudies(
            facultyId: faculty.id,
          );
          final deptProgramStudies = programStudies
              .where((ps) => ps.departmentId == department.id)
              .toList();

          departmentList.add({
            'department': department,
            'program_studies': deptProgramStudies,
          });
        }

        hierarchy.add({
          'faculty': faculty,
          'departments': departmentList,
        });
      }

      return hierarchy;
    } catch (e) {
      throw Exception('Failed to fetch faculty hierarchy: $e');
    }
  }
}
