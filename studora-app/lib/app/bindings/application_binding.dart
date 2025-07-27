import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:studora/app/data/providers/report_provider.dart';
import 'package:studora/app/data/repositories/report_repository.dart';
import 'package:studora/app/services/notification_service.dart';
import 'package:studora/app/services/storage_service.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/services/network_service.dart';
import 'package:studora/app/data/providers/auth_provider.dart';
import 'package:studora/app/data/providers/database_provider.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/services/wishlist_service.dart';
class ApplicationBinding extends Bindings {
  @override
  Future<void> dependencies() async {
    debugPrint("[BINDING] ApplicationBinding dependencies started...");
    Get.put<AppwriteService>(AppwriteService(), permanent: true);
    final AppwriteService appwriteService = Get.find<AppwriteService>();
    await Get.putAsync<NotificationService>(
      () => NotificationService().init(),
      permanent: true,
    );
    Get.put<StorageService>(StorageService(), permanent: true);
    debugPrint("[BINDING] StorageService put.");

    await Get.putAsync<NetworkService>(() async {
      final networkService = NetworkService();
      await networkService.init();
      debugPrint("[BINDING] NetworkService fully initialized and put.");
      return networkService;
    }, permanent: true);
    Get.lazyPut<ReportProvider>(
      () => ReportProvider(appwriteService),
      fenix: true,
    );
    Get.put<AuthProvider>(AuthProvider(), permanent: true);
    debugPrint("[BINDING] AuthProvider put.");
    Get.put<DatabaseProvider>(DatabaseProvider(), permanent: true);
    debugPrint("[BINDING] DatabaseProvider put.");
    Get.put<AuthRepository>(AuthRepository(), permanent: true);
    debugPrint("[BINDING] AuthRepository put.");
    Get.lazyPut<ReportRepository>(
      () => ReportRepository(Get.find<ReportProvider>()),
      fenix: true,
    );
    Get.put(WishlistService(), permanent: true);
    debugPrint(
      "[BINDING] ApplicationBinding dependencies finished. Navigating to SPLASH.",
    );
    Get.offAllNamed(AppRoutes.SPLASH);
  }
}
