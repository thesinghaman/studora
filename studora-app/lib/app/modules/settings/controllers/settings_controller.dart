import 'package:flutter/material.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import 'package:studora/app/data/models/user_model.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/services/notification_service.dart';
import 'package:studora/app/services/storage_service.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';

class SettingsController extends GetxController {
  static const String _className = 'SettingsController';
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final StorageService _storageService = Get.find<StorageService>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  Rx<UserModel?> get currentUser => _authRepository.appUser;

  final RxBool isDarkModeEnabled = false.obs;
  final RxBool arePushNotificationsEnabled = false.obs;
  @override
  void onInit() {
    super.onInit();

    isDarkModeEnabled.value = Get.isDarkMode;
    arePushNotificationsEnabled.value =
        _storageService.read('notifications_enabled') ?? true;
  }

  void onDarkModeChanged(bool value) {
    isDarkModeEnabled.value = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);

    _storageService.write('isDarkMode', value);
    LoggerService.logInfo(
      _className,
      'onDarkModeChanged',
      'Dark Mode preference saved: $value',
    );
  }

  Future<void> onPushNotificationsChanged(bool enable) async {
    arePushNotificationsEnabled.value = enable;
    if (enable) {
      await _notificationService.requestAndCheckPermissions();
      final status = _notificationService.authorizationStatus.value;
      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        LoggerService.logInfo(
          'SettingsController',
          'onPushNotificationsChanged',
          'Enabling notifications...',
        );
        await _authRepository.enablePushNotifications();
        await _storageService.write('notifications_enabled', true);
        SnackbarService.showSuccess("Push notifications enabled.");
      } else {
        SnackbarService.showError(
          "Permission denied. Go to your phone's settings to enable notifications.",
        );
        arePushNotificationsEnabled.value = false;
      }
    } else {
      LoggerService.logInfo(
        'SettingsController',
        'onPushNotificationsChanged',
        'Disabling notifications...',
      );
      await _authRepository.disablePushNotifications();
      await _storageService.write('notifications_enabled', false);
      SnackbarService.showSuccess("Push notifications disabled.");
    }
  }

  void navigateToEditProfile() {
    LoggerService.logInfo(
      _className,
      'navigateToEditProfile',
      'Navigation to Edit Profile triggered.',
    );
    Get.toNamed(AppRoutes.EDIT_PROFILE);
  }

  void navigateToPrivacy() {
    Get.toNamed(AppRoutes.PRIVACY);
  }

  void navigateToChangePassword() {
    LoggerService.logInfo(
      _className,
      'navigateToChangePassword',
      'Navigation to Change Password triggered.',
    );
    Get.toNamed(AppRoutes.CHANGE_PASSWORD);
  }

  void navigateToBlockedUsers() {
    Get.toNamed(AppRoutes.BLOCKED_USERS);
  }

  void navigateToHelpAndFaq() {
    LoggerService.logInfo(
      _className,
      'navigateToHelpAndFaq',
      'Navigation to Help & FAQ triggered.',
    );
    Get.toNamed(AppRoutes.HELP_FAQ);
  }

  void navigateToContactSupport() {
    LoggerService.logInfo(
      _className,
      'navigateToContactSupport',
      'Navigation to Contact Support triggered.',
    );
    Get.toNamed(AppRoutes.CONTACT_SUPPORT);
  }

  void navigateToTermsAndConditions() {
    Get.toNamed(AppRoutes.TERMS_CONDITIONS);
  }

  void navigateToPrivacyPolicy() {
    Get.toNamed(AppRoutes.PRIVACY_POLICY);
  }

  Future<void> logout() async {
    await _authRepository.logout();

    Get.offAllNamed(AppRoutes.LOGIN);
    LoggerService.logInfo(_className, 'logout', 'User logged out.');
  }
}
