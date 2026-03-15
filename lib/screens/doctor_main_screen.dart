import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animations/fade_in_slide.dart';

import 'patient_list_screen.dart';
import 'pending_reports_screen.dart';
import 'doctor_profile_screen.dart';
import 'prediction_screen.dart';
import 'doctor_schedule_screen.dart';
import '../widgets/doctor_search_delegate.dart';

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _currentIndex = 0;
  bool _isFabExpanded = false;

  // Demo Alerts Data
  final List<Map<String, String>> _alerts = [
    {
      'name': 'John Doe',
      'issue': 'SpO2 drops to 88%',
      'time': '10 min ago',
      'severity': 'High',
    },
    {
      'name': 'Sarah Connor',
      'issue': 'BP Spike 160/100',
      'time': '25 min ago',
      'severity': 'High',
    },
    {
      'name': 'Mike Ross',
      'issue': 'Irregular Heartbeat',
      'time': '1 hour ago',
      'severity': 'Medium',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorProfileScreen(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text(
                    'DS', // Doctor Smith
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).disabledColor,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('👋', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Dr. Sarah Smith',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              showSearch(context: context, delegate: DoctorSearchDelegate());
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInSlide(
              delay: const Duration(milliseconds: 100),
              child: _buildUpNextCard(),
            ),
            const SizedBox(height: 24),
            FadeInSlide(
              delay: const Duration(milliseconds: 200),
              child: _buildSummaryCards(),
            ),
            const SizedBox(height: 24),
            FadeInSlide(
              delay: const Duration(milliseconds: 400),
              child: _buildCriticalAlerts(),
            ),
            const SizedBox(height: 24),
            FadeInSlide(
              delay: const Duration(milliseconds: 600),
              child: _buildQuickActions(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: _buildExpandableFab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 1) {
              // Navigate to Patient List on 'Patients' tab tap
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientListScreen(),
                ),
              ).then((_) {
                // Reset index content when coming back if desired,
                // or handle state properly. For now simple push.
                setState(() => _currentIndex = 0);
              });
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorScheduleScreen(),
                ),
              ).then((_) {
                setState(() => _currentIndex = 0);
              });
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            title: 'Total Patients',
            value: '128',
            icon: Icons.people,
            color: AppTheme.primaryBlue,
            trend: '+12%',
            trendUp: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            title: 'Critical Alerts',
            value: '3',
            icon: Icons.warning_amber_rounded,
            color: AppTheme.error,
            isAlert: true,
            trend: '+1',
            trendUp: true, // bad trend for alerts
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            title: 'Avg Health',
            value: '78%',
            icon: Icons.favorite,
            color: AppTheme.success,
            trend: '+2.4%',
            trendUp: true,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isAlert = false,
    String? trend,
    bool trendUp = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isAlert
                ? color.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isAlert
              ? color.withValues(alpha: 0.3)
              : AppTheme.cardBorderColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (trend != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (isAlert ? !trendUp : trendUp)
                          ? AppTheme.success.withValues(alpha: 0.1)
                          : AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 10,
                          color: (isAlert ? !trendUp : trendUp)
                              ? AppTheme.success
                              : AppTheme.error,
                        ),
                        Flexible(
                          child: Text(
                            trend,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: (isAlert ? !trendUp : trendUp)
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isAlert
                    ? color
                    : Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Mini-chart / Progress Bar simulation
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: 0.7, // Mock value
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Critical Alerts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_alerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorderColor(context)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: AppTheme.success.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'All clear! No critical alerts.',
                  style: TextStyle(color: Theme.of(context).disabledColor),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _alerts.length > 2 ? 2 : _alerts.length,
            itemBuilder: (context, index) {
              final alert = _alerts[index];
              return Dismissible(
                key: Key(alert['issue']! + alert['time']!),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  setState(() {
                    _alerts.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${alert['issue']} marked as resolved'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          setState(() {
                            _alerts.insert(index, alert);
                          });
                        },
                      ),
                    ),
                  );
                },
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Icon(Icons.check, color: Colors.white, size: 28),
                ),
                child: _buildAlertItem(
                  name: alert['name']!,
                  issue: alert['issue']!,
                  time: alert['time']!,
                  severity: alert['severity']!,
                ),
              );
            },
          ),
        if (_alerts.length > 2)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.expand_more, size: 18),
                label: Text(
                  '+${_alerts.length - 2} more critical alerts',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAlertItem({
    required String name,
    required String issue,
    required String time,
    required String severity,
  }) {
    final isHigh = severity == 'High';
    final color = isHigh ? AppTheme.error : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isHigh
            ? Border.all(
                color: AppTheme.error.withValues(alpha: 0.5),
                width: 1.5,
              )
            : Border.all(color: AppTheme.cardBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: isHigh
                ? AppTheme.error.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isHigh ? 12 : 8,
            spreadRadius: isHigh ? 1 : 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isHigh ? Icons.warning_rounded : Icons.info_outline_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isHigh)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.error.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            FadeInSlide(
              duration: const Duration(milliseconds: 400),
              child: _buildActionCard(
                title: 'Patient List',
                icon: Icons.people_outline,
                gradient: AppTheme.blueGradient,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientListScreen(),
                    ),
                  );
                },
              ),
            ),
            FadeInSlide(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 400),
              child: _buildActionCard(
                title: 'Review Reports',
                icon: Icons.description_outlined,
                gradient: AppTheme.purpleGradient,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PendingReportsScreen(),
                    ),
                  );
                },
              ),
            ),
            FadeInSlide(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 400),
              child: _buildActionCard(
                title: 'AI Predictions',
                icon: Icons.auto_awesome_outlined,
                gradient: AppTheme.tealGradient,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PredictionScreen(),
                    ),
                  );
                },
              ),
            ),
            FadeInSlide(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 400),
              child: _buildActionCard(
                title: 'Quick Note',
                icon: Icons.note_add_outlined,
                gradient: AppTheme.orangeGradient,
                onTap: () => _showQuickNoteDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: AppTheme.cardBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: gradient.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) => gradient.createShader(bounds),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Quick Note'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type or dictate patient notes...',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    // Mock Dictation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Listening... (Mock)')),
                    );
                  },
                  icon: const Icon(Icons.mic, color: AppTheme.primaryBlue),
                  tooltip: 'Dictate',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note saved to Pending Review')),
              );
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpNextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.blueGradient,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'In 15 mins',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.video_call, color: Colors.white),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Text(
                  'SC',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sarah Connor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'General Checkup',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  'Join Now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isFabExpanded) ...[
          _buildFabMenuItem(
            icon: Icons.note_add,
            label: 'New Note',
            onTap: () {
              setState(() => _isFabExpanded = false);
              _showQuickNoteDialog();
            },
          ),
          const SizedBox(height: 12),
          _buildFabMenuItem(
            icon: Icons.search,
            label: 'Rapid Search',
            onTap: () {
              setState(() => _isFabExpanded = false);
              // Rapid search logic
            },
          ),
          const SizedBox(height: 12),
          _buildFabMenuItem(
            icon: Icons.contact_emergency,
            label: 'Emergency',
            onTap: () {
              setState(() => _isFabExpanded = false);
            },
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          onPressed: () => setState(() => _isFabExpanded = !_isFabExpanded),
          backgroundColor: AppTheme.primaryBlue,
          elevation: 4,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: _isFabExpanded ? 0.375 : 0, // Cross to Plus and vice-versa
            child: Icon(
              _isFabExpanded ? Icons.close : Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFabMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return FadeInSlide(
      slideOffset: 10,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
