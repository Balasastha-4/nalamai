import 'package:flutter/material.dart';
import 'dart:async';
import '../services/telemedicine_video_call_service.dart';
import '../services/ai_health_service.dart';
import '../services/interfaces/ml_service_interface.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import 'video_call_screen.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  // Services
  final TelemedicineVideoCallService _videoCallService = TelemedicineVideoCallService();
  final _mlService = MLServiceProvider.instance;

  // Call state tracking
  String _videoCallStatus = "Idle";
  StreamSubscription? _videoCallSub;

  // ML Testing State
  String _riskLevel = "Not Tested Yet";
  List<String> _suggestions = [];
  bool _isLoadingPrediction = false;

  @override
  void initState() {
    super.initState();
    _videoCallSub = _videoCallService.callStatus.listen((status) {
      if (mounted) {
        setState(() {
          _videoCallStatus = status.toString().split('.').last.toUpperCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _videoCallSub?.cancel();
    _videoCallService.endCall();
    super.dispose();
  }

  Future<void> _testStartCall() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VideoCallScreen(roomId: 'doctor_123', isInitiator: true),
      ),
    );
  }

  Future<void> _testEndCall() async {
    await _videoCallService.endCall();
  }

  Future<void> _testAiPrediction() async {
    setState(() {
      _isLoadingPrediction = true;
      _riskLevel = "Analyzing...";
      _suggestions = [];
    });

    try {
      final profile = UserProfile(
        name: 'Test Patient',
        age: '35',
        bloodGroup: 'O+',
        allergies: 'None',
        medicalHistory: 'Stable',
        emergencyContactName: 'Contact',
        emergencyContactPhone: '555-0000',
      );

      final vitals = [
        VitalInput('HeartRate', 105.0, DateTime.now()),
        VitalInput('SystolicBP', 135.0, DateTime.now()),
        VitalInput('DiastolicBP', 88.0, DateTime.now()),
      ];

      final prediction = await _mlService.predictHealthRisks(profile, vitals);

      if (mounted) {
        setState(() {
          _riskLevel = prediction.riskLevel;
          _suggestions = prediction.suggestions;
          _isLoadingPrediction = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _riskLevel = "Error: $e";
          _isLoadingPrediction = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Diagnostics & Service Test'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildTestCard(
            title: 'Telemedicine Service Test',
            subtitle: 'Current Call Status: $_videoCallStatus',
            icon: Icons.video_call,
            color: Colors.teal,
            actions: [
              ElevatedButton.icon(
                onPressed: _testStartCall,
                icon: const Icon(Icons.phone_in_talk),
                label: const Text('Start Call'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              ElevatedButton.icon(
                onPressed: _testEndCall,
                icon: const Icon(Icons.call_end),
                label: const Text('End Call'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTestCard(
            title: 'ML Health Prediction Test',
            subtitle: 'Risk Result: $_riskLevel',
            icon: Icons.analytics_outlined,
            color: AppTheme.primaryBlue,
            actions: [
              _isLoadingPrediction
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _testAiPrediction,
                      icon: const Icon(Icons.radar),
                      label: const Text('Generate Prediction'),
                    ),
            ],
            extraContent: _suggestions.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Suggestions from AI:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        ..._suggestions.map((s) => Text('• $s')),
                      ],
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> actions,
    Widget? extraContent,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            extraContent ?? const SizedBox.shrink(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceEvenly,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}
