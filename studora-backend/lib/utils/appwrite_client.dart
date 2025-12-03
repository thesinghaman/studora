import 'package:dart_appwrite/dart_appwrite.dart';
import 'app_config.dart';

class AppwriteClient {
  static Client init() {
    return Client()
      .setEndpoint(AppConfig.endpoint)
      .setProject(AppConfig.projectId)
      .setKey(AppConfig.apiKey);
  }
}

