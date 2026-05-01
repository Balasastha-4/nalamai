abstract class IPreventiveCareRepository {
  Future<Map<String, dynamic>> getPatientEligibility(String patientId);
  Future<Map<String, dynamic>> getPatientHRA(String patientId);
  Future<Map<String, dynamic>> submitHRA(Map<String, dynamic> hraData);
  Future<List<dynamic>> getPreventionPlans(String patientId);
  Future<Map<String, dynamic>> getActivePlan(String patientId);
  Future<List<dynamic>> getFollowUps(String patientId);
  Future<Map<String, dynamic>> getAdherenceStats(String patientId);
  Future<Map<String, dynamic>> predictNoShow(String patientId);
  Future<Map<String, dynamic>> assessRisk(String patientId);
}
