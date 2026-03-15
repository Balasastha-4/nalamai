import 'dart:io';

class ExtractedData {
  final Map<String, dynamic> rawData;
  final double confidence;

  ExtractedData(this.rawData, this.confidence);
}

abstract class OCRService {
  Future<ExtractedData> scanDocument(File image);
  Future<String> extractText(File image);
}
