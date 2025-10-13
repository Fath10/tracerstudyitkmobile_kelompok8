import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Employee table definition
class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get email => text().withLength(min: 1, max: 100)();
  TextColumn get password => text().withLength(min: 6, max: 100)();
  TextColumn get phone => text().nullable()();
  TextColumn get nikKtp => text().nullable()();
  TextColumn get placeOfBirth => text().nullable()();
  
  // Module permissions
  BoolColumn get canAccessUserDirectory => boolean().withDefault(const Constant(false))();
  BoolColumn get canAccessEmployeeDirectory => boolean().withDefault(const Constant(false))();
  BoolColumn get canAccessReports => boolean().withDefault(const Constant(false))();
  BoolColumn get canAccessSettings => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Survey table definition
class Surveys extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  IntColumn get createdBy => integer().references(Employees, #id)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Question table definition
class Questions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get surveyId => integer().references(Surveys, #id)();
  TextColumn get questionText => text().withLength(min: 1, max: 500)();
  TextColumn get questionType => text()(); // 'multiple_choice', 'text', 'rating', 'yes_no'
  IntColumn get orderIndex => integer()();
  TextColumn get metadata => text().nullable()(); // JSON string for options, scale, etc.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Response table definition
class Responses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get surveyId => integer().references(Surveys, #id)();
  IntColumn get respondentId => integer().references(Employees, #id).nullable()();
  TextColumn get respondentName => text().nullable()();
  TextColumn get respondentEmail => text().nullable()();
  DateTimeColumn get submittedAt => dateTime().withDefault(currentDateAndTime)();
}

// Answer table definition
class Answers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get responseId => integer().references(Responses, #id)();
  IntColumn get questionId => integer().references(Questions, #id)();
  TextColumn get answerText => text().nullable()();
  IntColumn get answerNumber => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Employees, Surveys, Questions, Responses, Answers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  // Get all employees
  Future<List<Employee>> getAllEmployees() => select(employees).get();

  // Get employee by ID
  Future<Employee?> getEmployeeById(int id) {
    return (select(employees)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  // Get employee by email for login
  Future<Employee?> getEmployeeByEmail(String email) {
    return (select(employees)..where((tbl) => tbl.email.equals(email))).getSingleOrNull();
  }

  // Login validation
  Future<Employee?> login(String email, String password) async {
    final employee = await (select(employees)
          ..where((tbl) => tbl.email.equals(email) & tbl.password.equals(password)))
        .getSingleOrNull();
    return employee;
  }

  // Create new employee
  Future<int> createEmployee(EmployeesCompanion employee) {
    return into(employees).insert(employee);
  }

  // Update employee
  Future<bool> updateEmployee(EmployeesCompanion employee) {
    return update(employees).replace(employee);
  }

  // Delete employee
  Future<int> deleteEmployee(int id) {
    return (delete(employees)..where((tbl) => tbl.id.equals(id))).go();
  }

  // Search employees by name or email
  Future<List<Employee>> searchEmployees(String query) {
    return (select(employees)
          ..where((tbl) =>
              tbl.name.contains(query) | tbl.email.contains(query)))
        .get();
  }

  // Survey methods
  Future<List<Survey>> getAllSurveys() => select(surveys).get();

  Future<Survey?> getSurveyById(int id) {
    return (select(surveys)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<List<Survey>> getSurveysByCreator(int creatorId) {
    return (select(surveys)..where((tbl) => tbl.createdBy.equals(creatorId))).get();
  }

  Future<int> createSurvey(SurveysCompanion survey) {
    return into(surveys).insert(survey);
  }

  Future<bool> updateSurvey(SurveysCompanion survey) {
    return update(surveys).replace(survey);
  }

  Future<int> deleteSurvey(int id) {
    return (delete(surveys)..where((tbl) => tbl.id.equals(id))).go();
  }

  // Question methods
  Future<List<Question>> getQuestionsBySurvey(int surveyId) {
    return (select(questions)
          ..where((tbl) => tbl.surveyId.equals(surveyId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.orderIndex)]))
        .get();
  }

  Future<int> createQuestion(QuestionsCompanion question) {
    return into(questions).insert(question);
  }

  Future<bool> updateQuestion(QuestionsCompanion question) {
    return update(questions).replace(question);
  }

  Future<int> deleteQuestion(int id) {
    return (delete(questions)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> deleteQuestionsBySurvey(int surveyId) {
    return (delete(questions)..where((tbl) => tbl.surveyId.equals(surveyId))).go();
  }

  // Response methods
  Future<int> createResponse(ResponsesCompanion response) {
    return into(responses).insert(response);
  }

  Future<List<Response>> getResponsesBySurvey(int surveyId) {
    return (select(responses)..where((tbl) => tbl.surveyId.equals(surveyId))).get();
  }

  // Answer methods
  Future<int> createAnswer(AnswersCompanion answer) {
    return into(answers).insert(answer);
  }

  Future<List<Answer>> getAnswersByResponse(int responseId) {
    return (select(answers)..where((tbl) => tbl.responseId.equals(responseId))).get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tracer_study_itk.sqlite'));
    return NativeDatabase(file);
  });
}
