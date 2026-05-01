import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../core/api_client.dart';

class AiService {
  // Use configurable URL from ApiClient
  static String get _baseUrl => '${ApiClient.aiBaseUrl}/api/ai';

  Future<Map<String, dynamic>> sendChatMessage(
    String message,
    String patientId, {
    Map<String, dynamic>? vitals,
  }) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'patient_id': patientId,
          'token': token,
          'vitals': vitals,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to communicate with AI Server: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('AI Service Error: $e');
      throw Exception('Network error connecting to AI Microservice.');
    }
  }

  Future<Map<String, dynamic>> getHealthPrediction(
    Map<String, dynamic> vitals,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(vitals),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get prediction: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Prediction Error: $e');
      throw Exception('Network error connecting to AI Microservice.');
    }
  }

  Future<Map<String, dynamic>> extractTextFromImage(
    String filePath,
    String patientId,
  ) async {
    try {
      final token = await AuthService().getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/ocr'),
      );

      request.fields['patient_id'] = patientId;
      if (token != null) request.fields['token'] = token;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        debugPrint('OCR Server Error Body: $responseBody');
        throw Exception('Failed to process image OCR: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OCR Error: $e');
      throw Exception('Network error executing OCR on AI Microservice.');
    }
  }
}
