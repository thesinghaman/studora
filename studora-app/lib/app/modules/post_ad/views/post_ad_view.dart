import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:studora/app/modules/post_ad/controllers/post_ad_controller.dart';
import 'package:studora/app/data/models/category_model.dart' as cat_model;

class PostAdScreenView extends GetView<PostAdController> {
  const PostAdScreenView({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post New Listing"),
        elevation: 0.5,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                "Add Photos (up to 5)*",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8.0),
              _buildImagePickerSection(context, theme),
              const SizedBox(height: 24.0),
              Text(
                "Listing Type*",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8.0),
              Obx(
                () => CupertinoSlidingSegmentedControl<ListingType>(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.8),
                  thumbColor: theme.colorScheme.primary,
                  groupValue: controller.listingType.value,
                  children: <ListingType, Widget>{
                    ListingType.sale: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Text(
                        'For Sale',
                        style: TextStyle(
                          color:
                              controller.listingType.value == ListingType.sale
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    ListingType.rent: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Text(
                        'For Rent',
                        style: TextStyle(
                          color:
                              controller.listingType.value == ListingType.rent
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  },
                  onValueChanged: (ListingType? newValue) {
                    if (newValue != null) {
                      controller.listingType.value = newValue;
                    }
                  },
                ),
              ),
              const SizedBox(height: 20.0),
              _buildTextFormField(
                controller: controller.titleController,
                label: "Title*",
                hint: "e.g., Calculus Textbook, Studio Apt",
                theme: theme,
              ),
              const SizedBox(height: 16.0),
              _buildTextFormField(
                controller: controller.descriptionController,
                label: "Description*",
                hint: "Describe your item or rental...",
                maxLines: 4,
                theme: theme,
              ),
              const SizedBox(height: 16.0),
              Obx(
                () => controller.isLoadingCategories.value
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CupertinoActivityIndicator(),
                        ),
                      )
                    : _buildDropdownFormField<String>(
                        label: "Category*",
                        value: controller.selectedCategory.value,
                        hintText: "Select a category",
                        items: controller.currentCategories
                            .map(
                              (cat_model.CategoryModel category) =>
                                  DropdownMenuItem<String>(
                                    value: category.id,
                                    child: Text(category.name),
                                  ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            controller.selectedCategory.value = value,
                        validator: (value) =>
                            value == null ? 'Please select a category' : null,
                        theme: theme,
                      ),
              ),
              const SizedBox(height: 16.0),
              Obx(
                () => _buildTextFormField(
                  controller: controller.priceController,
                  label: controller.listingType.value == ListingType.rent
                      ? "Rent per Term (INR)*"
                      : "Price (INR)*",
                  hint: controller.listingType.value == ListingType.rent
                      ? "e.g., 5000"
                      : "e.g., 250",
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
                  theme: theme,
                ),
              ),
              const SizedBox(height: 16.0),
              Obx(() {
                if (controller.listingType.value == ListingType.sale) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDropdownFormField<String>(
                        label: "Condition*",
                        value: controller.selectedCondition.value,
                        hintText: "Select item condition",
                        items: controller.productConditions
                            .map(
                              (condition) => DropdownMenuItem<String>(
                                value: condition,
                                child: Text(condition),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            controller.selectedCondition.value = value,
                        validator: (value) =>
                            controller.listingType.value == ListingType.sale &&
                                value == null
                            ? 'Please select a condition'
                            : null,
                        theme: theme,
                      ),
                      const SizedBox(height: 16.0),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              _buildTextFormField(
                controller: controller.locationController,
                label: "Location (Optional)",
                hint: "e.g., Near Main Library, Apt Complex Name",
                theme: theme,
              ),
              const SizedBox(height: 16.0),
              _buildDateField(
                context,
                theme,
                label: "Ad Expiry Date*",
                isAvailableFrom: false,
              ),
              const SizedBox(height: 16.0),
              Obx(() {
                if (controller.listingType.value == ListingType.rent) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
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
                            controller.listingType.value == ListingType.rent &&
                                (value == null || value.isEmpty)
                            ? 'Please specify rental term'
                            : null,
                        theme: theme,
                      ),
                      const SizedBox(height: 16.0),
                      _buildDateField(
                        context,
                        theme,
                        label: "Available From (Optional)",
                        isAvailableFrom: true,
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextFormField(
                        controller: controller.propertyTypeController,
                        label: "Property Type (Optional)",
                        hint: "e.g., 1 BHK, Studio, Shared Room",
                        theme: theme,
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextFormField(
                        controller: controller.amenitiesController,
                        label: "Amenities (comma separated, Optional)",
                        hint: "e.g., WiFi, Furnished, Parking",
                        maxLines: 2,
                        theme: theme,
                      ),
                      const SizedBox(height: 16.0),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 32.0),
              Obx(
                () => controller.isSubmitting.value
                    ? const Center(
                        child: CupertinoActivityIndicator(radius: 15),
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(
                          CupertinoIcons.paperplane_fill,
                          size: 20,
                        ),
                        label: const Text("Post Listing"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: controller.submitAd,
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
    required ThemeData theme,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? prefixIcon,
  }) {
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
    required ThemeData theme,
  }) {
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
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context,
    ThemeData theme, {
    required String label,
    required bool isAvailableFrom,
  }) {
    return Obx(() {
      DateTime? currentDate = isAvailableFrom
          ? controller.selectedAvailableFrom.value
          : controller.selectedExpiryDate.value;
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
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLowest,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
            ),
            onTap: () => controller.selectDate(
              context,
              isAvailableFrom: isAvailableFrom,
            ),
            validator: (value) {
              if (!isAvailableFrom &&
                  controller.selectedExpiryDate.value == null) {
                return 'Please set an expiry date';
              }
              return null;
            },
            style: theme.textTheme.bodyLarge,
          ),
        ],
      );
    });
  }

  Widget _buildImagePickerSection(BuildContext context, ThemeData theme) {
    return Obx(() {
      if (controller.selectedImages.isEmpty) {
        return GestureDetector(
          onTap: () => controller.showImageSourceActionSheetAndPreview(context),
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.8),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.camera_fill,
                  size: 48,
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
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
      return SizedBox(
        height: 110,
        child: Row(
          children: [
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.selectedImages.length,
                itemBuilder: (ctx, index) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 10.0,
                      top: 10,
                      bottom: 10,
                    ),
                    child: GestureDetector(
                      onTap: () => controller.reEditSelectedImages(),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11.0),
                              child: Image.file(
                                File(controller.selectedImages[index].path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -8,
                            right: -8,
                            child: GestureDetector(
                              onTap: () =>
                                  controller.removeImageFromPostAdScreen(index),
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
            if (controller.selectedImages.length < 5)
              Padding(
                padding: const EdgeInsets.only(left: 10.0, top: 10, bottom: 10),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Material(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12.0),
                    child: InkWell(
                      onTap: () => controller
                          .showImageSourceActionSheetAndPreview(context),
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
                            size: 30,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
