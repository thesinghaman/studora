import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';

import 'package:intl/intl.dart';
import 'package:studora/app/data/models/category_model.dart';
import 'package:studora/app/data/models/conversation_model.dart';
import 'package:studora/app/data/models/related_item_model.dart';
import 'package:studora/app/data/models/user_profile_model.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/data/repositories/category_repository.dart';
import 'package:studora/app/data/repositories/chat_repository.dart';
import 'package:studora/app/data/repositories/item_repository.dart';
import 'package:studora/app/data/repositories/lost_and_found_repository.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
import 'package:studora/app/data/repositories/report_repository.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';

class ChatUserProfileController extends GetxController {
  static const String _className = 'ChatUserProfileController';

  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final ReportRepository _reportRepository = Get.find<ReportRepository>();
  final ChatRepository _chatRepository = Get.find<ChatRepository>();
  final AppwriteService _appwrite = Get.find<AppwriteService>();

  final ItemRepository _itemRepository = Get.find<ItemRepository>();
  final LostAndFoundRepository _lostFoundRepository =
      Get.find<LostAndFoundRepository>();

  final RxBool isOtherUserOnline = false.obs;
  final Rxn<DateTime> otherUserLastSeen = Rxn<DateTime>();
  RealtimeSubscription? _userStatusSubscription;
  Timer? _lastSeenTimer;
  RealtimeSubscription? _conversationSubscription;

  final List<StreamSubscription> _itemStreamSubscriptions = [];

  final Rxn<UserProfileModel> userProfile = Rxn<UserProfileModel>();
  final RxBool isLoading = true.obs;

  final RxList<dynamic> currentlyDiscussingItems = <dynamic>[].obs;
  final RxList<CategoryModel> _lostFoundCategories = <CategoryModel>[].obs;
  final RxBool isCheckingReportStatus = false.obs;
  final RxBool isBlocking = false.obs;
  final RxBool isDeleting = false.obs;
  var isOtherUserBlocked = false.obs;
  late String userId;
  String? originatingConversationId;
  StreamSubscription? _userSubscription;
  final Rxn<ConversationModel> rxConversation = Rxn<ConversationModel>();
  String get currentUserId => _authRepository.appUser.value!.userId;
  @override
  void onInit() {
    super.onInit();
    _loadArgumentsAndFetchData();
    _checkBlockStatus();
    _startLastSeenTimer();
    _userSubscription = _authRepository.appUser.listen((_) {
      _checkBlockStatus();
    });
  }

  @override
  void onClose() {
    _userSubscription?.cancel();
    _userStatusSubscription?.close();
    _lastSeenTimer?.cancel();

    for (var sub in _itemStreamSubscriptions) {
      sub.cancel();
    }
    _itemStreamSubscriptions.clear();
    _conversationSubscription?.close();
    super.onClose();
  }

  Future<void> _loadArgumentsAndFetchData() async {
    isLoading.value = true;
    try {
      final arguments = Get.arguments as Map<String, dynamic>? ?? {};
      userId = arguments['userId'];
      originatingConversationId = arguments['originatingConversationId'];
      Future<void> fetchProfileFuture = _fetchUserProfile();
      Future<void> fetchCategoriesFuture = _fetchLostFoundCategories();
      if (originatingConversationId != null) {
        rxConversation.value = await _chatRepository.getConversationById(
          originatingConversationId!,
        );
        if (rxConversation.value != null) {
          _subscribeToItemStreamsFromConversation(rxConversation.value!);

          _subscribeToConversationUpdates();
        }
      }
      await Future.wait([fetchProfileFuture, fetchCategoriesFuture]);
    } catch (e, s) {
      LoggerService.logError(
        _className,
        '_loadArgumentsAndFetchData',
        'Error: $e',
        s,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeToConversationUpdates() {
    if (originatingConversationId == null) return;
    _conversationSubscription?.close();
    final channel =
        'databases.${AppConstants.appwriteDatabaseId}.collections.${AppConstants.conversationsCollectionId}.documents.$originatingConversationId';
    _conversationSubscription = _appwrite.subscribe([channel], (response) {
      if (response.events.any((event) => event.endsWith('.update'))) {
        final newConversationData = ConversationModel.fromJson(
          response.payload,
          response.payload['\$id'],
        );
        rxConversation.value = newConversationData;
        _subscribeToItemStreamsFromConversation(newConversationData);
      }
    });
  }

  void _subscribeToItemStreamsFromConversation(ConversationModel conversation) {
    _cleanupItemSubscriptions();
    currentlyDiscussingItems.clear();
    for (final relatedItem in conversation.relatedItems) {
      _subscribeToSingleItem(relatedItem);
    }
  }

  void _subscribeToSingleItem(RelatedItem relatedItem) {
    final initialIndex = currentlyDiscussingItems.indexWhere(
      (i) =>
          (i is RelatedItem && i.itemId == relatedItem.itemId) ||
          (i is! RelatedItem && i.id == relatedItem.itemId),
    );
    if (initialIndex == -1) {
      currentlyDiscussingItems.add(relatedItem);
    }
    Stream<dynamic>? itemStream;
    if (relatedItem.itemType == 'ItemModel') {
      itemStream = _itemRepository.getItemStream(relatedItem.itemId);
    } else {
      itemStream = _lostFoundRepository.getLostFoundItemStream(
        relatedItem.itemId,
      );
    }
    final subscription = itemStream.listen((itemData) {
      final index = currentlyDiscussingItems.indexWhere(
        (i) =>
            (i is RelatedItem && i.itemId == relatedItem.itemId) ||
            (i is! RelatedItem && i.id == relatedItem.itemId),
      );
      if (index != -1) {
        currentlyDiscussingItems[index] = itemData ?? relatedItem;
      }
    });
    _itemStreamSubscriptions.add(subscription);
  }

  void _cleanupItemSubscriptions() {
    for (var sub in _itemStreamSubscriptions) {
      sub.cancel();
    }
    _itemStreamSubscriptions.clear();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final profile = await _authRepository.getPublicUserProfile(userId);
      userProfile.value = profile;
      isOtherUserOnline.value = profile.isOnline;
      otherUserLastSeen.value = profile.lastSeen;
      update(['lastSeen']);
      _subscribeToOtherUserStatus();
    } catch (e) {
      LoggerService.logError(
        _className,
        '_fetchUserProfile',
        'Failed to fetch profile: $e',
      );
    }
  }

  void _subscribeToOtherUserStatus() {
    _userStatusSubscription?.close();
    final channel =
        'databases.${AppConstants.appwriteDatabaseId}.collections.${AppConstants.usersCollectionId}.documents.$userId';
    _userStatusSubscription = _appwrite.subscribe([channel], (response) {
      if (response.events.any((event) => event.endsWith('.update'))) {
        _fetchUserProfile();
      }
    });
  }

  String get formattedLastSeen {
    final bool canSeeLastSeen =
        _authRepository.appUser.value?.showLastSeen ?? false;
    if (!canSeeLastSeen) {
      return '';
    }
    if (isOtherUserOnline.value) {
      return 'Online';
    }
    if (otherUserLastSeen.value != null) {
      final now = DateTime.now();
      final difference = now.difference(otherUserLastSeen.value!);
      if (difference.inSeconds < 60) {
        return 'last seen recently';
      } else if (difference.inMinutes < 60) {
        return 'last seen ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'last seen ${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'last seen yesterday';
      } else {
        return 'last seen on ${DateFormat('MMM d').format(otherUserLastSeen.value!)}';
      }
    }
    return '';
  }

  void _startLastSeenTimer() {
    _lastSeenTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (!isOtherUserOnline.value) {
        update(['lastSeen']);
      }
    });
  }

  void blockOnlyUser() {
    if (userProfile.value == null || isBlocking.value) return;
    Get.dialog(
      AlertDialog(
        title: Text('Block ${userProfile.value!.userName}?'),
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
    if (userProfile.value == null || isBlocking.value) return;
    isBlocking.value = true;
    try {
      await _authRepository.blockUser(userProfile.value!.userId);
      SnackbarService.showSuccess("User has been blocked.");
    } catch (e) {
      SnackbarService.showError("Failed to block user. Please try again.");
      LoggerService.logError(_className, 'blockOnlyUser', e);
    } finally {
      isBlocking.value = false;
    }
  }

  void blockAndReportUser() {
    if (userProfile.value == null || isBlocking.value) return;
    Get.dialog(
      AlertDialog(
        title: Text('Block and Report ${userProfile.value!.userName}?'),
        content: const Text(
          'As a first step, the user will be blocked. You will then be taken to the report screen to provide more details.',
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Get.back()),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              _performBlockAndReport();
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBlockAndReport() async {
    if (userProfile.value == null || isBlocking.value) return;
    isBlocking.value = true;
    try {
      await _authRepository.blockUser(userProfile.value!.userId);
      SnackbarService.showInfo("User blocked. Now proceeding to report.");
      await reportUser();
    } catch (e) {
      SnackbarService.showError("Failed to block user. Please try again.");
      LoggerService.logError(_className, 'blockAndReportUser', e);
    } finally {
      isBlocking.value = false;
    }
  }

  Future<void> _fetchLostFoundCategories() async {
    try {
      _lostFoundCategories.value = await _categoryRepository.getCategories(
        type: AppConstants.categoryTypeLostFound,
      );
    } catch (e) {
      rethrow;
    }
  }

  void _checkBlockStatus() {
    final currentUser = _authRepository.appUser.value;
    if (currentUser != null) {
      isOtherUserBlocked.value =
          currentUser.blockedUsers?.contains(userId) ?? false;
    }
  }

  void unblockUser() async {
    if (userProfile.value == null || isBlocking.value) return;
    isBlocking.value = true;
    try {
      await _authRepository.unblockUser(userProfile.value!.userId);
      SnackbarService.showSuccess("User has been unblocked.");
    } catch (e) {
      SnackbarService.showError("Failed to unblock user.");
      LoggerService.logError(_className, 'unblockUser', e);
    } finally {
      isBlocking.value = false;
    }
  }

  Future<void> reportUser() async {
    if (userProfile.value == null) {
      SnackbarService.showError("Cannot report: User details are missing.");
      return;
    }
    final currentUser = _authRepository.appUser.value;
    if (currentUser == null) {
      SnackbarService.showError("You must be logged in to report.");
      return;
    }
    if (currentUser.userId == userId) {
      SnackbarService.showInfo("You cannot report yourself.");
      return;
    }
    isCheckingReportStatus.value = true;
    try {
      final existingReport = await _reportRepository.findExistingPendingReport(
        reporterId: currentUser.userId,
        reportedId: userId,
        type: ReportType.user,
      );
      if (existingReport != null) {
        Get.toNamed(
          AppRoutes.EXISTING_REPORT_DETAIL,
          arguments: {'report': existingReport},
        );
      } else {
        LoggerService.logInfo(
          _className,
          'reportUser',
          'Navigating to report screen for user: $userId',
        );
        Get.toNamed(
          AppRoutes.REPORT_SUBMISSION,
          arguments: {
            'reportedUserId': userId,
            'reportedUserName': userProfile.value?.userName ?? 'N/A',
            'reportType': ReportType.user,
          },
        );
      }
    } catch (e) {
      LoggerService.logError(
        _className,
        'reportUser',
        'Error checking for existing report: $e',
      );
      SnackbarService.showError(
        "Could not check report status. Please try again.",
      );
    } finally {
      isCheckingReportStatus.value = false;
    }
  }

  void deleteConversation() async {
    if (originatingConversationId == null) {
      SnackbarService.showError(
        "Cannot delete, conversation context is missing.",
      );
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
                final currentUserId = _authRepository.appUser.value!.userId;
                await _chatRepository.deleteConversations([
                  originatingConversationId!,
                ], currentUserId);
                Get.until(
                  (route) => route.settings.name == AppRoutes.MAIN_NAVIGATION,
                );
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

  IconData getCategoryIcon(String? categoryId) {
    if (categoryId == null) return CupertinoIcons.question_circle;
    try {
      final category = _lostFoundCategories.firstWhere(
        (c) => c.id == categoryId,
      );
      return AppConstants.lostAndFoundIcons[category.name] ??
          CupertinoIcons.question_circle;
    } catch (_) {
      return CupertinoIcons.question_circle;
    }
  }
}
