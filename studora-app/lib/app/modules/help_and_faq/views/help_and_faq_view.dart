import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';

import 'package:studora/app/modules/help_and_faq/controllers/help_and_faq_controller.dart';

class HelpAndFaqView extends GetView<HelpAndFaqController> {
  const HelpAndFaqView({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Help & FAQs",
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
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 80.0),
        itemCount: controller.faqItems.length + 2,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return _buildIntroText(theme);
          }
          if (index == controller.faqItems.length + 1) {
            return _buildContactSupportSection(theme);
          }
          final itemIndex = index - 1;
          final item = controller.faqItems[itemIndex];
          return Obx(() {
            final bool isExpanded = controller.expandedIndex.value == itemIndex;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => controller.toggle(itemIndex),
                  borderRadius: BorderRadius.circular(10.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 18.0,
                    ),
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? theme.colorScheme.primary.withValues(alpha: 0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.question,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isExpanded
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          isExpanded
                              ? CupertinoIcons.chevron_up
                              : CupertinoIcons.chevron_down,
                          size: 18,
                          color: isExpanded
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  child: Visibility(
                    visible: isExpanded,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 18.0),
                      child: Text(
                        item.answer,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.55,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                ),
                if (itemIndex < controller.faqItems.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: theme.dividerColor.withValues(
                      alpha: isDarkMode ? 0.15 : 0.25,
                    ),
                    indent: 12,
                    endIndent: 12,
                  )
                else
                  const SizedBox(height: 8),
              ],
            );
          });
        },
      ),
    );
  }

  Widget _buildIntroText(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 20.0),
      child: Text(
        "Find answers to common questions below. If you need further assistance, don't hesitate to contact support.",
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildContactSupportSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0, bottom: 16.0),
      child: Center(
        child: Column(
          children: [
            Text(
              "Can't find what you're looking for?",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: Icon(
                CupertinoIcons.mail,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                "Contact Support",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: controller.navigateToContactSupport,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
