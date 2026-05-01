import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ai_service.dart';
import 'interfaces/ocr_service_interface.dart';
import 'auth_service.dart';

class AiOCRService implements OCRService {
  final AiService _aiService = AiService();
  final AuthService _authService = AuthService();

  @override
  Future<ExtractedData> scanDocument(File image) async {
    try {
      final userId = await _authService.getUserId() ?? '1';
      final result = await _aiService.extractTextFromImage(image.path, userId);
      
      // Map the backend result to ExtractedData
      // The backend returns: { "status": "success", "extracted_text": "...", "structured_data": {...}, "confidence": 0.9 }
      final Map<String, dynamic> structuredData = result['structured_data'] ?? {};
      final double confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
      
      // Ensure the rawData contains the extracted text as well
      final Map<String, dynamic> rawData = {
        ...structuredData,
        'extracted_text': result['extracted_text'],
        'document_type': result['document_type'],
      };

      return ExtractedData(rawData, confidence);
    } catch (e) {
      debugPrint('AiOCRService scanDocument error: $e');
      rethrow;
    }
  }

  @override
  Future<String> extractText(File image) async {
    try {
      final userId = await _authService.getUserId() ?? '1';
      final result = await _aiService.extractTextFromImage(image.path, userId);
      return result['extracted_text'] ?? '';
    } catch (e) {
      debugPrint('AiOCRService extractText error: $e');
      return '';
    }
  }
}
