import 'package:flutter/material.dart';
import 'employee_edit_page.dart';
import '../database/database_helper.dart';
import 'user_management_page.dart';
import 'login_page.dart';
import 'survey_management_page.dart';
import '../services/auth_service.dart';

class EmployeeDirectoryPage extends StatefulWidget {
  const EmployeeDirectoryPage({super.key});

  @override
  State<EmployeeDirectoryPage> createState() => _EmployeeDirectoryPageState();
}

class _EmployeeDirectoryPageState extends State<EmployeeDirectoryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> employees = [];
  bool isLoading = true;
  int currentPage = 1;
  int itemsPerPage = 10;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final data = await DatabaseHelper.instance.getAllEmployees();
      setState(() {
        employees = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading employees: ${e.toString()}')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredEmployees {
    if (searchQuery.isEmpty) return employees;
    return employees.where((employee) {
      final name = employee['name']?.toString().toLowerCase() ?? '';
      final email = employee['email']?.toString().toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get paginatedEmployees {
    final filtered = filteredEmployees;
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filtered.length);
    if (startIndex >= filtered.length) return [];
    return filtered.sublist(startIndex, endIndex);
  }

  int get totalPages {
    final pages = (filteredEmployees.length / itemsPerPage).ceil();
    return pages > 0 ? pages : 1;
  }

  Future<void> _navigateToEmployeeEdit({Map<String, dynamic>? employee}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeEditPage(employee: employee),
      ),
    );
    
    // Reload if changes were made
    if (result == true) {
      _loadEmployees();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 28,
              width: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 16),
                );
              },
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tracer Study',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Sistem Tracking Lulusan',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87, size: 20),
            onPressed: () {},
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87, size: 20),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[400]!,
                Colors.blue[600]!,
              ],
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
                          (AuthService.currentUser?['name']?.toString() ?? 'U').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // User name
                    Text(
                      AuthService.currentUser?['name']?.toString() ?? 'Your Name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // User ID/Email
                    Text(
                      AuthService.currentUser?['email']?.toString() ?? '11221044',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Role debug info
                    Text(
                      'Role: ${AuthService.userRole} | Type: ${AuthService.accountType}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Menu items
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    children: [
                      // Only show Unit Directory for admins
                      if (AuthService.isAdmin)
                        _buildExpandableSection(
                          icon: Icons.business_center_outlined,
                          title: 'Unit Directory',
                          children: [
                            _buildSubMenuItem(
                              icon: Icons.folder_outlined,
                              title: 'User Management',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const UserManagementPage(),
                                  ),
                                );
                              },
                            ),
                            _buildSubMenuItem(
                              icon: Icons.business_outlined,
                              title: 'Employee Directory',
                              onTap: () {
                                Navigator.pop(context);
                                // Already on this page, no navigation needed
                              },
                            ),
                          ],
                        ),
                      // Show Questionnaire section for employees (admin, surveyor, team_prodi)
                      if (AuthService.isAdmin || AuthService.isSurveyor || AuthService.isTeamProdi)
                        _buildExpandableSection(
                          icon: Icons.quiz_outlined,
                          title: 'Questionnaire',
                          children: [
                            _buildSubMenuItem(
                              icon: Icons.poll_outlined,
                              title: 'Survey Management',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SurveyManagementPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      // Users (alumni) only see Take Questionnaire (no Survey Management)
                      if (AuthService.isUser)
                        _buildDrawerItem(
                          icon: Icons.assignment_outlined,
                          title: 'Take Questionnaire',
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      const SizedBox(height: 20),
                      _buildDrawerItem(
                        icon: Icons.logout,
                        title: 'Logout',
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Employee Directory', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade600),
                        suffixIcon: Icon(Icons.mic, size: 18, color: Colors.grey.shade600),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                          currentPage = 1;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Add Employee Button (+ Icon)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066CC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: IconButton(
                      onPressed: () => _navigateToEmployeeEdit(),
                      icon: const Icon(Icons.add, color: Colors.white, size: 20),
                      tooltip: 'Add Employee',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.filter_list, color: Colors.grey.shade700, size: 20),
                    onPressed: () {},
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  IconButton(
                    icon: Icon(Icons.view_column_outlined, color: Colors.grey.shade700, size: 20),
                    onPressed: () {},
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            // Table Header
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(flex: 3, child: _buildHeaderCell('Name')),
                                  Expanded(flex: 3, child: _buildHeaderCell('Email')),
                                  Expanded(flex: 2, child: _buildHeaderCell('Access')),
                                  SizedBox(width: 60, child: _buildHeaderCell('Actions')),
                                ],
                              ),
                            ),
                            // Table Rows
                            if (paginatedEmployees.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(40),
                                child: const Center(
                                  child: Text('No employees found', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                ),
                              )
                            else
                              ...paginatedEmployees.map((employee) => _buildEmployeeRow(employee)),
                          ],
                        ),
                      ),
                    ),
            ),
            // Pagination Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Show ', style: TextStyle(fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButton<int>(
                          value: itemsPerPage,
                          underline: const SizedBox(),
                          isDense: true,
                          items: [1, 5, 10, 25, 50, 100].map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString(), style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                itemsPerPage = newValue;
                                currentPage = 1; // Reset to first page
                              });
                            }
                          },
                        ),
                      ),
                      const Text(' entries', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '${((currentPage - 1) * itemsPerPage) + 1} - ${(currentPage * itemsPerPage).clamp(0, filteredEmployees.length)} of ${filteredEmployees.length}', 
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
                          iconSize: 18,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: const EdgeInsets.all(4),
                        ),
                        Text('$currentPage / $totalPages', style: const TextStyle(fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: currentPage < totalPages ? () => setState(() => currentPage++) : null,
                          iconSize: 18,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  Widget _buildEmployeeRow(Map<String, dynamic> employee) {
    final name = employee['name']?.toString() ?? 'Unknown';
    final email = employee['email']?.toString() ?? 'N/A';
    // Get role and format display
    final role = employee['role']?.toString() ?? 'surveyor';
    final prodi = employee['prodi']?.toString();
    
    String accessDisplay = '';
    switch (role) {
      case 'admin':
        accessDisplay = 'Admin';
        break;
      case 'surveyor':
        accessDisplay = 'Team Tracer';
        break;
      case 'team_prodi':
        accessDisplay = prodi != null ? 'Team Prodi ($prodi)' : 'Team Prodi';
        break;
      default:
        accessDisplay = 'Unknown';
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase(),
                        style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(email, style: const TextStyle(fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(accessDisplay, style: const TextStyle(fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis),
            ),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: IconButton(
                icon: Icon(Icons.edit, size: 18, color: Colors.blue[600]),
                onPressed: () => _navigateToEmployeeEdit(employee: employee),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Edit',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: children,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSubMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[600], size: 20),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
