import 'dart:io';

class AppConfig {
  static String get endpoint => _getEnv('APPWRITE_ENDPOINT', 'https://cloud.appwrite.io/v1');
  static String get projectId => _getEnv('APPWRITE_PROJECT_ID');
  static String get apiKey => _getEnv('APPWRITE_API_KEY');

  static String _getEnv(String key, [String? defaultValue]) {
    final value = Platform.environment[key];
    if (value == null || value.isEmpty) {
      if (defaultValue != null) return defaultValue;
      throw Exception('Critical Configuration Error: Environment variable "$key" is missing.');
    }
    return value;
  }

  static void validate() {
    // Accessing these properties will trigger the check
    endpoint;
    projectId;
    apiKey;
  }
}
