import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';

import 'package:studora/app/modules/messages/controllers/messages_controller.dart';
import 'package:studora/app/shared_components/widgets/elegant_message_card.dart';

class MessagesView extends GetView<MessagesController> {
  const MessagesView({super.key});
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: _buildAppBar(context),
        body: Stack(
          children: [
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CupertinoActivityIndicator());
              }
              if (controller.conversations.isEmpty) {
                return const Center(child: Text("No conversations yet."));
              }
              return RefreshIndicator(
                onRefresh: () => controller.loadConversations(isRefresh: true),
                child: ListView.builder(
                  itemCount: controller.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = controller.conversations[index];
                    return Obx(
                      () => ElegantMessageCard(
                        conversation: conversation,
                        currentUserId: controller.currentUserId,
                        isSelected: controller.selectedConversationIds.contains(
                          conversation.id,
                        ),
                        onTap: () => controller.onItemTap(conversation),
                        onLongPress: () =>
                            controller.onItemLongPress(conversation.id),
                      ),
                    );
                  },
                ),
              );
            }),
            if (controller.isDeleting.value)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoActivityIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Deleting...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final bool isInSelectionMode = controller.isSelectionMode.value;
    return AppBar(
      title: Text(
        isInSelectionMode
            ? '${controller.selectedConversationIds.length} selected'
            : 'Messages',
      ),
      centerTitle: !isInSelectionMode,
      leading: isInSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: controller.cancelSelectionMode,
            )
          : null,
      actions: isInSelectionMode
          ? [
              IconButton(
                icon: const Icon(Icons.select_all),
                tooltip: 'Select All',
                onPressed: controller.selectAll,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
                onPressed: controller.confirmDelete,
              ),
            ]
          : [],
    );
  }
}
