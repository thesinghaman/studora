import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/modules/auth/controllers/signup_controller.dart';
class CollegeSelectionModal extends StatelessWidget {
  const CollegeSelectionModal({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<SignupController>();
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [

              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20.0),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: controller.collegeSearchController,
                  decoration: InputDecoration(
                    hintText: "Search for your college",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainer,
                  ),
                  onChanged: controller.filterColleges,
                ),
              ),
              const SizedBox(height: 30.0),

              Expanded(
                child: Obx(() {
                  if (controller.isLoadingColleges.value) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  if (controller.filteredColleges.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "No colleges found for the selected country.",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    controller: scrollController,
                    itemCount: controller.filteredColleges.length,
                    itemBuilder: (context, index) {
                      final college = controller.filteredColleges[index];
                      return ListTile(
                        title: Text(college.name),
                        subtitle: Text(
                          '@${college.emailDomain}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        onTap: () {
                          controller.onCollegeSelectedFromModal(college);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
