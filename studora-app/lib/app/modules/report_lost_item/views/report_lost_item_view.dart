import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:studora/app/modules/report_lost_item/controllers/report_lost_item_controller.dart';
import 'package:studora/app/data/models/category_model.dart'
    as app_category_model;
import 'package:studora/app/shared_components/utils/input_validators.dart';

class ReportLostItemView extends GetView<ReportLostItemController> {
  const ReportLostItemView({super.key});

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required BuildContext context,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? prefixIcon,
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
    required BuildContext context,
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

  Widget _buildDateField(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date Lost*",
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => TextFormField(
            readOnly: true,
            controller: TextEditingController(
              text: controller.lostDate.value == null
                  ? ""
                  : DateFormat(
                      'MMM d, yyyy',
                    ).format(controller.lostDate.value!),
            ),
            decoration: InputDecoration(
              hintText: "Select date",
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
            onTap: () => controller.pickLostDate(context),
            validator: (value) => controller.lostDate.value == null
                ? 'Please select the date'
                : null,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Time Lost (Optional)",
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => TextFormField(
            readOnly: true,
            controller: TextEditingController(
              text: controller.lostTime.value == null
                  ? ""
                  : controller.lostTime.value!.format(context),
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
            onTap: () => controller.pickLostTime(context),
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerSection(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.pickedImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.pickedImages.length,
                itemBuilder: (ctx, index) {
                  final imageFile = controller.pickedImages[index];
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 10.0,
                      top: 10,
                      bottom: 10,
                    ),
                    child: GestureDetector(
                      onTap: () => controller.navigateToPreviewFromThumbnail(
                        startIndex: index,
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
                                color: theme.dividerColor.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1,
                              ),
                              image: DecorationImage(
                                image: FileImage(File(imageFile.path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -8,
                            right: -8,
                            child: GestureDetector(
                              onTap: () => controller.removeImage(index),
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
                    ),
                  );
                },
              ),
            ),
          if (controller.pickedImages.length < controller.maxImages)
            Padding(
              padding: EdgeInsets.only(
                top: controller.pickedImages.isNotEmpty ? 10.0 : 0.0,
                bottom: controller.pickedImages.isEmpty ? 10 : 0,
              ),
              child: _buildAddImageButton(
                context,
                isMini: controller.pickedImages.isNotEmpty,
              ),
            ),
        ],
      ),
    );
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
            onTap: () => controller.showImageSourceActionSheet(context),
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
        onTap: () => controller.showImageSourceActionSheet(context),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Lost Item"),
        elevation: 0.5,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                "Add Photo(s) (Optional, max ${controller.maxImages})",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Photos greatly help in identifying your item.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              _buildImagePickerSection(context),
              const SizedBox(height: 24.0),
              _buildTextFormField(
                context: context,
                controller: controller.titleController,
                label: "What did you lose?*",
                hint: "e.g., Black Jansport Backpack, iPhone 13",
                validator: (value) =>
                    InputValidators.validateNotEmpty(value, "Item Name"),
              ),
              const SizedBox(height: 16.0),
              Obx(
                () => _buildDropdownFormField<app_category_model.CategoryModel>(
                  context: context,
                  label: "Category*",
                  value: controller.selectedCategory.value,
                  hintText: "Select item category",
                  items: controller.categories
                      .map(
                        (category) =>
                            DropdownMenuItem<app_category_model.CategoryModel>(
                              value: category,
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
              _buildTextFormField(
                context: context,
                controller: controller.descriptionController,
                label: "Description*",
                hint:
                    "Provide details like color, brand, specific features, any contents (e.g., 'Student ID inside wallet')...",
                maxLines: 4,
                validator: (value) =>
                    InputValidators.validateNotEmpty(value, "Description"),
              ),
              const SizedBox(height: 16.0),
              _buildTextFormField(
                context: context,
                controller: controller.locationController,
                label: "Last Known Location*",
                hint: "e.g., Library 2nd floor, Cafeteria near window",
                validator: (value) =>
                    InputValidators.validateNotEmpty(value, "Location"),
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(child: _buildDateField(context)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTimeField(context)),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildTextFormField(
                context: context,
                controller: controller.contactPreferenceController,
                label: "Preferred Contact (Optional)",
                hint: "e.g., Email john.doe@example.com or Phone",
                maxLines: 1,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 2.0),
                child: Text(
                  "How should someone contact you if they find your item?",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 32.0),
              Obx(
                () => controller.isLoading.value
                    ? const Center(
                        child: CupertinoActivityIndicator(radius: 15),
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(
                          CupertinoIcons.paperplane_fill,
                          size: 20,
                        ),
                        label: const Text("Report as Lost"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: controller.submitReportLostItem,
                      ),
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }
}
