import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/models/user_model.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/data/repositories/college_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';

class EditProfileController extends GetxController {
  static const String _className = 'EditProfileController';

  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final CollegeRepository _collegeRepository = Get.find<CollegeRepository>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final ImageCropper _cropper = ImageCropper();

  var isLoading = true.obs;
  var isSaving = false.obs;
  var changesMade = false.obs;
  var currentUser = Rxn<UserModel>();
  var newAvatarFile = Rxn<XFile>();
  var collegeName = ''.obs;
  var avatarWasRemoved = false.obs;

  late TextEditingController userNameController;
  late TextEditingController rollNumberController;
  late TextEditingController hostelController;
  @override
  void onInit() {
    super.onInit();
    userNameController = TextEditingController();
    rollNumberController = TextEditingController();
    hostelController = TextEditingController();
    _loadUserProfile();
    _addListeners();
  }

  @override
  void onClose() {
    userNameController.removeListener(_onFieldChanged);
    rollNumberController.removeListener(_onFieldChanged);
    hostelController.removeListener(_onFieldChanged);
    userNameController.dispose();
    rollNumberController.dispose();
    hostelController.dispose();
    super.onClose();
  }

  void _addListeners() {
    userNameController.addListener(_onFieldChanged);
    rollNumberController.addListener(_onFieldChanged);
    hostelController.addListener(_onFieldChanged);
  }

  Future<void> _loadUserProfile() async {
    isLoading.value = true;
    currentUser.value = _authRepository.appUser.value;
    if (currentUser.value != null) {
      userNameController.text = currentUser.value!.userName;
      rollNumberController.text = currentUser.value!.rollNumber ?? "";
      hostelController.text = currentUser.value!.hostel ?? "";
      if (currentUser.value!.collegeId != null) {
        await _fetchCollegeName(currentUser.value!.collegeId!);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        changesMade.value = false;
      });
    } else {
      SnackbarService.showError("Failed to load user profile.");
    }
    isLoading.value = false;
  }

  Future<void> _fetchCollegeName(String collegeId) async {
    try {
      final college = await _collegeRepository.getCollegeById(collegeId);
      if (college != null) {
        collegeName.value = college.name;
      } else {
        collegeName.value = 'Unknown College';
      }
    } catch (e) {
      collegeName.value = 'Error loading college';
      LoggerService.logError(
        _className,
        '_fetchCollegeName',
        'Failed to fetch college name: $e',
      );
    }
  }

  void _onFieldChanged() {
    bool changed = false;
    if (currentUser.value != null) {
      if (userNameController.text != currentUser.value!.userName) {
        changed = true;
      }
      if (rollNumberController.text != (currentUser.value!.rollNumber ?? "")) {
        changed = true;
      }
      if (hostelController.text != (currentUser.value!.hostel ?? "")) {
        changed = true;
      }
    }
    if (newAvatarFile.value != null || avatarWasRemoved.value) {
      changed = true;
    }
    changesMade.value = changed;
  }

  Future<void> pickAndCropImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile == null) return;
      final CroppedFile? croppedFile = await _cropper.cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 70,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: Get.theme.colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
      if (croppedFile != null) {
        newAvatarFile.value = XFile(croppedFile.path);
        avatarWasRemoved.value = false;
        _onFieldChanged();
      }
    } catch (e) {
      SnackbarService.showError("Error processing image: $e");
    }
  }

  void removeAvatar() {
    newAvatarFile.value = null;
    avatarWasRemoved.value = true;
    _onFieldChanged();
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) {
      SnackbarService.showWarning("Please correct the errors in the form.");
      return;
    }
    isSaving.value = true;
    try {
      final updatedUser = currentUser.value!.copyWith(
        userName: userNameController.text,
        rollNumber: rollNumberController.text,
        hostel: hostelController.text,
      );

      await _authRepository.updateUserProfile(
        updatedUser: updatedUser,
        newAvatarFile: newAvatarFile.value,
        avatarWasRemoved: avatarWasRemoved.value,
      );

      Get.back();

      SnackbarService.showSuccess("Profile updated successfully!");
    } catch (e, s) {
      LoggerService.logError(
        _className,
        'saveProfile',
        'Profile update failed: $e',
        s,
      );
      SnackbarService.showError("Failed to update profile. Please try again.");
    } finally {
      isSaving.value = false;
    }
  }

  void navigateToDeleteConfirmation() {
    Get.toNamed(AppRoutes.DELETE_ACCOUNT);
  }
}
