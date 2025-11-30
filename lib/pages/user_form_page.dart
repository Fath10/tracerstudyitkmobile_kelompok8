import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserFormPage extends StatefulWidget {
  final UserModel? user;
  final List<RoleModel> roles;
  final List<ProgramStudyModel> programStudies;
  final Function(dynamic) onSave;

  const UserFormPage({
    super.key,
    this.user,
    required this.roles,
    required this.programStudies,
    required this.onSave,
  });

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _usernameController;
  late TextEditingController _nimController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _passwordController;
  
  RoleModel? _selectedRole;
  ProgramStudyModel? _selectedProgramStudy;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.user?.id ?? '');
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _nimController = TextEditingController(text: widget.user?.nim ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.user?.address ?? '');
    
    // Show plain password in edit mode, empty for new user
    _passwordController = TextEditingController(text: widget.user?.plainPassword ?? '');
    
    if (widget.user != null) {
      _selectedRole = widget.user!.role;
      _selectedProgramStudy = widget.user!.programStudy;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _usernameController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userData = {
        'id': _idController.text.trim(),
        'username': _usernameController.text.trim(),
        'nim': _nimController.text.trim().isEmpty ? null : _nimController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'role_id': _selectedRole?.id,  // Use role_id for write operations
        'program_study_id': _selectedProgramStudy?.id,  // Use program_study_id for write operations
      };
      
      // Only send password if user provided one
      // Backend will generate default if not provided
      final password = _passwordController.text.trim();
      if (password.isNotEmpty) {
        userData['password'] = password;
      }
      
      // Pass userData map to preserve password field
      await widget.onSave(userData);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit User' : 'Add User'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
            // User ID field - required for creation (backend uses it as primary key)
            TextFormField(
              controller: _idController,
              enabled: !isEdit, // Editable only when creating
              decoration: InputDecoration(
                labelText: 'User ID (NIM/NIP) *',
                hintText: 'Enter unique ID',
                border: const OutlineInputBorder(),
                helperText: isEdit ? 'Cannot be changed' : 'Used as login username and for password generation',
              ),
              validator: (value) {
                if (!isEdit && (value == null || value.trim().isEmpty)) {
                  return 'User ID is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Full Name
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                hintText: 'Enter full name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter email address',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone (Required for password generation)
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                hintText: 'Enter phone number (required)',
                border: OutlineInputBorder(),
                helperText: 'Used to generate default password',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Password field - always visible, no hiding
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                border: const OutlineInputBorder(),
                helperText: isEdit 
                  ? 'Current password shown, edit to change'
                  : 'Leave blank for default (UserID-PhoneNumber) or enter custom',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 20),

            // Role
            DropdownButtonFormField<RoleModel>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Role',
                border: const OutlineInputBorder(),
                helperText: widget.roles.isEmpty ? 'No roles available' : null,
              ),
              items: widget.roles.isEmpty
                  ? null
                  : widget.roles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.name),
                      );
                    }).toList(),
              onChanged: widget.roles.isEmpty
                  ? null
                  : (value) {
                      setState(() => _selectedRole = value);
                    },
            ),
            const SizedBox(height: 16),

            // Program Studi
            DropdownButtonFormField<ProgramStudyModel>(
              value: _selectedProgramStudy,
              decoration: InputDecoration(
                labelText: 'Program Studi',
                border: const OutlineInputBorder(),
                helperText: widget.programStudies.isEmpty ? 'No program studi available' : null,
              ),
              items: widget.programStudies.isEmpty
                  ? null
                  : widget.programStudies.map((ps) {
                      return DropdownMenuItem(
                        value: ps,
                        child: Text(ps.name),
                      );
                    }).toList(),
              onChanged: widget.programStudies.isEmpty
                  ? null
                  : (value) {
                      setState(() => _selectedProgramStudy = value);
                    },
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Enter address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Password generation info
            if (!isEdit)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Default password will be: UserID-PhoneNumber\n(Example: 11221044-081234567890)',
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isEdit ? 'Update User' : 'Create User'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
