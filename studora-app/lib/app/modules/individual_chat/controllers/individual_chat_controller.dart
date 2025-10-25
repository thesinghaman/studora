import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/models/conversation_model.dart';
import 'package:studora/app/data/models/message_model.dart';
import 'package:studora/app/data/models/related_item_model.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/data/repositories/chat_repository.dart';
import 'package:studora/app/data/repositories/item_repository.dart';
import 'package:studora/app/data/repositories/lost_and_found_repository.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/services/network_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';

class IndividualChatController extends GetxController {
  static const String _className = 'IndividualChatController';

  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final ItemRepository _itemRepository = Get.find<ItemRepository>();
  final LostAndFoundRepository _lostFoundRepository =
      Get.find<LostAndFoundRepository>();
  final ChatRepository _chatRepository = Get.find<ChatRepository>();
  final AppwriteService _appwrite = Get.find<AppwriteService>();
  final NetworkService _networkService = Get.find<NetworkService>();

  RealtimeSubscription? _messagesSubscription;
  RealtimeSubscription? _userStatusSubscription;
  RealtimeSubscription? _currentUserStatusSubscription;
  final List<StreamSubscription> _itemStreamSubscriptions = [];

  ConversationModel? conversation;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late String otherUserId;
  late String otherUserName;
  String? otherUserAvatarUrl;

  final RxList<dynamic> fullRelatedItems = <dynamic>[].obs;
  RelatedItem? _pendingRelatedItem;
  RealtimeSubscription? _conversationSubscription;
  final Rxn<ConversationModel> rxConversation = Rxn<ConversationModel>();

  List<MessageModel> messages = [];
  List<dynamic> chatListItems = [];
  bool isLoading = true;
  bool isComposing = false;
  bool isOtherUserOnline = false;
  DateTime? otherUserLastSeen;
  var isBlockedByMe = false.obs;
  var isBlockedByOtherUser = false.obs;
  var isDeleting = false.obs;
  var isBlocking = false.obs;
  String get currentUserId => _authRepository.appUser.value!.userId;
  final ImagePicker _imagePicker = ImagePicker();

  late Box<MessageModel> _pendingMessagesBox;
  String? _temporaryBoxName;
  Timer? _lastSeenTimer;
  var otherUserShowsReadReceipts = true.obs;
  @override
  void onInit() {
    super.onInit();
    _loadArguments();
    _initAndLoadMessages();
    _fetchOtherUserPrivacySettings();
    _checkBlockStatus();
    _fetchInitialUserStatus();
    textController.addListener(() {
      final newIsComposing = textController.text.trim().isNotEmpty;
      if (newIsComposing != isComposing) {
        isComposing = newIsComposing;
        update();
      }
    });
    _startLastSeenTimer();
  }

  Future<void> _initAndLoadMessages() async {
    await _initLocalStorage();

    _subscribeToRelatedItemStreams();
    await _loadInitialMessages();
  }

  @override
  void onReady() {
    super.onReady();
    if (conversation != null) {
      _subscribeToConversationUpdates();
      _subscribeToMessages();
      _markAllAsRead();
    }
    _subscribeToOtherUserStatus();
    _subscribeToCurrentUserUpdates();
    _subscribeToConversationUpdates();
  }

  @override
  void onClose() {
    _messagesSubscription?.close();
    _userStatusSubscription?.close();
    _conversationSubscription?.close();
    _currentUserStatusSubscription?.close;
    _lastSeenTimer?.cancel();

    for (var sub in _itemStreamSubscriptions) {
      sub.cancel();
    }
    _itemStreamSubscriptions.clear();

    _pendingMessagesBox.close();
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _subscribeToConversationUpdates() {
    if (conversation == null) return;
    _conversationSubscription?.close();
    final channel =
        'databases.${AppConstants.appwriteDatabaseId}.collections.${AppConstants.conversationsCollectionId}.documents.${conversation!.id}';
    _conversationSubscription = _appwrite.subscribe([channel], (response) {
      if (response.events.any((event) => event.endsWith('.update'))) {
        conversation = ConversationModel.fromJson(
          response.payload,
          response.payload['\$id'],
        );
        _subscribeToRelatedItemStreams();
      }
    });
  }

  void _subscribeToRelatedItemStreams() {
    for (var sub in _itemStreamSubscriptions) {
      sub.cancel();
    }
    _itemStreamSubscriptions.clear();
    fullRelatedItems.clear();

    final allItemsToTrack = List<RelatedItem>.from(
      conversation?.relatedItems ?? [],
    );

    if (_pendingRelatedItem != null &&
        !allItemsToTrack.any(
          (item) => item.itemId == _pendingRelatedItem!.itemId,
        )) {
      allItemsToTrack.add(_pendingRelatedItem!);
    }
    if (allItemsToTrack.isEmpty) return;

    for (final relatedItem in allItemsToTrack) {
      _subscribeToSingleItem(relatedItem);
    }
  }

  void _subscribeToSingleItem(RelatedItem relatedItem) {
    final initialIndex = fullRelatedItems.indexWhere(
      (i) =>
          (i is RelatedItem && i.itemId == relatedItem.itemId) ||
          (i is! RelatedItem && i.id == relatedItem.itemId),
    );
    if (initialIndex == -1) {
      fullRelatedItems.add(relatedItem);
    }
    Stream<dynamic>? itemStream;
    if (relatedItem.itemType == 'ItemModel') {
      itemStream = _itemRepository.getItemStream(relatedItem.itemId);
    } else if (relatedItem.itemType == 'LostFoundItemModel') {
      itemStream = _lostFoundRepository.getLostFoundItemStream(
        relatedItem.itemId,
      );
    }
    if (itemStream != null) {
      final subscription = itemStream.listen((itemData) {
        final index = fullRelatedItems.indexWhere(
          (i) =>
              (i is RelatedItem && i.itemId == relatedItem.itemId) ||
              (i is! RelatedItem && i.id == relatedItem.itemId),
        );
        if (index != -1) {
          if (itemData != null) {
            fullRelatedItems[index] = itemData;
          } else {
            fullRelatedItems[index] = relatedItem;
          }
        }
      });
      _itemStreamSubscriptions.add(subscription);
    }
  }

  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    conversation = args['conversation'] as ConversationModel?;

    _pendingRelatedItem = args['relatedItem'] as RelatedItem?;
    if (conversation != null) {
      otherUserId = conversation!.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      if (otherUserId.isEmpty) {
        Get.back();
        return;
      }
      otherUserName =
          conversation!.participantNames[otherUserId] ?? 'Unknown User';
      otherUserAvatarUrl = conversation!.participantAvatars[otherUserId];
    } else {
      otherUserId = args['otherUserId'];
      otherUserName = args['otherUserName'];
      otherUserAvatarUrl = args['otherUserAvatarUrl'];
    }
  }

  Future<appwrite_models.Execution> _sendViaRepository({
    required MessageModel messageToResend,
    List<String>? imageUrls,
    List<String>? imageFileIds,
  }) {
    final currentUser = _authRepository.appUser.value;
    if (currentUser == null) throw Exception("User not logged in");

    return _chatRepository.sendMessage(
      conversationId: conversation?.id,
      senderId: messageToResend.senderId,
      text: messageToResend.text,
      participants: [currentUserId, otherUserId],
      messageType: messageToResend.type,
      imageUrls: imageUrls,
      imageFileIds: imageFileIds,
      participantNames: {
        currentUserId: currentUser.userName,
        otherUserId: otherUserName,
      },
      participantAvatars: {
        currentUserId: currentUser.userAvatarUrl,
        otherUserId: otherUserAvatarUrl,
      },
      relatedItem: _pendingRelatedItem,
    );
  }

  Future<void> _handleSuccessfulSend(
    appwrite_models.Execution execution,
    String optimisticMessageId,
  ) async {
    if (execution.responseStatusCode == 200 ||
        execution.responseStatusCode == 201) {
      _pendingRelatedItem = null;
      await _pendingMessagesBox.delete(optimisticMessageId);
      final responseData = jsonDecode(execution.responseBody);
      final realMessage = MessageModel.fromJson(
        responseData['data'],
        responseData['data']['\$id'],
      );
      if (conversation == null) {
        try {
          final newConversation = await _chatRepository.getConversationById(
            realMessage.conversationId,
          );
          conversation = newConversation;
          await _migratePendingMessages();
          _subscribeToMessages();

          _subscribeToRelatedItemStreams();
        } catch (e) {
          LoggerService.logError(
            _className,
            '_handleSuccessfulSend',
            "Failed to fetch new conversation: $e",
          );
        }
      }
      final index = messages.indexWhere((m) => m.id == optimisticMessageId);
      if (index != -1) {
        messages[index] = realMessage;
        _prepareChatListItems();
        update();
      }
    } else {
      throw AppwriteException(
        jsonDecode(execution.responseBody)['message'] ??
            'Server returned an error',
      );
    }
  }

  void navigateToChatUserProfile() async {
    await Get.toNamed(
      AppRoutes.CHAT_USER_PROFILE,
      arguments: {
        'userId': otherUserId,

        'originatingConversationId': conversation?.id,
      },
    );
  }

  Future<void> _fetchOtherUserPrivacySettings() async {
    try {
      final otherUserProfile = await _authRepository.getPublicUserProfile(
        otherUserId,
      );
      otherUserShowsReadReceipts.value = otherUserProfile.showReadReceipts;
    } catch (e) {
      otherUserShowsReadReceipts.value = true;
      LoggerService.logError(_className, '_fetchOtherUserPrivacySettings', e);
    }
  }

  void _startLastSeenTimer() {
    _lastSeenTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!isOtherUserOnline) {
        update();
      }
    });
  }

  Future<void> _initLocalStorage() async {
    final boxName = conversation != null
        ? 'pending_messages_${conversation!.id}'
        : 'pending_messages_new_$otherUserId';
    if (conversation == null) _temporaryBoxName = boxName;
    if (!Hive.isAdapterRegistered(MessageTypeAdapter().typeId)) {
      Hive.registerAdapter(MessageTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(MessageModelAdapter().typeId)) {
      Hive.registerAdapter(MessageModelAdapter());
    }
    if (!Hive.isAdapterRegistered(MessageStatusAdapter().typeId)) {
      Hive.registerAdapter(MessageStatusAdapter());
    }
    _pendingMessagesBox = await Hive.openBox<MessageModel>(boxName);
  }

  Future<void> _loadInitialMessages() async {
    isLoading = true;
    update();
    try {
      List<MessageModel> remoteMessages = [];
      if (conversation != null) {
        remoteMessages = await _chatRepository.getMessages(
          conversation!.id,
          currentUserId,
        );
      }
      final localMessages = _pendingMessagesBox.values.toList();
      messages = [...remoteMessages, ...localMessages]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _prepareChatListItems();
    } catch (e) {
      LoggerService.logError(_className, '_loadInitialMessages', e);
    } finally {
      isLoading = false;
      update();
      _scrollToBottom(jump: true);
    }
  }

  void sendMessage() async {
    if (isBlockedByMe.value) {
      SnackbarService.showError(
        "You must unblock this user to send a message.",
      );
      return;
    }
    final textToSend = textController.text.trim();
    if (textToSend.isEmpty) return;
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = MessageModel(
      id: localId,
      conversationId: conversation?.id ?? 'temp_id_$otherUserId',
      senderId: currentUserId,
      text: textToSend,
      type: MessageType.text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    await _pendingMessagesBox.put(localId, optimisticMessage);
    textController.clear();
    _addOptimisticMessage(optimisticMessage);
    await _trySendingMessage(optimisticMessage);
  }

  Future<void> pickAndSendImages() async {
    if (isBlockedByMe.value) {
      SnackbarService.showError("You must unblock this user to send images.");
      return;
    }
    final List<XFile> pickedFiles;
    try {
      pickedFiles = await _imagePicker.pickMultiImage(imageQuality: 80);
    } catch (e) {
      LoggerService.logError(_className, 'pickAndSendImages', e);
      SnackbarService.showError("Failed to open gallery.");
      return;
    }
    if (pickedFiles.isEmpty) return;
    if (pickedFiles.length > 5) {
      SnackbarService.showError("You can only select up to 5 images.");
      return;
    }
    final result = await Get.toNamed(
      AppRoutes.IMAGE_PREVIEW,
      arguments: {'initialImages': pickedFiles},
    );
    if (result == null || result is! List || result.isEmpty) return;
    final imageFiles = List<XFile>.from(
      result,
    ).map((xf) => File(xf.path)).toList();
    final imagePaths = imageFiles.map((f) => f.path).toList();
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = MessageModel(
      id: localId,
      conversationId: conversation?.id ?? 'temp_id_$otherUserId',
      senderId: currentUserId,
      type: MessageType.image,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      localImagePaths: imagePaths,
    );
    await _pendingMessagesBox.put(localId, optimisticMessage);
    _addOptimisticMessage(optimisticMessage);
    _uploadAndSendMessage(optimisticMessage, imageFiles);
  }

  Future<void> _uploadAndSendMessage(
    MessageModel optimisticMessage,
    List<File> imageFiles,
  ) async {
    try {
      final uploadResult = await _chatRepository.uploadChatImages(imageFiles);
      final execution = await _sendViaRepository(
        messageToResend: optimisticMessage,
        imageUrls: uploadResult['imageUrls'],
        imageFileIds: uploadResult['imageFileIds'],
      );
      await _handleSuccessfulSend(execution, optimisticMessage.id);
    } catch (e) {
      await _handleFailedSend(e, optimisticMessage);
    }
  }

  Future<void> _trySendingMessage(MessageModel messageToResend) async {
    try {
      if (!await _networkService.isInternetAvailable()) {
        throw Exception("No internet connection");
      }
      final execution = await _sendViaRepository(
        messageToResend: messageToResend,
      );
      await _handleSuccessfulSend(execution, messageToResend.id);
    } catch (e) {
      await _handleFailedSend(e, messageToResend);
    }
  }

  void _addOptimisticMessage(MessageModel optimisticMessage) {
    messages.insert(0, optimisticMessage);
    _prepareChatListItems();
    update();
    _scrollToBottom();
  }

  Future<void> _handleFailedSend(
    Object e,
    MessageModel optimisticMessage,
  ) async {
    LoggerService.logError(_className, '_handleFailedSend', e);
    final index = messages.indexWhere((m) => m.id == optimisticMessage.id);
    if (index != -1) {
      messages[index].status = MessageStatus.failed;
      optimisticMessage.status = MessageStatus.failed;
      await _pendingMessagesBox.put(optimisticMessage.id, optimisticMessage);
      update();
    }
  }

  Future<void> _migratePendingMessages() async {
    if (_temporaryBoxName == null || conversation == null) return;
    final newBoxName = 'pending_messages_${conversation!.id}';
    final newBox = await Hive.openBox<MessageModel>(newBoxName);
    final tempMessages = _pendingMessagesBox.values.toList();
    if (tempMessages.isNotEmpty) {
      final messagesToMove = <String, MessageModel>{};
      for (var msg in tempMessages) {
        messagesToMove[msg.id] = msg;
      }
      await newBox.putAll(messagesToMove);
    }
    await _pendingMessagesBox.compact();
    await _pendingMessagesBox.close();
    await Hive.deleteBoxFromDisk(_temporaryBoxName!);
    _temporaryBoxName = null;
    _pendingMessagesBox = newBox;
  }

  void onFailedMessageTapped(MessageModel failedMessage) {
    Get.dialog(
      AlertDialog(
        title: const Text('Message Failed'),
        content: const Text('This message could not be sent.'),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Get.back();
              deleteFailedMessage(failedMessage);
            },
          ),
          TextButton(
            child: const Text('Try Again'),
            onPressed: () {
              Get.back();
              resendMessage(failedMessage);
            },
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Future<void> deleteFailedMessage(MessageModel messageToDelete) async {
    await _pendingMessagesBox.delete(messageToDelete.id);
    messages.removeWhere((m) => m.id == messageToDelete.id);
    _prepareChatListItems();
    update();
  }

  Future<void> resendMessage(MessageModel failedMessage) async {
    failedMessage.status = MessageStatus.sending;
    await _pendingMessagesBox.put(failedMessage.id, failedMessage);
    final index = messages.indexWhere((m) => m.id == failedMessage.id);
    if (index != -1) {
      messages[index].status = MessageStatus.sending;
      update();
    }
    if (failedMessage.type == MessageType.text) {
      await _trySendingMessage(failedMessage);
    } else if (failedMessage.type == MessageType.image) {
      final imageFiles = failedMessage.localImagePaths!
          .map((path) => File(path))
          .toList();
      await _uploadAndSendMessage(failedMessage, imageFiles);
    }
  }

  void _subscribeToMessages() {
    if (conversation == null) return;
    final channel =
        'databases.${AppConstants.appwriteDatabaseId}.collections.${AppConstants.messagesCollectionId}.documents';
    _messagesSubscription = _appwrite.subscribe([channel], (response) {
      final payload = response.payload;
      if (payload['conversationId'] != conversation?.id) return;
      if (response.events.any((event) => event.endsWith('.create'))) {
        final newMessage = MessageModel.fromJson(payload, payload['\$id']);
        if (newMessage.senderId != currentUserId) {
          messages.insert(0, newMessage);
          _prepareChatListItems();
          update();
          _scrollToBottom();
          _markAllAsRead();
        }
      }
      if (response.events.any((event) => event.endsWith('.update'))) {
        final messageId = payload['\$id'];
        final index = messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          messages[index] = messages[index].copyWith(
            status: MessageStatus.values.firstWhere(
              (e) => e.name == payload['status'],
              orElse: () => messages[index].status,
            ),
          );
          _prepareChatListItems();
          update();
        }
      }
    });
  }

  void _markAllAsRead() {
    if (conversation != null && conversation!.id.isNotEmpty) {
      _chatRepository.markMessagesAsRead(conversation!.id, currentUserId);
    }
  }

  void _prepareChatListItems() {
    if (messages.isEmpty) {
      chatListItems = [];
      return;
    }
    List<dynamic> items = [];
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    for (int i = 0; i < messages.length; i++) {
      final currentMessage = messages[i];
      items.add(currentMessage);
      final nextMessage = (i + 1 < messages.length) ? messages[i + 1] : null;
      if (nextMessage == null ||
          !DateUtils.isSameDay(
            currentMessage.timestamp,
            nextMessage.timestamp,
          )) {
        items.add(currentMessage.timestamp);
      }
    }
    chatListItems = items;
  }

  void _scrollToBottom({bool jump = false}) {
    if (!scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        if (jump) {
          scrollController.jumpTo(0.0);
        } else {
          scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  Future<void> _fetchInitialUserStatus() async {
    try {
      final profile = await _authRepository.getPublicUserProfile(otherUserId);
      isBlockedByOtherUser.value = profile.isBlocked;
      isOtherUserOnline = profile.isOnline;
      otherUserLastSeen = profile.lastSeen;
      otherUserAvatarUrl = profile.userAvatarUrl;
      update();
    } catch (e) {
      LoggerService.logError(_className, '_fetchInitialUserStatus', e);
      isBlockedByOtherUser.value = true;
      isOtherUserOnline = false;
      otherUserLastSeen = null;
      otherUserAvatarUrl = null;
      update();
    }
  }

  void _subscribeToOtherUserStatus() {
    final channel =
        'databases.${AppConstants.appwriteDatabaseId}.collections.${AppConstants.usersCollectionId}.documents.$otherUserId';
    _userStatusSubscription = _appwrite.subscribe([channel], (response) {
      if (response.events.any((event) => event.endsWith('.update'))) {
        _fetchInitialUserStatus();
      }
    });
  }

  void _subscribeToCurrentUserUpdates() {
    final channel =
        'databases.${AppConstants.appwriteDatabaseId}.collections.${AppConstants.usersCollectionId}.documents.$currentUserId';
    _currentUserStatusSubscription = _appwrite.subscribe([channel], (response) {
      if (response.events.any((event) => event.contains('update'))) {
        _authRepository.getCurrentAppUser(forceRemote: true).then((_) {
          _checkBlockStatus();
        });
      }
    });
  }

  void _checkBlockStatus() {
    final currentUser = _authRepository.appUser.value;
    if (currentUser == null) return;
    isBlockedByMe.value =
        currentUser.blockedUsers?.contains(otherUserId) ?? false;
  }

  void blockUser() {
    if (isBlocking.value) return;
    Get.dialog(
      AlertDialog(
        title: Text('Block $otherUserName?'),
        content: const Text(
          'They will no longer be able to see your ads or contact you. You will also be unable to message them until they are unblocked.',
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Get.back()),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              _performBlock();
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBlock() async {
    isBlocking.value = true;
    try {
      await _authRepository.blockUser(otherUserId);
      isBlockedByMe.value = true;
      SnackbarService.showSuccess("User has been blocked.");
    } catch (e) {
      SnackbarService.showError("Failed to block user. Please try again.");
      LoggerService.logError(_className, 'blockUser', e);
    } finally {
      isBlocking.value = false;
    }
  }

  void unblockUser() async {
    if (isBlocking.value) return;
    isBlocking.value = true;
    try {
      await _authRepository.unblockUser(otherUserId);
      isBlockedByMe.value = false;
      SnackbarService.showSuccess("User has been unblocked.");
    } catch (e) {
      SnackbarService.showError("Failed to unblock user. Please try again.");
      LoggerService.logError(_className, 'unblockUser', e);
    } finally {
      isBlocking.value = false;
    }
  }

  void deleteConversation() async {
    if (conversation == null) {
      SnackbarService.showError("Cannot delete an unsaved conversation.");
      return;
    }
    if (isDeleting.value) return;
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text(
          'Are you sure? This will hide the conversation from your list. It will not be deleted for the other person.',
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Get.back()),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Get.back();
              isDeleting.value = true;
              try {
                await _chatRepository.deleteConversations([
                  conversation!.id,
                ], currentUserId);
                Get.back();
                SnackbarService.showSuccess("Conversation deleted.");
              } catch (e) {
                SnackbarService.showError(
                  "Failed to delete conversation. Please try again.",
                );
                LoggerService.logError(_className, 'deleteConversation', e);
              } finally {
                isDeleting.value = false;
              }
            },
          ),
        ],
      ),
    );
  }

  String get formattedLastSeen {
    final bool canSeeLastSeen =
        _authRepository.appUser.value?.showLastSeen ?? false;
    if (!canSeeLastSeen) {
      return '';
    }
    if (isBlockedByOtherUser.value) return "";
    if (isOtherUserOnline) return "Online";
    final utcLastSeen = otherUserLastSeen;
    if (utcLastSeen == null) return "";
    final localLastSeen = utcLastSeen.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localLastSeen);
    if (difference.inSeconds < 60) return "Last seen just now";
    if (difference.inMinutes < 60) {
      return "Last seen ${difference.inMinutes}m ago";
    }
    if (DateUtils.isSameDay(localLastSeen, now)) {
      return "Last seen today at ${DateFormat.jm().format(localLastSeen)}";
    }
    if (DateUtils.isSameDay(
      localLastSeen,
      now.subtract(const Duration(days: 1)),
    )) {
      return "Last seen yesterday at ${DateFormat.jm().format(localLastSeen)}";
    }
    return "Last seen ${DateFormat('MMM d').format(localLastSeen)}";
  }

  Widget getStatusIcon(MessageStatus status) {
    final bool currentUserCanSeeReceipts =
        _authRepository.appUser.value?.showReadReceipts ?? false;
    final bool otherUserShowsReceipts = otherUserShowsReadReceipts.value;
    if (status == MessageStatus.read &&
        (!currentUserCanSeeReceipts || !otherUserShowsReceipts)) {
      status = MessageStatus.sent;
    }
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.schedule, size: 16, color: Colors.grey.shade600);
      case MessageStatus.sent:
        return Icon(Icons.done_all, size: 16, color: Colors.grey.shade600);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 16, color: Colors.blue);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 16, color: Colors.red);
      default:
        return const SizedBox.shrink();
    }
  }
}
