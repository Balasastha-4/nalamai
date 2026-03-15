import 'dart:io';

abstract class StorageService {
  Future<String> uploadFile(File file, String path);
  Future<File> downloadFile(String url);
  Future<void> deleteFile(String url);
}
