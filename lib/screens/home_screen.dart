import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animations/fade_in_slide.dart';
import '../widgets/feedback/skeleton_loader.dart';

import '../models/vital.dart';
import '../models/schedule_model.dart';
import '../models/health_tip.dart';

// Widgets
import '../widgets/home/daily_summary_card.dart';
import '../widgets/home/alert_banner.dart';
import '../widgets/home/vitals_list.dart';
import '../widgets/home/activity_section.dart';
import '../widgets/home/appointment_card.dart';
import '../widgets/home/section_header.dart';
import '../widgets/home/prediction_card.dart';
import '../widgets/home/health_tip_card.dart';

import 'schedule_screen.dart';
import 'info_center_screen.dart';
import 'prediction_screen.dart';
import 'preventive_care_screen.dart';
import '../services/api_service.dart';
import '../services/vitals_service.dart';
import '../services/agent_service.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _hasAlert = false;
  String _alertTitle = '';
  String _alertDescription = '';

  // Dynamic vitals loaded from API
  List<Vital> _vitals = [];
  int _wellnessScore = 0;
  int _scoreChange = 0;
  int _steps = 0;
  int _calories = 0;
  Map<String, dynamic> _eligibility = {};

  final ApiService _apiService = ApiService();
  final VitalsService _vitalsService = VitalsService();
  final AgentService _agentService = AgentService();
  final AuthService _authService = AuthService();
  List<ScheduleItem> _appointments = [];
  String _welcomeName = '';

  final HealthTip _dailyTip = const HealthTip(
    title: 'Daily Health Tip',
    description: 'Stay hydrated! Drink at least 8 glasses of water today.',
    icon: Icons.tips_and_updates,
    color: AppTheme.primaryBlue,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final displayName = (await _authService.getUserDisplayName())?.trim() ?? '';
      final userId = await _authService.getUserId() ?? '1';
      // Load data in parallel
      final results = await Future.wait([
        _apiService.getAppointments(false),
        _vitalsService.getLatestVitals(),
        _agentService.checkEligibility(userId),
      ]);

      final appointments = results[0] as List<ScheduleItem>;
      final vitalsData = results[1] as Map<String, dynamic>;
      final eligibility = results[2] as Map<String, dynamic>;

      // Parse vitals data
      final vitals = _parseVitals(vitalsData);
      final wellness = _calculateWellnessScore(vitalsData);
      final alert = _checkForAlerts(vitalsData);

      if (mounted) {
        setState(() {
          _welcomeName = displayName;
          _appointments = appointments;
          _vitals = vitals;
          _wellnessScore = wellness['score'];
          _scoreChange = wellness['change'];
          _steps = vitalsData['steps'] ?? 7500;
          _calories = vitalsData['calories'] ?? 1200;
          _hasAlert = alert['hasAlert'];
          _alertTitle = alert['title'];
          _alertDescription = alert['description'];
          _eligibility = eligibility;
        });
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
      final nameFallback =
          (await _authService.getUserDisplayName())?.trim() ?? '';
      if (mounted) {
        setState(() {
          _welcomeName = nameFallback;
          _vitals = _getDefaultVitals();
          _wellnessScore = 85;
          _scoreChange = 2;
          _steps = 7500;
          _calories = 1200;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Vital> _parseVitals(Map<String, dynamic> data) {
    final List<Vital> vitals = [];

    // Heart Rate
    if (data['heartRate'] != null) {
      final hr = data['heartRate'];
      final isAlert = hr > 100 || hr < 50;
      vitals.add(
        Vital(
          label: 'Heart Rate',
          value: '$hr bpm',
          icon: Icons.favorite,
          color: isAlert ? AppTheme.error : AppTheme.primaryBlue,
          isAlert: isAlert,
        ),
      );
    }

    // Blood Pressure
    if (data['systolicBP'] != null && data['diastolicBP'] != null) {
      final sys = data['systolicBP'];
      final dia = data['diastolicBP'];
      final isAlert = sys > 140 || dia > 90 || sys < 90 || dia < 60;
      vitals.add(
        Vital(
          label: 'Blood Pressure',
          value: '$sys/$dia',
          icon: Icons.bloodtype,
          color: isAlert ? AppTheme.error : AppTheme.primaryBlue,
          isAlert: isAlert,
        ),
      );
    }

    // SpO2
    if (data['spo2'] != null) {
      final spo2 = data['spo2'];
      final isAlert = spo2 < 95;
      vitals.add(
        Vital(
          label: 'SpO2',
          value: '$spo2%',
          icon: Icons.air,
          color: isAlert ? AppTheme.error : AppTheme.secondaryTeal,
          isAlert: isAlert,
        ),
      );
    }

    // Temperature
    if (data['temperature'] != null) {
      final temp = data['temperature'];
      final isAlert = temp > 38.0 || temp < 36.0;
      vitals.add(
        Vital(
          label: 'Temperature',
          value: '${temp.toStringAsFixed(1)}°C',
          icon: Icons.thermostat,
          color: isAlert ? AppTheme.error : Colors.orange,
          isAlert: isAlert,
        ),
      );
    }

    // Weight
    if (data['weight'] != null) {
      vitals.add(
        Vital(
          label: 'Weight',
          value: '${data['weight']} kg',
          icon: Icons.monitor_weight,
          color: Colors.orange,
        ),
      );
    }

    // Blood Glucose
    if (data['bloodGlucose'] != null) {
      final glucose = data['bloodGlucose'];
      final isAlert = glucose > 140 || glucose < 70;
      vitals.add(
        Vital(
          label: 'Blood Glucose',
          value: '$glucose mg/dL',
          icon: Icons.water_drop,
          color: isAlert ? AppTheme.error : Colors.purple,
          isAlert: isAlert,
        ),
      );
    }

    return vitals.isEmpty ? _getDefaultVitals() : vitals;
  }

  List<Vital> _getDefaultVitals() {
    return const [
      Vital(
        label: 'Heart Rate',
        value: '-- bpm',
        icon: Icons.favorite,
        color: AppTheme.primaryBlue,
      ),
      Vital(
        label: 'Blood Pressure',
        value: '--/--',
        icon: Icons.bloodtype,
        color: AppTheme.primaryBlue,
      ),
      Vital(
        label: 'SpO2',
        value: '--%',
        icon: Icons.air,
        color: AppTheme.secondaryTeal,
      ),
      Vital(
        label: 'Weight',
        value: '-- kg',
        icon: Icons.monitor_weight,
        color: Colors.orange,
      ),
    ];
  }

  Map<String, dynamic> _calculateWellnessScore(Map<String, dynamic> data) {
    int score = 85;
    int change = 0;

    // Calculate based on vitals
    if (data['heartRate'] != null) {
      final hr = data['heartRate'];
      if (hr >= 60 && hr <= 100)
        score += 5;
      else
        score -= 10;
    }

    if (data['systolicBP'] != null) {
      final sys = data['systolicBP'];
      if (sys >= 90 && sys <= 120)
        score += 5;
      else if (sys > 140 || sys < 80)
        score -= 15;
    }

    if (data['spo2'] != null) {
      final spo2 = data['spo2'];
      if (spo2 >= 98)
        score += 5;
      else if (spo2 < 95)
        score -= 20;
    }

    // Clamp score
    score = score.clamp(0, 100).toInt();

    // Calculate change from previous
    if (data['previousScore'] != null) {
      change = score - (data['previousScore'] as num).toInt();
    } else {
      change = (score > 80) ? 2 : -2;
    }

    return {'score': score, 'change': change};
  }

  Map<String, dynamic> _checkForAlerts(Map<String, dynamic> data) {
    bool hasAlert = false;
    String title = '';
    String description = '';

    // Check heart rate
    if (data['heartRate'] != null) {
      final hr = data['heartRate'];
      if (hr > 100) {
        hasAlert = true;
        title = 'Elevated Heart Rate Detected';
        description =
            'Your resting heart rate ($hr bpm) is higher than normal.';
      } else if (hr < 50) {
        hasAlert = true;
        title = 'Low Heart Rate Detected';
        description = 'Your heart rate ($hr bpm) is lower than normal.';
      }
    }

    // Check blood pressure
    if (data['systolicBP'] != null && !hasAlert) {
      final sys = data['systolicBP'];
      final dia = data['diastolicBP'] ?? 80;
      if (sys > 140 || dia > 90) {
        hasAlert = true;
        title = 'High Blood Pressure Detected';
        description =
            'Your blood pressure ($sys/$dia) is elevated. Consider consulting your doctor.';
      }
    }

    // Check SpO2
    if (data['spo2'] != null && !hasAlert) {
      final spo2 = data['spo2'];
      if (spo2 < 95) {
        hasAlert = true;
        title = 'Low Oxygen Saturation';
        description =
            'Your SpO2 ($spo2%) is below normal. Please seek medical attention if symptoms persist.';
      }
    }

    return {'hasAlert': hasAlert, 'title': title, 'description': description};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInSlide(child: _buildWelcomeSection(context)),
                const SizedBox(height: 20),
                if (_hasAlert)
                  FadeInSlide(
                    delay: const Duration(milliseconds: 100),
                    child: AlertBanner(
                      title: _alertTitle,
                      description: _alertDescription,
                      onTap: () {},
                    ),
                  ),
                const SizedBox(height: 24),
                FadeInSlide(
                  delay: const Duration(milliseconds: 200),
                  child: _isLoading
                      ? const SkeletonCard(height: 140)
                      : DailySummaryCard(
                          wellnessScore: _wellnessScore,
                          scoreChange: _scoreChange,
                          progressValue: _wellnessScore / 100,
                        ),
                ),
                const SizedBox(height: 32),
                FadeInSlide(
                  delay: const Duration(milliseconds: 300),
                  child: _isLoading
                      ? const SkeletonCard(height: 120)
                      : VitalsList(vitals: _vitals),
                ),
                const SizedBox(height: 24),
                FadeInSlide(
                  delay: const Duration(milliseconds: 400),
                  child: ActivitySection(
                    steps: _steps,
                    goalSteps: 10000,
                    calories: _calories,
                  ),
                ),

                // Preventive Care Section
                const SizedBox(height: 32),
                FadeInSlide(
                  delay: const Duration(milliseconds: 450),
                  child: SectionHeader(
                    title: 'Preventive Care',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PreventiveCareScreen(),
                        ),
                      );
                    },
                    actionText: 'View All',
                  ),
                ),
                const SizedBox(height: 12),
                FadeInSlide(
                  delay: const Duration(milliseconds: 500),
                  child: _buildPreventiveCareCard(context),
                ),

                const SizedBox(height: 32),
                FadeInSlide(
                  delay: const Duration(milliseconds: 550),
                  child: SectionHeader(
                    title: 'Upcoming Appointments',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScheduleScreen(),
                        ),
                      );
                    },
                    actionText: 'View All',
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const SkeletonCard(height: 100)
                else
                  ..._appointments.map(
                    (appointment) => FadeInSlide(
                      delay: const Duration(milliseconds: 600),
                      child: AppointmentCard(
                        appointment: appointment,
                        onJoin: () {
                          // Handle join/details action
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FadeInSlide(
                  delay: const Duration(milliseconds: 800),
                  child: SectionHeader(
                    title: 'Health Awareness',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InfoCenterScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FadeInSlide(
                  delay: const Duration(milliseconds: 900),
                  child: HealthTipCard(
                    tip: _dailyTip,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InfoCenterScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // AI Prediction Section
                FadeInSlide(
                  delay: const Duration(milliseconds: 1000),
                  child: SectionHeader(
                    title: 'AI Health Prediction',
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
                const SizedBox(height: 12),
                FadeInSlide(
                  delay: const Duration(milliseconds: 1100),
                  child: PredictionCard(
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreventiveCareCard(BuildContext context) {
    final isEligible = _eligibility['eligible'] == true;
    final programType = _eligibility['programType'] ?? 'Annual Wellness Visit';
    final riskCategory = _eligibility['riskCategory'] ?? 'unknown';

    Color riskColor;
    switch (riskCategory.toString().toLowerCase()) {
      case 'low':
        riskColor = Colors.green;
        break;
      case 'medium':
        riskColor = Colors.orange;
        break;
      case 'high':
        riskColor = Colors.red;
        break;
      default:
        riskColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PreventiveCareScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue.withOpacity(0.1),
                AppTheme.secondaryTeal.withOpacity(0.1),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  color: AppTheme.primaryBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      programType,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isEligible
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isEligible ? 'Eligible' : 'Check Eligibility',
                            style: TextStyle(
                              fontSize: 12,
                              color: isEligible ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (riskCategory != 'unknown')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: riskColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Risk: ${riskCategory.toString().toUpperCase()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: riskColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _welcomeName.isEmpty
              ? 'Hello'
              : 'Hello, $_welcomeName',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Here is your daily health update.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
