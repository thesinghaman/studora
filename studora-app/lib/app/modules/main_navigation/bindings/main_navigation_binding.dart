import 'package:get/get.dart';

import 'package:studora/app/modules/home/bindings/home_binding.dart';
import 'package:studora/app/modules/main_navigation/controllers/main_navigation_controller.dart';
import 'package:studora/app/modules/messages/bindings/messages_binding.dart';
import 'package:studora/app/modules/messages/controllers/messages_controller.dart';
import 'package:studora/app/modules/my_ads/bindings/my_ads_binding.dart';
import 'package:studora/app/modules/settings/bindings/settings_binding.dart';

class MainNavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainNavigationController>(() => MainNavigationController());

    HomeBinding().dependencies();
    MyAdsBinding().dependencies();
    SettingsBinding().dependencies();
    MessagesBinding().dependencies();
    Get.put<MessagesController>(MessagesController(), permanent: true);
  }
}
