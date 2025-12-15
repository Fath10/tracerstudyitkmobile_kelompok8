import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/backend_user_service.dart';
import '../widgets/standard_drawer.dart';
import 'employee_edit_page.dart';
import 'home_page.dart';

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
      final usersData = await _backendUserService.getAllUsers(
        employeesOnly: true,
      );
      print(
        '📱 EmployeeDirectory: Got ${usersData.length} employees from backend',
      );

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
        } else if (filterRole.toLowerCase().contains('surveyor') ||
            filterRole.toLowerCase().contains('tracer')) {
          return role.toLowerCase().contains('surveyor') ||
              role.toLowerCase().contains('tracer');
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
        endDrawer: StandardDrawer(
          employee: null,
          currentRoute: '/employee-directory',
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
                      // Add Employee Button
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066CC),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.person_add,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => _navigateToEmployeeEdit(),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          tooltip: 'Add User',
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
                      : _buildMobileView(),
                ),
                // Pagination Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: _buildMobilePagination(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Mobile View - Table layout with horizontal scroll
  Widget _buildMobileView() {
    if (paginatedEmployees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No employees found',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
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
                  _buildTableHeaderCell('', isCheckbox: true),
                  _buildTableHeaderCell('Name', width: 150),
                  _buildTableHeaderCell('Email', width: 180),
                  _buildTableHeaderCell('Role', width: 120),
                  _buildTableHeaderCell('Program Study', width: 150),
                  _buildTableHeaderCell('Faculty', width: 120),
                  _buildTableHeaderCell('Department', width: 150),
                  _buildTableHeaderCell('Phone', width: 120),
                  _buildTableHeaderCell('Actions', width: 80),
                ],
              ),
            ),
            // Table Rows
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: paginatedEmployees.map((employee) {
                    return _buildTableRow(employee);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Table Header Cell
  Widget _buildTableHeaderCell(
    String text, {
    bool isCheckbox = false,
    double? width,
  }) {
    return Container(
      width: width ?? 40,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
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
                    selectedEmployees.addAll(
                      paginatedEmployees.map((emp) => emp.id),
                    );
                  } else {
                    for (var emp in paginatedEmployees) {
                      selectedEmployees.remove(emp.id);
                    }
                  }
                });
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (text.isNotEmpty)
                  Icon(Icons.unfold_more, size: 14, color: Colors.grey[600]),
              ],
            ),
    );
  }

  // Table Row
  Widget _buildTableRow(UserModel employee) {
    final name = employee.username;
    final email = employee.email ?? '-';
    final employeeId = employee.id;
    final roleName = employee.role?.name ?? '-';
    final role = roleName.toLowerCase().trim();
    final programStudy = employee.programStudy?.name ?? '-';
    final faculty = employee.programStudy?.facultyName ?? '-';
    final department = employee.programStudy?.departmentName ?? '-';
    final phone = employee.phoneNumber ?? '-';

    String roleDisplay = '';
    if (role.contains('admin')) {
      roleDisplay = 'Admin';
    } else if (role.contains('surveyor') || role.contains('tracer')) {
      roleDisplay = 'Team Tracer';
    } else if (role.contains('prodi') || role.contains('team prodi')) {
      roleDisplay = programStudy != '-'
          ? 'Team Prodi ($programStudy)'
          : 'Team Prodi';
    } else if (roleName.isNotEmpty && roleName != '-') {
      roleDisplay = roleName;
    } else {
      roleDisplay = 'Unknown';
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _buildTableCell('', isCheckbox: true, employeeId: employeeId),
          _buildTableCell(name, width: 150),
          _buildTableCell(email, width: 180),
          _buildTableCell(roleDisplay, width: 120),
          _buildTableCell(programStudy, width: 150),
          _buildTableCell(faculty, width: 120),
          _buildTableCell(department, width: 150),
          _buildTableCell(phone, width: 120),
          _buildActionCell(employee, width: 80),
        ],
      ),
    );
  }

  // Table Cell
  Widget _buildTableCell(
    String text, {
    bool isCheckbox = false,
    String? employeeId,
    double? width,
  }) {
    return Container(
      width: width ?? 40,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
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
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
    );
  }

  // Action Cell with popup menu
  Widget _buildActionCell(UserModel employee, {double? width}) {
    return Container(
      width: width ?? 80,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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

  // Mobile Pagination
  Widget _buildMobilePagination() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${((currentPage - 1) * itemsPerPage) + 1}-${(currentPage * itemsPerPage).clamp(0, filteredEmployees.length)} of ${filteredEmployees.length}',
              style: const TextStyle(fontSize: 11),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  style: const TextStyle(fontSize: 11),
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
          ],
        ),
      ],
    );
  }
}
