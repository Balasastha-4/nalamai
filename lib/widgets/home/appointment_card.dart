import 'package:flutter/material.dart';
import '../../models/schedule_model.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class AppointmentCard extends StatelessWidget {
  final ScheduleItem appointment;
  final VoidCallback? onJoin;

  const AppointmentCard({super.key, required this.appointment, this.onJoin});

  @override
  Widget build(BuildContext context) {
    final isVideo = appointment.location?.contains('Video') ?? false;
    final timeStr = DateFormat('h:mm a').format(appointment.time);
    final isToday =
        DateTime.now().day == appointment.time.day &&
        DateTime.now().month == appointment.time.month &&
        DateTime.now().year == appointment.time.year;
    final dateStr = isToday
        ? 'Today'
        : DateFormat('MMM d').format(appointment.time);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left side (Color strip)
              Container(
                width: 6,
                color: isVideo ? Colors.purple : AppTheme.warning,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isVideo
                              ? Colors.purple.withValues(alpha: 0.1)
                              : AppTheme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isVideo ? Icons.videocam : Icons.calendar_today,
                          color: isVideo ? Colors.purple : AppTheme.warning,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              appointment.doctorName ?? 'Doctor',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${appointment.description} • $dateStr, $timeStr',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[400]
                                        : AppTheme.textLight,
                                  ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      // Divider Line
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey.withValues(alpha: 0.2),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      TextButton(
                        onPressed: onJoin,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(isVideo ? 'Join' : 'Details'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
