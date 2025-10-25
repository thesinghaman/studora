import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:studora/app/modules/application_settings/controllers/legal_document_controller.dart';
class TermsConditionsScreen extends GetView<LegalDocumentController> {
  const TermsConditionsScreen({super.key});
  List<Widget> _buildContentWidgets(String content, ThemeData theme) {
    final List<Widget> widgets = [];
    final lines = content.split('\n');
    for (String line in lines) {
      String trimmedLine = line.trim();
      if (trimmedLine.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4.0, top: 5.0, bottom: 5.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7.0, right: 10.0),
                  child: Icon(
                    CupertinoIcons.circle_fill,
                    size: 5.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Text(
                    trimmedLine.substring(2),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.95,
                      ),
                      height: 1.65,
                      fontSize: 15.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (trimmedLine.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              trimmedLine,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.95,
                ),
                height: 1.65,
                fontSize: 15.0,
              ),
            ),
          ),
        );
      } else {
        widgets.add(const SizedBox(height: 8.0));
      }
    }
    if (widgets.isNotEmpty &&
        widgets.last is SizedBox &&
        (lines.isEmpty || lines.last.trim().isEmpty)) {
      widgets.removeLast();
    }
    return widgets;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.legalDocument.value?.title ?? "Terms & Conditions",
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
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (controller.errorMessage.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value!,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                    onPressed: controller.fetchDocument,
                  ),
                ],
              ),
            ),
          );
        }
        if (controller.legalDocument.value == null) {
          return const Center(child: Text("Document not available."));
        }
        final doc = controller.legalDocument.value!;
        return Scrollbar(
          thumbVisibility: true,
          thickness: isDarkMode ? 4 : 5,
          radius: const Radius.circular(10),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(22.0, 16.0, 22.0, 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 28.0, top: 8.0),
                  child: Center(
                    child: Text(
                      "Last Updated: ${DateFormat('MMMM d, yyyy').format(doc.lastUpdated)} ${doc.version != null ? '(Version: ${doc.version})' : ''}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.9,
                        ),
                        fontStyle: FontStyle.italic,
                        fontSize: 13.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                ...doc.parsedSections.map((section) {
                  final sectionTitle = section['title'] ?? 'Section';
                  final sectionContent = section['content'] ?? '';
                  if (sectionTitle == "Document Status" &&
                      doc.parsedSections.firstWhereOrNull(
                            (s) => s['title'] == "Document Status",
                          ) !=
                          null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sectionTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        ..._buildContentWidgets(sectionContent, theme),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }),
    );
  }
}
