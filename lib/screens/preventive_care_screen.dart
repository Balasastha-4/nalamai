import 'package:flutter/material.dart';
import '../services/agent_service.dart';
import '../services/auth_service.dart';
import '../widgets/animated_health_card.dart';

/// Preventive Care Dashboard Screen
/// Displays preventive healthcare workflow status, eligibility, and AI agent actions
class PreventiveCareScreen extends StatefulWidget {
  const PreventiveCareScreen({super.key});

  @override
  State<PreventiveCareScreen> createState() => _PreventiveCareScreenState();
}

class _PreventiveCareScreenState extends State<PreventiveCareScreen>
    with SingleTickerProviderStateMixin {
  final AgentService _agentService = AgentService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _eligibility = {};
  Map<String, dynamic> _healthRisk = {};
  Map<String, dynamic> _preventionPlan = {};
  Map<String, dynamic> _adherence = {};
  List<Map<String, dynamic>> _followUps = [];
  Map<String, dynamic> _workflowStatus = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = await _authService.getUserId() ?? '1';

      // Load all data in parallel
      final results = await Future.wait([
        _agentService.checkEligibility(userId),
        _agentService.assessHealthRisk(userId),
        _agentService.getPreventionPlan(userId),
        _agentService.getAdherenceTracking(userId),
        _agentService.getFollowUps(userId),
        _agentService.getWorkflowStatus(userId),
      ]);

      setState(() {
        _eligibility = results[0];
        _healthRisk = results[1];
        _preventionPlan = results[2];
        _adherence = results[3];
        _followUps = List<Map<String, dynamic>>.from(results[4]);
        _workflowStatus = results[5];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _executeWorkflow() async {
    final userId = await _authService.getUserId() ?? '1';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Executing preventive care workflow...'),
          ],
        ),
      ),
    );

    try {
      final result = await _agentService.executePreventiveWorkflow(
        patientId: userId,
      );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['status'] == 'success'
                ? 'Workflow executed successfully!'
                : 'Workflow completed with issues',
          ),
          backgroundColor: result['status'] == 'success'
              ? Colors.green
              : Colors.orange,
        ),
      );

      _loadData();
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preventive Care'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.assessment), text: 'HRA'),
            Tab(icon: Icon(Icons.medical_services), text: 'Plan'),
            Tab(icon: Icon(Icons.notifications_active), text: 'Follow-ups'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(theme),
                _buildHRATab(theme),
                _buildPlanTab(theme),
                _buildFollowUpsTab(theme),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _executeWorkflow,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Run Workflow'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    final riskLevel = _healthRisk['risk_level'] ?? 'unknown';
    final riskColor = _getRiskColor(riskLevel);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health Risk Card
            AnimatedHealthCard(
              title: 'Health Risk Assessment',
              icon: Icons.health_and_safety,
              color: riskColor,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildRiskIndicator(
                        'Overall',
                        _healthRisk['overall_risk']?.toString() ?? 'N/A',
                        riskColor,
                      ),
                      _buildRiskIndicator(
                        'Cardiovascular',
                        _healthRisk['cardiovascular_risk']?.toString() ?? 'N/A',
                        Colors.red,
                      ),
                      _buildRiskIndicator(
                        'Diabetes',
                        _healthRisk['diabetes_risk']?.toString() ?? 'N/A',
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber, color: riskColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Risk Level: ${riskLevel.toUpperCase()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Eligibility Card
            AnimatedHealthCard(
              title: 'Program Eligibility',
              icon: Icons.verified_user,
              color: Colors.blue,
              child: _buildEligibilityList(),
            ),

            const SizedBox(height: 16),

            // Adherence Card
            AnimatedHealthCard(
              title: 'Adherence Tracking',
              icon: Icons.trending_up,
              color: Colors.green,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Adherence Rate',
                        '${(_adherence['adherence_rate'] ?? 0).toStringAsFixed(0)}%',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatItem(
                        'Tasks Completed',
                        '${_adherence['tasks_completed'] ?? 0}',
                        Icons.task_alt,
                        Colors.blue,
                      ),
                      _buildStatItem(
                        'Pending',
                        '${_adherence['tasks_pending'] ?? 0}',
                        Icons.pending_actions,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Workflow Status Card
            AnimatedHealthCard(
              title: 'Workflow Status',
              icon: Icons.account_tree,
              color: Colors.purple,
              child: _buildWorkflowSteps(),
            ),

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildHRATab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Risk Assessment',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your health assessment to get personalized preventive care recommendations.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // HRA Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Assessment Status',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        _buildStatusChip(
                          _healthRisk['hra_status'] ?? 'PENDING',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_healthRisk['last_assessment'] != null)
                      Text('Last completed: ${_healthRisk['last_assessment']}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Start HRA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showHRAForm(context),
                icon: const Icon(Icons.edit_document),
                label: const Text('Complete Health Assessment'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recommendations
            if (_healthRisk['recommendations'] != null) ...[
              Text('AI Recommendations', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...(_healthRisk['recommendations'] as List? ?? []).map(
                (rec) => _buildRecommendationItem(rec.toString()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTab(ThemeData theme) {
    final hasPlan = _preventionPlan['id'] != null;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Prevention Plan', style: theme.textTheme.headlineSmall),
                if (!hasPlan)
                  ElevatedButton.icon(
                    onPressed: _generatePlan,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (hasPlan) ...[
              // Plan Progress
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Plan Progress',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            '${_preventionPlan['completion_percentage'] ?? 0}%',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value:
                            (_preventionPlan['completion_percentage'] ?? 0) /
                            100,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(Colors.green),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Health Goals
              if (_preventionPlan['health_goals'] != null)
                _buildPlanSection(
                  'Health Goals',
                  Icons.flag,
                  _preventionPlan['health_goals'],
                  Colors.blue,
                ),

              // Preventive Measures
              if (_preventionPlan['preventive_measures'] != null)
                _buildPlanSection(
                  'Preventive Measures',
                  Icons.medical_services,
                  _preventionPlan['preventive_measures'],
                  Colors.green,
                ),

              // Recommended Screenings
              if (_preventionPlan['recommended_screenings'] != null)
                _buildPlanSection(
                  'Recommended Screenings',
                  Icons.biotech,
                  _preventionPlan['recommended_screenings'],
                  Colors.orange,
                ),

              // Lifestyle Recommendations
              if (_preventionPlan['lifestyle_recommendations'] != null)
                _buildPlanSection(
                  'Lifestyle Recommendations',
                  Icons.self_improvement,
                  _preventionPlan['lifestyle_recommendations'],
                  Colors.purple,
                ),
            ] else
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active prevention plan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete your HRA to generate a personalized plan',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpsTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _followUps.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No follow-ups',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _followUps.length,
              itemBuilder: (context, index) {
                final followUp = _followUps[index];
                return _buildFollowUpCard(followUp, theme);
              },
            ),
    );
  }

  Widget _buildFollowUpCard(Map<String, dynamic> followUp, ThemeData theme) {
    final status = followUp['status'] ?? 'PENDING';
    final type = followUp['follow_up_type'] ?? 'GENERAL';
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getFollowUpIcon(type), color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    followUp['message'] ?? 'Follow-up reminder',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Scheduled: ${followUp['scheduled_date'] ?? 'Not set'}',
              style: theme.textTheme.bodySmall,
            ),
            if (status == 'PENDING') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _dismissFollowUp(followUp['id']),
                    child: const Text('Dismiss'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _completeFollowUp(followUp['id']),
                    child: const Text('Complete'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiskIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildEligibilityList() {
    final programs = _eligibility['programs'] as List? ?? [];
    if (programs.isEmpty) {
      return const Text('Loading eligibility data...');
    }

    return Column(
      children: programs.map((program) {
        final isEligible = program['is_eligible'] ?? false;
        return ListTile(
          dense: true,
          leading: Icon(
            isEligible ? Icons.check_circle : Icons.cancel,
            color: isEligible ? Colors.green : Colors.red,
          ),
          title: Text(program['program_type'] ?? 'Unknown'),
          trailing: _buildStatusChip(
            program['eligibility_status'] ?? 'UNKNOWN',
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkflowSteps() {
    final steps = _workflowStatus['steps'] as List? ?? [];
    if (steps.isEmpty) {
      return const Text('No workflow data available');
    }

    return Column(
      children: steps.map((step) {
        final status = step['status'] ?? 'pending';
        return ListTile(
          dense: true,
          leading: Icon(_getStepIcon(status), color: _getStepColor(status)),
          title: Text(step['name'] ?? 'Step'),
          subtitle: Text(step['description'] ?? ''),
        );
      }).toList(),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Chip(
      label: Text(status, style: TextStyle(color: color, fontSize: 10)),
      backgroundColor: color.withOpacity(0.1),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildRecommendationItem(String text) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.lightbulb, color: Colors.amber),
        title: Text(text),
      ),
    );
  }

  Widget _buildPlanSection(
    String title,
    IconData icon,
    dynamic items,
    Color color,
  ) {
    final itemList = items is List ? items : [];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        children: itemList.map<Widget>((item) {
          return ListTile(
            leading: const Icon(Icons.check, size: 16),
            title: Text(item.toString()),
          );
        }).toList(),
      ),
    );
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'ELIGIBLE':
      case 'VALIDATED':
        return Colors.green;
      case 'PENDING':
      case 'SUBMITTED':
        return Colors.orange;
      case 'OVERDUE':
      case 'NOT_ELIGIBLE':
      case 'FLAGGED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStepIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.autorenew;
      case 'pending':
        return Icons.radio_button_unchecked;
      case 'error':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _getStepColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.grey;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getFollowUpIcon(String type) {
    switch (type.toUpperCase()) {
      case 'MEDICATION':
        return Icons.medication;
      case 'APPOINTMENT':
        return Icons.event;
      case 'SCREENING':
        return Icons.biotech;
      case 'LIFESTYLE':
        return Icons.self_improvement;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _showHRAForm(BuildContext context) async {
    // Navigate to HRA form screen or show modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _HRAFormSheet(
          scrollController: scrollController,
          onSubmit: (data) async {
            final userId = await _authService.getUserId() ?? '1';
            await _agentService.submitHRA(patientId: userId, hraData: data);
            Navigator.pop(context);
            _loadData();
          },
        ),
      ),
    );
  }

  Future<void> _generatePlan() async {
    final userId = await _authService.getUserId() ?? '1';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Generating personalized plan...'),
          ],
        ),
      ),
    );

    try {
      await _agentService.generatePreventionPlan(userId);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prevention plan generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _completeFollowUp(String? id) async {
    if (id == null) return;
    await _agentService.respondToFollowUp(
      followUpId: id,
      response: 'Completed',
      taskCompleted: true,
    );
    _loadData();
  }

  Future<void> _dismissFollowUp(String? id) async {
    if (id == null) return;
    await _agentService.respondToFollowUp(
      followUpId: id,
      response: 'Dismissed',
      taskCompleted: false,
    );
    _loadData();
  }
}

/// HRA Form Sheet Widget
class _HRAFormSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Function(Map<String, dynamic>) onSubmit;

  const _HRAFormSheet({required this.scrollController, required this.onSubmit});

  @override
  State<_HRAFormSheet> createState() => _HRAFormSheetState();
}

class _HRAFormSheetState extends State<_HRAFormSheet> {
  final _formKey = GlobalKey<FormState>();

  bool _isSmoker = false;
  bool _consumesAlcohol = false;
  String _exerciseFrequency = 'MODERATE';
  String _dietQuality = 'GOOD';
  double _height = 170;
  double _weight = 70;
  int _systolicBP = 120;
  int _diastolicBP = 80;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          controller: widget.scrollController,
          children: [
            Text(
              'Health Risk Assessment',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Please answer the following questions honestly.'),
            const SizedBox(height: 24),

            // Lifestyle Section
            Text('Lifestyle', style: Theme.of(context).textTheme.titleMedium),
            SwitchListTile(
              title: const Text('Do you smoke?'),
              value: _isSmoker,
              onChanged: (v) => setState(() => _isSmoker = v),
            ),
            SwitchListTile(
              title: const Text('Do you consume alcohol regularly?'),
              value: _consumesAlcohol,
              onChanged: (v) => setState(() => _consumesAlcohol = v),
            ),
            ListTile(
              title: const Text('Exercise Frequency'),
              subtitle: DropdownButton<String>(
                isExpanded: true,
                value: _exerciseFrequency,
                items: ['NONE', 'RARE', 'MODERATE', 'REGULAR']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _exerciseFrequency = v!),
              ),
            ),
            ListTile(
              title: const Text('Diet Quality'),
              subtitle: DropdownButton<String>(
                isExpanded: true,
                value: _dietQuality,
                items: ['POOR', 'FAIR', 'GOOD', 'EXCELLENT']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _dietQuality = v!),
              ),
            ),

            const SizedBox(height: 16),

            // Biometrics Section
            Text('Biometrics', style: Theme.of(context).textTheme.titleMedium),
            ListTile(
              title: Text('Height: ${_height.toInt()} cm'),
              subtitle: Slider(
                value: _height,
                min: 100,
                max: 220,
                divisions: 120,
                onChanged: (v) => setState(() => _height = v),
              ),
            ),
            ListTile(
              title: Text('Weight: ${_weight.toInt()} kg'),
              subtitle: Slider(
                value: _weight,
                min: 30,
                max: 200,
                divisions: 170,
                onChanged: (v) => setState(() => _weight = v),
              ),
            ),
            ListTile(
              title: Text('Blood Pressure: $_systolicBP / $_diastolicBP mmHg'),
              subtitle: Column(
                children: [
                  Slider(
                    value: _systolicBP.toDouble(),
                    min: 80,
                    max: 200,
                    divisions: 120,
                    label: 'Systolic',
                    onChanged: (v) => setState(() => _systolicBP = v.toInt()),
                  ),
                  Slider(
                    value: _diastolicBP.toDouble(),
                    min: 50,
                    max: 130,
                    divisions: 80,
                    label: 'Diastolic',
                    onChanged: (v) => setState(() => _diastolicBP = v.toInt()),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSubmit({
                    'isSmoker': _isSmoker,
                    'consumesAlcohol': _consumesAlcohol,
                    'exerciseFrequency': _exerciseFrequency,
                    'dietQuality': _dietQuality,
                    'height': _height,
                    'weight': _weight,
                    'systolicBP': _systolicBP,
                    'diastolicBP': _diastolicBP,
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Submit Assessment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
