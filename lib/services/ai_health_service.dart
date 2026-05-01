import 'ai_service.dart';
import 'interfaces/ml_service_interface.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class AiHealthService implements MLHealthService {
  final AiService _aiService = AiService();

  @override
  Future<HealthPrediction> predictHealthRisks(
    UserProfile profile,
    List<VitalInput> vitals,
  ) async {
    try {
      int? heartRate;
      int? sysBp;
      int? diaBp;
      double? oxygen;
      double? temp;
      double? glucose;
      int? respRate;

      for (var v in vitals) {
        final type = v.type.toLowerCase();
        if (type == 'heartrate' || type == 'heart_rate') {
          heartRate = v.value.toInt();
        } else if (type == 'systolicbp' || type == 'blood_pressure_systolic' || type == 'systolic_bp') {
          sysBp = v.value.toInt();
        } else if (type == 'diastolicbp' || type == 'blood_pressure_diastolic' || type == 'diastolic_bp') {
          diaBp = v.value.toInt();
        } else if (type == 'blood_oxygen' || type == 'spo2' || type == 'oxygen') {
          oxygen = v.value;
        } else if (type == 'temperature' || type == 'temp') {
          temp = v.value;
        } else if (type == 'blood_glucose' || type == 'glucose') {
          glucose = v.value;
        } else if (type == 'respiratoryrate' || type == 'respiratory_rate' || type == 'resp_rate') {
          respRate = v.value.toInt();
        }
      }

      heartRate ??= 75;
      sysBp ??= 120;
      diaBp ??= 80;
      oxygen ??= 98.0;
      temp ??= 36.8;
      respRate ??= 16;
      glucose ??= 100.0;

      final authService = AuthService();
      final userId = await authService.getUserId() ?? '1';
      final token = await authService.getToken() ?? 'dummy_token';

      final Map<String, dynamic> payload = {
        'patient_id': userId,
        'vital_signs': {
          'heart_rate': heartRate,
          'blood_pressure_systolic': sysBp,
          'blood_pressure_diastolic': diaBp,
          'blood_oxygen': oxygen,
          'temperature': temp,
          'respiratory_rate': respRate,
          'blood_glucose': glucose,
        },
        'token': token,
      };

      final result = await _aiService.getHealthPrediction(payload);

      return HealthPrediction(
        riskLevel: result['risk_level'] ?? 'Unknown',
        suggestions: List<String>.from(result['suggestions'] ?? result['recommendations'] ?? []),
        confidenceScore: (result['confidence'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      debugPrint('AiHealthService predictHealthRisks error: $e');
      return HealthPrediction(
        riskLevel: 'Error',
        suggestions: ['Could not reach AI service for prediction'],
        confidenceScore: 0.0,
      );
    }
  }

  @override
  Future<List<String>> getDietaryRecommendations(UserProfile profile) async {
    try {
      final result = await _aiService.sendChatMessage(
        "Provide 3 dietary recommendations for a ${profile.age} year old based on their profile.",
        '1',
      );

      final String content = result['agent_response'] ?? '';
      return content.split('\n')
          .where((s) => s.trim().startsWith('-') || s.trim().startsWith('*') || RegExp(r'^\d+\.').hasMatch(s.trim()))
          .map((s) => s.replaceFirst(RegExp(r'^[-*]\s*|\d+\.\s*'), '').trim())
          .toList();
    } catch (e) {
      debugPrint('AiHealthService getDietaryRecommendations error: $e');
      return ['Eat a balanced diet with plenty of vegetables and fruits.'];
    }
  }
}

class MLServiceProvider {
  static MLHealthService _instance = AiHealthService();

  static MLHealthService get instance => _instance;

  static void inject(MLHealthService service) {
    _instance = service;
  }
}
