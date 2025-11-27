import 'api_service.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class BackendUserService {
  final ApiService _apiService = ApiService();

  // ============ USER MANAGEMENT ============
  
  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _apiService.get(ApiConfig.users);
      final List<dynamic> data = response is List ? response : (response['results'] ?? []);
      return data.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Get user by ID
  Future<UserModel> getUserById(String id) async {
    try {
      final response = await _apiService.get(ApiConfig.userDetail(int.parse(id)));
      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  // Create new user
  Future<UserModel> createUser(UserModel user) async {
    try {
      final userData = user.toJson();
      print('Creating user with data: $userData'); // Debug log
      final response = await _apiService.post(ApiConfig.users, userData);
      print('User created successfully: $response'); // Debug log
      return UserModel.fromJson(response);
    } catch (e) {
      print('Error creating user: $e'); // Debug log
      throw Exception('Failed to create user: $e');
    }
  }

  // Update user
  Future<UserModel> updateUser(String id, UserModel user) async {
    try {
      final response = await _apiService.put(
        ApiConfig.userDetail(int.parse(id)),
        user.toJson(),
      );
      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Partial update user
  Future<UserModel> patchUser(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.patch(
        ApiConfig.userDetail(int.parse(id)),
        updates,
      );
      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(String id) async {
    try {
      await _apiService.delete(ApiConfig.userDetail(int.parse(id)));
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // ============ ROLE MANAGEMENT ============
  
  // Get all roles
  Future<List<RoleModel>> getAllRoles() async {
    try {
      final response = await _apiService.get(ApiConfig.roles);
      final List<dynamic> data = response is List ? response : (response['results'] ?? []);
      return data.map((json) => RoleModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch roles: $e');
    }
  }

  // Get role by ID
  Future<RoleModel> getRoleById(int id) async {
    try {
      final response = await _apiService.get(ApiConfig.roleDetail(id));
      return RoleModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch role: $e');
    }
  }

  // Create role
  Future<RoleModel> createRole(RoleModel role) async {
    try {
      final response = await _apiService.post(ApiConfig.roles, role.toJson());
      return RoleModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create role: $e');
    }
  }

  // Update role
  Future<RoleModel> updateRole(int id, RoleModel role) async {
    try {
      final response = await _apiService.put(
        ApiConfig.roleDetail(id),
        role.toJson(),
      );
      return RoleModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update role: $e');
    }
  }

  // Delete role
  Future<void> deleteRole(int id) async {
    try {
      await _apiService.delete(ApiConfig.roleDetail(id));
    } catch (e) {
      throw Exception('Failed to delete role: $e');
    }
  }

  // ============ FACULTY MANAGEMENT ============
  
  // Get all faculties
  Future<List<FacultyModel>> getAllFaculties() async {
    try {
      final response = await _apiService.get(ApiConfig.faculties);
      final List<dynamic> data = response is List ? response : (response['results'] ?? []);
      return data.map((json) => FacultyModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch faculties: $e');
    }
  }

  // Get faculty by ID
  Future<FacultyModel> getFacultyById(int id) async {
    try {
      final response = await _apiService.get(ApiConfig.facultyDetail(id));
      return FacultyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch faculty: $e');
    }
  }

  // Create faculty
  Future<FacultyModel> createFaculty(FacultyModel faculty) async {
    try {
      final response = await _apiService.post(ApiConfig.faculties, faculty.toJson());
      return FacultyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create faculty: $e');
    }
  }

  // Update faculty
  Future<FacultyModel> updateFaculty(int id, FacultyModel faculty) async {
    try {
      final response = await _apiService.put(
        ApiConfig.facultyDetail(id),
        faculty.toJson(),
      );
      return FacultyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update faculty: $e');
    }
  }

  // Delete faculty
  Future<void> deleteFaculty(int id) async {
    try {
      await _apiService.delete(ApiConfig.facultyDetail(id));
    } catch (e) {
      throw Exception('Failed to delete faculty: $e');
    }
  }

  // ============ DEPARTMENT MANAGEMENT ============
  
  // Get all departments
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

  // Get department by ID
  Future<DepartmentModel> getDepartmentById(int id) async {
    try {
      final response = await _apiService.get(ApiConfig.departmentDetail(id));
      return DepartmentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch department: $e');
    }
  }

  // Create department
  Future<DepartmentModel> createDepartment(DepartmentModel department) async {
    try {
      final response = await _apiService.post(
        ApiConfig.departments,
        department.toJson(),
      );
      return DepartmentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create department: $e');
    }
  }

  // Update department
  Future<DepartmentModel> updateDepartment(int id, DepartmentModel department) async {
    try {
      final response = await _apiService.put(
        ApiConfig.departmentDetail(id),
        department.toJson(),
      );
      return DepartmentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update department: $e');
    }
  }

  // Delete department
  Future<void> deleteDepartment(int id) async {
    try {
      await _apiService.delete(ApiConfig.departmentDetail(id));
    } catch (e) {
      throw Exception('Failed to delete department: $e');
    }
  }

  // ============ PROGRAM STUDY MANAGEMENT ============
  
  // Get all program studies
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

  // Get program study by ID
  Future<ProgramStudyModel> getProgramStudyById(int id) async {
    try {
      final response = await _apiService.get(ApiConfig.programStudyDetail(id));
      return ProgramStudyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch program study: $e');
    }
  }

  // Create program study
  Future<ProgramStudyModel> createProgramStudy(ProgramStudyModel programStudy) async {
    try {
      final response = await _apiService.post(
        ApiConfig.programStudies,
        programStudy.toJson(),
      );
      return ProgramStudyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create program study: $e');
    }
  }

  // Update program study
  Future<ProgramStudyModel> updateProgramStudy(int id, ProgramStudyModel programStudy) async {
    try {
      final response = await _apiService.put(
        ApiConfig.programStudyDetail(id),
        programStudy.toJson(),
      );
      return ProgramStudyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update program study: $e');
    }
  }

  // Delete program study
  Future<void> deleteProgramStudy(int id) async {
    try {
      await _apiService.delete(ApiConfig.programStudyDetail(id));
    } catch (e) {
      throw Exception('Failed to delete program study: $e');
    }
  }

  // ============ PERIOD MANAGEMENT ============
  
  // Get all periods
  Future<List<dynamic>> getAllPeriods() async {
    try {
      final response = await _apiService.get(ApiConfig.periodes);
      return response is List ? response : (response['results'] ?? []);
    } catch (e) {
      throw Exception('Failed to fetch periods: $e');
    }
  }

  // Get period by ID
  Future<Map<String, dynamic>> getPeriodById(int id) async {
    try {
      return await _apiService.get(ApiConfig.periodeDetail(id));
    } catch (e) {
      throw Exception('Failed to fetch period: $e');
    }
  }
}
