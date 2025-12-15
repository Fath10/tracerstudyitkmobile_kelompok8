import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_page.dart';
import '../services/auth_service.dart';
import '../services/backend_survey_service.dart';
import '../services/survey_storage.dart';
import '../widgets/standard_drawer.dart';
import 'employee_directory_page.dart';
import 'google_forms_style_survey_editor.dart';
import 'home_page.dart';
import 'questionnaire_list_page.dart';
import 'take_questionnaire_page.dart';
import 'user_management_page.dart';
import 'user_profile_page.dart';

class SurveyManagementPage extends StatefulWidget {
  final Map<String, dynamic>? employee;

  const SurveyManagementPage({super.key, this.employee});

  @override
  State<SurveyManagementPage> createState() => _SurveyManagementPageState();
}

class _SurveyManagementPageState extends State<SurveyManagementPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _surveyService = BackendSurveyService();
  bool _isLoadingSurveys = false;
  bool _hasShownBackendError = false;

  // Survey data lists - ALL from backend now
  List<Map<String, dynamic>> customSurveys = [];
  List<Map<String, dynamic>> templateSurveys = [];

  // Category management
  List<Map<String, dynamic>> customSections = [];
  
  Future<void> _saveCustomSections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sectionsJson = jsonEncode(customSections);
      await prefs.setString('custom_sections', sectionsJson);
      print('💾 Custom categories saved to local storage');
    } catch (e) {
      print('❌ Error saving custom categories: $e');
    }
  }
  
  Future<void> _loadCustomSections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sectionsJson = prefs.getString('custom_sections');
      if (sectionsJson != null) {
        final List<dynamic> decoded = jsonDecode(sectionsJson);
        setState(() {
          customSections = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
        print('📂 Loaded ${customSections.length} custom categories from local storage');
      }
    } catch (e) {
      print('❌ Error loading custom categories: $e');
    }
  }
  String liveSectionTitle = 'Live Questionnaires';
  String templateSectionTitle = 'Template';
  bool isEditingLiveSection = false;
  bool isEditingTemplateSection = false;
  final TextEditingController _liveSectionController = TextEditingController();
  final TextEditingController _templateSectionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _liveSectionController.text = liveSectionTitle;
    _templateSectionController.text = templateSectionTitle;
    _loadCustomSections();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSurveys = true;
    });

    try {
      print('📋 Loading surveys from backend...');

      // Load from backend
      final backendSurveys = await _surveyService.getAllSurveys();
      print('   Fetched ${backendSurveys.length} surveys from backend');
      
      // Load template surveys from SurveyStorage
      final allSurveys = SurveyStorage.getAllAvailableSurveys();
      final templates = allSurveys.where((s) => s['isTemplate'] == true).toList();
      print('   Loaded ${templates.length} template surveys from SurveyStorage');

      if (!mounted) return;

      setState(() {
        // Combine backend surveys and templates
        customSurveys = backendSurveys.map((s) => Map<String, dynamic>.from(s as Map)).toList();
        
        // Add templates to customSurveys if they have isLive = true
        for (var template in templates) {
          if (template['isLive'] == true) {
            customSurveys.add({
              ...template,
              'is_active': true, // Mark as active for live questionnaires
              'isTemplate': true,
            });
          }
        }
        
        print('   Total surveys (backend + templates): ${customSurveys.length}');
        templateSurveys = [];
        _isLoadingSurveys = false;
      });

      print('✅ Loaded ${customSurveys.length} backend surveys');
    } catch (e) {
      print('❌ Error loading surveys: $e');

      if (!mounted) return;

      setState(() {
        customSurveys = [];
        templateSurveys = [];
        _isLoadingSurveys = false;
      });

      // Show error message
      if (!_hasShownBackendError) {
        _hasShownBackendError = true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load surveys from backend: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _hasShownBackendError = false;
                _loadSurveys();
              },
            ),
          ),
        );
      }
    }
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
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(employee: widget.employee),
                ),
              );
            },
          ),
          title: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  'assets/images/Logo ITK.png',
                  height: 24,
                  width: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 24,
                      width: 24,
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          actions: [
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
          employee: widget.employee,
          currentRoute: '/survey-management',
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

                  // Search Bar
                  Container(
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
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              // TODO: Implement search functionality
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoadingSurveys
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadSurveys,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
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
                                                controller:
                                                    _liveSectionController,
                                                autofocus: true,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                      border:
                                                          UnderlineInputBorder(),
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 4,
                                                          ),
                                                    ),
                                                onSubmitted: (value) {
                                                  setState(() {
                                                    liveSectionTitle = value;
                                                    isEditingLiveSection =
                                                        false;
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
                                      PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.more_vert,
                                          size: 18,
                                          color: Colors.grey[700],
                                        ),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                  color: Colors.blue[700],
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  isEditingLiveSection
                                                      ? 'Save'
                                                      : 'Edit Name',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: Colors.red[700],
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Delete Category',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.red[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'add_survey',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.add_circle_outline,
                                                  size: 18,
                                                  color: Colors.green[700],
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Add Survey',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            setState(() {
                                              if (isEditingLiveSection) {
                                                liveSectionTitle =
                                                    _liveSectionController.text;
                                              }
                                              isEditingLiveSection =
                                                  !isEditingLiveSection;
                                            });
                                          } else if (value == 'delete') {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) =>
                                                  AlertDialog(
                                                    title: const Text(
                                                      'Delete Category',
                                                    ),
                                                    content: const Text(
                                                      'Are you sure you want to delete this category?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Cannot delete default category',
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: const Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                          } else if (value == 'add_survey') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    GoogleFormsStyleSurveyEditor(
                                                      survey: {
                                                        'name': 'New Survey',
                                                        'description':
                                                            'Survey description',
                                                        'sections': [],
                                                        'isLive': false,
                                                      },
                                                    ),
                                              ),
                                            ).then((result) async {
                                              if (result != null &&
                                                  result
                                                      is Map<String, dynamic>) {
                                                // Save new survey to backend
                                                try {
                                                  final savedSurvey =
                                                      await _surveyService
                                                          .createSurvey(result);
                                                  print(
                                                    'DEBUG [SURVEY MANAGEMENT]: New survey saved to backend with ID: ${savedSurvey['id']}',
                                                  );

                                                  // Reload surveys to show the new one
                                                  await _loadSurveys();

                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Survey created successfully!',
                                                        ),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  print(
                                                    'DEBUG [SURVEY MANAGEMENT]: Failed to save new survey to backend: $e',
                                                  );
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Warning: Survey created locally only. Could not save to server.',
                                                        ),
                                                        backgroundColor:
                                                            Colors.orange,
                                                      ),
                                                    );
                                                  }
                                                  setState(
                                                    () {},
                                                  ); // Refresh UI with local data
                                                }
                                              }
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green[200]!,
                                    ),
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
                                // Show backend surveys that are active (is_active == true)
                                final liveSurveys = customSurveys
                                    .where((survey) => survey['is_active'] == true)
                                    .toList();

                                if (liveSurveys.isEmpty) {
                                  return Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: Card(
                                          elevation: 2,
                                          color: Colors.green[50],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            side: BorderSide(
                                              color: Colors.green[200]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: InkWell(
                                            onTap: () async {
                                              // Navigate to Take Questionnaire Page
                                              print(
                                                'DEBUG [LIVE SURVEY]: Opening survey: ${survey['title'] ?? survey['name']}',
                                              );
                                              
                                              // For template surveys, navigate directly to take questionnaire
                                              if (survey['isTemplate'] == true) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => TakeQuestionnairePage(
                                                      survey: survey,
                                                      employee: widget.employee,
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              
                                              // Check if survey has backend ID
                                              if (survey['id'] == null) {
                                                // Local survey without backend ID - navigate to take questionnaire
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => TakeQuestionnairePage(
                                                      survey: survey,
                                                      employee: widget.employee,
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              
                                              // Show loading indicator
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (context) => const Center(
                                                  child: CircularProgressIndicator(),
                                                ),
                                              );
                                              
                                              try {
                                                // Fetch full survey with sections and questions from backend
                                                final fullSurvey = await _surveyService.getSurveyById(survey['id']);
                                                
                                                // Close loading indicator
                                                if (mounted) Navigator.pop(context);
                                                
                                                // Navigate to take questionnaire page
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => TakeQuestionnairePage(
                                                      survey: fullSurvey,
                                                      employee: widget.employee,
                                                    ),
                                                  ),
                                                );

                                                setState(() {});
                              } catch (e) {
                                                // Close loading indicator if still open
                                                if (mounted && Navigator.canPop(context)) {
                                                  Navigator.pop(context);
                                                }
                                                
                                                print('❌ Failed to load survey: $e');
                                                
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Failed to load survey: $e'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(14),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Icon with response indicator
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors.green[100],
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Icon(
                                                          Icons
                                                              .assignment_outlined,
                                                          size: 22,
                                                          color:
                                                              Colors.green[700],
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors.green[700],
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          'LIVE',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const Spacer(),

                                                  // Title
                                                  Text(
                                                    survey['name'] ??
                                                        'Untitled Survey',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),

                                                  // Description
                                                  Expanded(
                                                    child: Text(
                                                      survey['description'] ??
                                                          'No description',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                      ),
                                                      maxLines: 4,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),

                                                  // Tap indicator
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .analytics_outlined,
                                                        size: 14,
                                                        color:
                                                            Colors.green[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Tap to view responses',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Colors.green[700],
                                                          fontWeight:
                                                              FontWeight.w500,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'View all custom surveys feature coming soon!',
                                          ),
                                        ),
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: BorderSide(
                                            color: Colors.blue[200]!,
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            _takeSurvey(survey);
                                          },
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue[100],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons.poll_outlined,
                                                        size: 18,
                                                        color: Colors.blue[700],
                                                      ),
                                                    ),
                                                    PopupMenuButton<String>(
                                                      padding: EdgeInsets.zero,
                                                      onSelected: (value) {
                                                        switch (value) {
                                                          case 'edit':
                                                            _editSurvey(
                                                              survey,
                                                              index,
                                                              isCustom: true,
                                                            );
                                                            break;
                                                          case 'delete':
                                                            _deleteSurvey(
                                                              index,
                                                              isCustom: true,
                                                              surveyName:
                                                                  survey['title'] ?? survey['name'] ?? 'Untitled',
                                                              surveyId:
                                                                  survey['id'],
                                                            );
                                                            break;
                                                        }
                                                      },
                                                      icon: Icon(
                                                        Icons.more_vert,
                                                        size: 18,
                                                        color: Colors.grey[700],
                                                      ),
                                                      itemBuilder: (context) => [
                                                        PopupMenuItem(
                                                          value: 'edit',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .edit_outlined,
                                                                size: 18,
                                                                color: Colors
                                                                    .blue[700],
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              const Text(
                                                                'Edit',
                                                                style:
                                                                    TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        PopupMenuItem(
                                                          value: 'delete',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .delete_outline,
                                                                size: 18,
                                                                color: Colors
                                                                    .red[700],
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text(
                                                                'Delete',
                                                                style: TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .red[700],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const Spacer(),
                                                Text(
                                                  (survey['title'] ?? survey['name'] ?? 'Untitled') as String,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  (survey['description'] ?? '') as String,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[600],
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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

                            // Template Section REMOVED (templates now shown in Live Questionnaires if isLive=true)

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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[50],
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                    ),
                                                    child: Icon(
                                                      Icons.description,
                                                      size: 18,
                                                      color: Colors.blue[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Spacer(),
                                              Text(
                                                template['title']?.toString() ??
                                                    'Untitled',
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
                                                template['subtitle']
                                                        ?.toString() ??
                                                    'No description',
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
                                  // Custom Category Header
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.more_vert,
                                          size: 18,
                                          color: Colors.grey[700],
                                        ),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                  color: Colors.blue[700],
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Edit Name',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.delete_outline,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Delete Category',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'add_survey',
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.add_circle_outline,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text('Add Survey'),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) async {
                                          if (value == 'edit') {
                                            _showEditSectionDialog(section);
                                          } else if (value == 'delete') {
                                            _deleteSection(section);
                                          } else if (value == 'add_survey') {
                                            // Add new survey to this custom category
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    GoogleFormsStyleSurveyEditor(
                                                      survey: {
                                                        'name': 'New Survey',
                                                        'description':
                                                            'Survey description',
                                                        'sections': [],
                                                        'isLive': false,
                                                      },
                                                    ),
                                              ),
                                            ).then((result) async {
                                              if (result != null &&
                                                  result
                                                      is Map<String, dynamic>) {
                                                // Save new survey to backend
                                                try {
                                                  final savedSurvey =
                                                      await _surveyService
                                                          .createSurvey(result);
                                                  print(
                                                    'DEBUG [SURVEY MANAGEMENT]: New survey saved to backend with ID: ${savedSurvey['id']}',
                                                  );

                                                  // Reload surveys to show the new one
                                                  await _loadSurveys();

                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Survey created successfully!',
                                                        ),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  print(
                                                    'DEBUG [SURVEY MANAGEMENT]: Failed to save new survey to backend: $e',
                                                  );
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Warning: Survey created locally only. Could not save to server.',
                                                        ),
                                                        backgroundColor:
                                                            Colors.orange,
                                                      ),
                                                    );
                                                  }
                                                  setState(
                                                    () {},
                                                  ); // Refresh UI with local data
                                                }
                                              }
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Custom Category Survey Cards Grid
                                  SizedBox(
                                    height: 140,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: (section['surveys'] as List?)?.length ?? 0,
                                      itemBuilder: (context, index) {
                                        final surveys = section['surveys'] as List?;
                                        if (surveys == null || index >= surveys.length) {
                                          return const SizedBox.shrink();
                                        }
                                        final survey = surveys[index];

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
                                                _takeSurvey(survey);
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Padding(
                                                padding: const EdgeInsets.all(12),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Container(
                                                          width: 32,
                                                          height: 32,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .description_outlined,
                                                      size: 18,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  PopupMenuButton<String>(
                                                    onSelected: (value) {
                                                      switch (value) {
                                                        case 'edit':
                                                          _editSurvey(
                                                            survey,
                                                            index,
                                                            isCustom: false,
                                                          );
                                                          break;
                                                        case 'delete':
                                                          _deleteSurvey(
                                                            index,
                                                            isCustom: false,
                                                            surveyName:
                                                                survey['title'],
                                                            surveyId:
                                                                survey['id'],
                                                          );
                                                          break;
                                                        case 'add_questionnaire':
                                                          _takeSurvey(survey);
                                                          break;
                                                      }
                                                    },
                                                    icon: Icon(
                                                      Icons.more_vert,
                                                      size: 18,
                                                      color: Colors.grey[700],
                                                    ),
                                                    itemBuilder: (context) => [
                                                      PopupMenuItem(
                                                        value: 'edit',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .edit_outlined,
                                                              size: 18,
                                                              color: Colors
                                                                  .blue[700],
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            const Text(
                                                              'Edit',
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value:
                                                            'add_questionnaire',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .add_circle_outline,
                                                              size: 18,
                                                              color: Colors
                                                                  .green[700],
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            const Text(
                                                              'Take Survey',
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .delete_outline,
                                                              size: 18,
                                                              color: Colors
                                                                  .red[700],
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Text(
                                                              'Delete',
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                color: Colors
                                                                    .red[700],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const Spacer(),
                                              Text(
                                                survey['title']?.toString() ??
                                                    (survey['name']?.toString() ?? 'Untitled'),
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
                                                survey['description']
                                                        ?.toString() ??
                                                    'No description',
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
                              );
                            }).toList(),

                            const SizedBox(height: 8),

                            // Add New Section Button
                            ...customSections.map((section) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Custom Category Header
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                            const SizedBox(width: 4),
                                            PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.more_vert,
                                          size: 18,
                                          color: Colors.grey[700],
                                        ),
                                        onSelected: (value) async {
                                          if (value == 'edit') {
                                            _showEditSectionDialog(section);
                                          } else if (value == 'delete') {
                                            _deleteSection(section);
                                          } else if (value == 'add_survey') {
                                            // Add new survey to this custom category
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    GoogleFormsStyleSurveyEditor(
                                                      survey: {
                                                        'name': 'New Survey',
                                                        'description':
                                                            'Survey description',
                                                        'sections': [],
                                                        'isLive': false,
                                                      },
                                                    ),
                                              ),
                                            );

                                            if (result != null &&
                                                result
                                                    is Map<String, dynamic>) {
                                              // Save to backend
                                              try {
                                                final savedSurvey =
                                                    await _surveyService
                                                        .createSurvey(result);
                                                print(
                                                  'DEBUG [SURVEY MANAGEMENT]: New survey saved to backend with ID: ${savedSurvey['id']}',
                                                );

                                                // Reload surveys from backend to get updated list
                                                await _loadSurveys();
                                                
                                                // Also add to custom category locally
                                                setState(() {
                                                  (section['surveys'] as List).add({
                                                    ...savedSurvey,
                                                    'title':
                                                        savedSurvey['name'],
                                                    'subtitle':
                                                        savedSurvey['description'],
                                                  });
                                                });
                                                _saveCustomSections();

                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Survey added successfully!',
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                print(
                                                  'DEBUG [SURVEY MANAGEMENT]: Failed to save survey: $e',
                                                );
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Failed to add survey: $e',
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                  color: Colors.blue[700],
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Edit',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'add_survey',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.add_circle_outline,
                                                  size: 18,
                                                  color: Colors.green[700],
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Add Survey',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: Colors.red[700],
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.red[700],
                                                  ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),                                  // Custom Category Surveys
                                  SizedBox(
                                    height: 140,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount:
                                          (section['surveys'] as List).length,
                                      itemBuilder: (context, index) {
                                        final survey =
                                            (section['surveys'] as List)[index];

                                        return Container(
                                          width: 120,
                                          margin: const EdgeInsets.only(
                                            right: 12,
                                          ),
                                          child: Card(
                                            elevation: 1,
                                            color: Colors.blue[50],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                _takeSurvey(survey);
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Icon and menu in same row
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Container(
                                                          width: 32,
                                                          height: 32,
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          child: Icon(
                                                            Icons
                                                                .description_outlined,
                                                            size: 18,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                        PopupMenuButton<String>(
                                                          padding:
                                                              EdgeInsets.zero,
                                                          iconSize: 18,
                                                          icon: Icon(
                                                            Icons.more_vert,
                                                            size: 18,
                                                            color: Colors.grey[700],
                                                          ),
                                                          onSelected: (value) async {
                                                            if (value ==
                                                                'edit') {
                                                              // Check if survey has backend ID
                                                              if (survey['id'] == null) {
                                                                // Local survey without backend ID - open directly
                                                                final result = await Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (context) =>
                                                                        GoogleFormsStyleSurveyEditor(
                                                                          survey: survey,
                                                                        ),
                                                                  ),
                                                                );
                                                                
                                                                if (result != null) {
                                                                  setState(() {
                                                                    (section['surveys'] as List)[index] = {
                                                                      ...result,
                                                                      'title': result['name'],
                                                                      'subtitle': result['description'],
                                                                    };
                                                                  });
                                                                }
                                                                return;
                                                              }
                                                              
                                                              // Load full survey with sections and questions
                                                              showDialog(
                                                                context: context,
                                                                barrierDismissible: false,
                                                                builder: (context) => const Center(
                                                                  child: CircularProgressIndicator(),
                                                                ),
                                                              );
                                                              
                                                              try {
                                                                // Fetch full survey with sections and questions from backend
                                                                final fullSurvey = await _surveyService.getSurveyById(survey['id']);
                                                                
                                                                // Close loading indicator
                                                                if (mounted) Navigator.pop(context);
                                                                
                                                                // Edit survey
                                                                final result = await Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (context) => GoogleFormsStyleSurveyEditor(
                                                                      survey: {
                                                                        ...fullSurvey,
                                                                        'name': fullSurvey['title'],
                                                                        'isLive': fullSurvey['is_active'] ?? false,
                                                                      },
                                                                    ),
                                                                  ),
                                                                );

                                                                if (result !=
                                                                        null &&
                                                                    result
                                                                        is Map<
                                                                          String,
                                                                          dynamic
                                                                        >) {
                                                                  // Update in backend if has ID
                                                                  if (survey['id'] !=
                                                                      null) {
                                                                    try {
                                                                      await _surveyService
                                                                          .updateSurvey(
                                                                            survey['id'],
                                                                            result,
                                                                          );
                                                                      print(
                                                                        'DEBUG [SURVEY MANAGEMENT]: Survey updated in backend',
                                                                      );
                                                                    } catch (e) {
                                                                      print(
                                                                        'DEBUG [SURVEY MANAGEMENT]: Failed to update survey: $e',
                                                                      );
                                                                    }
                                                                  }

                                                                  // Update in UI
                                                                  setState(() {
                                                                    (section['surveys']
                                                                        as List)[index] = {
                                                                      ...result,
                                                                      'title':
                                                                          result['name'],
                                                                      'subtitle':
                                                                          result['description'],
                                                                    };
                                                                  });

                                                                  if (mounted) {
                                                                    ScaffoldMessenger.of(
                                                                      context,
                                                                    ).showSnackBar(
                                                                      const SnackBar(
                                                                        content: Text(
                                                                          'Survey updated successfully!',
                                                                        ),
                                                                        backgroundColor:
                                                                            Colors
                                                                                .green,
                                                                      ),
                                                                    );
                                                                  }
                                                                }
                                                              } catch (e) {
                                                                // Close loading indicator if still open
                                                                if (mounted && Navigator.canPop(context)) {
                                                                  Navigator.pop(context);
                                                                }
                                                                
                                                                print('❌ Failed to load survey: $e');
                                                                
                                                                if (mounted) {
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    SnackBar(
                                                                      content: Text('Failed to load survey: $e'),
                                                                      backgroundColor: Colors.red,
                                                                    ),
                                                                  );
                                                                }
                                                              }
                                                            } else if (value ==
                                                                'delete') {
                                                              // Delete survey from backend if has ID
                                                              if (survey['id'] !=
                                                                  null) {
                                                                try {
                                                                  await _surveyService
                                                                      .deleteSurvey(
                                                                        survey['id'],
                                                                      );
                                                                  print(
                                                                    'DEBUG [SURVEY MANAGEMENT]: Survey deleted from backend',
                                                                  );
                                                                } catch (e) {
                                                                  print(
                                                                    'DEBUG [SURVEY MANAGEMENT]: Failed to delete from backend: $e',
                                                                  );
                                                                }
                                                              }

                                                              // Remove from UI
                                                              setState(() {
                                                                (section['surveys']
                                                                        as List)
                                                                    .removeAt(
                                                                      index,
                                                                    );
                                                              });

                                                              if (mounted) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  const SnackBar(
                                                                    content: Text(
                                                                      'Survey deleted successfully!',
                                                                    ),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .orange,
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                          },
                                                          itemBuilder: (context) => [
                                                            PopupMenuItem(
                                                              value: 'edit',
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .edit_outlined,
                                                                    size: 18,
                                                                    color: Colors
                                                                        .blue[700],
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  const Text(
                                                                    'Edit',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            PopupMenuItem(
                                                              value: 'delete',
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .delete_outline,
                                                                    size: 18,
                                                                    color: Colors
                                                                        .red[700],
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Text(
                                                                    'Delete',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      color: Colors
                                                                          .red[700],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      survey['title']
                                                              ?.toString() ??
                                                          survey['name']?.toString() ??
                                                          'Untitled',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                        color: Colors.black87,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      survey['subtitle']
                                                              ?.toString() ??
                                                          survey['description']
                                                              ?.toString() ??
                                                          '',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey[600],
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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

                            // Add New Category Button
                            Center(
                              child: OutlinedButton.icon(
                                onPressed: _showAddSectionDialog,
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Add New Category'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue[600],
                                  side: BorderSide(color: Colors.blue[600]!),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSectionDialog(Map<String, dynamic> section) {
    final controller = TextEditingController(text: section['title']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  section['title'] = controller.text.trim();
                });
                _saveCustomSections();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Section updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteSection(Map<String, dynamic> section) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${section['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                customSections.remove(section);
              });
              _saveCustomSections();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Category "${section['title']}" deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editSurvey(
    Map<String, dynamic> survey,
    int index, {
    bool isCustom = false,
  }) async {
    // Convert survey data to match GoogleFormsStyleSurveyEditor expectations
    final surveyData = {
      'id': survey['id'], // Include survey ID for backend updates
      'name': survey['title'] ?? survey['name'] ?? 'Untitled Survey',
      'title': survey['title'] ?? survey['name'] ?? 'Untitled Survey',
      'description':
          survey['subtitle'] ?? survey['description'] ?? 'No description',
      'questions': survey['questions'], // Pass the questions data
      'sections': survey['sections'], // Pass sections if available
      'isDefault': survey['isDefault'] ?? false,
      'isTemplate':
          !isCustom &&
          survey['isDefault'] !=
              true, // Mark as template if not custom and not default
      'isLive': survey['isLive'] ?? false, // Pass live status
    };

    print(
      'DEBUG [SURVEY MANAGEMENT]: Opening editor for survey: ${surveyData['title']}',
    );
    print(
      'DEBUG [SURVEY MANAGEMENT]: Survey data being passed: ${surveyData.keys}',
    );
    print(
      'DEBUG [SURVEY MANAGEMENT]: Survey has sections: ${surveyData['sections'] != null}',
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleFormsStyleSurveyEditor(survey: surveyData),
      ),
    );

    print(
      'DEBUG [SURVEY MANAGEMENT]: Editor closed, result is null: ${result == null}',
    );

    if (result != null) {
      print(
        'DEBUG [SURVEY MANAGEMENT]: ========== RECEIVED RESULT FROM EDITOR ==========',
      );
      print('DEBUG [SURVEY MANAGEMENT]: Result keys: ${result.keys}');
      print('DEBUG [SURVEY MANAGEMENT]: Result name: ${result['name']}');
      print(
        'DEBUG [SURVEY MANAGEMENT]: Result isDefault: ${result['isDefault']}',
      );
      print(
        'DEBUG [SURVEY MANAGEMENT]: Result sections: ${result['sections']}',
      );

      // Try to save to backend first if survey has an ID
      if (survey['id'] != null) {
        try {
          await _surveyService.updateSurvey(survey['id'], result);
          print(
            'DEBUG [SURVEY MANAGEMENT]: Survey successfully saved to backend',
          );
        } catch (e) {
          print('DEBUG [SURVEY MANAGEMENT]: Failed to save to backend: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Warning: Could not save to server. Changes saved locally only.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // Reload from backend to get updated data
      print('DEBUG [SURVEY MANAGEMENT]: Survey updated, reloading from backend...');
      _loadSurveys();

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

  void _deleteSurvey(
    int index, {
    bool isCustom = false,
    required String surveyName,
    int? surveyId,
  }) {
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
              onPressed: () async {
                // Try to delete from backend first if survey has an ID
                if (surveyId != null) {
                  try {
                    await _surveyService.deleteSurvey(surveyId);
                    print(
                      'DEBUG [SURVEY MANAGEMENT]: Survey deleted from backend',
                    );
                  } catch (e) {
                    print(
                      'DEBUG [SURVEY MANAGEMENT]: Failed to delete from backend: $e',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Warning: Could not delete from server. Removing locally only.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                }

                // Reload from backend
                _loadSurveys();

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
    // Debug: Check survey data
    print('🎯 _takeSurvey called');
    print('   Survey keys: ${survey.keys}');
    print('   Survey id: ${survey['id']}');
    print('   Survey name: ${survey['name']}');
    print('   Survey title: ${survey['title']}');
    
    // Navigate to questionnaire page normally so back button works
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakeQuestionnairePage(
          survey: {
            'id': survey['id'], // Don't default to 0, keep null for local surveys
            'name': survey['title'] ?? survey['name'] ?? 'Survey',
            'description':
                survey['subtitle'] ??
                survey['description'] ??
                'Please answer the following questions',
            'questions':
                survey['questions'], // Pass the actual survey questions
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
          title: const Text('Add New Category'),
          content: TextField(
            controller: sectionNameController,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'Enter category name',
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
                          'subtitle':
                              'Template questionnaire for ${sectionNameController.text.trim()}',
                          'questions': [],
                          'isTemplate': true,
                          'isLive': false,
                        },
                      ],
                    });
                  });
                  _saveCustomSections();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Category "${sectionNameController.text.trim()}" created with 1 sample survey!',
                      ),
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


