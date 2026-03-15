import 'dart:convert';

class UserProfile {
  String name;
  String age;
  String bloodGroup;
  String allergies;
  String medicalHistory;
  String emergencyContactName;
  String emergencyContactPhone;

  UserProfile({
    required this.name,
    required this.age,
    required this.bloodGroup,
    required this.allergies,
    required this.medicalHistory,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  // Default empty profile
  factory UserProfile.empty() {
    return UserProfile(
      name: 'Sarah Smith',
      age: '28',
      bloodGroup: 'O+',
      allergies: 'Peanuts, Penicillin',
      medicalHistory: 'Hypertension (diagnosed 2022)',
      emergencyContactName: 'John Smith',
      emergencyContactPhone: '+1 555-0123',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medicalHistory': medicalHistory,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      age: json['age'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      allergies: json['allergies'] ?? '',
      medicalHistory: json['medicalHistory'] ?? '',
      emergencyContactName: json['emergencyContactName'] ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] ?? '',
    );
  }

  String toJsonString() => json.encode(toJson());

  factory UserProfile.fromJsonString(String jsonString) {
    return UserProfile.fromJson(json.decode(jsonString));
  }
}
