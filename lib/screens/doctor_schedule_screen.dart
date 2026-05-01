import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../repositories/interfaces/appointments_repository.dart';
import '../repositories/appointments_repository_impl.dart';
import '../models/schedule_model.dart';
import '../services/auth_service.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  final IAppointmentsRepository _appointmentsRepo = AppointmentsRepositoryImpl();
  List<ScheduleItem> _allAppointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final items = await _appointmentsRepo.getAppointments(true);
      if (mounted) {
        setState(() {
          _allAppointments = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading doctor appointments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ScheduleItem> _getFilteredAppointments() {
    return _allAppointments.where((item) {
      return item.time.year == _selectedDate.year &&
          item.time.month == _selectedDate.month &&
          item.time.day == _selectedDate.day;
    }).toList();
  }

  void _showNewAppointmentModal(BuildContext context) {
    final patientIdController = TextEditingController();
    final notesController = TextEditingController();
    DateTime pickedDateTime = DateTime.now().add(const Duration(hours: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Schedule Appointment',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: patientIdController,
                      decoration: InputDecoration(
                        labelText: 'Patient ID',
                        hintText: 'Enter patient ID e.g. 1',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Consultation Reason / Notes',
                        hintText: 'e.g. Regular Checkup',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.note_alt_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: pickedDateTime,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (pickedDate != null) {
                                setModalState(() {
                                  pickedDateTime = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedDateTime.hour,
                                    pickedDateTime.minute,
                                  );
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(DateFormat('yyyy-MM-dd').format(pickedDateTime)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(pickedDateTime),
                              );
                              if (pickedTime != null) {
                                setModalState(() {
                                  pickedDateTime = DateTime(
                                    pickedDateTime.year,
                                    pickedDateTime.month,
                                    pickedDateTime.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              }
                            },
                            icon: const Icon(Icons.access_time),
                            label: Text(DateFormat('hh:mm a').format(pickedDateTime)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                     SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (patientIdController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid Patient ID')),
                            );
                            return;
                          }

                          final messenger = ScaffoldMessenger.of(context);
                          final authService = AuthService();
                          final doctorId = await authService.getUserId() ?? '1';

                          final success = await _appointmentsRepo.createAppointment(
                            patientId: patientIdController.text.trim(),
                            doctorId: doctorId,
                            appointmentTime: pickedDateTime,
                            notes: notesController.text.trim().isNotEmpty
                                ? notesController.text.trim()
                                : 'Consultation',
                          );

                          if (mounted) {
                            Navigator.pop(context);
                            if (success) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Appointment scheduled successfully!')),
                              );
                              _fetchAppointments();
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Failed to schedule appointment. Please try again.')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Confirm Appointment',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
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
          onPressed: () => _showNewAppointmentModal(context),
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
    final filtered = _getFilteredAppointments();

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
                  '${filtered.length} Patients',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No appointments scheduled for this date.',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildAppointmentCard(filtered[index]);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(ScheduleItem appointment) {
    final DateTime time = appointment.time;
    final String status = appointment.status == ScheduleStatus.completed ? 'Completed' : 'Upcoming';
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
          SizedBox(
            width: 56,
            child: Column(
              children: [
                const SizedBox(height: 24),
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
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                decoration: AppTheme.glassDecoration(context),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
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
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryBlue.withAlpha(30),
                            radius: 20,
                            child: Text(
                              appointment.title.isNotEmpty ? appointment.title[0] : 'P',
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appointment.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  appointment.description,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context).textTheme.bodySmall?.color,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
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
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
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
