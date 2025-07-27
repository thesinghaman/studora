import 'package:get/get.dart';

import 'package:studora/app/modules/settings/controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SettingsController>(SettingsController(), permanent: true);
  }
}
