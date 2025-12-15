import 'package:flutter/material.dart';
import 'take_questionnaire_page.dart';
import '../auth/login_page.dart';
import 'home_page.dart';
import 'employee_directory_page.dart';
import 'user_management_page.dart';
import 'survey_management_page.dart';
import '../services/survey_storage.dart';
import '../services/auth_service.dart';
import '../widgets/standard_drawer.dart';

class QuestionnaireListPage extends StatefulWidget {
  final Map<String, dynamic>? employee;
  
  const QuestionnaireListPage({super.key, this.employee});

  @override
  State<QuestionnaireListPage> createState() => _QuestionnaireListPageState();
}

class _QuestionnaireListPageState extends State<QuestionnaireListPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    child: const Icon(Icons.school, color: Colors.white, size: 16),
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
      endDrawer: StandardDrawer(
        employee: widget.employee,
        currentRoute: '/questionnaire-list',
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final allSurveys = SurveyStorage.getAllAvailableSurveys();
    final availableSurveys = allSurveys.where((survey) {
      final isLive = survey['isLive'];
      return isLive == true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Questionnaires',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select a questionnaire to complete',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              availableSurveys.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          Icon(
                            Icons.assignment_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No questionnaires available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: availableSurveys.length,
                      itemBuilder: (context, index) {
                        final survey = availableSurveys[index];
                        return _buildQuestionnaireCard(survey);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionnaireCard(Map<String, dynamic> survey) {
    return Card(
      elevation: 2,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue[200]!, width: 1),
      ),
      child: InkWell(
        onTap: () => _takeSurvey(survey),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  size: 22,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  survey['description'] ?? 'No description',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 14,
                    color: Colors.blue[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to take',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _takeSurvey(Map<String, dynamic> survey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakeQuestionnairePage(
          survey: survey,
          employee: widget.employee,
        ),
      ),
    );
  }
}
