import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/splash_screen.dart';
import 'pages/network_test_page.dart';
import 'database/database_helper.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load user from stored session (fast operation)
  await AuthService.loadUser();
  
  // Don't block startup for database operations
  // They will run in background
  _createDefaultAdmin();
  
  runApp(const MyApp());
}

Future<void> _createDefaultAdmin() async {
  try {
    // Set timeout for database operations
    final employees = await DatabaseHelper.instance.getAllEmployees().timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        debugPrint('⚠️ Database timeout - skipping admin check');
        return [];
      },
    );
    
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
      debugPrint('✅ Default admin account created');
    }
  } catch (e) {
    debugPrint('⚠️ Error creating default admin: $e');
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
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/network-test': (context) => const NetworkTestPage(),
      },
    );
  }
}
