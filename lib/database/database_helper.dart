import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tracer_study_itk.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5, // Increment version for responses table
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to employees table
      await db.execute('ALTER TABLE employees ADD COLUMN role TEXT DEFAULT "surveyor"');
      await db.execute('ALTER TABLE employees ADD COLUMN prodi TEXT');
      
      // Set the first employee as admin
      await db.execute('UPDATE employees SET role = "admin" WHERE id = (SELECT MIN(id) FROM employees)');
      
      // Create users table for alumni
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          nikKtp TEXT,
          password TEXT NOT NULL,
          role TEXT NOT NULL DEFAULT "user",
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      // Update the first employee to admin if not already set
      await db.execute('UPDATE employees SET role = "admin" WHERE id = (SELECT MIN(id) FROM employees) AND role != "admin"');
    }
    if (oldVersion < 4) {
      // Add nikKtp column to users table if it doesn't exist
      try {
        await db.execute('ALTER TABLE users ADD COLUMN nikKtp TEXT');
      } catch (e) {
        // Column might already exist, ignore error
      }
      
      // Delete any employees that should be users (cleanup)
      // This removes any incorrectly created user accounts from employees table
      await db.execute('DELETE FROM employees WHERE role = "user"');
    }
    if (oldVersion < 5) {
      // Create responses table to track survey submissions
      await db.execute('''
        CREATE TABLE IF NOT EXISTS responses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          surveyName TEXT NOT NULL,
          userId INTEGER,
          userEmail TEXT NOT NULL,
          userName TEXT NOT NULL,
          answers TEXT NOT NULL,
          submittedAt TEXT NOT NULL
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL DEFAULT 0';

    // Employees table (for surveyor/admin/team prodi)
    await db.execute('''
      CREATE TABLE employees (
        id $idType,
        name $textType,
        email $textType UNIQUE,
        password $textType,
        phone $textTypeNullable,
        nikKtp $textTypeNullable,
        placeOfBirth $textTypeNullable,
        birthday $textTypeNullable,
        department $textTypeNullable,
        position $textTypeNullable,
        role TEXT DEFAULT "surveyor",
        prodi $textTypeNullable,
        canAccessUserDirectory $intType,
        canAccessEmployeeDirectory $intType,
        canAccessReports $intType,
        canAccessSettings $intType,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Users table (for alumni)
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        name $textType,
        email $textType UNIQUE,
        nikKtp $textTypeNullable,
        password $textType,
        role TEXT NOT NULL DEFAULT "user",
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Responses table (for tracking survey submissions)
    await db.execute('''
      CREATE TABLE responses (
        id $idType,
        surveyName $textType,
        userId INTEGER,
        userEmail $textType,
        userName $textType,
        answers $textType,
        submittedAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> createEmployee(Map<String, dynamic> employee) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    employee['createdAt'] = now;
    employee['updatedAt'] = now;
    return await db.insert('employees', employee);
  }

  Future<Map<String, dynamic>?> getEmployeeById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getEmployeeByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'employees',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'employees',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllEmployees() async {
    final db = await instance.database;
    return await db.query('employees', orderBy: 'name ASC');
  }

  Future<int> updateEmployee(int id, Map<String, dynamic> employee) async {
    final db = await instance.database;
    employee['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update(
      'employees',
      employee,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteEmployee(int id) async {
    final db = await instance.database;
    return await db.delete(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    final db = await instance.database;
    return await db.query(
      'employees',
      where: 'name LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
  }

  // User (Alumni) methods
  Future<int> createUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    user['createdAt'] = now;
    user['updatedAt'] = now;
    user['role'] = 'user'; // Always set to 'user' for alumni
    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await instance.database;
    return await db.query('users', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await instance.database;
    user['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Response tracking methods
  Future<int> saveResponse(Map<String, dynamic> response) async {
    final db = await instance.database;
    response['submittedAt'] = DateTime.now().toIso8601String();
    return await db.insert('responses', response);
  }

  Future<List<Map<String, dynamic>>> getResponsesBySurvey(String surveyName) async {
    final db = await instance.database;
    return await db.query(
      'responses',
      where: 'surveyName = ?',
      whereArgs: [surveyName],
      orderBy: 'submittedAt DESC',
    );
  }

  Future<int> getResponseCount(String surveyName) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM responses WHERE surveyName = ?',
      [surveyName],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteAllResponses(String surveyName) async {
    final db = await instance.database;
    return await db.delete(
      'responses',
      where: 'surveyName = ?',
      whereArgs: [surveyName],
    );
  }

  Future<List<Map<String, dynamic>>> getAllResponses() async {
    final db = await instance.database;
    return await db.query('responses', orderBy: 'submittedAt DESC');
  }

  // Universal login method (checks both employees and users)
  Future<Map<String, dynamic>?> universalLogin(String email, String password) async {
    // First check employees table
    final employee = await login(email, password);
    if (employee != null) {
      // Create mutable copy and add accountType
      final mutableEmployee = Map<String, dynamic>.from(employee);
      mutableEmployee['accountType'] = 'employee';
      return mutableEmployee;
    }
    
    // Then check users table
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) {
      // Create mutable copy and add accountType
      final mutableUser = Map<String, dynamic>.from(maps.first);
      mutableUser['accountType'] = 'user';
      return mutableUser;
    }
    
    return null;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
