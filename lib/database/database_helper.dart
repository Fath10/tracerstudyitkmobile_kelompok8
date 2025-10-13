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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL DEFAULT 0';

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
        canAccessUserDirectory $intType,
        canAccessEmployeeDirectory $intType,
        canAccessReports $intType,
        canAccessSettings $intType,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
