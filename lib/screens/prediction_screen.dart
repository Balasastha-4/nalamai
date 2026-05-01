import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import '../services/ai_service.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final AiService _aiService = AiService();
  bool _isLoading = true;
  String _healthPrediction = "Stable";
  int _riskScore = 0;
  List<String> _warnings = [];
  double _confidence = 0.0;

  // Demo Input Data (In a real app, this comes from the User Model)
  final demoData = {
    'heartRate': 110.0,
    'bp_systolic': 145.0,
    'bp_diastolic': 95.0,
    'oxygenLevel': 94.0,
    'temperature': 99.1,
    'age': 35.0,
    'glucose': 110.0,
    'bmi': 28.5,
  };

  @override
  void initState() {
    super.initState();
    _fetchAiPrediction();
  }

  Future<void> _fetchAiPrediction() async {
    try {
      // Map the local UI demo data to what specifically the Pydantic FastAPI model expects
      final apiPayload = {
        'heartRate': (demoData['heartRate'] ?? 0).toInt(),
        'systolicBP': (demoData['bp_systolic'] ?? 0).toInt(),
        'diastolicBP': (demoData['bp_diastolic'] ?? 0).toInt(),
        'oxygenLevel': (demoData['oxygenLevel'] ?? 0).toInt(),
        'temperature': (demoData['temperature'] ?? 0).toDouble(),
        'age': (demoData['age'] ?? 0).toInt(),
      };

      final response = await _aiService.getHealthPrediction(apiPayload);
      setState(() {
        _healthPrediction = response['health_prediction'] ?? "Stable";
        _riskScore = response['risk_score'] ?? 0;
        _warnings = List<String>.from(response['warnings'] ?? []);
        _confidence = (response['model_confidence'] ?? 0.0) * 100;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _warnings = ["Failed to connect to AI server."];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('AI Health Prediction'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverallHealthScore(context),
                  if (_warnings.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildWarningsBox(context),
                  ],
                  const SizedBox(height: 32),
                  _buildInputSummary(context, demoData),
                  const SizedBox(height: 32),
                  _buildComparisonChart(context),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Text(
                        'Detailed Risk Assessment',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Tooltip(
                        message: 'Tap on cards to see detailed explanations.',
                        child: Icon(
                          Icons.help_outline,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRiskCard(
                    context: context,
                    title: 'Diabetes Risk',
                    riskLevel: _getDiabetesRisk(
                      (demoData['glucose'] as num?)?.toDouble() ?? 0.0,
                    ),
                    icon: Icons.water_drop,
                    shortDesc: 'Based on random blood glucose levels.',
                    longDesc:
                        'A random glucose level of 110 mg/dL is within the normal range (70-140 mg/dL). Consistent monitoring is recommended to maintain this healthy state.',
                  ),
                  _buildRiskCard(
                    context: context,
                    title: 'Hypertension Risk',
                    riskLevel: _getHypertensionRisk(
                      (demoData['bp_systolic'] as num?)?.toInt() ?? 0,
                      (demoData['bp_diastolic'] as num?)?.toInt() ?? 0,
                    ),
                    icon: Icons.speed,
                    shortDesc: 'Based on systolic and diastolic BP.',
                    longDesc:
                        'Your BP is 135/85 mmHg, which is considered "High Normal" or "Pre-hypertension". Lifestyle changes like reducing salt intake and exercising can help lower it.',
                  ),
                  _buildRiskCard(
                    context: context,
                    title: 'Obesity Risk',
                    riskLevel: _getObesityRisk(
                      (demoData['bmi'] as num?)?.toDouble() ?? 0.0,
                    ),
                    icon: Icons.monitor_weight,
                    shortDesc: 'Based on Body Mass Index (BMI).',
                    longDesc:
                        'A BMI of 28.5 falls into the "Overweight" category (25-29.9). Aiming for a BMI between 18.5 and 24.9 is optimal for long-term health.',
                  ),
                  _buildRiskCard(
                    context: context,
                    title: 'Cardiac Risk',
                    riskLevel: _getCardiacRisk(demoData),
                    icon: Icons.favorite,
                    shortDesc: 'Composite score based on BP, BMI, and Age.',
                    longDesc:
                        'This is a composite score. While age is low risk, slightly elevated BP and BMI contribute to a moderate risk profile. Regular cardio exercise is advised.',
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.privacy_tip_outlined,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Disclaimer: The AI Prediction confidence is ${_confidence.toInt()}%. These predictions are generated by the Nalamai AI Microservice and should not be used for medical diagnosis. Always consult a doctor.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                              height: 1.4,
                            ),
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

  Widget _buildOverallHealthScore(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryTeal.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 150,
            height: 150,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 0.75),
              duration: const Duration(seconds: 2),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                backgroundColor: AppTheme.secondaryTeal.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.secondaryTeal,
                ),
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_riskScore',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryTeal,
                ),
              ),
              Text(
                'Risk Score\n($_healthPrediction)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.error),
              const SizedBox(width: 8),
              Text(
                'AI Warnings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.error,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "• ",
                    style: TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      w,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          _buildBarChartRow(context, 'Diabetes', 0.2, AppTheme.success),
          const SizedBox(height: 20),
          _buildBarChartRow(context, 'Hypertension', 0.6, AppTheme.warning),
          const SizedBox(height: 20),
          _buildBarChartRow(context, 'Obesity', 0.5, AppTheme.warning),
          const SizedBox(height: 20),
          _buildBarChartRow(context, 'Cardiac', 0.4, AppTheme.error),
        ],
      ),
    );
  }

  Widget _buildBarChartRow(
    BuildContext context,
    String label,
    double targetValue,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: targetValue),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutQuart,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 40,
          child: Text(
            '${(targetValue * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildInputSummary(BuildContext context, Map<String, num> data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.05),
            AppTheme.primaryBlue.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Key Metrics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInputItem(
                context,
                'Heart Rate',
                '${data['heartRate']} bpm',
              ),
              _buildInputItem(context, 'SpO2', '${data['oxygenLevel']}%'),
              _buildInputItem(
                context,
                'BP',
                '${(data['bp_systolic'] ?? 0).toInt()}/${(data['bp_diastolic'] ?? 0).toInt()}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskCard({
    required BuildContext context,
    required String title,
    required RiskLevel riskLevel,
    required IconData icon,
    required String shortDesc,
    required String longDesc,
  }) {
    Color color;
    String riskText;

    switch (riskLevel) {
      case RiskLevel.low:
        color = AppTheme.success;
        riskText = 'Low Risk';
        break;
      case RiskLevel.moderate:
        color = AppTheme.warning;
        riskText = 'Moderate Risk';
        break;
      case RiskLevel.high:
        color = AppTheme.error;
        riskText = 'High Risk';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(20),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  riskText,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              shortDesc,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.insights, size: 16, color: color),
                      const SizedBox(width: 8),
                      Text(
                        'AI Analysis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    longDesc,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About AI Predictions'),
        content: const Text(
          'This module simulates AI analysis using rule-based algorithms on demo data.\n\nRisk Levels:\n\n'
          '🟢 Low: Within healthy range.\n'
          '🟠 Moderate: Borderline, monitoring advised.\n'
          '🔴 High: Outside healthy range, consult doctor.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- Demo Logic ---

  RiskLevel _getDiabetesRisk(double glucose) {
    if (glucose > 180) return RiskLevel.high;
    if (glucose > 140) return RiskLevel.moderate;
    return RiskLevel.low;
  }

  RiskLevel _getHypertensionRisk(int systolic, int diastolic) {
    if (systolic >= 140 || diastolic >= 90) return RiskLevel.high;
    if (systolic >= 120 || diastolic >= 80) return RiskLevel.moderate;
    return RiskLevel.low;
  }

  RiskLevel _getObesityRisk(double bmi) {
    if (bmi >= 30) return RiskLevel.high;
    if (bmi >= 25) return RiskLevel.moderate;
    return RiskLevel.low;
  }

  RiskLevel _getCardiacRisk(Map<String, num> data) {
    // Simple composite Logic
    int score = 0;
    if ((data['bmi'] ?? 0) >= 25) score++;
    if ((data['bp_systolic'] ?? 0) >= 120) score++;
    if ((data['age'] ?? 0) > 40) score++;

    if (score >= 3) return RiskLevel.high;
    if (score >= 1) return RiskLevel.moderate;
    return RiskLevel.low;
  }
}

enum RiskLevel { low, moderate, high }
