import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class EmployeeEditPage extends StatefulWidget {
  final int? employeeId;
  final Map<String, dynamic>? employee;
  
  const EmployeeEditPage({super.key, this.employeeId, this.employee});

  @override
  State<EmployeeEditPage> createState() => _EmployeeEditPageState();
}

class _EmployeeEditPageState extends State<EmployeeEditPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  late TextEditingController _nikKtpController;
  late TextEditingController _placeOfBirthController;
  late TextEditingController _birthdayController;
  
  // Dropdown values
  String? _selectedDepartment;
  String? _selectedPosition;
  
  // Module permissions
  bool _canAccessUserDirectory = false;
  bool _canAccessEmployeeDirectory = false;
  bool _canAccessReports = false;
  bool _canAccessSettings = false;
  
  String? createdAt;
  String? lastModified;
  bool isNewEmployee = true;
  bool _obscurePassword = true;
  
  // Department options
  final List<String> _departments = [
    'Mitra',
    'Hukitan',
    'Tracer Study',
    'Fakultas FSTI',
    'Matematika',
    'Aktuaria',
  ];
  
  // Position options
  final List<String> _positions = [
    'Pimpinan Unit',
    'Staff',
    'Manager',
    'Coordinator',
    'Director',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    isNewEmployee = widget.employee == null;
    
    _nameController = TextEditingController(
      text: widget.employee?['name']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: widget.employee?['email']?.toString() ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.employee?['password']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.employee?['phone']?.toString() ?? '',
    );
    _nikKtpController = TextEditingController(
      text: widget.employee?['nikKtp']?.toString() ?? '',
    );
    _placeOfBirthController = TextEditingController(
      text: widget.employee?['placeOfBirth']?.toString() ?? '',
    );
    _birthdayController = TextEditingController(
      text: widget.employee?['birthday']?.toString() ?? '',
    );
    
    // Load dropdown values
    _selectedDepartment = widget.employee?['department']?.toString();
    _selectedPosition = widget.employee?['position']?.toString();
    
    // Load module permissions
    _canAccessUserDirectory = widget.employee?['canAccessUserDirectory'] == true || widget.employee?['canAccessUserDirectory'] == 1;
    _canAccessEmployeeDirectory = widget.employee?['canAccessEmployeeDirectory'] == true || widget.employee?['canAccessEmployeeDirectory'] == 1;
    _canAccessReports = widget.employee?['canAccessReports'] == true || widget.employee?['canAccessReports'] == 1;
    _canAccessSettings = widget.employee?['canAccessSettings'] == true || widget.employee?['canAccessSettings'] == 1;
    
    createdAt = widget.employee?['createdAt']?.toString();
    lastModified = widget.employee?['updatedAt']?.toString();
    
    // Format timestamps if they exist
    if (createdAt != null) {
      createdAt = _formatTimestamp(createdAt!);
    }
    if (lastModified != null) {
      lastModified = _formatTimestamp(lastModified!);
    }
  }
  
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return timestamp;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _nikKtpController.dispose();
    _placeOfBirthController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      try {
        final employeeData = {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
          'nikKtp': _nikKtpController.text.isEmpty ? null : _nikKtpController.text,
          'placeOfBirth': _placeOfBirthController.text.isEmpty ? null : _placeOfBirthController.text,
          'birthday': _birthdayController.text.isEmpty ? null : _birthdayController.text,
          'department': _selectedDepartment,
          'position': _selectedPosition,
          'canAccessUserDirectory': _canAccessUserDirectory ? 1 : 0,
          'canAccessEmployeeDirectory': _canAccessEmployeeDirectory ? 1 : 0,
          'canAccessReports': _canAccessReports ? 1 : 0,
          'canAccessSettings': _canAccessSettings ? 1 : 0,
        };
        
        if (isNewEmployee) {
          // Creating new employee
          employeeData['password'] = _passwordController.text;
          await DatabaseHelper.instance.createEmployee(employeeData);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee created successfully')),
          );
        } else {
          // Updating existing employee
          if (_passwordController.text.isNotEmpty) {
            employeeData['password'] = _passwordController.text;
          }
          await DatabaseHelper.instance.updateEmployee(widget.employee!['id'] as int, employeeData);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee updated successfully')),
          );
        }
        
        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: const Text('Are you sure you want to delete this employee? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await DatabaseHelper.instance.deleteEmployee(widget.employee!['id'] as int);
                if (!mounted) return;
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Employee deleted successfully')),
                );
                Navigator.pop(context, true); // Close edit page
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting employee: ${e.toString()}')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
              height: 32,
              width: 32,
              fit: BoxFit.contain,
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
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Sistem Tracking Lulusan',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!isNewEmployee)
            TextButton(
              onPressed: _handleDelete,
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // TabBar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue[700],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.blue[700],
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Personal'),
                Tab(text: 'Module Permissions'),
              ],
            ),
          ),
          // TabBarView
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalTab(),
                  _buildModulePermissionsTab(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Save Employee',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          _buildTextField(
            label: 'Name',
            controller: _nameController,
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter employee name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Email field
          _buildTextField(
            label: 'Email',
            controller: _emailController,
            isRequired: true,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Password field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: 'Password',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    if (isNewEmployee)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  hintText: isNewEmployee ? 'Enter password' : 'Leave empty to keep current password',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (isNewEmployee && (value == null || value.isEmpty)) {
                    return 'Please enter password';
                  }
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Phone field
          _buildTextField(
            label: 'Phone',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          
          // NIK KTP field
          _buildTextField(
            label: 'NIK KTP',
            controller: _nikKtpController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          // Place of Birth field
          _buildTextField(
            label: 'Place of Birth',
            controller: _placeOfBirthController,
          ),
          const SizedBox(height: 16),
          
          // Birthday field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Birthday',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _birthdayController,
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  hintText: 'd-m-yyyy',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
                onTap: _selectDate,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildModulePermissionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Department dropdown
          _buildDropdownField(
            label: 'Department',
            value: _selectedDepartment,
            items: _departments,
            isRequired: true,
            onChanged: (value) {
              setState(() {
                _selectedDepartment = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Position dropdown
          _buildDropdownField(
            label: 'Position',
            value: _selectedPosition,
            items: _positions,
            isRequired: true,
            onChanged: (value) {
              setState(() {
                _selectedPosition = value;
              });
            },
          ),
          const SizedBox(height: 24),
          
          Text(
            'Select which modules this employee can access',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Permission checkboxes
          _buildPermissionCheckbox(
            title: 'User Directory',
            subtitle: 'Allow access to view and manage user directory',
            value: _canAccessUserDirectory,
            onChanged: (value) {
              setState(() {
                _canAccessUserDirectory = value ?? false;
              });
            },
          ),
          const SizedBox(height: 12),
          
          _buildPermissionCheckbox(
            title: 'Employee Directory',
            subtitle: 'Allow access to view and manage employee directory',
            value: _canAccessEmployeeDirectory,
            onChanged: (value) {
              setState(() {
                _canAccessEmployeeDirectory = value ?? false;
              });
            },
          ),
          const SizedBox(height: 12),
          
          _buildPermissionCheckbox(
            title: 'Reports',
            subtitle: 'Allow access to view and generate reports',
            value: _canAccessReports,
            onChanged: (value) {
              setState(() {
                _canAccessReports = value ?? false;
              });
            },
          ),
          const SizedBox(height: 12),
          
          _buildPermissionCheckbox(
            title: 'Settings',
            subtitle: 'Allow access to application settings',
            value: _canAccessSettings,
            onChanged: (value) {
              setState(() {
                _canAccessSettings = value ?? false;
              });
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    bool isRequired = false,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            hintText: 'Select $label',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select $label';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildPermissionCheckbox({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
