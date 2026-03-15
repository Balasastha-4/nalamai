import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import '../widgets/animations/animated_progress.dart';
import 'device_connectivity_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(
      begin: 0.1,
      end: 0.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Central Body Illustration Section
          SizedBox(
            height: 480, // Increased height for better spacing
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Abstract Body Visual with Pulse
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow Effect
                        Container(
                          width: 320,
                          height: 320,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.primaryBlue.withValues(
                                  alpha: _fadeAnimation.value,
                                ),
                                Colors.transparent,
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                        // Body Icon
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Icon(
                            Icons.accessibility_new,
                            size: 300,
                            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // Positioned Metrics
                // Top Left: Temperature
                Positioned(
                  top: 40,
                  left: 0,
                  child: _MiniMetric(
                    icon: Icons.thermostat,
                    value: '36.6°C',
                    color: Colors.orange,
                    label: 'Temp',
                    tooltip: 'Body Temperature',
                    onTap: () => _showMetricDetails(
                      'Body Temperature',
                      '36.6',
                      '°C',
                      Icons.thermostat,
                      Colors.orange,
                      'Normal',
                      Colors.green,
                      0.9,
                      'Your body temperature is normal.',
                    ),
                  ),
                ),
                // Top Right: SpO2
                Positioned(
                  top: 40,
                  right: 0,
                  child: _MiniMetric(
                    icon: Icons.air,
                    value: '98%',
                    color: AppTheme.secondaryTeal,
                    label: 'SpO2',
                    tooltip: 'Blood Oxygen',
                    onTap: () => _showMetricDetails(
                      'Blood Oxygen (SpO2)',
                      '98',
                      '%',
                      Icons.air,
                      AppTheme.secondaryTeal,
                      'Excellent',
                      Colors.green,
                      0.98,
                      'Oxygen saturation levels are excellent.',
                    ),
                  ),
                ),
                // Middle Left: Heart Rate
                Positioned(
                  top: 180,
                  left: 0,
                  child: _MiniMetric(
                    icon: Icons.favorite,
                    value: '72 bpm',
                    color: Colors.redAccent,
                    label: 'Heart',
                    tooltip: 'Heart Rate',
                    onTap: () => _showMetricDetails(
                      'Heart Rate',
                      '72',
                      'bpm',
                      Icons.favorite,
                      Colors.redAccent,
                      'Normal',
                      Colors.green,
                      0.6,
                      'Resting heart rate is optimal.',
                    ),
                  ),
                ),
                // Middle Right: BP
                Positioned(
                  top: 180,
                  right: 0,
                  child: _MiniMetric(
                    icon: Icons.water_drop,
                    value: '120/80',
                    color: AppTheme.primaryBlue,
                    label: 'BP',
                    tooltip: 'Blood Pressure',
                    onTap: () => _showMetricDetails(
                      'Blood Pressure',
                      '120/80',
                      'mmHg',
                      Icons.water_drop,
                      AppTheme.primaryBlue,
                      'Normal',
                      Colors.green,
                      0.7,
                      'Your blood pressure is within the healthy range.',
                    ),
                  ),
                ),
                // Bottom Center: BMI
                Positioned(
                  bottom: 40,
                  child: _MiniMetric(
                    icon: Icons.monitor_weight_outlined,
                    value: '22.5',
                    color: Colors.purple,
                    label: 'BMI',
                    tooltip: 'Body Mass Index',
                    onTap: () => _showMetricDetails(
                      'Body Mass Index',
                      '22.5',
                      '',
                      Icons.monitor_weight_outlined,
                      Colors.purple,
                      'Healthy',
                      Colors.green,
                      0.5,
                      'Your BMI indicates a healthy weight.',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Connectivity Banner
          // Connectivity Banner
          _ConnectivityBanner(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceConnectivityScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Recent Activity Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Icon(Icons.history, size: 20, color: AppTheme.textDark),
                const SizedBox(width: 8),
                Text(
                  'Recent Updates',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityLog(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showMetricDetails(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
    String status,
    Color statusColor,
    double progress,
    String description,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            HealthMetricCard(
              title: title,
              value: value,
              unit: unit,
              icon: icon,
              color: color,
              status: status,
              statusColor: statusColor,
              progress: progress,
              description: description,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLog(BuildContext context) {
    final activities = [
      {
        'title': 'Heart Rate Synced',
        'time': '2 mins ago',
        'icon': Icons.favorite,
        'color': Colors.redAccent,
        'detail': '72 bpm (Resting)',
      },
      {
        'title': 'Blood Pressure Check',
        'time': 'Today, 9:00 AM',
        'icon': Icons.water_drop,
        'color': AppTheme.primaryBlue,
        'detail': '120/80 mmHg (Normal)',
      },
      {
        'title': 'Sleep Analysis',
        'time': 'Yesterday',
        'icon': Icons.bedtime,
        'color': Colors.indigo,
        'detail': '7h 30m • Deep Sleep 2h',
      },
      {
        'title': 'Weight Logged',
        'time': 'Mon, 12 Feb',
        'icon': Icons.monitor_weight_outlined,
        'color': Colors.purple,
        'detail': 'Weight remaining stable.',
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (activity['color'] as Color).withValues(
                        alpha: 0.1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      activity['icon'] as IconData,
                      size: 16,
                      color: activity['color'] as Color,
                    ),
                  ),
                  if (index != activities.length - 1)
                    Container(
                      width: 2,
                      height: 30,
                      margin: const EdgeInsets.only(top: 8),
                      color: Colors.grey[200],
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title'] as String,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity['detail'] as String,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity['time'] as String,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  const _MiniMetric({
    required this.icon,
    required this.value,
    required this.color,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HealthMetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String status;
  final Color statusColor;
  final double progress;
  final String description;

  const HealthMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.status,
    required this.statusColor,
    required this.progress,
    required this.description,
  });

  @override
  State<HealthMetricCard> createState() => _HealthMetricCardState();
}

class _HealthMetricCardState extends State<HealthMetricCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withAlpha(20)
              : Colors.grey.withAlpha(20),
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.value,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                widget.unit,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.status,
                      style: TextStyle(
                        color: widget.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AnimatedProgress(
                  value: widget.progress,
                  backgroundColor: Theme.of(context).dividerColor,
                  color: widget.color,
                  height: 8,
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).iconTheme.color?.withAlpha(150),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectivityBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _ConnectivityBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryBlue.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bluetooth_connected,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sync Health Devices',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connect BP Monitor, Glucometer & more',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
