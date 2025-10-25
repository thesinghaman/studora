import 'package:get/get.dart';

import 'package:studora/app/data/providers/college_provider.dart';
import 'package:studora/app/data/repositories/college_repository.dart';
import 'package:studora/app/modules/edit_profile/controllers/edit_profile_controller.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CollegeProvider());
    Get.lazyPut(() => CollegeRepository());
    Get.lazyPut<EditProfileController>(() => EditProfileController());
  }
}
