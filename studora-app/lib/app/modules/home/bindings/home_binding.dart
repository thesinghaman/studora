import 'package:get/get.dart';

import 'package:studora/app/modules/home/controllers/home_controller.dart';
import 'package:studora/app/data/providers/item_provider.dart';
import 'package:studora/app/data/repositories/item_repository.dart';
import 'package:studora/app/data/providers/category_provider.dart';
import 'package:studora/app/data/repositories/category_repository.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ItemProvider>(() => ItemProvider());
    Get.lazyPut<ItemRepository>(() => ItemRepository());
    Get.lazyPut<CategoryProvider>(() => CategoryProvider());
    Get.lazyPut<CategoryRepository>(() => CategoryRepository());
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
