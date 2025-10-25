import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';

import 'package:studora/app/modules/contact_support/controllers/contact_support_controller.dart';

class ContactSupportView extends GetView<ContactSupportController> {
  const ContactSupportView({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Contact Support",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.scaffoldBackgroundColor,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "We're here to help!",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please fill out the form below, or if you prefer, you can email us directly at support@campusconnect.app (placeholder).",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              Text(
                "What is your issue related to?*",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.selectedIssueCategory.value,
                  hint: const Text("Select a category"),
                  isExpanded: true,
                  decoration: _inputDecoration(
                    theme,
                    "Select category",
                    prefixIconData: CupertinoIcons.tag_solid,
                  ),
                  items: controller.issueCategories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(
                        category,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: controller.onCategoryChanged,
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Subject*",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.subjectController,
                decoration: _inputDecoration(
                  theme,
                  "e.g., Trouble logging in",
                  prefixIconData: CupertinoIcons.pen,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject';
                  }
                  if (value.length < 5) {
                    return 'Subject should be at least 5 characters';
                  }
                  return null;
                },
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),

              Text(
                "Your Message*",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.messageController,
                decoration: _inputDecoration(
                  theme,
                  "Please describe your issue in detail...",
                  prefixIconData: CupertinoIcons.chat_bubble_text_fill,
                ),
                maxLines: 6,
                minLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your message';
                  }
                  if (value.length < 15) {
                    return 'Message should be at least 15 characters';
                  }
                  return null;
                },
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton.icon(
                    icon: controller.isLoading.value
                        ? Container()
                        : Icon(
                            CupertinoIcons.paperplane_fill,
                            size: 20,
                            color: theme.colorScheme.onPrimary,
                          ),
                    label: controller.isLoading.value
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            "Send Message",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      disabledBackgroundColor: theme.colorScheme.primary
                          .withValues(alpha: 0.5),
                    ),
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.submitSupportRequest,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    ThemeData theme,
    String hintText, {
    IconData? prefixIconData,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: theme.textTheme.bodyLarge?.copyWith(
        color: theme.hintColor.withValues(alpha: 0.7),
      ),
      prefixIcon: prefixIconData != null
          ? Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 12.0),
              child: Icon(
                prefixIconData,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
                size: 20,
              ),
            )
          : null,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 14.0,
      ),
    );
  }
}
