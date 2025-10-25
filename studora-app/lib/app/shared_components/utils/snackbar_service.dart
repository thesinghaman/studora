import 'package:flutter/material.dart';

import 'package:get/get.dart';

enum SnackbarType { success, error, warning, info }

class SnackbarService {
  static void showSnackbar(
    String title,
    String message, {
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    SnackPosition snackPosition = SnackPosition.BOTTOM,
  }) {
    Color backgroundColor;
    IconData iconData;
    Color iconColor = Colors.white;
    switch (type) {
      case SnackbarType.success:
        backgroundColor = Colors.green.shade600;
        iconData = Icons.check_circle_outline_rounded;
        break;
      case SnackbarType.error:
        backgroundColor = Colors.redAccent.shade400;
        iconData = Icons.error_outline_rounded;
        break;
      case SnackbarType.warning:
        backgroundColor = Colors.orange.shade700;
        iconData = Icons.warning_amber_rounded;
        break;
      case SnackbarType.info:
        backgroundColor = Colors.blueGrey.shade700;
        iconData = Icons.info_outline_rounded;
        break;
    }
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    Get.snackbar(
      title,
      message,
      snackPosition: snackPosition,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      borderRadius: 8.0,
      margin: const EdgeInsets.all(12.0),
      icon: Icon(iconData, color: iconColor),
      shouldIconPulse:
          type == SnackbarType.warning || type == SnackbarType.error,
      duration: duration,
      isDismissible: true,
    );
  }

  static void showError(String message, {String title = "Error"}) {
    showSnackbar(title, message, type: SnackbarType.error);
  }

  static void showSuccess(String message, {String title = "Success"}) {
    showSnackbar(title, message, type: SnackbarType.success);
  }

  static void showWarning(String message, {String title = "Warning"}) {
    showSnackbar(title, message, type: SnackbarType.warning);
  }

  static void showInfo(String message, {String title = "Info"}) {
    showSnackbar(title, message, type: SnackbarType.info);
  }
}
