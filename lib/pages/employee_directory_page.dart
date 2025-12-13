import 'package:flutter/material.dart';
import 'employee_edit_page.dart';
import 'user_management_page.dart';
import '../auth/login_page.dart';
import 'home_page.dart';
import 'survey_management_page.dart';
import 'take_questionnaire_page.dart';
import 'questionnaire_list_page.dart';
import 'user_profile_page.dart';
import '../services/auth_service.dart';
import '../services/backend_user_service.dart';
import '../services/survey_storage.dart';
import '../models/user_model.dart';

class EmployeeDirectoryPage extends StatefulWidget {
  const EmployeeDirectoryPage({super.key});

  @override
  State<EmployeeDirectoryPage> createState() => _EmployeeDirectoryPageState();
}

class _EmployeeDirectoryPageState extends State<EmployeeDirectoryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _backendUserService = BackendUserService();
  List<UserModel> employees = [];
  bool isLoading = true;
  int currentPage = 1;
  int itemsPerPage = 10;
  String searchQuery = '';
  Set<String> selectedEmployees =
      {}; // Track selected employee IDs for checkboxes
  String? selectedAccessFilter; // Filter by access type
  bool showFilters = false; // Toggle filter visibility

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    if (!mounted) return;

    print('📱 EmployeeDirectory: Starting data load...');
    setState(() {
      isLoading = true;
    });

    try {
      // Load employees (admin/surveyor/team_prodi) from backend
      final usersData = await _backendUserService.getAllUsers(employeesOnly: true);
      print('📱 EmployeeDirectory: Got ${usersData.length} employees from backend');

      if (!mounted) return;

      setState(() {
        employees = usersData;
        isLoading = false;
      });

      print(
        '📱 EmployeeDirectory: State updated - isLoading=$isLoading, employees=${employees.length}',
      );

      if (usersData.isEmpty) {
        print('📱 EmployeeDirectory: No data available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No employee data available'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _loadEmployees,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ EmployeeDirectory: Error loading data: $e');
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading employees: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _loadEmployees,
          ),
        ),
      );
    }
  }

  Future<void> _deleteEmployee(UserModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await _backendUserService.deleteUser(employee.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employee deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadEmployees();
        setState(() {
          selectedEmployees.remove(employee.id);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSelectedEmployees() async {
    if (selectedEmployees.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employees'),
        content: Text(
          'Are you sure you want to delete ${selectedEmployees.length} selected employee(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      for (final id in selectedEmployees) {
        await _backendUserService.deleteUser(id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${selectedEmployees.length} employee(s) deleted successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        selectedEmployees.clear();
      });

      _loadEmployees();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<UserModel> get filteredEmployees {
    var filtered = employees;

    // Backend already filters for employees (admin/surveyor/team_prodi), no need to filter again
    
    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((employee) {
        final name = employee.username.toLowerCase();
        final email = (employee.email ?? '').toLowerCase();
        final query = searchQuery.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    // Apply role filter
    if (selectedAccessFilter != null && selectedAccessFilter != 'All') {
      filtered = filtered.where((employee) {
        final role = employee.role?.name ?? '';
        final filterRole = selectedAccessFilter!;
        
        // Match filter to role (case-insensitive contains check)
        if (filterRole.toLowerCase().contains('admin')) {
          return role.toLowerCase().contains('admin');
        } else if (filterRole.toLowerCase().contains('surveyor') || filterRole.toLowerCase().contains('tracer')) {
          return role.toLowerCase().contains('surveyor') || role.toLowerCase().contains('tracer');
        } else if (filterRole.toLowerCase().contains('prodi')) {
          return role.toLowerCase().contains('prodi');
        }
        
        // Exact match fallback
        return role.toLowerCase() == filterRole.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  List<UserModel> get paginatedEmployees {
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

  Future<void> _navigateToEmployeeEdit({UserModel? employee}) async {
    print('📱 EmployeeDirectory: Navigating to employee edit...');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeEditPage(employee: employee?.toJson()),
      ),
    );

    print('📱 EmployeeDirectory: Returned from edit with result: $result');
    
    // Reload if changes were made
    if (result == true) {
      print('📱 EmployeeDirectory: Reloading employees...');
      await _loadEmployees();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate back to home/dashboard instead of stacking
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
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
                'assets/images/Logo ITK.png',
                height: 18,
                width: 18,
                fit: BoxFit.scaleDown,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 18,
                    width: 18,
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 16,
                    ),
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 9),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (selectedEmployees.isNotEmpty)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 22,
                ),
                tooltip:
                    'Delete selected employees (${selectedEmployees.length})',
                onPressed: _deleteSelectedEmployees,
              ),
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.black87,
                size: 22,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87, size: 22),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
          ],
        ),
        endDrawer: Drawer(
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),

                // User profile section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
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
                            (AuthService.currentUser?.username ?? 'U')
                                .substring(0, 1)
                                .toUpperCase(),
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
                        AuthService.currentUser?.username ?? 'Your Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // User ID/Email
                      Text(
                        AuthService.currentUser?.nim ??
                            AuthService.currentUser?.email ??
                            '11221044',
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
                        // Dashboard for employees (admin, surveyor, team_prodi)
                        if (AuthService.isAdmin ||
                            AuthService.isSurveyor ||
                            AuthService.isTeamProdi)
                          _buildDrawerItem(
                            icon: Icons.dashboard,
                            title: 'Dashboard',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(),
                                ),
                              );
                            },
                          ),

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
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const UserManagementPage(),
                                    ),
                                    (route) => false,
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
                        if (AuthService.isAdmin ||
                            AuthService.isSurveyor ||
                            AuthService.isTeamProdi)
                          _buildExpandableSection(
                            icon: Icons.quiz_outlined,
                            title: 'Questionnaire',
                            children: [
                              _buildSubMenuItem(
                                icon: Icons.dashboard_outlined,
                                title: 'Survey Management',
                                onTap: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SurveyManagementPage(),
                                    ),
                                    (route) => false,
                                  );
                                },
                              ),
                              _buildSubMenuItem(
                                icon: Icons.assignment_outlined,
                                title: 'Take Questionnaire',
                                onTap: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const QuestionnaireListPage(),
                                    ),
                                    (route) => false,
                                  );
                                },
                              ),
                            ],
                          ),

                        // Users (alumni) - show Take Questionnaire option
                        if (AuthService.isUser)
                          _buildDrawerItem(
                            icon: Icons.assignment_outlined,
                            title: 'Take Questionnaire',
                            onTap: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const QuestionnaireListPage(),
                                ),
                                (route) => false,
                              );
                            },
                          ),

                        const Divider(height: 32),

                        // Profile
                        _buildDrawerItem(
                          icon: Icons.person,
                          title: 'My Profile',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UserProfilePage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 8),

                        // Logout
                        _buildDrawerItem(
                          icon: Icons.logout,
                          title: 'Logout',
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
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
        body: RefreshIndicator(
          onRefresh: _loadEmployees,
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Employee Directory',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showFilters)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Role: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedAccessFilter,
                                isExpanded: true,
                                hint: const Text(
                                  'All',
                                  style: TextStyle(fontSize: 12),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      'All',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'Admin',
                                    child: Text(
                                      'Admin',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'Surveyor',
                                    child: Text(
                                      'Surveyor',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'Team_prodi',
                                    child: Text(
                                      'Team Prodi',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedAccessFilter = value;
                                    currentPage = 1;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: 'Clear filters',
                              onPressed: () {
                                setState(() {
                                  selectedAccessFilter = null;
                                  currentPage = 1;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                            suffixIcon: Icon(
                              Icons.mic,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
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
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Add Employee',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          Icons.filter_list,
                          color: showFilters
                              ? Colors.blue
                              : Colors.grey.shade700,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            showFilters = !showFilters;
                          });
                        },
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.view_column_outlined,
                          color: Colors.grey.shade700,
                          size: 20,
                        ),
                        onPressed: () {},
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
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
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  child: Table(
                                    columnWidths: const {
                                      0: FixedColumnWidth(35),
                                      1: FlexColumnWidth(2.2),
                                      2: FlexColumnWidth(1.5),
                                      3: FlexColumnWidth(1.2),
                                      4: FixedColumnWidth(80),
                                    },
                                    children: [
                                      TableRow(
                                        children: [
                                          _buildHeaderCell(
                                            '',
                                            isCheckbox: true,
                                          ),
                                          _buildHeaderCell('Name'),
                                          _buildHeaderCell('Email'),
                                          _buildHeaderCell('Access'),
                                          _buildHeaderCell('Actions'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Table Rows
                                if (paginatedEmployees.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(40),
                                    child: const Center(
                                      child: Text(
                                        'No employees found',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ...paginatedEmployees.map(
                                    (employee) => _buildEmployeeRow(employee),
                                  ),
                              ],
                            ),
                          ),
                        ),
                ),
                // Pagination Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
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
                                  child: Text(
                                    value.toString(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
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
                          const Text(
                            ' entries',
                            style: TextStyle(fontSize: 12),
                          ),
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
                              onPressed: currentPage > 1
                                  ? () => setState(() => currentPage--)
                                  : null,
                              iconSize: 18,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: const EdgeInsets.all(4),
                            ),
                            Text(
                              '$currentPage / $totalPages',
                              style: const TextStyle(fontSize: 12),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: currentPage < totalPages
                                  ? () => setState(() => currentPage++)
                                  : null,
                              iconSize: 18,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
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
        ), // Close SafeArea
      ), // Close RefreshIndicator
    ); // Close Scaffold
  }

  Widget _buildHeaderCell(String text, {bool isCheckbox = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      alignment: Alignment.center,
      child: isCheckbox
          ? Checkbox(
              value:
                  paginatedEmployees.isNotEmpty &&
                  paginatedEmployees.every(
                    (emp) => selectedEmployees.contains(emp.id),
                  ),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    // Select all employees on current page
                    selectedEmployees.addAll(
                      paginatedEmployees.map((emp) => emp.id),
                    );
                  } else {
                    // Deselect all employees on current page
                    for (var emp in paginatedEmployees) {
                      selectedEmployees.remove(emp.id);
                    }
                  }
                });
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            )
          : Text(
              text,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
    );
  }

  Widget _buildEmployeeRow(UserModel employee) {
    final name = employee.username;
    final email = employee.email ?? 'N/A';
    final employeeId = employee.id;
    // Get role and format display
    final roleName = employee.role?.name ?? '';
    final role = roleName.toLowerCase().trim();
    final prodi = employee.programStudy?.name;
    
    print('👤 Employee ${employee.username}: role="$roleName" (normalized: "$role"), prodi=$prodi');

    String roleDisplay = '';
    if (role.contains('admin')) {
      roleDisplay = 'Admin';
    } else if (role.contains('surveyor') || role.contains('tracer')) {
      roleDisplay = 'Team Tracer';
    } else if (role.contains('prodi') || role.contains('team prodi')) {
      roleDisplay = prodi != null ? 'Team Prodi ($prodi)' : 'Team Prodi';
    } else if (roleName.isNotEmpty) {
      // Show the actual role name from backend if it doesn't match known patterns
      roleDisplay = roleName;
    } else {
      roleDisplay = 'Unknown';
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Table(
            columnWidths: const {
              0: FixedColumnWidth(35),
              1: FlexColumnWidth(2.2),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.2),
              4: FixedColumnWidth(80),
            },
            children: [
              TableRow(
                children: [
                  _buildDataCell('', isCheckbox: true, employeeId: employeeId),
                  _buildDataCell(name),
                  _buildDataCell(email),
                  _buildDataCell(roleDisplay),
                  _buildActionCell(employee),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDataCell(
    String text, {
    bool isCheckbox = false,
    String? employeeId,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      alignment: Alignment.center,
      child: isCheckbox
          ? Checkbox(
              value:
                  employeeId != null && selectedEmployees.contains(employeeId),
              onChanged: (value) {
                setState(() {
                  if (value == true && employeeId != null) {
                    selectedEmployees.add(employeeId);
                  } else if (employeeId != null) {
                    selectedEmployees.remove(employeeId);
                  }
                });
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            )
          : Text(
              text,
              style: const TextStyle(fontSize: 10, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
    );
  }

  Widget _buildActionCell(UserModel employee) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
      alignment: Alignment.center,
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade700),
        padding: EdgeInsets.zero,
        iconSize: 18,
        offset: const Offset(0, 40),
        onSelected: (value) {
          if (value == 'edit') {
            _navigateToEmployeeEdit(employee: employee);
          } else if (value == 'delete') {
            _deleteEmployee(employee);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text('Edit', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Delete',
                  style: TextStyle(fontSize: 13, color: Colors.red),
                ),
              ],
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
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        children: children,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showAvailableSurveys() {
    final allSurveys = SurveyStorage.getAllAvailableSurveys();
    final availableSurveys = allSurveys.where((survey) {
      final isLive = survey['isLive'];
      return isLive == true;
    }).toList();

    if (availableSurveys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No questionnaires available at this time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Questionnaires',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: availableSurveys.length,
                itemBuilder: (context, index) {
                  final survey = availableSurveys[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.assignment_outlined,
                          color: Colors.blue[700],
                        ),
                      ),
                      title: Text(
                        survey['name'] ?? 'Untitled Survey',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        survey['description'] ?? 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TakeQuestionnairePage(survey: survey),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
