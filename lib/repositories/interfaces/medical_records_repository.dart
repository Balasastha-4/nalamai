import '../../models/medical_record.dart';

abstract class IMedicalRecordsRepository {
  Future<List<MedicalRecord>> getMedicalRecords();
  Future<bool> saveMedicalRecord({
    required String patientId,
    required String diagnosis,
    List<String> medicines = const [],
    String notes = '',
  });
}
