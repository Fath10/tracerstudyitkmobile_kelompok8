// Role Model
class RoleModel {
  final int id;
  final String name;
  final int? programStudyId;
  final String? programStudyName;

  RoleModel({
    required this.id,
    required this.name,
    this.programStudyId,
    this.programStudyName,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'],
      name: json['name'] ?? '',
      programStudyId: json['program_study'],
      programStudyName: json['program_study_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'program_study': programStudyId,
    };
  }
}

// Program Study Model
class ProgramStudyModel {
  final int id;
  final String name;
  final int? departmentId;
  final String? departmentName;
  final String? facultyName;

  ProgramStudyModel({
    required this.id,
    required this.name,
    this.departmentId,
    this.departmentName,
    this.facultyName,
  });

  factory ProgramStudyModel.fromJson(Map<String, dynamic> json) {
    return ProgramStudyModel(
      id: json['id'],
      name: json['name'] ?? '',
      departmentId: json['department'],
      departmentName: json['department_name'],
      facultyName: json['faculty_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': departmentId,
    };
  }
}

// Faculty Model
class FacultyModel {
  final int id;
  final String name;

  FacultyModel({
    required this.id,
    required this.name,
  });

  factory FacultyModel.fromJson(Map<String, dynamic> json) {
    return FacultyModel(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

// Department Model
class DepartmentModel {
  final int id;
  final String name;
  final int facultyId;
  final String? facultyName;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.facultyId,
    this.facultyName,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'],
      name: json['name'] ?? '',
      facultyId: json['faculty'],
      facultyName: json['faculty_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'faculty': facultyId,
    };
  }
}

// User Model
class UserModel {
  final String id;
  final String username;
  final String? email;
  final String? nim;
  final RoleModel? role;
  final ProgramStudyModel? programStudy;
  final String? address;
  final String? phoneNumber;
  final String lastSurvey;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.nim,
    this.role,
    this.programStudy,
    this.address,
    this.phoneNumber,
    this.lastSurvey = 'none',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'],
      nim: json['nim'],
      role: json['role'] != null && json['role'] is Map
          ? RoleModel.fromJson(json['role'])
          : null,
      programStudy: json['program_study'] != null && json['program_study'] is Map
          ? ProgramStudyModel.fromJson(json['program_study'])
          : null,
      address: json['address'],
      phoneNumber: json['phone_number'],
      lastSurvey: json['last_survey'] ?? 'none',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nim': nim,
      'role': role?.id,
      'program_study': programStudy?.id,
      'address': address,
      'phone_number': phoneNumber,
      'last_survey': lastSurvey,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? nim,
    RoleModel? role,
    ProgramStudyModel? programStudy,
    String? address,
    String? phoneNumber,
    String? lastSurvey,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      nim: nim ?? this.nim,
      role: role ?? this.role,
      programStudy: programStudy ?? this.programStudy,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      lastSurvey: lastSurvey ?? this.lastSurvey,
    );
  }
}
