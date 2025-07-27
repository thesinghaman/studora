import 'dart:async';
import 'package:flutter/material.dart';

import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';

import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/models/conversation_model.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/data/repositories/chat_repository.dart';
import 'package:studora/app/modules/main_navigation/controllers/main_navigation_controller.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';

class MessagesController extends GetxController {
  static const String _className = 'MessagesController';

  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final ChatRepository _chatRepository = Get.find<ChatRepository>();
  final AppwriteService _appwrite = Get.find<AppwriteService>();
  StreamSubscription<String>? _deletionSubscription;

  var isLoading = true.obs;
  var conversations = <ConversationModel>[].obs;
  var isSelectionMode = false.obs;
  var selectedConversationIds = <String>{}.obs;
  var isDeleting = false.obs;

  var totalUnreadCount = 0.obs;
  RealtimeSubscription? _conversationsSubscription;
  String get currentUserId => _authRepository.appUser.value?.userId ?? '';
  @override
  void onInit() {
    super.onInit();
    _initialLoad();
    _initNavigationListener();
    _subscribeToConversationDeletions();
  }

  @override
  void onClose() {
    _conversationsSubscription?.close();
    _deletionSubscription?.cancel();
    super.onClose();
  }

  void _calculateTotalUnreadCount() {
    int count = 0;
    for (var convo in conversations) {
      count += convo.unreadCounts[currentUserId] ?? 0;
    }
    totalUnreadCount.value = count;
  }

  void _initialLoad() async {
    await _authRepository.getCurrentAppUser();
    if (currentUserId.isNotEmpty) {
      await loadConversations();
      _subscribeToConversations();
    } else {
      isLoading.value = false;
    }
  }

  void _initNavigationListener() {
    const messagesViewIndex = 1;
    ever(Get.find<MainNavigationController>().selectedIndex, (newIndex) {
      if (newIndex == messagesViewIndex) {
        if (!isSelectionMode.value) {
          loadConversations(isRefresh: true);
        }
      }
    });
  }

  void _subscribeToConversationDeletions() {
    _deletionSubscription = _chatRepository.onConversationDeleted.listen((
      deletedId,
    ) {
      _removeConversationById(deletedId);
    });
  }

  void _removeConversationById(String conversationId) {
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      conversations.removeAt(index);
      _calculateTotalUnreadCount();
      if (selectedConversationIds.contains(conversationId)) {
        selectedConversationIds.remove(conversationId);
      }
      LoggerService.logInfo(
        _className,
        '_removeConversationById',
        'Reactively removed conversation $conversationId from list.',
      );
    }
  }

  void _subscribeToConversations() {
    _conversationsSubscription?.close();
    final channel =
        'databases.${AppConstants.appwriteDatabaseId}.collections.${AppConstants.conversationsCollectionId}.documents';
    _conversationsSubscription = _appwrite.subscribe([channel], (response) {
      if (!response.events.any((event) => event.contains('.update'))) return;
      final payload = response.payload;
      final conversationId = payload['\$id'] as String;
      final List<String> visibleTo = List<String>.from(
        payload['visibleTo'] ?? [],
      );
      if (visibleTo.contains(currentUserId)) {
        final updatedConversation = ConversationModel.fromJson(
          payload,
          conversationId,
        );
        final index = conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          conversations[index] = updatedConversation;
        } else {
          conversations.add(updatedConversation);
        }
      } else {
        conversations.removeWhere((c) => c.id == conversationId);
      }
      conversations.sort(
        (a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp),
      );
      _calculateTotalUnreadCount();
      LoggerService.logInfo(
        _className,
        '_subscribeToConversations',
        'Real-time event processed for conversation: $conversationId',
      );
    });
  }

  Future<void> loadConversations({bool isRefresh = false}) async {
    if (!isRefresh) isLoading.value = true;
    if (isSelectionMode.value) cancelSelectionMode();
    try {
      if (currentUserId.isEmpty) {
        throw Exception("User not logged in.");
      }
      final fetchedConversations = await _chatRepository
          .getConversationsForUser(currentUserId);
      fetchedConversations.sort(
        (a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp),
      );
      conversations.assignAll(fetchedConversations);
      _calculateTotalUnreadCount();
    } catch (e, s) {
      LoggerService.logError(_className, 'loadConversations', 'Error: $e', s);
    } finally {
      if (isLoading.value) isLoading.value = false;
    }
  }

  void onItemTap(ConversationModel conversation) {
    if (isSelectionMode.value) {
      toggleSelection(conversation.id);
    } else {
      final index = conversations.indexWhere((c) => c.id == conversation.id);
      if (index != -1 &&
          (conversations[index].unreadCounts[currentUserId] ?? 0) > 0) {
        conversations[index].unreadCounts[currentUserId] = 0;
        conversations.refresh();
        _calculateTotalUnreadCount();
      }
      navigateToChat(conversation);
    }
  }

  void onItemLongPress(String conversationId) {
    if (!isSelectionMode.value) {
      isSelectionMode.value = true;
    }
    toggleSelection(conversationId);
  }

  void toggleSelection(String conversationId) {
    if (selectedConversationIds.contains(conversationId)) {
      selectedConversationIds.remove(conversationId);
      if (selectedConversationIds.isEmpty) {
        isSelectionMode.value = false;
      }
    } else {
      selectedConversationIds.add(conversationId);
    }
  }

  void cancelSelectionMode() {
    isSelectionMode.value = false;
    selectedConversationIds.clear();
  }

  void navigateToChat(ConversationModel conversation) {
    Get.toNamed(
      AppRoutes.INDIVIDUAL_CHAT,
      arguments: {'conversation': conversation},
    );
  }

  void selectAll() {
    if (selectedConversationIds.length == conversations.length) {
      cancelSelectionMode();
    } else {
      selectedConversationIds.assignAll(conversations.map((c) => c.id).toSet());
    }
  }

  void confirmDelete() {
    if (selectedConversationIds.isEmpty) return;
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Conversations?'),
        content: Text(
          'Are you sure you want to delete ${selectedConversationIds.length} conversation(s)? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              _deleteSelectedConversations();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedConversations() async {
    isDeleting.value = true;
    try {
      final idsToDelete = selectedConversationIds.toList();

      await _chatRepository.deleteConversations(idsToDelete, currentUserId);
      SnackbarService.showSuccess(
        title: 'Success',
        '${idsToDelete.length} conversation(s) deleted.',
      );
    } catch (e) {
      SnackbarService.showError('Failed to delete conversations.');
      LoggerService.logError(_className, '_deleteSelectedConversations', e);
    } finally {
      isDeleting.value = false;
      cancelSelectionMode();
    }
  }
}
