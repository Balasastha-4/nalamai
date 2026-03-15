import '../../models/user_profile.dart';

class HealthPrediction {
  final String riskLevel; // e.g., 'Low', 'Medium', 'High'
  final List<String> suggestions;
  final double confidenceScore;

  HealthPrediction({
    required this.riskLevel,
    required this.suggestions,
    required this.confidenceScore,
  });
}

class VitalInput {
  final String type;
  final double value;
  final DateTime timestamp;

  VitalInput(this.type, this.value, this.timestamp);
}

abstract class MLHealthService {
  Future<HealthPrediction> predictHealthRisks(
    UserProfile profile,
    List<VitalInput> vitals,
  );

  Future<List<String>> getDietaryRecommendations(UserProfile profile);
}
