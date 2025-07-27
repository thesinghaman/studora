import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:studora/app/modules/edit_profile/controllers/edit_profile_controller.dart';
import 'package:studora/app/shared_components/utils/input_validators.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          Obx(
            () => TextButton(
              onPressed:
                  (controller.changesMade.value && !controller.isSaving.value)
                  ? controller.saveProfile
                  : null,
              child: Text(
                "Save",
                style: TextStyle(
                  color:
                      (controller.changesMade.value &&
                          !controller.isSaving.value)
                      ? theme.colorScheme.primary
                      : theme.disabledColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.currentUser.value == null) {
          return const Center(child: Text("Could not load profile."));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(context, theme),
                const SizedBox(height: 32.0),
                _buildTextField(
                  controller: controller.userNameController,
                  label: "Full Name",
                  icon: Icons.person_outline_rounded,
                  validator: InputValidators.validateName,
                ),
                const SizedBox(height: 20.0),
                _buildReadOnlyField(
                  label: "College Name",

                  value: controller.collegeName.value,
                  icon: Icons.school_outlined,
                  theme: theme,
                  helperText: "Your college name cannot be changed.",
                ),
                const SizedBox(height: 20.0),
                _buildReadOnlyField(
                  label: "Email",
                  value: controller.currentUser.value!.email,
                  icon: Icons.mail_outline_rounded,
                  theme: theme,
                  helperText: "Email is used for login and cannot be changed.",
                ),
                const SizedBox(height: 20.0),
                _buildTextField(
                  controller: controller.rollNumberController,
                  label: "Roll Number",
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 20.0),
                _buildTextField(
                  controller: controller.hostelController,
                  label: "Hostel / Residence",
                  icon: Icons.home_outlined,
                ),
                const SizedBox(height: 48.0),

                TextButton.icon(
                  onPressed: controller.navigateToDeleteConfirmation,
                  icon: Icon(
                    CupertinoIcons.delete,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    "Delete Profile",
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32.0),
                if (controller.isSaving.value)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAvatar(BuildContext context, ThemeData theme) {
    return Obx(() {
      ImageProvider? backgroundImage;
      Widget? child;
      final user = controller.currentUser.value!;

      if (controller.newAvatarFile.value != null) {
        backgroundImage = FileImage(File(controller.newAvatarFile.value!.path));
      } else if (user.userAvatarUrl != null &&
          user.userAvatarUrl!.isNotEmpty &&
          !controller.avatarWasRemoved.value) {
        backgroundImage = NetworkImage(user.userAvatarUrl!);
      } else {
        child = Icon(
          Icons.person_rounded,
          size: 50,
          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
        );
      }
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.5,
            ),
            backgroundImage: backgroundImage,
            child: child,
          ),
          Material(
            color: theme.colorScheme.primary,
            shape: const CircleBorder(),
            elevation: 2.0,
            child: InkWell(
              onTap: () => _showImagePickerOptions(context, theme),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.edit_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _showImagePickerOptions(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(
                Icons.photo_library_outlined,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                controller.pickAndCropImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt_outlined,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Get.back();
                controller.pickAndCropImage(ImageSource.camera);
              },
            ),
            if (controller.newAvatarFile.value != null ||
                (controller.currentUser.value?.userAvatarUrl?.isNotEmpty ??
                    false))
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Remove Current Photo',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Get.back();
                  controller.removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    final theme = Get.theme;
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: theme.iconTheme.color?.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required ThemeData theme,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                child: Icon(
                  icon,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                  size: 20,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 4.0),
            child: Text(
              helperText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}
