import 'package:flutter/material.dart';
import '../auth/login_page.dart';
import '../pages/home_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/survey_management_page.dart';
import '../pages/questionnaire_list_page.dart';
import '../pages/employee_directory_page.dart';
import '../pages/user_management_page.dart';
import '../pages/role_management_page.dart';

import '../pages/user_profile_page.dart';
import '../pages/response_data_page.dart';
import '../services/auth_service.dart';

class StandardDrawer extends StatelessWidget {
  final Map<String, dynamic>? employee;
  final String? currentRoute;

  const StandardDrawer({
    super.key,
    this.employee,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final username = AuthService.currentUser?.username ?? 'User';
    final userInitial = username.isNotEmpty ? username.substring(0, 1).toUpperCase() : 'U';
    final userRole = AuthService.currentUser?.role ?? 'user';

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[400]!, Colors.blue[600]!],
          ),
        ),
        child: Column(
          children: [
            // Close button
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 40, right: 16),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // User profile section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        userInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      userRole.toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              color: Colors.white.withOpacity(0.3),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.home_outlined,
                    title: 'Home',
                    route: '/',
                    isActive: currentRoute == '/',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(employee: employee),
                          ),
                        );
                      }
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    route: '/dashboard',
                    isActive: currentRoute == '/dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/dashboard') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashboardPage(),
                          ),
                        );
                      }
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Survey Management',
                    route: '/survey',
                    isActive: currentRoute == '/survey',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/survey') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SurveyManagementPage(employee: employee),
                          ),
                        );
                      }
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.assignment_outlined,
                    title: 'Questionnaires',
                    route: '/questionnaire',
                    isActive: currentRoute == '/questionnaire',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/questionnaire') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuestionnaireListPage(employee: employee),
                          ),
                        );
                      }
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.analytics_outlined,
                    title: 'Response Data',
                    route: '/response',
                    isActive: currentRoute == '/response',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/response') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ResponseDataPage(),
                          ),
                        );
                      }
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.people_outline,
                    title: 'Employee Directory',
                    route: '/employee',
                    isActive: currentRoute == '/employee',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/employee') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmployeeDirectoryPage(),
                          ),
                        );
                      }
                    },
                  ),
                  
                  // Admin only sections
                  if (userRole == 'admin') ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text(
                        'ADMIN',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.manage_accounts_outlined,
                      title: 'User Management',
                      route: '/users',
                      isActive: currentRoute == '/users',
                      onTap: () {
                        Navigator.pop(context);
                        if (currentRoute != '/users') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserProfilePage(),
                            ),
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.security_outlined,
                      title: 'Role Management',
                      route: '/roles',
                      isActive: currentRoute == '/roles',
                      onTap: () {
                        Navigator.pop(context);
                        if (currentRoute != '/roles') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RoleManagementPage(),
                            ),
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.business_outlined,
                      title: 'Unit Management',
                      route: '/units',
                      isActive: currentRoute == '/units',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Unit Management - Coming Soon'),
                          ),
                        );
                        // TODO: Implement UnitManagementPage
                        // if (currentRoute != '/units') {
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) => const UnitManagementPage(),
                        //     ),
                        //   );
                        // }
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Bottom section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile button
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'Profile',
                    route: '/profile',
                    isActive: currentRoute == '/profile',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserProfilePage(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  // Logout button
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await AuthService.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
