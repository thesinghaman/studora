import 'package:get/get.dart';
import 'package:studora/app/modules/auth/controllers/login_controller.dart';
import 'package:studora/app/modules/auth/controllers/signup_controller.dart';
import 'package:studora/app/modules/auth/controllers/forgot_password_controller.dart';
import 'package:studora/app/data/providers/college_provider.dart';
import 'package:studora/app/data/repositories/college_repository.dart';
import 'package:studora/app/data/providers/country_provider.dart';
import 'package:studora/app/data/repositories/country_repository.dart';
import 'package:studora/app/data/providers/auth_provider.dart';
import 'package:studora/app/data/providers/database_provider.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CountryProvider>(() => CountryProvider());
    Get.lazyPut<CountryRepository>(() => CountryRepository());
    Get.lazyPut<CollegeProvider>(() => CollegeProvider());
    Get.lazyPut<CollegeRepository>(() => CollegeRepository());
    Get.lazyPut<AuthProvider>(() => AuthProvider());
    Get.lazyPut<DatabaseProvider>(() => DatabaseProvider());
    Get.lazyPut<AuthRepository>(() => AuthRepository());
    Get.lazyPut<LoginController>(() => LoginController());
    Get.lazyPut<SignupController>(() => SignupController());
    Get.lazyPut<ForgotPasswordController>(() => ForgotPasswordController());
  }
}
