import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/models/college_model.dart';
import 'package:studora/app/data/models/country_model.dart';
import 'package:studora/app/data/repositories/college_repository.dart';
import 'package:studora/app/data/repositories/country_repository.dart';
import 'package:studora/app/modules/auth/views/college_selection_modal.dart';
import 'package:studora/app/services/network_service.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
import 'package:studora/app/services/logger_service.dart';
class SignupController extends GetxController {
  static const String _className = 'SignupController';
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailPrefixController = TextEditingController();
  final TextEditingController collegeDisplayController =
      TextEditingController();
  final TextEditingController collegeSearchModalController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController rollNumberController = TextEditingController();
  late TextEditingController collegeSearchController;
  final RxList<CollegeModel> filteredColleges = <CollegeModel>[].obs;
  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;
  var agreedToTerms = false.obs;
  var isSigningUp = false.obs;
  var hasAttemptedSignup = false.obs;
  var supportedCountries = <CountryModel>[].obs;
  var selectedCountry = Rxn<CountryModel>();
  var allColleges = <CollegeModel>[].obs;
  var filteredCollegesForModal = <CollegeModel>[].obs;
  var isLoadingColleges = true.obs;
  var isLoadingCountries = true.obs;
  var selectedCollege = Rxn<CollegeModel>();
  var emailDomain = "".obs;
  var countriesError = RxnString();
  var collegesError = RxnString();
  final CollegeRepository _collegeRepository = Get.find<CollegeRepository>();
  final CountryRepository _countryRepository = Get.find<CountryRepository>();
  final NetworkService _networkService = Get.find<NetworkService>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  StreamSubscription? _networkSubscription;
  bool _countriesLoadFailedDueToNetwork = false;
  bool _collegesLoadFailedDueToNetwork = false;
  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
    collegeSearchModalController.addListener(() {
      filterCollegesForModal(collegeSearchModalController.text);
    });
    _networkSubscription = _networkService.connectionStatus.listen((status) {
      bool isConnected = _networkService.isConnected();
      LoggerService.logInfo(
        _className,
        'networkListener',
        "Network status changed. Connected: $isConnected",
      );
      if (isConnected) {
        if (_countriesLoadFailedDueToNetwork ||
            (supportedCountries.isEmpty && countriesError.value != null)) {
          LoggerService.logInfo(
            _className,
            'networkListener',
            "Retrying to fetch countries due to network reconnection...",
          );
          fetchInitialData();
        } else if (_collegesLoadFailedDueToNetwork ||
            (allColleges.isEmpty &&
                collegesError.value != null &&
                supportedCountries.isNotEmpty &&
                countriesError.value == null)) {
          LoggerService.logInfo(
            _className,
            'networkListener',
            "Retrying to fetch colleges due to network reconnection...",
          );
          fetchCollegesAndFilter();
        }
      }
    });
    collegeSearchController = TextEditingController();
  }
  @override
  void onClose() {
    nameController.dispose();
    emailPrefixController.dispose();
    collegeDisplayController.dispose();
    collegeSearchModalController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    rollNumberController.dispose();
    _networkSubscription?.cancel();
    collegeSearchController.dispose();
    super.onClose();
  }
  void filterColleges(String query) {
    if (query.isEmpty) {
      filteredColleges.assignAll(allColleges);
    } else {
      filteredColleges.assignAll(
        allColleges
            .where(
              (college) =>
                  college.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList(),
      );
    }
  }
  void onCollegeSelectedFromModal(CollegeModel college) {
    selectedCollege.value = college;
    collegeDisplayController.text = college.name;
    emailDomain.value = '@${college.emailDomain}';
    emailPrefixController.clear();
  }
  Future<void> fetchInitialData() async {
    if (!_networkService.isConnected()) {
      countriesError.value = "No internet. Please check your connection.";
      collegesError.value = "No internet. Please check your connection.";
      isLoadingCountries(false);
      isLoadingColleges(false);
      _countriesLoadFailedDueToNetwork = true;
      _collegesLoadFailedDueToNetwork = true;
      return;
    }
    _countriesLoadFailedDueToNetwork = false;
    isLoadingCountries(true);
    countriesError.value = null;
    await fetchSupportedCountries();
    isLoadingCountries(false);
    if (countriesError.value == null && _networkService.isConnected()) {
      await fetchCollegesAndFilter();
    } else if (countriesError.value != null) {
      _collegesLoadFailedDueToNetwork = _countriesLoadFailedDueToNetwork;
      if (_countriesLoadFailedDueToNetwork) {
        collegesError.value = "Please connect to internet to load colleges.";
      } else {
        collegesError.value =
            "Could not load colleges as countries failed to load.";
      }
      isLoadingColleges(false);
    }
  }
  Future<void> fetchCollegesAndFilter() async {
    if (!_networkService.isConnected()) {
      collegesError.value = "No internet to load colleges.";
      isLoadingColleges(false);
      _collegesLoadFailedDueToNetwork = true;
      return;
    }
    _collegesLoadFailedDueToNetwork = false;
    isLoadingColleges(true);
    collegesError.value = null;
    await fetchColleges();
    isLoadingColleges(false);
  }
  Future<void> fetchSupportedCountries() async {
    const String methodName = 'fetchSupportedCountries';
    try {
      final result = await _countryRepository.getActiveCountries();
      if (result.isEmpty && _networkService.isConnected()) {
        countriesError.value = "No countries available at the moment.";
        supportedCountries.clear();
      } else if (result.isNotEmpty) {
        supportedCountries.assignAll(result);
        countriesError.value = null;
      }
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        "Error fetching countries: $e",
        s,
      );
      countriesError.value = "Failed to load countries. Tap to retry.";
      _countriesLoadFailedDueToNetwork = !_networkService.isConnected();
    }
  }
  Future<void> fetchColleges() async {
    const String methodName = 'fetchColleges';
    try {
      final result = await _collegeRepository.getActiveColleges();
      if (result.isEmpty && _networkService.isConnected()) {
        if (selectedCountry.value != null) {
          collegesError.value =
              "No colleges found for ${selectedCountry.value!.name}.";
        } else {
          collegesError.value = "No colleges available at the moment.";
        }
        allColleges.clear();
      } else if (result.isNotEmpty) {
        allColleges.assignAll(result);
        collegesError.value = null;
      }
      filterCollegesForModal(collegeSearchModalController.text);
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        "Error fetching colleges: $e",
        s,
      );
      collegesError.value = "Failed to load colleges. Tap to retry.";
      _collegesLoadFailedDueToNetwork = !_networkService.isConnected();
    }
  }
  void onCountrySelected(String? countryNameFromDropdown) {
    CountryModel? selected = supportedCountries.firstWhereOrNull(
      (c) => c.name == countryNameFromDropdown,
    );
    selectedCountry.value = selected;
    _updateSelectedCollegeState(null);
    collegeSearchModalController.clear();
    collegesError.value = null;
    if (allColleges.isNotEmpty) {
      filterCollegesForModal("");
    } else if (_networkService.isConnected()) {
      fetchCollegesAndFilter();
    } else {
      collegesError.value =
          "No internet to load colleges for the selected country.";
      filteredCollegesForModal.clear();
    }
  }
  void filterCollegesForModal(String searchText) {
    List<CollegeModel> tempFiltered;
    if (selectedCountry.value != null) {
      tempFiltered = allColleges.where((college) {
        return college.country.toLowerCase() ==
            selectedCountry.value!.name.toLowerCase();
      }).toList();
    } else {
      tempFiltered = List.from(allColleges);
    }
    if (searchText.isNotEmpty) {
      tempFiltered = tempFiltered.where((college) {
        return college.name.toLowerCase().contains(searchText.toLowerCase());
      }).toList();
    }
    filteredCollegesForModal.assignAll(tempFiltered);
  }
  void _updateSelectedCollegeState(CollegeModel? college) {
    selectedCollege.value = college;
    if (college != null) {
      collegeDisplayController.text = college.name;
      emailDomain.value = "@${college.emailDomain}";
      emailPrefixController.clear();
    } else {
      collegeDisplayController.clear();
      emailDomain.value = "";
    }
  }
  void collegePickedFromModal(CollegeModel college) {
    _updateSelectedCollegeState(college);
    Get.back();
  }
  void openCollegeSelectionModal() {
    filterColleges('');
    Get.bottomSheet(
      const CollegeSelectionModal(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      ignoreSafeArea: false,
    );
  }
  void togglePasswordVisibility() => isPasswordVisible.toggle();
  void toggleConfirmPasswordVisibility() => isConfirmPasswordVisible.toggle();
  void toggleAgreedToTerms(bool? value) => agreedToTerms.value = value ?? false;
  Future<void> signupUser() async {
    const String methodName = 'signupUser';
    hasAttemptedSignup.value = true;
    if (formKey.currentState!.validate()) {
      if (selectedCountry.value == null) {
        SnackbarService.showWarning(
          title: "Incomplete",
          "Please select your country.",
        );
        return;
      }
      if (selectedCollege.value == null) {
        SnackbarService.showWarning(
          title: "Incomplete",
          "Please select your college.",
        );
        return;
      }
      if (!agreedToTerms.value) {
        SnackbarService.showWarning(
          title: "Agreement Required",
          "Please agree to the Terms & Conditions and Privacy Policy.",
        );
        return;
      }
      isSigningUp(true);
      String fullName = nameController.text;
      String email = "${emailPrefixController.text.trim()}${emailDomain.value}";
      String password = passwordController.text;
      String rollNumber = rollNumberController.text.trim();
      LoggerService.logInfo(
        _className,
        methodName,
        "Signup initiated for $email",
      );
      try {
        await _authRepository.signupCreateProfileLoginAndVerify(
          name: fullName,
          email: email,
          password: password,
          collegeId: selectedCollege.value!.id,
          rollNumber: rollNumber,
          currencySymbol: selectedCountry.value!.currencySymbol,
        );
        LoggerService.logInfo(
          _className,
          methodName,
          "Signup, login, and verification email process initiated for $email. Navigating to verification screen.",
        );
        SnackbarService.showSuccess(
          title: "Signup Almost Complete!",
          "Please check your email to verify your account.",
        );
        Get.offAllNamed(
          AppRoutes.VERIFICATION,
          arguments: {
            'email': email,
            'verificationType': VerificationType.emailSignup,
          },
        );
      } catch (e, s) {
        LoggerService.logError(
          _className,
          methodName,
          "Full signup flow failed: $e",
          s,
        );
        SnackbarService.showError(e.toString());
      } finally {
        isSigningUp(false);
      }
    }
  }
  void navigateToLogin() {
    if (Get.previousRoute == AppRoutes.ONBOARDING || Get.previousRoute == "") {
      Get.offNamed(AppRoutes.LOGIN);
    } else {
      Get.back();
    }
  }
  void navigateToTerms() => Get.toNamed(AppRoutes.TERMS_CONDITIONS);
  void navigateToPrivacy() => Get.toNamed(AppRoutes.PRIVACY_POLICY);
}
