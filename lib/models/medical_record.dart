class MedicalRecord {
  final String id;
  final DateTime date;

  String get formattedDate {
    // Basic formatting, consider using intl package if available
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  final String doctor;
  final String specialty;
  final String diagnosis;
  final List<String> medicines;
  final List<String> documents;
  final String notes;

  MedicalRecord({
    required this.id,
    required this.date,
    required this.doctor,
    required this.specialty,
    required this.diagnosis,
    required this.medicines,
    required this.documents,
    this.notes = '',
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.parse(json['recordDate']),
      doctor: json['doctor'] != null ? json['doctor']['name'] : 'Unknown Doctor',
      specialty: 'General', // Not in current backend schema yet
      diagnosis: json['diagnosis'] ?? 'No Diagnosis',
      medicines: json['prescription'] != null ? [json['prescription']] : [],
      documents: [],
      notes: json['notes'] ?? '',
    );
  }
}
