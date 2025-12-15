import 'package:flutter/material.dart';

import '../services/backend_survey_service.dart';
import '../widgets/standard_drawer.dart';
import 'google_forms_style_survey_editor.dart';
import 'home_page.dart';

class SurveyManagementPage extends StatefulWidget {
  final Map<String, dynamic>? employee;

  const SurveyManagementPage({super.key, this.employee});

  @override
  State<SurveyManagementPage> createState() => _SurveyManagementPageState();
}

class _SurveyManagementPageState extends State<SurveyManagementPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _surveyService = BackendSurveyService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoadingSurveys = false;
  bool _hasShownBackendError = false;
  bool _isEditMode = false;

  // Survey data - surveys without periode (template section)
  List<Map<String, dynamic>> surveysWithoutPeriode = [];

  // Sections with surveys (periode-based)
  List<Map<String, dynamic>> sections = [];

  // Sections to delete when switching from edit mode to done
  List<int> sectionsToDelete = [];

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSurveys() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSurveys = true;
    });

    try {
      print('📋 Loading surveys from backend...');

      final backendSurveys = await _surveyService.getAllSurveys();
      print('   Fetched ${backendSurveys.length} surveys from backend');

      if (!mounted) return;

      // Separate surveys without periode and with periode
      final withoutPeriode = <Map<String, dynamic>>[];
      final surveysByPeriode = <String, List<Map<String, dynamic>>>{};
      final periodsSet = <int>{};

      for (var survey in backendSurveys) {
        final surveyData = Map<String, dynamic>.from(survey as Map);

        // Get periode ID
        final periodeId = surveyData['periode'];

        if (periodeId == null) {
          // Survey without periode
          withoutPeriode.add({
            'id': surveyData['id'],
            'title':
                surveyData['title'] ?? surveyData['name'] ?? 'Untitled Survey',
            'description': surveyData['description'] ?? '',
            'lastEdit': surveyData['updated_at'] != null
                ? 'Last Edit ${_formatDate(surveyData['updated_at'])}'
                : 'Never edited',
            'type': surveyData['type'] ?? 'survey',
            'is_active': surveyData['is_active'] ?? false,
            'survey_type': surveyData['survey_type'] ?? 'exit',
            'periode': null,
            'start_at': surveyData['start_at'],
            'end_at': surveyData['end_at'],
            'questions': surveyData['questions'] ?? [],
          });
        } else {
          // Survey with periode
          final periodeKey = periodeId.toString();
          periodsSet.add(periodeId as int);

          if (!surveysByPeriode.containsKey(periodeKey)) {
            surveysByPeriode[periodeKey] = [];
          }

          surveysByPeriode[periodeKey]!.add({
            'id': surveyData['id'],
            'title':
                surveyData['title'] ?? surveyData['name'] ?? 'Untitled Survey',
            'description': surveyData['description'] ?? '',
            'lastEdit': surveyData['updated_at'] != null
                ? 'Last Edit ${_formatDate(surveyData['updated_at'])}'
                : 'Never edited',
            'type': surveyData['type'] ?? 'survey',
            'is_active': surveyData['is_active'] ?? false,
            'survey_type': surveyData['survey_type'] ?? 'exit',
            'periode': periodeId,
            'start_at': surveyData['start_at'],
            'end_at': surveyData['end_at'],
            'questions': surveyData['questions'] ?? [],
          });
        }
      }

      // Create sections from periods
      final newSections = <Map<String, dynamic>>[];
      final sortedPeriods = periodsSet.toList()..sort();

      for (var i = 0; i < sortedPeriods.length; i++) {
        final periodeId = sortedPeriods[i];
        final periodeKey = periodeId.toString();
        final currentYear = DateTime.now().year;

        newSections.add({
          'id': periodeId,
          'name': 'Periode ${currentYear + i}/${currentYear + i + 1}',
          'order': i + 1,
          'surveys': surveysByPeriode[periodeKey] ?? [],
          'isCollapsed': false,
          'isNew': false,
        });
      }

      setState(() {
        surveysWithoutPeriode = withoutPeriode;
        sections = newSections;
        _isLoadingSurveys = false;
      });

      print('✅ Loaded ${withoutPeriode.length} surveys without periode');
      print('✅ Loaded ${newSections.length} sections');
    } catch (e) {
      print('❌ Error loading surveys: $e');

      if (!mounted) return;

      setState(() {
        surveysWithoutPeriode = [];
        sections = [];
        _isLoadingSurveys = false;
      });

      // Show error message
      if (!_hasShownBackendError && mounted) {
        _hasShownBackendError = true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load surveys: $e'),
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

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Never';
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Never';
    }
  }

  void _handleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });

    if (!_isEditMode) {
      // Switching from Edit mode to Done mode - save all changes
      _saveAllChanges();
    }
  }

  Future<void> _saveAllChanges() async {
    // TODO: Implement saving logic for section name changes and reordering
    // This would involve calling backend APIs to update period names and orders
    print('Saving all changes...');

    // For now, just reload to refresh the state
    _loadSurveys();
  }

  void _showNewSurveyDialog() {
    // TODO: Implement new survey dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New Survey dialog - to be implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleDeleteSurvey(String surveyId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Survey'),
          content: const Text('Are you sure you want to delete this survey?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  await _surveyService.deleteSurvey(int.parse(surveyId));
                  _loadSurveys();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Survey deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete survey: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _handleDuplicateSurvey(String surveyId) async {
    try {
      // TODO: Implement duplicate functionality with backend API
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duplicate functionality - to be implemented'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate survey: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleEditSurvey(Map<String, dynamic> survey) {
    // Navigate to survey editor
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleFormsStyleSurveyEditor(survey: survey),
      ),
    ).then((result) {
      if (result != null) {
        _loadSurveys();
      }
    });
  }

  void _moveSectionUp(int index) {
    if (index <= 0) return;

    setState(() {
      final temp = sections[index];
      sections[index] = sections[index - 1];
      sections[index - 1] = temp;

      // Update orders
      for (var i = 0; i < sections.length; i++) {
        sections[i]['order'] = i + 1;
      }
    });
  }

  void _moveSectionDown(int index) {
    if (index >= sections.length - 1) return;

    setState(() {
      final temp = sections[index];
      sections[index] = sections[index + 1];
      sections[index + 1] = temp;

      // Update orders
      for (var i = 0; i < sections.length; i++) {
        sections[i]['order'] = i + 1;
      }
    });
  }

  void _deleteSection(int sectionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Section'),
          content: const Text('Are you sure you want to delete this section?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                setState(() {
                  sections.removeWhere((section) => section['id'] == sectionId);
                  sectionsToDelete.add(sectionId);
                });
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _updateSectionName(int sectionId, String newName) {
    setState(() {
      final index = sections.indexWhere((s) => s['id'] == sectionId);
      if (index != -1) {
        sections[index]['name'] = newName;
      }
    });
  }

  void _addNewSection() {
    setState(() {
      final newId = sections.isNotEmpty
          ? sections
                    .map((s) => s['id'] as int)
                    .reduce((a, b) => a < b ? a : b) -
                1
          : -1;
      final maxOrder = sections.isNotEmpty
          ? sections
                .map((s) => s['order'] as int)
                .reduce((a, b) => a > b ? a : b)
          : 0;

      final currentYear = DateTime.now().year;
      final nextYear = currentYear + 1;

      sections.add({
        'id': newId,
        'name': 'Periode $currentYear/$nextYear',
        'order': maxOrder + 1,
        'surveys': [],
        'isCollapsed': false,
        'isNew': true,
      });
    });
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Survey Management',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
            // Controls Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action Buttons Row
                  Row(
                    children: [
                      // Edit/Done Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleEditMode,
                          icon: Icon(
                            _isEditMode ? Icons.check : Icons.edit,
                            size: 18,
                          ),
                          label: Text(_isEditMode ? 'Done' : 'Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Add New Survey Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showNewSurveyDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New Survey'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Template Section (surveys without periode)
                            if (surveysWithoutPeriode.isNotEmpty) ...[
                              _buildSurveyGrid(surveysWithoutPeriode),
                              const SizedBox(height: 24),
                            ],

                            // Dynamic Sections (periode-based)
                            ...sections.asMap().entries.map((entry) {
                              final index = entry.key;
                              final section = entry.value;
                              return _buildSection(section, index);
                            }).toList(),

                            // Add New Section Button (only in edit mode)
                            if (_isEditMode) ...[
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: _addNewSection,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      style: BorderStyle.solid,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[50],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add, color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Add New Section',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

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

  Widget _buildSection(Map<String, dynamic> section, int index) {
    final surveys = section['surveys'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            // Section Name
            if (_isEditMode)
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: section['name']),
                  onChanged: (value) =>
                      _updateSectionName(section['id'], value),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Text(
                  section['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Edit Mode Controls
            if (_isEditMode) ...[
              const SizedBox(width: 8),

              // Move Up Button
              IconButton(
                onPressed: index == 0 ? null : () => _moveSectionUp(index),
                icon: Icon(
                  Icons.keyboard_arrow_up,
                  color: index == 0 ? Colors.grey[300] : Colors.grey[600],
                ),
                style: IconButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),

              // Move Down Button
              IconButton(
                onPressed: index == sections.length - 1
                    ? null
                    : () => _moveSectionDown(index),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: index == sections.length - 1
                      ? Colors.grey[300]
                      : Colors.grey[600],
                ),
                style: IconButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),

              // Delete Button
              IconButton(
                onPressed: () => _deleteSection(section['id']),
                icon: const Icon(Icons.delete, color: Colors.red),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // Surveys Grid
        _buildSurveyGrid(surveys),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSurveyGrid(List<Map<String, dynamic>> surveys) {
    if (surveys.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Center(
          child: Text(
            'No surveys in this section',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: surveys.length,
      itemBuilder: (context, index) {
        return _buildSurveyCard(surveys[index]);
      },
    );
  }

  Widget _buildSurveyCard(Map<String, dynamic> survey) {
    final isActive = survey['is_active'] ?? false;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: _isEditMode ? null : () => _handleEditSurvey(survey),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with dropdown menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Expanded(
                    child: Text(
                      survey['title'] ?? 'Untitled Survey',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Menu button (only when not in edit mode)
                  if (!_isEditMode)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _handleEditSurvey(survey);
                            break;
                          case 'duplicate':
                            _handleDuplicateSurvey(survey['id'].toString());
                            break;
                          case 'delete':
                            _handleDeleteSurvey(survey['id'].toString());
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Text('Duplicate'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green[50] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: isActive ? Colors.green[700] : Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Description
              Expanded(
                child: Text(
                  survey['description'] ?? 'No description available',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
