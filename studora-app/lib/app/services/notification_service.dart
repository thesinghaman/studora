import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'package:studora/app/services/logger_service.dart';
import 'package:studora/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService extends GetxService {
  static const String _className = 'NotificationService';
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final Rx<AuthorizationStatus> authorizationStatus =
      AuthorizationStatus.notDetermined.obs;
  Future<NotificationService> init() async {
    await requestAndCheckPermissions();

    await _initializeLocalNotifications();
    _setupListeners();
    return this;
  }

  Future<void> requestAndCheckPermissions() async {
    final NotificationSettings settings = await _firebaseMessaging
        .requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

    authorizationStatus.value = settings.authorizationStatus;
    LoggerService.logInfo(
      _className,
      '_requestAndCheckPermissions',
      'User notification permission status: ${settings.authorizationStatus}',
    );
    if (authorizationStatus.value == AuthorizationStatus.denied) {
      LoggerService.logWarning(
        _className,
        '_requestAndCheckPermissions',
        'Push notification permission was denied by the user.',
      );
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);
  }

  void _setupListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  Future<String?> getFcmToken() => _firebaseMessaging.getToken();
}
