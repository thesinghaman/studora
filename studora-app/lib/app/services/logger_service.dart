import 'package:flutter/foundation.dart';
class LoggerService {
  static void logError(String className, String methodName, dynamic error,
      [dynamic stackTrace]) {
    if (kDebugMode) {
      print('ERROR 🔴: [$className.$methodName] - $error');
      if (stackTrace != null) {
        print('STACKTRACE: $stackTrace');
      }
    }


  }
  static void logInfo(String className, String methodName, String message) {
    if (kDebugMode) {
      print('INFO 🔵: [$className.$methodName] - $message');
    }

  }
  static void logWarning(String className, String methodName, String message) {
    if (kDebugMode) {
      print('WARNING 🟡: [$className.$methodName] - $message');
    }

  }
}
