import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:studora/app/modules/edit_ad/controllers/edit_ad_controller.dart';
import 'package:studora/app/shared_components/utils/enums.dart';

class EditAdView extends GetView<EditAdController> {
  const EditAdView({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isRental.value
                ? "Edit Rental Listing"
                : "Edit Ad for Sale",
          ),
        ),
        elevation: 0.5,
      ),
      body: Obx(() {
        if (controller.isLoadingCategories.value) {
          return const Center(child: CupertinoActivityIndicator(radius: 15));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  "Images (max 5)*",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Manage your ad's images. You can remove existing ones or add new ones. At least one image is required.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _buildImagePickerSection(context, theme),
                const SizedBox(height: 24.0),
                Text(
                  "Listing Type",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
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
                  child: Obx(
                    () => Text(
                      controller.isRental.value ? "For Rent" : "For Sale",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                _buildTextFormField(
                  controller: controller.titleController,
                  label: "Title*",
                  hint: "e.g., Calculus Textbook",
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a title'
                      : null,
                ),
                const SizedBox(height: 16.0),
                _buildTextFormField(
                  controller: controller.descriptionController,
                  label: "Description*",
                  hint: "Describe your item...",
                  maxLines: 4,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a description'
                      : null,
                ),
                const SizedBox(height: 16.0),
                Obx(
                  () => _buildDropdownFormField<String>(
                    label: "Category*",
                    value: controller.selectedCategory.value,
                    hintText: "Select a category",
                    items: controller.currentCategories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      controller.selectedCategory.value = value;
                    },
                    validator: (value) =>
                        value == null ? 'Please select a category' : null,
                  ),
                ),
                const SizedBox(height: 16.0),
                Obx(
                  () => _buildTextFormField(
                    controller: controller.priceController,
                    label: controller.isRental.value
                        ? "Rent per Term (\$)*"
                        : "Price (\$)*",
                    hint: controller.isRental.value
                        ? "e.g., 500.00"
                        : "e.g., 25.00",
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Price must be positive';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16.0),
                Obx(() {
                  if (controller.isRental.value) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDropdownFormField<ItemCondition>(
                        label: "Condition*",
                        value: controller.selectedCondition.value,
                        hintText: "Select item condition",
                        items: controller.productConditions
                            .map(
                              (condition) => DropdownMenuItem<ItemCondition>(
                                value: condition,
                                child: Text(
                                  controller.itemConditionToString(condition),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          controller.selectedCondition.value = value;
                        },
                        validator: (value) =>
                            !controller.isRental.value && value == null
                            ? 'Please select a condition'
                            : null,
                      ),
                      const SizedBox(height: 16.0),
                    ],
                  );
                }),
                _buildTextFormField(
                  controller: controller.locationController,
                  label: "Location (Optional)",
                  hint: "e.g., Near Main Library",
                ),
                const SizedBox(height: 16.0),
                Obx(
                  () => _buildDateField(
                    context,
                    label: "Ad Expiry Date*",
                    currentDate: controller.selectedExpiryDate.value,
                    onDateSelected: (date) =>
                        controller.selectedExpiryDate.value = date,
                    isAvailableFrom: false,
                    validator: (value) {
                      if (controller.selectedExpiryDate.value == null) {
                        return 'Please set an expiry date';
                      }
                      if (controller.selectedExpiryDate.value!.isBefore(
                        DateTime.now().subtract(const Duration(days: 1)),
                      )) {
                        return 'Expiry date cannot be in the past.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16.0),
                Obx(() {
                  if (!controller.isRental.value) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                        child: Text(
                          "Rental Specifics",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _buildTextFormField(
                        controller: controller.rentalTermController,
                        label: "Rental Term*",
                        hint: "e.g., /month, /semester",
                        validator: (value) =>
                            controller.isRental.value &&
                                (value == null || value.isEmpty)
                            ? 'Please specify rental term'
                            : null,
                      ),
                      const SizedBox(height: 16.0),
                      _buildDateField(
                        context,
                        label: "Available From (Optional)",
                        currentDate: controller.selectedAvailableFrom.value,
                        onDateSelected: (date) =>
                            controller.selectedAvailableFrom.value = date,
                        isAvailableFrom: true,
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextFormField(
                        controller: controller.propertyTypeController,
                        label: "Property Type (Optional)",
                        hint: "e.g., 1 BHK, Studio",
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextFormField(
                        controller: controller.amenitiesController,
                        label: "Amenities (comma separated, Optional)",
                        hint: "e.g., WiFi, Furnished",
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16.0),
                    ],
                  );
                }),
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
        );
      }),
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
              vertical: 10.0,
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
    required DateTime? currentDate,
    required Function(DateTime) onDateSelected,
    required bool isAvailableFrom,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    String hintText = isAvailableFrom
        ? "Select date (Optional)"
        : "Set expiry date";
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
            text: currentDate == null
                ? ""
                : DateFormat('MMM d, yyyy').format(currentDate),
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
          onTap: () =>
              controller.selectDate(context, isAvailableFrom: isAvailableFrom),
          validator:
              validator ??
              (value) {
                if (!isAvailableFrom && currentDate == null) {
                  return 'Please set an expiry date';
                }
                return null;
              },
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildImagePickerSection(BuildContext context, ThemeData theme) {
    return Obx(() {
      List<Widget> imageWidgets = [];

      for (int i = 0; i < controller.existingImageUrls.length; i++) {
        final imageUrl = controller.existingImageUrls[i];
        imageWidgets.add(
          _buildImageTile(
            theme,
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) =>
                  Icon(CupertinoIcons.photo, color: theme.hintColor, size: 30),
              loadingBuilder: (ctx, child, progress) => progress == null
                  ? child
                  : const Center(child: CupertinoActivityIndicator(radius: 10)),
            ),
            () => controller.markExistingImageForDeletion(imageUrl),
          ),
        );
      }

      for (int i = 0; i < controller.newSelectedImages.length; i++) {
        final imageFile = controller.newSelectedImages[i];
        imageWidgets.add(
          _buildImageTile(
            theme,
            Image.file(File(imageFile.path), fit: BoxFit.cover),
            () => controller.removeNewImage(i),
          ),
        );
      }
      int totalImages =
          controller.existingImageUrls.length +
          controller.newSelectedImages.length;
      bool canAddMore = totalImages < 5;
      if (canAddMore) {
        imageWidgets.add(
          _buildAddImageButton(
            context,
            theme,
            isMini: totalImages > 0,
            onTap: () =>
                controller.showImageSourceActionSheetAndPreview(context),
          ),
        );
      }
      if (imageWidgets.isEmpty && !canAddMore) {
        return _buildAddImageButton(
          context,
          theme,
          isMini: false,
          onTap: () => controller.showImageSourceActionSheetAndPreview(context),
        );
      } else if (imageWidgets.isEmpty && canAddMore) {
        return _buildAddImageButton(
          context,
          theme,
          isMini: false,
          onTap: () => controller.showImageSourceActionSheetAndPreview(context),
        );
      }
      return Wrap(spacing: 10.0, runSpacing: 10.0, children: imageWidgets);
    });
  }

  Widget _buildImageTile(
    ThemeData theme,
    Widget imageWidget,
    VoidCallback onRemove,
  ) {
    return Stack(
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
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
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
    );
  }

  Widget _buildAddImageButton(
    BuildContext context,
    ThemeData theme, {
    required bool isMini,
    required VoidCallback onTap,
  }) {
    if (isMini) {
      return SizedBox(
        width: 80,
        height: 80,
        child: Material(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.0),
          child: InkWell(
            onTap: onTap,
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
        onTap: onTap,
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
                "Add Photos",
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
