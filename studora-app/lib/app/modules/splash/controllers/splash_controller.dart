import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';

import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/services/storage_service.dart';
import 'package:studora/app/data/providers/auth_provider.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/enums.dart';

class SplashController extends GetxController {
  static const String _className = 'SplashController';
  late final StorageService _storageService;
  late final AuthProvider _authProvider;
  SplashController() {
    LoggerService.logInfo(
      _className,
      'Constructor',
      "SplashController constructor executed.",
    );
  }
  @override
  void onInit() {
    super.onInit();
    LoggerService.logInfo(
      _className,
      'onInit',
      "SplashController onInit started.",
    );
    try {
      _storageService = Get.find<StorageService>();
      _authProvider = Get.find<AuthProvider>();
      LoggerService.logInfo(
        _className,
        'onInit',
        "Dependencies (StorageService, AuthProvider) found successfully.",
      );
    } catch (e, s) {
      LoggerService.logError(
        _className,
        'onInit',
        "Error finding dependencies: $e",
        s,
      );
    }
    LoggerService.logInfo(
      _className,
      'onInit',
      "SplashController onInit finished.",
    );
  }

  @override
  void onReady() {
    super.onReady();
    LoggerService.logInfo(
      _className,
      'onReady',
      "SplashController onReady called. Preparing to handle startup logic.",
    );
    if (Get.isRegistered<StorageService>() &&
        Get.isRegistered<AuthProvider>()) {
      _handleStartupLogic();
    } else {
      LoggerService.logError(
        _className,
        'onReady',
        "Dependencies not registered. Cannot proceed. Navigating to Login.",
      );
      FlutterNativeSplash.remove();
      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }

  Future<void> _handleStartupLogic() async {
    const String methodName = '_handleStartupLogic';
    LoggerService.logInfo(
      _className,
      methodName,
      "START: _handleStartupLogic.",
    );
    LoggerService.logInfo(
      _className,
      methodName,
      "Checking onboarding status...",
    );
    bool onboardingComplete = _storageService.isOnboardingComplete();
    LoggerService.logInfo(
      _className,
      methodName,
      "Onboarding complete: $onboardingComplete",
    );
    if (!onboardingComplete) {
      LoggerService.logInfo(
        _className,
        methodName,
        "Navigating to Onboarding.",
      );
      FlutterNativeSplash.remove();
      Get.offAllNamed(AppRoutes.ONBOARDING);
      return;
    }
    LoggerService.logInfo(
      _className,
      methodName,
      "Onboarding is complete. Checking session status...",
    );
    try {
      LoggerService.logInfo(
        _className,
        methodName,
        "Attempting to get current Appwrite user...",
      );
      appwrite_models.User currentUser = await _authProvider.getCurrentUser();
      LoggerService.logInfo(
        _className,
        methodName,
        "SUCCESS: Got current user: ${currentUser.$id}. Email verified: ${currentUser.emailVerification}",
      );
      if (currentUser.emailVerification) {
        LoggerService.logInfo(
          _className,
          methodName,
          "User is verified. Navigating to Main Navigation.",
        );
        FlutterNativeSplash.remove();
        Get.offAllNamed(AppRoutes.MAIN_NAVIGATION);
      } else {
        LoggerService.logInfo(
          _className,
          methodName,
          "User is NOT verified. Navigating to Verification Screen.",
        );
        FlutterNativeSplash.remove();
        Get.offAllNamed(
          AppRoutes.VERIFICATION,
          arguments: {
            'email': currentUser.email,
            'verificationType': VerificationType.emailSignup,
          },
        );
      }
    } on AppwriteException catch (e) {
      LoggerService.logWarning(
        _className,
        methodName,
        "AppwriteException (likely no session or network issue to Appwrite): ${e.message}. Navigating to Login.",
      );
      FlutterNativeSplash.remove();
      Get.offAllNamed(AppRoutes.LOGIN);
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        "Unexpected error during startup: $e. Navigating to Login.",
        s,
      );
      FlutterNativeSplash.remove();
      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }
}
