import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create default admin account if no employees exist
  await _createDefaultAdmin();
  
  runApp(const MyApp());
}

Future<void> _createDefaultAdmin() async {
  try {
    final employees = await DatabaseHelper.instance.getAllEmployees();
    if (employees.isEmpty) {
      // Create default admin account
      await DatabaseHelper.instance.createEmployee({
        'name': 'Administrator',
        'email': 'admin@itk.ac.id',
        'password': 'admin123',
        'phone': '08123456789',
        'nikKtp': null,
        'placeOfBirth': null,
        'canAccessUserDirectory': 1,
        'canAccessEmployeeDirectory': 1,
        'canAccessReports': 1,
        'canAccessSettings': 1,
      });
      debugPrint('Default admin account created: admin@itk.ac.id / admin123');
    }
  } catch (e) {
    debugPrint('Error creating default admin: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracer Study ITK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
