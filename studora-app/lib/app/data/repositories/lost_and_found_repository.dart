import 'dart:async';
import 'package:appwrite/appwrite.dart' as appwrite_sdk;
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studora/app/data/models/lost_found_item_model.dart';
import 'package:studora/app/data/providers/lost_and_found_provider.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
class LostAndFoundRepository extends GetxService {
  final LostAndFoundProvider _provider = Get.find<LostAndFoundProvider>();
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  static const String _className = 'LostAndFoundRepository';

  final RxList<LostFoundItemModel> _lostItems = <LostFoundItemModel>[].obs;
  final RxList<LostFoundItemModel> _foundItems = <LostFoundItemModel>[].obs;
  final RxList<LostFoundItemModel> _myLostFoundPosts =
      <LostFoundItemModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isInitialized = false.obs;

  RxList<LostFoundItemModel> get allLostItems => _lostItems;
  RxList<LostFoundItemModel> get allFoundItems => _foundItems;
  RxList<LostFoundItemModel> get myLostFoundPosts => _myLostFoundPosts;
  Stream<LostFoundItemModel?> getLostFoundItemStream(String itemId) {
    const String methodName = 'getLostFoundItemStream';
    final docPath =
        'databases.${AppConstants.appwriteDatabaseId}.collections.${AppConstants.lostFoundItemsCollectionId}.documents.$itemId';
    late StreamController<LostFoundItemModel?> controller;
    appwrite_sdk.RealtimeSubscription? subscription;
    void handleStreamEvent(appwrite_sdk.RealtimeMessage event) {
      if (event.events.contains(
        'databases.*.collections.*.documents.*.delete',
      )) {
        LoggerService.logInfo(
          _className,
          methodName,
          'Item $itemId deleted via stream. Emitting null.',
        );
        if (!controller.isClosed) {
          controller.add(null);
        }
        return;
      }
      if (event.payload.isNotEmpty) {
        try {
          final updatedDoc = appwrite_models.Document.fromMap(event.payload);
          final item = LostFoundItemModel.fromAppwriteDocument(updatedDoc);
          if (!controller.isClosed) {
            controller.add(item);
          }
        } catch (e, s) {
          LoggerService.logError(
            _className,
            methodName,
            'Error parsing stream payload for item $itemId: $e',
            s,
          );
          if (!controller.isClosed) {
            controller.add(null);
          }
        }
      }
    }
    Future<void> startStream() async {
      try {
        final initialDoc = await getLostFoundItemById(itemId);
        if (!controller.isClosed) {
          controller.add(initialDoc);
        }
      } catch (e, s) {
        LoggerService.logError(
          _className,
          methodName,
          'Failed to fetch initial state for item $itemId: $e',
          s,
        );
        if (!controller.isClosed) {
          controller.add(null);
        }
      }
      try {
        subscription?.close();
        subscription = _appwriteService.realtime.subscribe([docPath]);
        subscription!.stream.listen(
          handleStreamEvent,
          onError: (e) {
            LoggerService.logError(
              _className,
              methodName,
              'Realtime stream error for item $itemId: $e',
            );
            if (!controller.isClosed) controller.add(null);
          },
          onDone: () {
            if (!controller.isClosed) controller.close();
          },
        );
      } catch (e, s) {
        LoggerService.logError(
          _className,
          methodName,
          'Failed to subscribe to realtime for item $itemId: $e',
          s,
        );
        if (!controller.isClosed) {
          controller.add(null);
          controller.close();
        }
      }
    }
    void stopStream() {
      subscription?.close();
    }
    controller = StreamController<LostFoundItemModel?>(
      onListen: startStream,
      onPause: stopStream,
      onResume: startStream,
      onCancel: stopStream,
    );
    return controller.stream;
  }

  Future<void> initializeAndFetchAllItems() async {
    if (isInitialized.value) return;
    isLoading.value = true;
    try {

      final lostDocs = await _provider.getPublicFilteredLfItems(
        'lost',
        _authRepository.appUser.value?.collegeId,
      );
      _lostItems.assignAll(
        lostDocs
            .map((doc) => LostFoundItemModel.fromAppwriteDocument(doc))
            .toList(),
      );

      final foundDocs = await _provider.getPublicFilteredLfItems(
        'found',
        _authRepository.appUser.value?.collegeId,
      );
      _foundItems.assignAll(
        foundDocs
            .map((doc) => LostFoundItemModel.fromAppwriteDocument(doc))
            .toList(),
      );

      final currentUserId = _authRepository.appUser.value?.userId;
      if (currentUserId != null) {
        final myPosts = await _provider.getAllUserLostAndFoundItems(
          currentUserId,
        );
        myPosts.sort((a, b) => b.dateReported.compareTo(a.dateReported));
        _myLostFoundPosts.assignAll(myPosts);
      } else {
        _myLostFoundPosts.clear();
      }
      isInitialized.value = true;
    } catch (e, s) {
      LoggerService.logError(
        _className,
        'initializeAndFetchAllItems',
        'Error: $e',
        s,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearUserSpecificData() {
    _myLostFoundPosts.clear();
  }

  Future<LostFoundItemModel> createLostFoundItem(
    LostFoundItemModel item,
  ) async {
    final createdItem = await _provider.createLostFoundItem(item);

    _myLostFoundPosts.insert(0, createdItem);

    if (createdItem.isActive) {
      if (createdItem.type == LostFoundType.lost) {
        _lostItems.insert(0, createdItem);
      } else if (createdItem.type == LostFoundType.found) {
        _foundItems.insert(0, createdItem);
      }
    }
    return createdItem;
  }

  Future<LostFoundItemModel> getLostFoundItemById(String itemId) async {

    LostFoundItemModel? cachedItem =
        _lostItems.firstWhereOrNull((i) => i.id == itemId) ??
        _foundItems.firstWhereOrNull((i) => i.id == itemId) ??
        _myLostFoundPosts.firstWhereOrNull((i) => i.id == itemId);
    if (cachedItem != null) {
      return cachedItem;
    }

    return await _provider.getLostFoundItemById(itemId);
  }

  Future<LostFoundItemModel> updateLostFoundItem(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    final updatedItem = await _provider.updateLostFoundItem(itemId, data);

    final myIndex = _myLostFoundPosts.indexWhere((i) => i.id == itemId);
    if (myIndex != -1) {
      _myLostFoundPosts[myIndex] = updatedItem;
    }

    final publicList = updatedItem.type == LostFoundType.lost
        ? _lostItems
        : _foundItems;
    final publicIndex = publicList.indexWhere((i) => i.id == itemId);
    if (updatedItem.isActive) {

      if (publicIndex != -1) {
        publicList[publicIndex] = updatedItem;
      } else {
        publicList.insert(0, updatedItem);
      }
    } else {

      if (publicIndex != -1) {
        publicList.removeAt(publicIndex);
      }
    }
    return updatedItem;
  }

  Future<List<LostFoundItemModel>> getAllUserLostAndFoundItems(String userId) {
    return _provider.getAllUserLostAndFoundItems(userId);
  }
  Future<List<String>> uploadAndGetImageUrls(
    List<XFile> images,
    String bucketId,
  ) async {
    if (images.isEmpty) return [];
    return await _provider.uploadImagesToBucket(images, bucketId);
  }
  Future<void> deleteSpecifiedImages(
    List<String> fileIds,
    String bucketId,
  ) async {
    if (fileIds.isEmpty) return;
    await _provider.deleteImagesFromBucket(fileIds, bucketId);
  }

  Future<void> deleteLostFoundItemWithImages(
    String itemId,
    List<String>? imageUrls,
  ) async {
    const String functionName = 'deleteLostFoundItemWithImages';
    if (imageUrls != null && imageUrls.isNotEmpty) {
      List<String> fileIdsToDelete = [];
      for (String url in imageUrls) {
        try {
          Uri uri = Uri.parse(url);
          int filesSegmentIndex = uri.pathSegments.indexOf('files');
          if (filesSegmentIndex != -1 &&
              filesSegmentIndex < uri.pathSegments.length - 1) {
            fileIdsToDelete.add(uri.pathSegments[filesSegmentIndex + 1]);
          }
        } catch (e) {
          LoggerService.logError(
            _className,
            functionName,
            'Error parsing URL $url: $e',
          );
        }
      }
      if (fileIdsToDelete.isNotEmpty) {
        await deleteSpecifiedImages(
          fileIdsToDelete,
          AppConstants.itemsImagesBucketId,
        );
      }
    }

    await _provider.permanentlyDeleteItemDocument(itemId);

    _lostItems.removeWhere((item) => item.id == itemId);
    _foundItems.removeWhere((item) => item.id == itemId);
    _myLostFoundPosts.removeWhere((item) => item.id == itemId);
    LoggerService.logInfo(
      _className,
      functionName,
      'Successfully processed permanent deletion for item $itemId.',
    );
  }

  Future<LostFoundItemModel> markItemAsClaimed(String itemId) async {
    return await updateLostFoundItem(itemId, {
      'postStatus': 'Claimed',
      'isActive': false,
    });
  }
  Future<List<LostFoundItemModel>> getLostItems({
    String? collegeId,
    List<String>? categoryIds,
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final documents = await _provider.getPublicFilteredLfItems(
        'lost',
        collegeId,
        categoryIds: categoryIds,
        limit: limit,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
      );
      return documents
          .map((doc) => LostFoundItemModel.fromAppwriteDocument(doc))
          .toList();
    } catch (e) {
      LoggerService.logError(
        "LostAndFoundRepository",
        "getLostItems",
        "Failed to fetch lost items: $e",
      );
      rethrow;
    }
  }
  Future<List<LostFoundItemModel>> getFoundItems({
    String? collegeId,
    List<String>? categoryIds,
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final documents = await _provider.getPublicFilteredLfItems(
        'found',
        collegeId,
        categoryIds: categoryIds,
        limit: limit,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
      );
      return documents
          .map((doc) => LostFoundItemModel.fromAppwriteDocument(doc))
          .toList();
    } catch (e) {
      LoggerService.logError(
        "LostAndFoundRepository",
        "getFoundItems",
        "Failed to fetch found items: $e",
      );
      rethrow;
    }
  }
}
