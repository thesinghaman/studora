import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';

class AppwriteClient {
  static Client init() {
    final client = Client();
    
    // These environment variables are automatically provided by Appwrite
    client
      .setEndpoint(Platform.environment['APPWRITE_ENDPOINT'] ?? 'https://cloud.appwrite.io/v1')
      .setProject(Platform.environment['APPWRITE_PROJECT_ID'] ?? '')
      .setKey(Platform.environment['APPWRITE_API_KEY'] ?? '');
      
    return client;
  }
}

