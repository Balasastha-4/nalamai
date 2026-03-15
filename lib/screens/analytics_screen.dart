import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo Data
    final heartRateData = [72, 75, 74, 78, 82, 79, 75];
    final systolicData = [120, 122, 118, 125, 130, 128, 124];
    final diastolicData = [80, 82, 78, 84, 85, 83, 81];
    final spo2Data = [98, 99, 97, 98, 99, 98, 99];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildChartCard(
            context,
            title: 'Heart Rate (BPM)',
            chart: _LineChartWidget(
              data: heartRateData,
              days: days,
              color: Colors.redAccent,
              minY: 60,
              maxY: 100,
            ),
          ),
          const SizedBox(height: 16),
          _buildChartCard(
            context,
            title: 'Blood Pressure (mmHg)',
            chart: _BarChartWidget(
              systolic: systolicData,
              diastolic: diastolicData,
              days: days,
            ),
          ),
          const SizedBox(height: 16),
          _buildChartCard(
            context,
            title: 'SpO2 (%)',
            chart: _LineChartWidget(
              data: spo2Data,
              days: days,
              color: Colors.teal,
              minY: 90,
              maxY: 100,
              isCurved: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(
    BuildContext context, {
    required String title,
    required Widget chart,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 24),
          AspectRatio(aspectRatio: 1.5, child: chart),
        ],
      ),
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  final List<int> data;
  final List<String> days;
  final Color color;
  final double minY;
  final double maxY;
  final bool isCurved;

  const _LineChartWidget({
    required this.data,
    required this.days,
    required this.color,
    required this.minY,
    required this.maxY,
    this.isCurved = false,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[index],
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (maxY - minY) / 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: days.length.toDouble() - 1,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(data.length, (index) {
              return FlSpot(index.toDouble(), data[index].toDouble());
            }),
            isCurved: isCurved,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final List<int> systolic;
  final List<int> diastolic;
  final List<String> days;

  const _BarChartWidget({
    required this.systolic,
    required this.diastolic,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 160,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[index],
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value % 40 == 0) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 10,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 40,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        barGroups: List.generate(days.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: systolic[index].toDouble(),
                color: Colors.blueAccent,
                width: 8,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: diastolic[index].toDouble(),
                color: Colors.lightBlueAccent.withValues(alpha: 0.5),
                width: 8,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
