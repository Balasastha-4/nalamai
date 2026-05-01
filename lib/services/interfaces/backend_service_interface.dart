import '../../models/user_profile.dart';
import '../../models/medical_record.dart';

abstract class BackendService {
  Future<void> syncUserData(UserProfile profile);
  Future<UserProfile?> fetchUserData(String userId);
  Future<List<MedicalRecord>> fetchMedicalRecords(String userId);
  Future<void> saveMedicalRecord(MedicalRecord record);
}
