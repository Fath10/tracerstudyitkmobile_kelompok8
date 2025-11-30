import 'package:flutter/material.dart';
import 'employee_directory_page.dart';
import 'login_page.dart';
import 'user_management_page.dart';
import 'home_page.dart';
import 'add_survey_page.dart';
import 'edit_survey_with_sections_page.dart';
import 'take_questionnaire_page.dart';
import 'questionnaire_list_page.dart';
import '../services/survey_storage.dart';
import '../services/auth_service.dart';

class SurveyManagementPage extends StatefulWidget {
  final Map<String, dynamic>? employee;
  
  const SurveyManagementPage({super.key, this.employee});

  @override
  State<SurveyManagementPage> createState() => _SurveyManagementPageState();
}

class _SurveyManagementPageState extends State<SurveyManagementPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Survey data lists
  List<Map<String, dynamic>> customSurveys = SurveyStorage.customSurveys;
  List<Map<String, dynamic>> templateSurveys = [
    {'title': 'Informatics Alumni Survey', 'subtitle': 'Career tracking for Informatics graduates'},
    {'title': 'Chemical Engineering Survey', 'subtitle': 'Industry placement for Chemical Engineering alumni'},
    {'title': 'Mathematics Alumni Survey', 'subtitle': 'Career development for Mathematics graduates'},
    {'title': 'Industrial Engineering Survey', 'subtitle': 'Professional advancement tracking'},
    {'title': 'Environmental Engineering Survey', 'subtitle': 'Environmental sector career survey'},
    {'title': 'Food Technology Survey', 'subtitle': 'Food industry career assessment'},
  ];
  
  // Section management
  List<Map<String, dynamic>> customSections = [];
  String liveSectionTitle = 'Live Questionnaires';
  String templateSectionTitle = 'Template';
  bool isEditingLiveSection = false;
  bool isEditingTemplateSection = false;
  final TextEditingController _liveSectionController = TextEditingController();
  final TextEditingController _templateSectionController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _liveSectionController.text = liveSectionTitle;
    _templateSectionController.text = templateSectionTitle;
  }
  
  @override
  void dispose() {
    _liveSectionController.dispose();
    _templateSectionController.dispose();
    super.dispose();
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
                            (widget.employee?['name']?.toString() ?? 'User').substring(0, 1).toUpperCase(),
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
                        widget.employee?['name']?.toString() ?? 'Your Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // User ID/Email
                      Text(
                        widget.employee?['email']?.toString() ?? '11221044',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
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
                        // Dashboard for employees
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
                        // Show Questionnaire section for employees
                        if (AuthService.isAdmin ||
                            AuthService.isSurveyor ||
                            AuthService.isTeamProdi)
                          _buildExpandableSection(
                            icon: Icons.poll_outlined,
                            title: 'Questionnaire',
                            children: [
                              _buildSubMenuItem(
                                icon: Icons.dashboard_outlined,
                                title: 'Survey Management',
                                onTap: () {
                                  Navigator.pop(context);
                                  // Already on Survey Management page
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
        body: Column(
          children: [
            // Page Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Survey Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Search Bar with Add Button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey[500], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search surveys...',
                                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onChanged: (value) {
                                    // TODO: Implement search functionality
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Create Button (+ Icon)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[600],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddSurveyPage(),
                              ),
                            );
                            
                            if (result != null) {
                              SurveyStorage.addSurvey(result);
                              setState(() {
                                customSurveys = SurveyStorage.customSurveys;
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Survey created successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.add, color: Colors.white, size: 24),
                          tooltip: 'Create Survey',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Questionnaires Section (for tracking user responses)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: isEditingLiveSection
                                    ? TextField(
                                        controller: _liveSectionController,
                                        autofocus: true,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        decoration: const InputDecoration(
                                          border: UnderlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                                        ),
                                        onSubmitted: (value) {
                                          setState(() {
                                            liveSectionTitle = value;
                                            isEditingLiveSection = false;
                                          });
                                        },
                                      )
                                    : Text(
                                        liveSectionTitle,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isEditingLiveSection) {
                                      liveSectionTitle = _liveSectionController.text;
                                    }
                                    isEditingLiveSection = !isEditingLiveSection;
                                  });
                                },
                                child: Icon(
                                  isEditingLiveSection ? Icons.check : Icons.edit,
                                  size: 18,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Text(
                            'Accepting Responses',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These questionnaires are currently accepting responses',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Active Questionnaires Grid (only show live surveys - both default and custom)
                    Builder(
                      builder: (context) {
                        // Combine default surveys and custom surveys, then filter for live ones
                        final allSurveys = SurveyStorage.getAllAvailableSurveys();
                        final liveSurveys = allSurveys
                            .where((survey) => survey['isLive'] == true)
                            .toList();
                        
                        if (liveSurveys.isEmpty) {
                          return Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 32,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No live questionnaires',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Enable "Live Questionnaire" in survey settings',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        return SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: liveSurveys.length,
                            itemBuilder: (context, index) {
                              final survey = liveSurveys[index];
                          
                              return Container(
                                width: 160,
                                margin: const EdgeInsets.only(right: 12),
                                child: Card(
                                  elevation: 2,
                                  color: Colors.green[50],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.green[200]!, width: 1),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      // Navigate to edit page to view responses
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditSurveyWithSectionsPage(
                                            survey: survey,
                                          ),
                                        ),
                                      ).then((_) => setState(() {}));
                                    },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Icon with response indicator
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.assignment_outlined,
                                              size: 22,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green[700],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'LIVE',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      
                                      // Title
                                      Text(
                                        survey['name'] ?? 'Untitled Survey',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      
                                      // Description
                                      Expanded(
                                        child: Text(
                                          survey['description'] ?? 'No description',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      
                                      // Tap indicator
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.analytics_outlined,
                                            size: 14,
                                            color: Colors.green[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Tap to view responses',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Custom Surveys Section (if any exist)
                    if (customSurveys.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Surveys',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('View all custom surveys feature coming soon!')),
                              );
                            },
                            child: Text(
                              'View all',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Custom Surveys Grid
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: customSurveys.length,
                          itemBuilder: (context, index) {
                            final survey = customSurveys[index];
                            
                            return Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              child: Card(
                                elevation: 1,
                                color: Colors.blue[50],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.blue[200]!),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    _takeSurvey(survey);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.blue[100],
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                Icons.poll_outlined,
                                                size: 18,
                                                color: Colors.blue[700],
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              onSelected: (value) {
                                                switch (value) {
                                                  case 'edit':
                                                    _editSurvey(survey, index, isCustom: true);
                                                    break;
                                                  case 'delete':
                                                    _deleteSurvey(index, isCustom: true, surveyName: survey['name']);
                                                    break;
                                                }
                                              },
                                              icon: Icon(
                                                Icons.more_vert,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit_outlined, size: 16),
                                                      SizedBox(width: 8),
                                                      Text('Edit Survey'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('Delete Survey', style: TextStyle(color: Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Text(
                                          survey['name'] as String,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          survey['description'] as String,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                    
                    // Template Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: isEditingTemplateSection
                                    ? TextField(
                                        controller: _templateSectionController,
                                        autofocus: true,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        decoration: const InputDecoration(
                                          border: UnderlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                                        ),
                                        onSubmitted: (value) {
                                          setState(() {
                                            templateSectionTitle = value;
                                            isEditingTemplateSection = false;
                                          });
                                        },
                                      )
                                    : Text(
                                        templateSectionTitle,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isEditingTemplateSection) {
                                      templateSectionTitle = _templateSectionController.text;
                                    }
                                    isEditingTemplateSection = !isEditingTemplateSection;
                                  });
                                },
                                child: Icon(
                                  isEditingTemplateSection ? Icons.check : Icons.edit,
                                  size: 18,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('View all templates feature coming soon!')),
                            );
                          },
                          child: Text(
                            'View all',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Template Cards Grid
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: templateSurveys.length,
                        itemBuilder: (context, index) {
                          final template = templateSurveys[index];
                          
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              elevation: 1,
                              color: Colors.grey[200],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: () {
                                  _takeSurvey(template);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.description_outlined,
                                              size: 18,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              switch (value) {
                                                case 'edit':
                                                  _editSurvey(template, index, isCustom: false);
                                                  break;
                                                case 'delete':
                                                  _deleteSurvey(index, isCustom: false, surveyName: template['title']);
                                                  break;
                                              }
                                            },
                                            icon: Icon(
                                              Icons.more_vert,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit_outlined, size: 16),
                                                    SizedBox(width: 8),
                                                    Text('Edit Survey'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Delete Survey', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text(
                                        template['title'] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        template['subtitle'] as String,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Custom Sections (dynamically created by user)
                    ...customSections.map((section) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Custom Section Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        section['title'] as String,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Colors.blue[600],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    customSections.remove(section);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Section "${section['title']}" deleted'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                                tooltip: 'Delete section',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Custom Section Surveys
                          SizedBox(
                            height: 140,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: (section['surveys'] as List).length,
                              itemBuilder: (context, index) {
                                final survey = (section['surveys'] as List)[index];
                                
                                return Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Card(
                                    elevation: 1,
                                    color: Colors.blue[50],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        _takeSurvey(survey);
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Icon(
                                                    Icons.description_outlined,
                                                    size: 18,
                                                    color: Colors.blue[600],
                                                  ),
                                                ),
                                                PopupMenuButton<String>(
                                                  onSelected: (value) {
                                                    if (value == 'delete') {
                                                      setState(() {
                                                        (section['surveys'] as List).removeAt(index);
                                                      });
                                                    }
                                                  },
                                                  icon: Icon(
                                                    Icons.more_vert,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                  itemBuilder: (context) => [
                                                    const PopupMenuItem(
                                                      value: 'delete',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                                          SizedBox(width: 8),
                                                          Text('Delete'),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const Spacer(),
                                            Text(
                                              survey['title'] as String,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              survey['subtitle'] as String,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[700],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }).toList(),

                    const SizedBox(height: 8),
                    
                    // Add New Section Button
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _showAddSectionDialog,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add New Section'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[600],
                          side: BorderSide(color: Colors.blue[600]!),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  void _editSurvey(Map<String, dynamic> survey, int index, {bool isCustom = false}) async {
    // Convert survey data to match EditSurveyWithSectionsPage expectations
    final surveyData = {
      'name': survey['title'] ?? survey['name'] ?? 'Untitled Survey',
      'title': survey['title'] ?? survey['name'] ?? 'Untitled Survey',
      'description': survey['subtitle'] ?? survey['description'] ?? 'No description',
      'questions': survey['questions'], // Pass the questions data
      'sections': survey['sections'], // Pass sections if available
      'isDefault': survey['isDefault'] ?? false,
      'isTemplate': !isCustom && survey['isDefault'] != true, // Mark as template if not custom and not default
      'isLive': survey['isLive'] ?? false, // Pass live status
    };
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSurveyWithSectionsPage(survey: surveyData),
      ),
    );
    
    if (result != null) {
      if (isCustom) {
        SurveyStorage.updateSurvey(index, result);
        setState(() {
          customSurveys = SurveyStorage.customSurveys;
        });
      } else if (result['isDefault'] == true) {
        // For default surveys, update in storage
        SurveyStorage.updateDefaultSurvey(result['name'], result);
        setState(() {});
      } else {
        // For template surveys, update in storage (not just local)
        SurveyStorage.updateTemplateSurvey(survey['title'] ?? survey['name'], result);
        setState(() {
          // Update local display data
          templateSurveys[index]['title'] = result['name'];
          templateSurveys[index]['subtitle'] = result['description'] ?? templateSurveys[index]['subtitle'];
          templateSurveys[index]['questions'] = result['questions'];
          templateSurveys[index]['isLive'] = result['isLive'] ?? false;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Survey updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _deleteSurvey(int index, {bool isCustom = false, required String surveyName}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Survey'),
          content: Text('Are you sure you want to delete "$surveyName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (isCustom) {
                  SurveyStorage.removeSurvey(index);
                } else {
                  // Template surveys
                  templateSurveys.removeAt(index);
                }
                
                setState(() {
                  if (isCustom) {
                    customSurveys = SurveyStorage.customSurveys;
                  }
                });
                
                Navigator.of(context).pop();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$surveyName deleted successfully!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _takeSurvey(Map<String, dynamic> survey) {
    // Navigate to questionnaire page normally so back button works
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakeQuestionnairePage(
          survey: {
            'name': survey['title'] ?? survey['name'] ?? 'Survey',
            'description': survey['subtitle'] ?? survey['description'] ?? 'Please answer the following questions',
            'questions': survey['questions'], // Pass the actual survey questions
          },
          employee: widget.employee,
        ),
      ),
    );
  }
  
  void _showAddSectionDialog() {
    final TextEditingController sectionNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Section'),
          content: TextField(
            controller: sectionNameController,
            decoration: const InputDecoration(
              labelText: 'Section Name',
              hintText: 'Enter section name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (sectionNameController.text.trim().isNotEmpty) {
                  setState(() {
                    customSections.add({
                      'title': sectionNameController.text.trim(),
                      'surveys': [
                        {
                          'title': 'Sample Survey',
                          'subtitle': 'Template questionnaire for ${sectionNameController.text.trim()}',
                          'questions': SurveyStorage.getDefaultQuestions(),
                          'isTemplate': true,
                          'isLive': false,
                        }
                      ],
                    });
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Section "${sectionNameController.text.trim()}" created with 1 sample survey!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
