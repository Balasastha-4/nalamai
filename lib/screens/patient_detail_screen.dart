import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animations/fade_in_slide.dart';
import 'document_review_screen.dart';
import 'doctor_notes_screen.dart';
import 'patient_history_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientName;
  final String patientId;

  const PatientDetailScreen({
    super.key,
    required this.patientName,
    required this.patientId,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _expandedVitals = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.patientName),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        iconTheme: Theme.of(context).iconTheme,
        actions: [
          IconButton(
            icon: Icon(
              Icons.videocam_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {},
            tooltip: 'Video Call',
          ),
          IconButton(
            icon: Icon(
              Icons.call_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {},
            tooltip: 'Audio Call',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 13,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                ),
              ),
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(height: 32, text: 'Overview'),
                Tab(height: 32, text: 'Vitals'),
                Tab(height: 32, text: 'Predictions'),
                Tab(height: 32, text: 'Documents'),
                Tab(height: 32, text: 'Reports'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FadeInSlide(child: _buildOverviewTab()),
          FadeInSlide(child: _buildVitalsTab()),
          FadeInSlide(child: _buildPredictionsTab()),
          FadeInSlide(child: _buildDocumentsTab()),
          FadeInSlide(child: _buildReportsTab()),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactProfileHeader(),
          const SizedBox(height: 16),
          _buildAISummaryCard(),
          const SizedBox(height: 24),
          _buildSectionTitle('Medical Bio'),
          const SizedBox(height: 12),
          _buildBioCard(),
          const SizedBox(height: 24),
          _buildSectionTitle('Active Conditions'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('Hypertension', Colors.orange),
              _buildChip('Type 2 Diabetes', Colors.red),
              _buildChip('Asthma', Colors.blue),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Device Status'),
          const SizedBox(height: 12),
          _buildDeviceStatusCard(),
        ],
      ),
    );
  }

  Widget _buildVitalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Latest Readings'),
          const SizedBox(height: 16),
          _buildEnhancedVitalCard(
            title: 'Blood Pressure',
            value: '135/85',
            unit: 'mmHg',
            color: Colors.orange,
            icon: Icons.favorite,
            trend: 'stable',
            lastReadings: [130, 132, 135, 134, 135],
          ),
          const SizedBox(height: 12),
          _buildEnhancedVitalCard(
            title: 'Heart Rate',
            value: '78',
            unit: 'bpm',
            color: Colors.green,
            icon: Icons.monitor_heart,
            trend: 'up',
            lastReadings: [72, 75, 74, 76, 78],
          ),
          const SizedBox(height: 12),
          _buildEnhancedVitalCard(
            title: 'SpO2',
            value: '98',
            unit: '%',
            color: Colors.blue,
            icon: Icons.air,
            trend: 'stable',
            lastReadings: [99, 98, 98, 99, 98],
          ),
          const SizedBox(height: 12),
          _buildEnhancedVitalCard(
            title: 'Body Temperature',
            value: '37.5',
            unit: '°C',
            color: Colors.green,
            icon: Icons.thermostat,
            trend: 'down',
            lastReadings: [38.2, 38.0, 37.8, 37.6, 37.5],
          ),
          const SizedBox(height: 12),
          _buildEnhancedVitalCard(
            title: 'Blood Sugar',
            value: '110',
            unit: 'mg/dL',
            color: Colors.orange,
            icon: Icons.water_drop,
            trend: 'variable',
            lastReadings: [105, 115, 108, 120, 110],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedVitalCard(
                  title: 'BMI',
                  value: '25.9',
                  unit: 'kg/m²',
                  color: Colors.amber,
                  icon: Icons.monitor_weight,
                  trend: 'stable',
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedVitalCard(
                  title: 'Resp Rate',
                  value: '18',
                  unit: 'br/min',
                  color: Colors.green,
                  icon: Icons.air,
                  trend: 'stable',
                  isCompact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Risk Analysis Overview'),
          const SizedBox(height: 16),
          _buildComparisonChart(),
          const SizedBox(height: 24),
          _buildSectionTitle('Risk Trends (Last 6 Months)'),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: RiskTrendPainter(Theme.of(context)),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Detailed Risk Assessment'),
          const SizedBox(height: 12),
          _buildRiskCard(
            title: 'Diabetes Risk',
            risk: 'High',
            trend: 'increasing',
            color: Colors.red,
            icon: Icons.water_drop,
            explanation:
                'Random glucose (110 mg/dL) is elevated. Trend shows a 5% increase over the last 3 months.',
          ),
          _buildRiskCard(
            title: 'Hypertension',
            risk: 'Moderate',
            trend: 'stable',
            color: Colors.orange,
            icon: Icons.speed,
            explanation:
                'BP (135/85) is in the pre-hypertension range. Stable over last 4 visits.',
          ),
          _buildRiskCard(
            title: 'Cardiac Event',
            risk: 'Moderate',
            trend: 'decreasing',
            color: Colors.orange,
            icon: Icons.favorite,
            explanation:
                'Composite risk based on Age, BP, and BMI. Risk has decreased by 2% due to weight loss.',
          ),
          _buildRiskCard(
            title: 'Obesity',
            risk: 'Low',
            trend: 'stable',
            color: Colors.green,
            icon: Icons.monitor_weight,
            explanation:
                'BMI (25.9) is slightly overweight but stable. No immediate intervention required.',
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDocumentTile('Blood Test Result - Feb 2026', 'PDF', '2.4 MB'),
        const SizedBox(height: 12),
        _buildDocumentTile('X-Ray Chest Scan', 'JPG', '5.1 MB'),
        const SizedBox(height: 12),
        _buildDocumentTile('Prescription - Jan 2026', 'PDF', '1.1 MB'),
      ],
    );
  }

  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Recent Reports'),
        const SizedBox(height: 12),
        _buildReportTile('General Checkup', 'Dr. Smith', 'Feb 01, 2026'),
        const SizedBox(height: 12),
        _buildReportTile('Cardiology Consult', 'Dr. Adams', 'Jan 15, 2026'),
        const SizedBox(height: 12),
        _buildReportTile('Endocrinology', 'Dr. Ray', 'Dec 20, 2025'),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PatientHistoryScreen(patientName: widget.patientName),
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('View Full History'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppTheme.primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildCompactProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'avatar_${widget.patientName}',
            child: CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
              child: Text(
                widget.patientName.isNotEmpty ? widget.patientName[0] : '?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '45 years • Male',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${widget.patientId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAISummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.primaryBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Health Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Stable',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryLine(
                      'Overall health has improved by 5% since last week.',
                    ),
                    _buildSummaryLine(
                      'Blood pressure is stabilizing within target range.',
                    ),
                    _buildSummaryLine(
                      'Activity levels are up; recommended to maintain current meds.',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildHealthScoreGauge(84),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreGauge(int score) {
    return Column(
      children: [
        SizedBox(
          height: 70,
          width: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: score / 100,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                color: _getScoreColor(score),
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
              ),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(score),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Health Score',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }

  Widget _buildBioCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.cardBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBioRow('Blood Group', 'O+'),
          const Divider(),
          _buildBioRow('Height', '178 cm'),
          const Divider(),
          _buildBioRow('Weight', '82 kg'),
          const Divider(),
          _buildBioRow('Allergies', 'Penicillin, Peanuts'),
        ],
      ),
    );
  }

  Widget _buildBioRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, MaterialColor color) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(color: color[800], fontWeight: FontWeight.bold),
      ),
      backgroundColor: color[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildDeviceStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.watch, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Watch Connected',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Last synced: 2 mins ago',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedVitalCard({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
    required String trend,
    List<double>? lastReadings,
    bool isCompact = false,
  }) {
    IconData trendIcon;
    Color trendColor;

    switch (trend) {
      case 'up':
        trendIcon = Icons.trending_up;
        trendColor = Colors.red;
        break;
      case 'down':
        trendIcon = Icons.trending_down;
        trendColor = Colors.green;
        break;
      case 'variable':
        trendIcon = Icons.compare_arrows;
        trendColor = Colors.orange;
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.grey;
    }

    final bool isAbnormal = color == Colors.red || color == Colors.orange;
    final Color cardBg = isAbnormal
        ? color.withValues(alpha: 0.05)
        : Theme.of(context).cardColor;

    final bool isExpanded = _expandedVitals.contains(title);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedVitals.remove(title);
          } else {
            _expandedVitals.add(title);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: isAbnormal
                ? color.withValues(alpha: 0.3)
                : AppTheme.cardBorderColor(context),
            width: isAbnormal ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isAbnormal
                                  ? color
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              unit,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isCompact)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: trendColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(trendIcon, color: trendColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          trend.toUpperCase(),
                          style: TextStyle(
                            color: trendColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (isExpanded && lastReadings != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    Text(
                      '7-Day History',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: lastReadings.map((reading) {
                          double max = lastReadings.reduce(
                            (curr, next) => curr > next ? curr : next,
                          );
                          double min = lastReadings.reduce(
                            (curr, next) => curr < next ? curr : next,
                          );
                          double range = max - min;
                          if (range == 0) range = 1;
                          double heightFactor = (reading - min) / range;
                          double height = 15 + (heightFactor * 35);

                          return Container(
                            width: 10,
                            height: height,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Average: ${(lastReadings.reduce((a, b) => a + b) / lastReadings.length).toStringAsFixed(1)} $unit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Relative Risk Comparison',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildBarChartRow('Diabetes', 0.8, Colors.red),
          const SizedBox(height: 12),
          _buildBarChartRow('Hypertension', 0.6, Colors.orange),
          const SizedBox(height: 12),
          _buildBarChartRow('Cardiac', 0.45, Colors.orange),
          const SizedBox(height: 12),
          _buildBarChartRow('Obesity', 0.2, Colors.green),
        ],
      ),
    );
  }

  Widget _buildBarChartRow(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(value * 100).toInt()}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskCard({
    required String title,
    required String risk,
    required String trend,
    required Color color,
    required IconData icon,
    required String explanation,
  }) {
    IconData trendIcon;
    Color trendIconColor;

    switch (trend) {
      case 'increasing':
        trendIcon = Icons.trending_up;
        trendIconColor = Colors.red;
        break;
      case 'decreasing':
        trendIcon = Icons.trending_down;
        trendIconColor = Colors.green;
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendIconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                risk,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(trendIcon, size: 16, color: trendIconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                trend,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).iconTheme.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    explanation,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(String name, String type, String size) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            type == 'PDF' ? Icons.picture_as_pdf : Icons.image,
            color: Colors.red,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$type • $size'),
        trailing: const Icon(Icons.download_rounded, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentReviewScreen(
                documentTitle: name,
                documentType: type,
                patientName: widget.patientName,
                date: 'Feb 07, 2026', // Demo date
                patientId: widget.patientId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportTile(String title, String doctor, String date) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorderColor(context)),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('By $doctor'),
        onTap: () {},
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              date,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.note_add, color: AppTheme.primaryBlue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorNotesScreen(
                      reportTitle: title,
                      date: date,
                      patientName: widget.patientName,
                    ),
                  ),
                );
              },
              tooltip: 'Add Note',
            ),
          ],
        ),
      ),
    );
  }
}

class RiskTrendPainter extends CustomPainter {
  final ThemeData theme;

  RiskTrendPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      color: theme.textTheme.bodySmall?.color ?? Colors.grey,
      fontSize: 10,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Simulated Data Points (0.0 to 1.0 risk scale)
    // Diabetes (Red), Hypertension (Orange), Cardiac (Blue)
    final diabetesPoints = [0.6, 0.65, 0.7, 0.72, 0.75, 0.8];
    final hypertensionPoints = [0.5, 0.52, 0.55, 0.58, 0.6, 0.6];
    final startX = 30.0;
    final endX = size.width - 10;
    final stepX = (endX - startX) / (diabetesPoints.length - 1);
    final bottomY = size.height - 30;
    final topY = 20.0;
    final graphHeight = bottomY - topY;

    // Draw Grid Lines & Labels
    final linePaint = Paint()
      ..color = theme.dividerColor.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (int i = 0; i <= 5; i++) {
      final y = bottomY - (graphHeight * (i / 5));
      canvas.drawLine(Offset(startX, y), Offset(endX, y), linePaint);

      textPainter.text = TextSpan(text: '${i * 20}%', style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Draw Months (X Axis)
    final months = ['Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb'];
    for (int i = 0; i < months.length; i++) {
      textPainter.text = TextSpan(text: months[i], style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(startX + (stepX * i) - 10, bottomY + 10),
      );
    }

    // Helper to draw line
    void drawLine(List<double> points, Color color) {
      paint.color = color;
      dotPaint.color = color;

      final path = Path();
      for (int i = 0; i < points.length; i++) {
        final x = startX + (stepX * i);
        final y = bottomY - (points[i] * graphHeight);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }

        canvas.drawCircle(Offset(x, y), 4, dotPaint);
      }
      canvas.drawPath(path, paint);
    }

    drawLine(diabetesPoints, Colors.red);
    drawLine(hypertensionPoints, Colors.orange);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
