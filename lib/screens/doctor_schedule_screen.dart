import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  // Demo Data - In a real app, fetch this based on _selectedDate
  final List<Map<String, dynamic>> _appointments = [
    {
      'time': DateTime.now().add(const Duration(hours: 1)),
      'patientName': 'Sarah Connor',
      'type': 'General Checkup',
      'status': 'Upcoming',
      'image': 'assets/images/patient1.png', // Placeholder
    },
    {
      'time': DateTime.now().add(const Duration(hours: 2, minutes: 30)),
      'patientName': 'John Doe',
      'type': 'Cardiology Review',
      'status': 'Upcoming',
      'image': 'assets/images/patient2.png',
    },
    {
      'time': DateTime.now().add(const Duration(hours: 4)),
      'patientName': 'Emily Clark',
      'type': 'Follow-up',
      'status': 'Pending Confirmation',
      'image': 'assets/images/patient3.png',
    },
    {
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'patientName': 'Mike Ross',
      'type': 'Emergency',
      'status': 'Completed',
      'image': 'assets/images/patient4.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Schedule'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: AppTheme.primaryBlue,
            ),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppTheme.primaryBlue,
                        onPrimary: Colors.white,
                        surface: Theme.of(context).cardColor,
                        onSurface: Theme.of(
                          context,
                        ).textTheme.bodyLarge!.color!,
                      ),
                      datePickerTheme: DatePickerThemeData(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        headerHeadlineStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    child: MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: const TextScaler.linear(0.95)),
                      child: child!,
                    ),
                  );
                },
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendarStrip(),
          const SizedBox(height: 16),
          _buildTimeline(),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {},
          backgroundColor: AppTheme.primaryBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'New Appointment',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return Container(
      height: 85, // Reduced from 100
      color: Colors.transparent,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 14, // 2 weeks
        itemBuilder: (context, index) {
          final date = DateTime.now().add(
            Duration(days: index - 2),
          ); // Start slightly in past
          final isSelected =
              date.day == _selectedDate.day &&
              date.month == _selectedDate.month;
          final isToday =
              date.day == DateTime.now().day &&
              date.month == DateTime.now().month;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
            },
            child: Container(
              width: 50, // Reduced from 60
              margin: const EdgeInsets.only(right: 8), // Reduced from 12
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(25), // Pill shape
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withAlpha(100),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : const BoxDecoration(
                      color: Colors.transparent, // Floating text
                    ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isToday && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      width: 5, // Reduced from 6
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11, // Reduced from 12
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 6), // Reduced from 8
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18, // Reduced from 22
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeline() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Appointments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_appointments.length} Patients',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _appointments.length,
                itemBuilder: (context, index) {
                  return _buildAppointmentCard(_appointments[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final DateTime time = appointment['time'];
    final String status = appointment['status'];
    final bool isCompleted = status == 'Completed';

    Color statusColor;
    if (status == 'Upcoming') {
      statusColor = AppTheme.primaryBlue;
    } else if (status == 'Completed') {
      statusColor = Colors.green;
    } else {
      statusColor = Colors.orange;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact Timeline Track
          SizedBox(
            width: 56, // Thinner width
            child: Column(
              children: [
                const SizedBox(height: 24), // Align with card content
                Text(
                  DateFormat('hh:mm').format(time),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('a').format(time),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withAlpha(100),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Appointment Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                decoration: AppTheme.glassDecoration(context),
                child: Padding(
                  padding: const EdgeInsets.all(16), // Reduced from 20
                  child: Column(
                    children: [
                      // Top Row: Status only (Time is on timeline)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Middle Row: Avatar and Patient Details
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryBlue.withAlpha(30),
                            radius: 20, // Reduced from 28
                            child: Text(
                              appointment['patientName'][0],
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16, // Reduced from 20
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appointment['patientName'],
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  appointment['type'],
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.5),
                        height: 1,
                      ),
                      const SizedBox(height: 12),
                      if (!isCompleted)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.description_outlined,
                                  size: 16,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                label: Text(
                                  'Records',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  side: BorderSide(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.video_call, size: 16),
                                label: const Text(
                                  'Join Call',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.edit_note, size: 16),
                              label: const Text(
                                'View Notes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
