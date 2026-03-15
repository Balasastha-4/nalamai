import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/schedule_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  final ApiService _apiService = ApiService();
  List<ScheduleItem> _allSchedule = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    setState(() => _isLoading = true);
    final appointments = await _apiService.getAppointments(false);
    
    // Generate dummy medicines since backend only does appointments for now
    final mockMedicines = [
      ScheduleItem(
        id: 'mock1',
        title: 'Amlodipine',
        description: 'For Hypertension',
        time: DateTime.now().add(const Duration(hours: 1)),
        type: ScheduleType.medicine,
        status: ScheduleStatus.upcoming,
        dosage: '5mg (1 Tablet)',
      )
    ];

    if (mounted) {
      setState(() {
        _allSchedule = [...appointments, ...mockMedicines];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ScheduleItem> _getFilteredItems(ScheduleType type) {
    // For demo, we just filter by type.
    // In a real app, we would also filter by _selectedDate.
    return _allSchedule.where((item) => item.type == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: 'Appointments'),
            Tab(text: 'Medicines'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildCalendarStrip(),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildScheduleList(ScheduleType.appointment),
                      _buildScheduleList(ScheduleType.medicine),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return Container(
      height: 100,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = index == 0; // Always select today for demo

          return Container(
            width: 60,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryBlue
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? null
                  : Border.all(color: Theme.of(context).dividerColor),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE').format(date).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleList(ScheduleType type) {
    final items = _getFilteredItems(type);

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No ${type == ScheduleType.appointment ? "appointments" : "medicines"} for today',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildItemCard(items[index]);
      },
    );
  }

  Widget _buildItemCard(ScheduleItem item) {
    final isCompleted = item.status == ScheduleStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: isCompleted
          ? Theme.of(context).disabledColor.withAlpha(20)
          : Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  DateFormat('hh:mm').format(item.time),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isCompleted
                        ? Colors.grey
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  DateFormat('a').format(item.time),
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted ? Colors.grey : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.grey
                    : (item.type == ScheduleType.appointment
                          ? Colors.orange
                          : AppTheme.secondaryTeal),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCompleted
                          ? Colors.grey
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.type == ScheduleType.appointment
                        ? item.location ?? ''
                        : item.dosage ?? '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            if (item.type == ScheduleType.medicine)
              Checkbox(
                value: isCompleted,
                activeColor: AppTheme.secondaryTeal,
                onChanged: (val) {
                  setState(() {
                    item.status = val == true
                        ? ScheduleStatus.completed
                        : ScheduleStatus.upcoming;
                  });
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.video_call),
                color: isCompleted ? Colors.grey : AppTheme.primaryBlue,
                onPressed: isCompleted
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Starting Video Call...'),
                          ),
                        );
                      },
              ),
          ],
        ),
      ),
    );
  }
}
