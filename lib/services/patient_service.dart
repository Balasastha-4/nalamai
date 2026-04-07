import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_service.dart';

/// Patient model for doctor's patient management
class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodType;
  final List<String>? allergies;
  final List<String>? conditions;
  final DateTime? lastVisit;
  final String? profileImageUrl;

  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.bloodType,
    this.allergies,
    this.conditions,
    this.lastVisit,
    this.profileImageUrl,
  });

  String get fullName => '$firstName $lastName';

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years--;
    }
    return years;
  }

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id']?.toString() ?? '',
    firstName: json['firstName'] ?? json['first_name'] ?? '',
    lastName: json['lastName'] ?? json['last_name'] ?? '',
    email: json['email'],
    phone: json['phone'] ?? json['phoneNumber'],
    dateOfBirth: json['dateOfBirth'] != null || json['date_of_birth'] != null
        ? DateTime.tryParse(json['dateOfBirth'] ?? json['date_of_birth'])
        : null,
    gender: json['gender'],
    bloodType: json['bloodType'] ?? json['blood_type'],
    allergies: json['allergies'] != null
        ? List<String>.from(json['allergies'])
        : null,
    conditions: json['conditions'] != null
        ? List<String>.from(json['conditions'])
        : null,
    lastVisit: json['lastVisit'] != null || json['last_visit'] != null
        ? DateTime.tryParse(json['lastVisit'] ?? json['last_visit'])
        : null,
    profileImageUrl: json['profileImageUrl'] ?? json['profile_image_url'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'gender': gender,
    'bloodType': bloodType,
    'allergies': allergies,
    'conditions': conditions,
    'lastVisit': lastVisit?.toIso8601String(),
    'profileImageUrl': profileImageUrl,
  };
}

/// Clinical Note model
class ClinicalNote {
  final String id;
  final String patientId;
  final String doctorId;
  final String noteType; // SOAP, Progress, Discharge, Consultation
  final String? subjective;
  final String? objective;
  final String? assessment;
  final String? plan;
  final String? content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ClinicalNote({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.noteType,
    this.subjective,
    this.objective,
    this.assessment,
    this.plan,
    this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory ClinicalNote.fromJson(Map<String, dynamic> json) => ClinicalNote(
    id: json['id']?.toString() ?? '',
    patientId:
        json['patientId']?.toString() ?? json['patient_id']?.toString() ?? '',
    doctorId:
        json['doctorId']?.toString() ?? json['doctor_id']?.toString() ?? '',
    noteType: json['noteType'] ?? json['note_type'] ?? 'Progress',
    subjective: json['subjective'],
    objective: json['objective'],
    assessment: json['assessment'],
    plan: json['plan'],
    content: json['content'],
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'doctorId': doctorId,
    'noteType': noteType,
    'subjective': subjective,
    'objective': objective,
    'assessment': assessment,
    'plan': plan,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

/// Service for doctor's patient management
class PatientService {
  // Use configurable URLs from ApiService
  static String get _javaBaseUrl => '${ApiService.baseUrl}/api';
  static String get _pythonBaseUrl => '${ApiService.aiBaseUrl}/api/ai';
  final AuthService _authService = AuthService();

  /// Get list of patients for a doctor
  Future<List<Patient>> getPatients({
    String? searchQuery,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final doctorId = await _authService.getUserId() ?? '1';

      var url = '$_javaBaseUrl/patients/doctor/$doctorId?page=$page&size=$size';
      if (searchQuery != null && searchQuery.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(searchQuery)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List patients = data is List
            ? data
            : (data['content'] ?? data['patients'] ?? []);
        return patients.map((p) => Patient.fromJson(p)).toList();
      }
      throw Exception('Failed to fetch patients: ${response.statusCode}');
    } catch (e) {
      debugPrint('PatientService Error: $e');
      return _getDemoPatients();
    }
  }

  /// Get patient by ID
  Future<Patient?> getPatientById(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_javaBaseUrl/patients/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return Patient.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('PatientService Error: $e');
      return _getDemoPatients().firstWhere(
        (p) => p.id == patientId,
        orElse: () => _getDemoPatients().first,
      );
    }
  }

  /// Get patient's vitals history
  Future<List<Map<String, dynamic>>> getPatientVitals(
    String patientId, {
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_javaBaseUrl/vitals/patient/$patientId?limit=$limit'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(
          data is List ? data : (data['vitals'] ?? []),
        );
      }
      return [];
    } catch (e) {
      debugPrint('PatientService Error: $e');
      return [];
    }
  }

  /// Get clinical notes for a patient
  Future<List<ClinicalNote>> getPatientNotes(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_javaBaseUrl/clinical-notes/patient/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List notes = data is List ? data : (data['notes'] ?? []);
        return notes.map((n) => ClinicalNote.fromJson(n)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('PatientService Error: $e');
      return [];
    }
  }

  /// Create a new clinical note
  Future<ClinicalNote?> createClinicalNote({
    required String patientId,
    required String noteType,
    String? subjective,
    String? objective,
    String? assessment,
    String? plan,
    String? content,
  }) async {
    try {
      final doctorId = await _authService.getUserId() ?? '1';

      final response = await http.post(
        Uri.parse('$_javaBaseUrl/clinical-notes'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'patientId': patientId,
          'doctorId': doctorId,
          'noteType': noteType,
          'subjective': subjective,
          'objective': objective,
          'assessment': assessment,
          'plan': plan,
          'content': content,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ClinicalNote.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('PatientService Error: $e');
      return null;
    }
  }

  /// Generate AI-assisted clinical note
  Future<Map<String, dynamic>> generateAINotes({
    required String patientId,
    required String noteType,
    required String chiefComplaint,
    Map<String, dynamic>? vitals,
    List<String>? symptoms,
    String? physicalExam,
  }) async {
    try {
      final doctorId = await _authService.getUserId() ?? '1';

      final response = await http.post(
        Uri.parse('$_pythonBaseUrl/notes/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': patientId,
          'doctor_id': doctorId,
          'note_type': noteType,
          'chief_complaint': chiefComplaint,
          'vitals': vitals,
          'symptoms': symptoms,
          'physical_exam': physicalExam,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to generate notes: ${response.statusCode}');
    } catch (e) {
      debugPrint('PatientService Error: $e');
      throw Exception('Network error generating AI notes.');
    }
  }

  /// Update clinical note
  Future<bool> updateClinicalNote(
    String noteId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_javaBaseUrl/clinical-notes/$noteId'),
        headers: await _getHeaders(),
        body: jsonEncode(updates),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('PatientService Error: $e');
      return false;
    }
  }

  /// Delete clinical note
  Future<bool> deleteClinicalNote(String noteId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_javaBaseUrl/clinical-notes/$noteId'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('PatientService Error: $e');
      return false;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  List<Patient> _getDemoPatients() {
    return [
      Patient(
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@email.com',
        phone: '+1 234 567 8900',
        dateOfBirth: DateTime(1985, 5, 15),
        gender: 'Male',
        bloodType: 'A+',
        allergies: ['Penicillin'],
        conditions: ['Hypertension'],
        lastVisit: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Patient(
        id: '2',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane.smith@email.com',
        phone: '+1 234 567 8901',
        dateOfBirth: DateTime(1990, 8, 22),
        gender: 'Female',
        bloodType: 'O+',
        allergies: [],
        conditions: ['Diabetes Type 2'],
        lastVisit: DateTime.now().subtract(const Duration(days: 14)),
      ),
      Patient(
        id: '3',
        firstName: 'Robert',
        lastName: 'Johnson',
        email: 'robert.j@email.com',
        phone: '+1 234 567 8902',
        dateOfBirth: DateTime(1978, 3, 10),
        gender: 'Male',
        bloodType: 'B+',
        allergies: ['Sulfa drugs', 'Aspirin'],
        conditions: [],
        lastVisit: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
  }
}
