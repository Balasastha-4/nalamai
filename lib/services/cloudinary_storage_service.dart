import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../app_config.dart';
import 'interfaces/storage_service_interface.dart';

class CloudinaryStorageService implements StorageService {
  @override
  Future<String> uploadFile(File file, String path) async {
    try {
      final cloudName = AppConfig.cloudinaryCloudName;
      final uploadPreset = AppConfig.cloudinaryUploadPreset;
      
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(responseData);
        return json['secure_url'] as String;
      } else {
        debugPrint('Cloudinary upload error: $responseData');
        throw Exception('Failed to upload to Cloudinary: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('CloudinaryStorageService error: $e');
      rethrow;
    }
  }

  @override
  Future<File> downloadFile(String url) async {
    // For Cloudinary, we just need the URL, but if we need the actual File object:
    throw UnimplementedError('Download not implemented for Cloudinary (use URL directly)');
  }

  @override
  Future<void> deleteFile(String url) async {
    // Deleting from Cloudinary requires signed requests (API Secret),
    // which shouldn't be in the mobile app. 
    // This should ideally be handled by the backend.
    debugPrint('Delete file called for Cloudinary (stubbed for security)');
  }
}
