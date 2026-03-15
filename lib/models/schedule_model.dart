enum ScheduleType { appointment, medicine }

enum ScheduleStatus { upcoming, completed, missed }

class ScheduleItem {
  final String id;
  final String title;
  final String description;
  final DateTime time;
  final ScheduleType type;
  ScheduleStatus status;

  // Specific to Appointment
  final String? doctorName;
  final String? location; // e.g. "Video Call" or "Room 302"

  // Specific to Medicine
  final String? dosage; // e.g. "1 Tablet", "5ml"

  ScheduleItem({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.type,
    this.status = ScheduleStatus.upcoming,
    this.doctorName,
    this.location,
    this.dosage,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'].toString(),
      title: json['diagnosis'] != null ? 'Follow up' : 'Appointment',
      description: json['notes'] ?? 'No notes provided',
      time: DateTime.parse(json['appointmentTime']),
      type: ScheduleType.appointment,
      status: _parseStatus(json['status']),
      doctorName: json['doctor'] != null ? json['doctor']['name'] : null,
      location: 'Virtual',
    );
  }

  static ScheduleStatus _parseStatus(String? status) {
    if (status == 'COMPLETED') return ScheduleStatus.completed;
    if (status == 'CANCELLED') return ScheduleStatus.missed;
    return ScheduleStatus.upcoming;
  }
}
