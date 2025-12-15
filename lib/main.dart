import 'package:flutter/material.dart';
import 'auth/login_page.dart';
import 'auth/splash_screen.dart';
import 'config/app_theme.dart';
import 'pages/dashboard_page.dart';
import 'pages/employee_directory_page.dart';
import 'pages/home_page.dart';
import 'pages/response_data_page.dart';
import 'pages/role_management_page.dart';
import 'pages/survey_management_page.dart';
import 'pages/unit_management_page.dart';
import 'pages/user_profile_page.dart';
import 'services/auth_service.dart';
import 'utils/pages/network_test_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load user from stored session (fast operation)
  await AuthService.loadUser();
  
  runApp(const MyApp());
}

// Removed _createDefaultAdmin() - all data now comes from backend
// No local Drift database needed

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracer Study ITK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const HomePage(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/employee': (context) => const EmployeeDirectoryPage(),
        '/survey': (context) => const SurveyManagementPage(),
        '/response': (context) => const ResponseDataPage(),
        '/unit': (context) => const UnitManagementPage(),
        '/roles': (context) => const RoleManagementPage(),
        '/profile': (context) => const UserProfilePage(),
        '/network-test': (context) => const NetworkTestPage(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes like /employee/add, /employee/:id/edit
        if (settings.name?.startsWith('/employee/') == true) {
          return MaterialPageRoute(
            builder: (context) => const EmployeeDirectoryPage(),
          );
        }
        if (settings.name?.startsWith('/survey/') == true) {
          return MaterialPageRoute(
            builder: (context) => const SurveyManagementPage(),
          );
        }
        return null;
      },
    );
  }
}
