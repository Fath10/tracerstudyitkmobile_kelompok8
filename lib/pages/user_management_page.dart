import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'employee_directory_page.dart';
import 'login_page.dart';
import 'survey_management_page.dart';
import '../services/auth_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  int currentPage = 1;
  int itemsPerPage = 10;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() { isLoading = true; });
    try {
      final data = await DatabaseHelper.instance.getAllUsers();
      setState(() {
        users = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() { isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: ${e.toString()}')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredUsers {
    if (searchQuery.isEmpty) return users;
    return users.where((user) {
      final name = user['name']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get paginatedUsers {
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

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user['name']}?'),
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
        await DatabaseHelper.instance.deleteEmployee(user['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully'), backgroundColor: Colors.green),
          );
        }
        _loadUsers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final nikController = TextEditingController();
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Name *', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Enter name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  contentPadding: const EdgeInsets.all(10),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Email *', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Enter email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  contentPadding: const EdgeInsets.all(10),
                  isDense: true,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              const Text('NIK *', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: nikController,
                decoration: InputDecoration(
                  hintText: 'Enter NIK',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  contentPadding: const EdgeInsets.all(10),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              const Text('Password *', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  hintText: 'Enter password (min. 6 characters)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  contentPadding: const EdgeInsets.all(10),
                  isDense: true,
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              final nik = nikController.text.trim();
              final password = passwordController.text;
              if (name.isEmpty || email.isEmpty || nik.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red),
                );
                return;
              }
              if (!email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid email address'), backgroundColor: Colors.red),
                );
                return;
              }
              if (password.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
                );
                return;
              }
              try {
                await DatabaseHelper.instance.createUser({
                  'name': name,
                  'email': email,
                  'nikKtp': nik,
                  'password': password,
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User created successfully'), backgroundColor: Colors.green),
                  );
                  _loadUsers();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add User'),
          ),
        ],
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
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
                  icon: Icon(Icons.filter_list, color: Colors.grey.shade700, size: 22),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
                                    0: FixedColumnWidth(35),
                                    1: FlexColumnWidth(3),
                                    2: FlexColumnWidth(2),
                                    3: FlexColumnWidth(2),
                                    4: FixedColumnWidth(45),
                                  } : const {
                                    0: FixedColumnWidth(40),
                                    1: FlexColumnWidth(2),
                                    2: FlexColumnWidth(2),
                                    3: FlexColumnWidth(2),
                                    4: FixedColumnWidth(50),
                                  },
                                  children: [
                                    TableRow(
                                      children: [
                                        _buildHeaderCell('', isCheckbox: true),
                                        _buildHeaderCell('Name'),
                                        _buildHeaderCell('NIK'),
                                        _buildHeaderCell('Unit'),
                                        _buildHeaderCell(''),
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
                                      0: FixedColumnWidth(35),
                                      1: FlexColumnWidth(3),
                                      2: FlexColumnWidth(2),
                                      3: FlexColumnWidth(2),
                                      4: FixedColumnWidth(45),
                                    } : const {
                                      0: FixedColumnWidth(40),
                                      1: FlexColumnWidth(2),
                                      2: FlexColumnWidth(2),
                                      3: FlexColumnWidth(2),
                                      4: FixedColumnWidth(50),
                                    },
                                    children: [
                                      TableRow(
                                        children: [
                                          _buildDataCell('', isCheckbox: true),
                                          _buildDataCell(user['name']?.toString() ?? 'Item default'),
                                          _buildDataCell(user['nikKtp']?.toString() ?? 'Item default'),
                                          _buildDataCell('Item default'),
                                          _buildDeleteCell(user),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: isCheckbox
          ? Checkbox(
              value: false, 
              onChanged: (value) {}, 
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, 
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4)
            )
          : Text(
              text, 
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
    );
  }

  Widget _buildDataCell(String text, {bool isCheckbox = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: isCheckbox
          ? Checkbox(
              value: false, 
              onChanged: (value) {}, 
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, 
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4)
            )
          : Text(
              text, 
              style: const TextStyle(fontSize: 11, color: Colors.black87), 
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
    );
  }

  Widget _buildDeleteCell(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        color: Colors.red.shade700,
        onPressed: () => _deleteUser(user),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: 'Delete',
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
