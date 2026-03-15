class Report {
  final String id;
  final String date;
  final String doctorName;
  final String diagnosis;
  final List<String> medicines;
  final String imagePath;

  Report({
    required this.id,
    required this.date,
    required this.doctorName,
    required this.diagnosis,
    required this.medicines,
    required this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'doctorName': doctorName,
      'diagnosis': diagnosis,
      'medicines': medicines,
      'imagePath': imagePath,
    };
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      date: json['date'],
      doctorName: json['doctorName'],
      diagnosis: json['diagnosis'],
      medicines: List<String>.from(json['medicines']),
      imagePath: json['imagePath'],
    );
  }
}
