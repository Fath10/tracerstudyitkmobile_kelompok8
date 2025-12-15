import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

/// Role Management Page - Manage user roles and permissions
/// Based on Frontend/caps-fe/src/app/roles/page.tsx
class RoleManagementPage extends StatefulWidget {
  const RoleManagementPage({super.key});

  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage> {
  final _apiService = ApiService();
  List<Role> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() => _isLoading = true);
    
    try {
      final rolesData = await _apiService.get('/accounts/roles/');
      
      setState(() {
        if (rolesData is List) {
          _roles = rolesData.map((json) => Role.fromJson(json)).toList();
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading roles: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading roles: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role Management',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Dashboard / Role Management',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildRoleList(),
    );
  }

  Widget _buildRoleList() {
    if (_roles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 64,
              color: AppTheme.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              'No roles found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Roles (${_roles.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        
        // Role cards
        ..._roles.map((role) => _buildRoleCard(role)),
      ],
    );
  }

  Widget _buildRoleCard(Role role) {
    // Define icon and color based on role name
    IconData icon;
    Color backgroundColor;
    Color iconColor;
    
    switch (role.name.toLowerCase()) {
      case 'admin':
        icon = Icons.admin_panel_settings;
        backgroundColor = AppTheme.danger50;
        iconColor = AppTheme.danger700;
        break;
      case 'surveyor':
        icon = Icons.poll;
        backgroundColor = AppTheme.info50;
        iconColor = AppTheme.info700;
        break;
      case 'team_prodi':
        icon = Icons.groups;
        backgroundColor = AppTheme.warning50;
        iconColor = AppTheme.warning700;
        break;
      case 'alumni':
        icon = Icons.school;
        backgroundColor = AppTheme.success50;
        iconColor = AppTheme.success700;
        break;
      default:
        icon = Icons.person;
        backgroundColor = AppTheme.gray200;
        iconColor = AppTheme.gray700;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            CircleAvatar(
              backgroundColor: backgroundColor,
              radius: 24,
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Role Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${role.id}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRoleDisplayName(role.name),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'surveyor':
        return 'Surveyor';
      case 'team_prodi':
        return 'Team Prodi';
      case 'alumni':
        return 'Alumni';
      default:
        return roleName;
    }
  }
}

// Data Model
class Role {
  final int id;
  final String name;

  Role({required this.id, required this.name});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
    );
  }
}
