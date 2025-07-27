import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studora/app/bindings/application_binding.dart';
import 'package:studora/app/config/theme/app_theme.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/config/navigation/app_pages.dart';
import 'package:studora/app/services/notification_service.dart';
import 'package:studora/app/services/storage_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:studora/firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Hive.initFlutter();

  final storageService = await Get.putAsync(() => StorageService().init());
  final bool isDarkMode = storageService.read('isDarkMode') ?? false;
  runApp(StudoraApp(isDarkMode: isDarkMode));
}

class StudoraApp extends StatelessWidget {
  const StudoraApp({super.key, required this.isDarkMode});
  final bool isDarkMode;
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Studora',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      initialBinding: ApplicationBinding(),
      initialRoute: AppRoutes.INIT_LOADING,
      getPages: AppPages.routes,
    );
  }
}
