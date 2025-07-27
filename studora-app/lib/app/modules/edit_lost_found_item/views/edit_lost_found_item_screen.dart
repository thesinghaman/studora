import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:studora/app/modules/edit_lost_found_item/controllers/edit_lost_found_item_controller.dart';
import 'package:studora/app/data/models/category_model.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';

class EditLostFoundItemScreen extends GetView<EditLostFoundItemController> {
  const EditLostFoundItemScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String appBarTitle = controller.itemType == LostFoundType.lost
        ? "Edit Lost Item Report"
        : "Edit Found Item Report";
    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle), elevation: 0.5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                "Images (max 3)",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Manage the images for your report.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              _buildImagePickerSectionForEdit(context),
              const SizedBox(height: 24.0),
              Text(
                "Item Type",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 14.0,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  controller.itemType == LostFoundType.lost
                      ? "Reporting a LOST Item"
                      : "Reporting a FOUND Item",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              _buildTextFormField(
                controller: controller.itemNameController,
                label: "Item Name/Title*",
                hint: "e.g., Black Jansport Backpack",
                validator: (v) =>
                    v == null || v.isEmpty ? "Item name cannot be empty" : null,
              ),
              const SizedBox(height: 16.0),

              Obx(() {
                if (controller.isLoadingCategories.value) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                return _buildDropdownFormField<String>(
                  label: "Category*",
                  value: controller.selectedCategory.value,
                  hintText: "Select item category",
                  items: controller.lfCategories.map((CategoryModel category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      controller.selectedCategory.value = value,
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                );
              }),
              const SizedBox(height: 16.0),
              _buildTextFormField(
                controller: controller.descriptionController,
                label: "Description*",
                hint: "Provide details...",
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty
                    ? "Description cannot be empty"
                    : null,
              ),
              const SizedBox(height: 16.0),
              _buildTextFormField(
                controller: controller.locationController,
                label: controller.itemType == LostFoundType.lost
                    ? "Last Known Location*"
                    : "Location Found*",
                hint: "e.g., Library 2nd floor",
                validator: (v) =>
                    v == null || v.isEmpty ? "Location cannot be empty" : null,
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => _buildDateField(
                        context,
                        label: controller.itemType == LostFoundType.lost
                            ? "Date Lost*"
                            : "Date Found*",
                        currentValue: controller.selectedDateReported.value,
                        isDateLostFound: true,
                        onTap: () => controller.selectDate(
                          context,
                          isDateReported: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(
                      () => _buildTimeField(
                        context,
                        label: controller.itemType == LostFoundType.lost
                            ? "Time Lost (Optional)"
                            : "Time Found (Optional)",
                        currentValue: controller.selectedTimeReported.value,
                        onTap: () => controller.selectTime(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildTextFormField(
                controller: controller.contactInfoController,
                label: "Handover/Contact Info*",
                hint: "e.g., Handed to Campus Security...",
                validator: (v) => v == null || v.isEmpty
                    ? "Contact/Handover info cannot be empty"
                    : null,
              ),
              const SizedBox(height: 16.0),
              Obx(
                () => _buildDateField(
                  context,
                  label: "Post Expiry Date*",
                  currentValue: controller.selectedExpiryDate.value,
                  isDateLostFound: false,
                  onTap: () =>
                      controller.selectDate(context, isDateReported: false),
                ),
              ),
              const SizedBox(height: 32.0),
              Obx(
                () => controller.isSubmitting.value
                    ? const Center(
                        child: CupertinoActivityIndicator(radius: 15),
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(
                          CupertinoIcons.checkmark_alt,
                          size: 20,
                        ),
                        label: const Text("Save Changes"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: controller.saveChanges,
                      ),
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? prefixIcon,
  }) {
    final theme = Theme.of(Get.context!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildDropdownFormField<T>({
    required String label,
    required T? value,
    required String hintText,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    final theme = Theme.of(Get.context!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
          ),
          style: theme.textTheme.bodyLarge,
          isExpanded: true,
          icon: Icon(
            CupertinoIcons.chevron_down,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime? currentValue,
    required bool isDateLostFound,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    String hintText = isDateLostFound ? "Select date" : "Set post expiry";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: currentValue == null
                ? ""
                : DateFormat('MMM d, yyyy').format(currentValue),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: Icon(
              CupertinoIcons.calendar,
              color: theme.colorScheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
          ),
          onTap: onTap,
          validator: (value) {
            if (currentValue == null) {
              if (isDateLostFound) return 'Please select the date';
              return 'Please set an expiry date';
            }
            return null;
          },
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildTimeField(
    BuildContext context, {
    required String label,
    required TimeOfDay? currentValue,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: currentValue == null ? "" : currentValue.format(context),
          ),
          decoration: InputDecoration(
            hintText: "Select time",
            suffixIcon: Icon(
              CupertinoIcons.time,
              color: theme.colorScheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
          ),
          onTap: onTap,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext modalCtx) => CupertinoActionSheet(
        title: const Text('Update Photos (Max 3)'),
        message: const Text('Select new images or manage existing ones.'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('Camera'),
            onPressed: () {
              Navigator.pop(modalCtx);
              controller.requestPermissionAndPickImages(
                ImageSource.camera,
                context,
              );
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Gallery'),
            onPressed: () {
              Navigator.pop(modalCtx);
              controller.requestPermissionAndPickImages(
                ImageSource.gallery,
                context,
              );
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(modalCtx),
        ),
      ),
    );
  }

  Widget _buildImagePickerSectionForEdit(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      List<dynamic> allDisplayImages = [
        ...controller.existingImageUrls,
        ...controller.newSelectedImages,
      ];
      bool canAddMoreImages = allDisplayImages.length < 3;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allDisplayImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allDisplayImages.length,
                itemBuilder: (context, index) {
                  dynamic imageSource = allDisplayImages[index];
                  Widget imageWidget;
                  bool isExistingUrl = imageSource is String;
                  if (imageSource is XFile) {
                    imageWidget = Image.file(
                      File(imageSource.path),
                      fit: BoxFit.cover,
                    );
                  } else if (isExistingUrl && imageSource.startsWith('http')) {
                    imageWidget = Image.network(
                      imageSource,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Icon(
                        CupertinoIcons.photo,
                        color: theme.hintColor,
                        size: 30,
                      ),
                      loadingBuilder: (ctx, child, progress) => progress == null
                          ? child
                          : const Center(
                              child: CupertinoActivityIndicator(radius: 10),
                            ),
                    );
                  } else {
                    imageWidget = Icon(
                      CupertinoIcons.question_circle,
                      color: theme.hintColor,
                      size: 30,
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 10.0,
                      top: 10,
                      bottom: 10,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11.0),
                            child: imageWidget,
                          ),
                        ),
                        Positioned(
                          top: -8,
                          right: -8,
                          child: GestureDetector(
                            onTap: () {
                              if (controller.existingImageUrls.length +
                                      controller.newSelectedImages.length <=
                                  1) {
                                SnackbarService.showError(
                                  "At least one image is required.",
                                );
                                return;
                              }
                              if (isExistingUrl) {
                                controller.markExistingImageForDeletion(
                                  imageSource,
                                );
                              } else {
                                controller.removeNewImage(
                                  controller.newSelectedImages.indexOf(
                                    imageSource as XFile,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.xmark,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (canAddMoreImages)
            Padding(
              padding: EdgeInsets.only(
                top: allDisplayImages.isNotEmpty ? 10.0 : 0.0,
              ),
              child: _buildAddImageButton(
                context,
                isMini: allDisplayImages.isNotEmpty,
              ),
            )
          else if (allDisplayImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Maximum 3 images reached.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            )
          else
            _buildAddImageButton(context, isMini: false),
        ],
      );
    });
  }

  Widget _buildAddImageButton(BuildContext context, {required bool isMini}) {
    final theme = Theme.of(context);
    if (isMini) {
      return SizedBox(
        width: 80,
        height: 80,
        child: Material(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.0),
          child: InkWell(
            onTap: () => _showImageSourceActionSheet(context),
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.plus,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => _showImageSourceActionSheet(context),
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.camera_fill,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                "Add Photos (Max 3)",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
