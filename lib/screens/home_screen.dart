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
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;

  // Mock Data
  final List<Vital> _vitals = [
    const Vital(
      label: 'Heart Rate',
      value: '98 bpm',
      icon: Icons.favorite,
      color: AppTheme.error,
      isAlert: true,
    ),
    const Vital(
      label: 'Blood Pressure',
      value: '120/80',
      icon: Icons.bloodtype,
      color: AppTheme.primaryBlue,
    ),
    const Vital(
      label: 'SpO2',
      value: '98%',
      icon: Icons.air,
      color: AppTheme.secondaryTeal,
    ),
    const Vital(
      label: 'Weight',
      value: '72 kg',
      icon: Icons.monitor_weight,
      color: Colors.orange,
    ),
  ];

  final ApiService _apiService = ApiService();
  List<ScheduleItem> _appointments = [];

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
      final appointments = await _apiService.getAppointments(false); // pass 'false' for Patient view
      if (mounted) {
        setState(() {
          _appointments = appointments;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInSlide(child: _buildWelcomeSection(context)),
              const SizedBox(height: 20),
              FadeInSlide(
                delay: const Duration(milliseconds: 100),
                child: AlertBanner(
                  title: 'Abnormal Heart Rate Detected',
                  description: 'Your resting heart rate is higher than usual.',
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 24),
              FadeInSlide(
                delay: const Duration(milliseconds: 200),
                child: _isLoading
                    ? const SkeletonCard(height: 140)
                    : const DailySummaryCard(
                        wellnessScore: 85,
                        scoreChange: 2,
                        progressValue: 0.85,
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
                child: const ActivitySection(
                  steps: 7543,
                  goalSteps: 10000,
                  calories: 1200,
                ),
              ),
              const SizedBox(height: 32),
              FadeInSlide(
                delay: const Duration(milliseconds: 500),
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
          'Hello, Balasastha Eswaran',
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
