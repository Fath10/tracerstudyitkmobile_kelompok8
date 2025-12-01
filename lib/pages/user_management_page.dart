import 'package:flutter/material.dart';
import 'employee_directory_page.dart';
import 'login_page.dart';
import 'survey_management_page.dart';
import 'user_form_page.dart';
import 'home_page.dart';
import 'questionnaire_list_page.dart';
import '../services/auth_service.dart';
import '../services/backend_user_service.dart';
import '../models/user_model.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _backendUserService = BackendUserService();
  List<UserModel> users = [];
  List<RoleModel> roles = [];
  List<ProgramStudyModel> programStudies = [];
  bool isLoading = true;
  int currentPage = 1;
  int itemsPerPage = 10;
  String searchQuery = '';
  Set<String> selectedUsers = {}; // Track selected user IDs for checkboxes
  String? selectedRoleFilter; // Filter by role
  String? selectedFakultasFilter; // Filter by fakultas
  bool showFilters = false; // Toggle filter visibility

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    print('📱 UserManagement: Starting data load...');
    setState(() { isLoading = true; });
    
    // Load all data - service methods handle timeouts and return empty lists on error
    final usersResult = await _backendUserService.getAllUsers();
    print('📱 UserManagement: Got ${usersResult.length} users');
    
    final rolesResult = await _backendUserService.getAllRoles();
    print('📱 UserManagement: Got ${rolesResult.length} roles');
    
    final programStudiesResult = await _backendUserService.getAllProgramStudies();
    print('📱 UserManagement: Got ${programStudiesResult.length} program studies');
    
    if (!mounted) return;
    
    setState(() {
      users = usersResult;
      roles = rolesResult;
      programStudies = programStudiesResult;
      isLoading = false;
    });
    
    print('📱 UserManagement: State updated - isLoading=$isLoading, users=${users.length}');
    
    // Determine if we're using cached data (offline mode)
    final bool hasData = usersResult.isNotEmpty || rolesResult.isNotEmpty || programStudiesResult.isNotEmpty;
    
    if (hasData) {
      print('📱 UserManagement: Data loaded - users=${usersResult.length}, roles=${rolesResult.length}, programs=${programStudiesResult.length}');
      // Check if data seems to be from cache (no backend connection)
      // Show info if any of the cached data indicators are present
    } else {
      print('📱 UserManagement: No data available (not even cached)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Backend server is offline and no cached data available'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }

  List<UserModel> get filteredUsers {
    var filtered = users;
    
    // Filter out admin users
    filtered = filtered.where((user) => user.role?.name.toLowerCase() != 'admin').toList();
    
    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final name = user.username.toLowerCase();
        final id = user.id.toLowerCase();
        final email = user.email?.toLowerCase() ?? '';
        final query = searchQuery.toLowerCase();
        return name.contains(query) || id.contains(query) || email.contains(query);
      }).toList();
    }
    
    // Apply role filter
    if (selectedRoleFilter != null && selectedRoleFilter != 'All') {
      filtered = filtered.where((user) => user.role?.name == selectedRoleFilter).toList();
    }
    
    // Apply fakultas filter
    if (selectedFakultasFilter != null && selectedFakultasFilter != 'All') {
      filtered = filtered.where((user) => user.fakultas == selectedFakultasFilter).toList();
    }
    
    return filtered;
  }

  List<UserModel> get paginatedUsers {
    final filtered = filteredUsers;
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filtered.length);
    if (startIndex >= filtered.length) return [];
    return filtered.sublist(startIndex, endIndex);
  }

  int get totalPages {
    final pages = (filteredUsers.length / itemsPerPage).ceil();
    return pages > 0 ? pages : 1;
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.username}?'),
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
        await _backendUserService.deleteUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully'), backgroundColor: Colors.green),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _deleteSelectedUsers() async {
    if (selectedUsers.isEmpty) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Users'),
        content: Text('Are you sure you want to delete ${selectedUsers.length} selected user(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete each selected user
        for (String userId in selectedUsers) {
          await _backendUserService.deleteUser(userId);
        }
        
        setState(() {
          selectedUsers.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected users deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting users: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAddUserDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserFormPage(
          roles: roles,
          programStudies: programStudies,
          onSave: (userOrData) async {
            try {
              await _backendUserService.createUser(userOrData);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User created successfully'), backgroundColor: Colors.green),
                );
                _loadData();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserFormPage(
          user: user,
          roles: roles,
          programStudies: programStudies,
          onSave: (updatedUserOrData) async {
            try {
              await _backendUserService.updateUser(user.id, updatedUserOrData);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User updated successfully'), backgroundColor: Colors.green),
                );
                _loadData();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                );
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              width: 32,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 20),
                );
              },
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tracer Study',
                  style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Sistem Tracking Lulusan',
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (selectedUsers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
              tooltip: 'Delete selected users (${selectedUsers.length})',
              onPressed: _deleteSelectedUsers,
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87, size: 22),
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
                          (AuthService.currentUser?.username ?? 'U').substring(0, 1).toUpperCase(),
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
                      AuthService.currentUser?.nim ?? AuthService.currentUser?.email ?? '11221044',
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
                                Navigator.pop(context);
                                // Already on this page, no navigation needed
                              },
                            ),
                            _buildSubMenuItem(
                              icon: Icons.business_outlined,
                              title: 'Employee Directory',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EmployeeDirectoryPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      // Show Questionnaire section for employees (admin, surveyor, team_prodi)
                      if (AuthService.isAdmin || AuthService.isSurveyor || AuthService.isTeamProdi)
                        _buildExpandableSection(
                          icon: Icons.poll_outlined,
                          title: 'Questionnaire',
                          children: [
                            _buildSubMenuItem(
                              icon: Icons.dashboard_outlined,
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
                            _buildSubMenuItem(
                              icon: Icons.assignment_outlined,
                              title: 'Take Questionnaire',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const QuestionnaireListPage(),
                                  ),
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
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QuestionnaireListPage(),
                              ),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile page coming soon')),
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
      body: Padding(
        padding: EdgeInsets.only(
          bottom: 0, // REMOVED ALL BOTTOM PADDING FOR TESTING
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text('User Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                // Search bar and buttons
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by name, ID, or email',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade600),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic, size: 20, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                            ],
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                            currentPage = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add User Button (+ Icon)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066CC),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: IconButton(
                        onPressed: _showAddUserDialog,
                        icon: const Icon(Icons.add, color: Colors.white, size: 24),
                        tooltip: 'Add User',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        showFilters ? Icons.filter_list : Icons.filter_list_outlined, 
                        color: showFilters ? Colors.blue : Colors.grey.shade700, 
                        size: 22
                      ),
                      onPressed: () {
                        setState(() {
                          showFilters = !showFilters;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Toggle Filters',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.view_column_outlined, color: Colors.grey.shade700, size: 22),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                // Filter dropdowns (shown when showFilters is true)
                if (showFilters) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Filters:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      // Role filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        ),
                        child: DropdownButton<String>(
                          value: selectedRoleFilter,
                          hint: const Text('All Roles', style: TextStyle(fontSize: 12)),
                          underline: const SizedBox(),
                          isDense: true,
                          items: ['All', ...roles.map((r) => r.name).toSet()].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value == 'All' ? null : value,
                              child: Text(value, style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedRoleFilter = newValue;
                              currentPage = 1;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Fakultas filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        ),
                        child: DropdownButton<String>(
                          value: selectedFakultasFilter,
                          hint: const Text('All Fakultas', style: TextStyle(fontSize: 12)),
                          underline: const SizedBox(),
                          isDense: true,
                          items: ['All', 'FSTI', 'FPB', 'FRTI'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value == 'All' ? null : value,
                              child: Text(value, style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedFakultasFilter = newValue;
                              currentPage = 1;
                            });
                          },
                        ),
                      ),
                      const Spacer(),
                      if (selectedRoleFilter != null || selectedFakultasFilter != null)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              selectedRoleFilter = null;
                              selectedFakultasFilter = null;
                              currentPage = 1;
                            });
                          },
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Clear filters',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
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
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Responsive column widths based on screen size
                                final isSmallScreen = constraints.maxWidth < 600;
                                return Table(
                                  columnWidths: isSmallScreen ? const {
                                    0: FixedColumnWidth(30),
                                    1: FlexColumnWidth(2.5),
                                    2: FlexColumnWidth(1.5),
                                    3: FlexColumnWidth(1.2),
                                    4: FlexColumnWidth(1.0),
                                    5: FixedColumnWidth(70),
                                  } : const {
                                    0: FixedColumnWidth(35),
                                    1: FlexColumnWidth(2.2),
                                    2: FlexColumnWidth(1.5),
                                    3: FlexColumnWidth(1.2),
                                    4: FlexColumnWidth(1.0),
                                    5: FixedColumnWidth(80),
                                  },
                                  children: [
                                    TableRow(
                                      children: [
                                        _buildHeaderCell('', isCheckbox: true),
                                        _buildHeaderCell('Name'),
                                        _buildHeaderCell('ID/NIM'),
                                        _buildHeaderCell('Role'),
                                        _buildHeaderCell('Fakultas'),
                                        _buildHeaderCell('Actions'),
                                      ],
                                    ),
                                  ],
                                );
                              }
                            ),
                          ),
                          ...paginatedUsers.asMap().entries.map((entry) {
                            final index = entry.key;
                            final user = entry.value;
                            final isLastRow = index == paginatedUsers.length - 1;
                            return Container(
                              decoration: BoxDecoration(
                                border: Border(bottom: isLastRow ? BorderSide.none : BorderSide(color: Colors.grey.shade300)),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isSmallScreen = constraints.maxWidth < 600;
                                  return Table(
                                    columnWidths: isSmallScreen ? const {
                                      0: FixedColumnWidth(30),
                                      1: FlexColumnWidth(2.5),
                                      2: FlexColumnWidth(1.5),
                                      3: FlexColumnWidth(1.2),
                                      4: FlexColumnWidth(1.0),
                                      5: FixedColumnWidth(70),
                                    } : const {
                                      0: FixedColumnWidth(35),
                                      1: FlexColumnWidth(2.2),
                                      2: FlexColumnWidth(1.5),
                                      3: FlexColumnWidth(1.2),
                                      4: FlexColumnWidth(1.0),
                                      5: FixedColumnWidth(80),
                                    },
                                    children: [
                                    TableRow(
                                      children: [
                                        _buildDataCell('', isCheckbox: true, userId: user.id),
                                        _buildDataCell(user.username),
                                        _buildDataCell(user.nim ?? user.id),
                                        _buildDataCell(user.role?.name ?? '-'),
                                        _buildDataCell(user.fakultas ?? ''),
                                        _buildActionCell(user),
                                      ],
                                    ),
                                    ],
                                  );
                                }
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
          ),
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
                          '${((currentPage - 1) * itemsPerPage) + 1}-${(currentPage * itemsPerPage).clamp(0, filteredUsers.length)} of ${filteredUsers.length}', 
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
                      Text('$currentPage/$totalPages', style: const TextStyle(fontSize: 12)),
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
      ),
    );
  }

  Widget _buildHeaderCell(String text, {bool isCheckbox = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      alignment: Alignment.center,
      child: isCheckbox
          ? Checkbox(
              value: paginatedUsers.isNotEmpty && paginatedUsers.every((user) => selectedUsers.contains(user.id)),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    // Select all users on current page
                    selectedUsers.addAll(paginatedUsers.map((user) => user.id));
                  } else {
                    // Deselect all users on current page
                    for (var user in paginatedUsers) {
                      selectedUsers.remove(user.id);
                    }
                  }
                });
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4)
            )
          : Text(
              text,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
    );
  }

  Widget _buildDataCell(String text, {bool isCheckbox = false, String? userId}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      alignment: Alignment.center,
      child: isCheckbox
          ? Checkbox(
              value: userId != null && selectedUsers.contains(userId),
              onChanged: (value) {
                setState(() {
                  if (value == true && userId != null) {
                    selectedUsers.add(userId);
                  } else if (userId != null) {
                    selectedUsers.remove(userId);
                  }
                });
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4)
            )
          : Text(
              text,
              style: const TextStyle(fontSize: 10, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
    );
  }

  Widget _buildActionCell(UserModel user) {
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
            _showEditUserDialog(user);
          } else if (value == 'delete') {
            _deleteUser(user);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text('Edit', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 16, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Text('Delete', style: TextStyle(fontSize: 13)),
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
