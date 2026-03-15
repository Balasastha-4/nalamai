import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'doctor_notes_screen.dart';

class PatientHistoryScreen extends StatelessWidget {
  final String patientName;

  const PatientHistoryScreen({super.key, required this.patientName});

  @override
  Widget build(BuildContext context) {
    // Demo Data
    final historyEvents = [
      {
        'date': 'Feb 07, 2026',
        'time': '10:00 AM',
        'title': 'General Checkup',
        'type': 'Visit',
        'doctor': 'Dr. Smith',
        'desc': 'Routine follow-up. BP slightly elevated.',
      },
      {
        'date': 'Feb 05, 2026',
        'time': '02:30 PM',
        'title': 'Blood Test Report',
        'type': 'Report',
        'doctor': 'Lab Tech',
        'desc': 'CBC and Lipid Profile results uploaded.',
      },
      {
        'date': 'Jan 28, 2026',
        'time': '11:15 AM',
        'title': 'Prescription Renewed',
        'type': 'Prescription',
        'doctor': 'Dr. Smith',
        'desc': 'Metformin 500mg - Refill for 3 months.',
      },
      {
        'date': 'Jan 15, 2026',
        'time': '09:00 AM',
        'title': 'Cardiology Consult',
        'type': 'Visit',
        'doctor': 'Dr. Adams',
        'desc': 'Referred for mild chest pain. ECG Normal.',
      },
      {
        'date': 'Dec 20, 2025',
        'time': '04:45 PM',
        'title': 'X-Ray Chest',
        'type': 'Report',
        'doctor': 'Radiology',
        'desc': 'Clear scan. No abnormalities.',
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Timeline',
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              patientName,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 13,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historyEvents.length,
        itemBuilder: (context, index) {
          final event = historyEvents[index];
          final isLast = index == historyEvents.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time Column
                SizedBox(
                  width: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        event['date']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        event['time']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Timeline Line
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getEventColor(event['type']!),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _getEventColor(
                              event['type']!,
                            ).withAlpha(100),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: CustomPaint(
                          size: const Size(2, double.infinity),
                          painter: _DashedLinePainter(
                            Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Event Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.cardBorderColor(context),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getEventIcon(event['type']!),
                                size: 18,
                                color: _getEventColor(event['type']!),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event['title']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event['desc']!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'By ${event['doctor']}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const Spacer(),
                              if (event['type'] == 'Report')
                                IconButton(
                                  icon: const Icon(Icons.download_rounded),
                                  color: AppTheme.primaryBlue,
                                  iconSize: 20,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Downloading report...'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  tooltip: 'Download',
                                ),
                              IconButton(
                                icon: const Icon(Icons.note_alt_outlined),
                                color: AppTheme.secondaryTeal,
                                iconSize: 20,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DoctorNotesScreen(
                                        reportTitle: event['title']!,
                                        date: event['date']!,
                                        patientName: patientName,
                                      ),
                                    ),
                                  );
                                },
                                tooltip: 'View Notes',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'Visit':
        return Colors.blue;
      case 'Report':
        return Colors.orange;
      case 'Prescription':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'Visit':
        return Icons.medical_services;
      case 'Report':
        return Icons.assignment;
      case 'Prescription':
        return Icons.medication;
      default:
        return Icons.circle;
    }
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color lineColor;

  _DashedLinePainter(this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
