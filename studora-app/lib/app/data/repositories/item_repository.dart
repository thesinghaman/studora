import 'dart:async';
import 'package:appwrite/appwrite.dart' as appwrite_sdk;
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/data/providers/database_provider.dart';
import 'package:studora/app/data/providers/item_provider.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
class ItemRepository {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  final ItemProvider _itemProvider = Get.find<ItemProvider>();
  final DatabaseProvider _databaseProvider = Get.find<DatabaseProvider>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  static const String _className = 'ItemRepository';
  final RxList<ItemModel> _marketplaceItems = <ItemModel>[].obs;
  final RxList<ItemModel> _rentalItems = <ItemModel>[].obs;
  final RxList<ItemModel> _myAds = <ItemModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isInitialized = false.obs;
  RxList<ItemModel> get allMarketplaceItems => _marketplaceItems;
  RxList<ItemModel> get allRentalItems => _rentalItems;
  RxList<ItemModel> get myAds => _myAds;
  Stream<ItemModel?> getItemStream(String itemId) {
    const String methodName = 'getItemStream';
    final docPath =
        'databases.${AppConstants.appwriteDatabaseId}.collections.${AppConstants.itemsCollectionId}.documents.$itemId';
    late StreamController<ItemModel?> controller;
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
          final item = ItemModel.fromJson(updatedDoc.data, updatedDoc.$id);
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
        final initialDoc = await getItemById(itemId);
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
    controller = StreamController<ItemModel?>(
      onListen: startStream,
      onPause: stopStream,
      onResume: startStream,
      onCancel: stopStream,
    );
    return controller.stream;
  }


  Future<void> initializeAndFetchAllItems() async {
    const String methodName = 'initial izeAndFetchAllItems';
    isLoading.value = true;
    try {

      final marketplaceDocs = await _itemProvider.getPublicFilteredItems(
        'marketplace',
      );
      _marketplaceItems.assignAll(
        marketplaceDocs
            .map((doc) => ItemModel.fromJson(doc.data, doc.$id))
            .toList(),
      );
      final rentalDocs = await _itemProvider.getPublicFilteredItems('rental');
      _rentalItems.assignAll(
        rentalDocs.map((doc) => ItemModel.fromJson(doc.data, doc.$id)).toList(),
      );

      final currentUserId = _authRepository.appUser.value?.userId;
      if (currentUserId != null && currentUserId.isNotEmpty) {
        final myMarketplaceItems = await _itemProvider
            .getAllUserMarketplaceItems(currentUserId);
        final myRentalItems = await _itemProvider.getAllUserRentalItems(
          currentUserId,
        );
        final allMyItems = [...myMarketplaceItems, ...myRentalItems];
        allMyItems.sort((a, b) => b.datePosted.compareTo(a.datePosted));
        _myAds.assignAll(allMyItems);
      } else {
        _myAds.clear();
      }
      isInitialized.value = true;
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        'Error initializing repository: $e',
        s,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearUserSpecificData() {
    _myAds.clear();
  }

  Future<ItemModel?> getItemById(String itemId) async {
    const String methodName = 'getItemById';
    try {

      ItemModel? cachedItem =
          _marketplaceItems.firstWhereOrNull((item) => item.id == itemId) ??
          _rentalItems.firstWhereOrNull((item) => item.id == itemId) ??
          _myAds.firstWhereOrNull((item) => item.id == itemId);
      if (cachedItem != null) {
        LoggerService.logInfo(
          _className,
          methodName,
          'Found item $itemId in cache.',
        );
        return cachedItem;
      }

      final appwrite_models.Document? document = await _databaseProvider
          .getDocument(
            databaseId: AppConstants.appwriteDatabaseId,
            collectionId: AppConstants.itemsCollectionId,
            documentId: itemId,
          );
      return document != null
          ? ItemModel.fromJson(document.data, document.$id)
          : null;
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        'Error fetching item $itemId: $e',
        s,
      );
      return null;
    }
  }

  Future<ItemModel> createItem({
    required ItemModel itemDraft,
    required List<XFile> imagesToUpload,
    required String bucketId,
  }) async {
    final createdItem = await _createItemInBackend(
      itemDraft: itemDraft,
      imagesToUpload: imagesToUpload,
      bucketId: bucketId,
    );

    _myAds.insert(0, createdItem);

    if (createdItem.isActive) {
      if (createdItem.isRental) {
        _rentalItems.insert(0, createdItem);
      } else {
        _marketplaceItems.insert(0, createdItem);
      }
    }
    return createdItem;
  }

  Future<ItemModel> updateItem({
    required ItemModel updatedItemData,
    List<XFile> newImagesToUpload = const [],
    List<String> imageFileIdsToDelete = const [],
    required String bucketId,
  }) async {
    final updatedItem = await _updateItemInBackend(
      updatedItemData: updatedItemData,
      newImagesToUpload: newImagesToUpload,
      imageFileIdsToDelete: imageFileIdsToDelete,
      bucketId: bucketId,
    );


    final myAdsIndex = _myAds.indexWhere((ad) => ad.id == updatedItem.id);
    if (myAdsIndex != -1) {
      _myAds[myAdsIndex] = updatedItem;
    }

    final publicList = updatedItem.isRental ? _rentalItems : _marketplaceItems;
    final publicIndex = publicList.indexWhere((p) => p.id == updatedItem.id);
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

  Future<void> deleteItem(
    String itemId,
    List<String>? imageFileIds,
    String bucketId,
  ) async {
    await _deleteItemFromBackend(itemId, imageFileIds, bucketId);

    _myAds.removeWhere((item) => item.id == itemId);
    _marketplaceItems.removeWhere((item) => item.id == itemId);
    _rentalItems.removeWhere((item) => item.id == itemId);
  }

  Future<ItemModel> _createItemInBackend({
    required ItemModel itemDraft,
    required List<XFile> imagesToUpload,
    required String bucketId,
  }) async {
    const String methodName = '_createItemInBackend';
    List<String> uploadedImageFileIds = [];
    List<String> uploadedImageUrls = [];
    try {
      for (XFile imageFile in imagesToUpload) {
        final String originalFileName = Uri.file(
          imageFile.path,
        ).pathSegments.last;
        final String sanitizedFileName = originalFileName.replaceAll(
          RegExp(r'[^a-zA-Z0-9._-]'),
          '_',
        );
        final String uniqueFileName =
            '${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
        final appwrite_sdk.InputFile appwriteFile = appwrite_sdk
            .InputFile.fromPath(path: imageFile.path, filename: uniqueFileName);
        List<String> filePermissions = [
          appwrite_sdk.Permission.read(appwrite_sdk.Role.any()),
          appwrite_sdk.Permission.update(
            appwrite_sdk.Role.user(itemDraft.sellerId),
          ),
          appwrite_sdk.Permission.delete(
            appwrite_sdk.Role.user(itemDraft.sellerId),
          ),
        ];
        final uploadedFile = await _appwriteService.storage.createFile(
          bucketId: bucketId,
          fileId: appwrite_sdk.ID.unique(),
          file: appwriteFile,
          permissions: filePermissions,
        );
        uploadedImageFileIds.add(uploadedFile.$id);
        final String imageUrlString =
            "${AppwriteService.projectEndpoint}/storage/buckets/$bucketId/files/${uploadedFile.$id}/view?project=${AppwriteService.projectId}&mode=public";
        uploadedImageUrls.add(imageUrlString);
      }
      final String newItemId = appwrite_sdk.ID.unique();
      final ItemModel finalItemData = itemDraft.copyWith(
        id: newItemId,
        imageFileIds: uploadedImageFileIds,
        imageUrls: uploadedImageUrls,
        datePosted: DateTime.now(),
        isActive: true,
        adStatus: "Active",
        viewCount: 0,
        isFavorite: false,
      );
      List<String> documentPermissions = [
        appwrite_sdk.Permission.read(appwrite_sdk.Role.any()),
        appwrite_sdk.Permission.update(
          appwrite_sdk.Role.user(finalItemData.sellerId),
        ),
        appwrite_sdk.Permission.delete(
          appwrite_sdk.Role.user(finalItemData.sellerId),
        ),
      ];
      final createdDocument = await _databaseProvider.createDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.itemsCollectionId,
        documentId: newItemId,
        data: finalItemData.toJson(),
        permissions: documentPermissions,
      );
      return ItemModel.fromJson(createdDocument.data, createdDocument.$id);
    } catch (e, s) {
      LoggerService.logError(_className, methodName, "Error: $e", s);
      for (String fileId in uploadedImageFileIds) {
        try {
          await _appwriteService.storage.deleteFile(
            bucketId: bucketId,
            fileId: fileId,
          );
        } catch (cleanupError) {
          LoggerService.logError(
            _className,
            methodName,
            "Cleanup error for $fileId: $cleanupError",
          );
        }
      }
      rethrow;
    }
  }
  Future<ItemModel> _updateItemInBackend({
    required ItemModel updatedItemData,
    List<XFile> newImagesToUpload = const [],
    List<String> imageFileIdsToDelete = const [],
    required String bucketId,
  }) async {
    const String methodName = '_updateItemInBackend';
    List<String> finalImageFileIds = List<String>.from(
      updatedItemData.imageFileIds ?? [],
    );
    List<String> finalImageUrls = List<String>.from(
      updatedItemData.imageUrls ?? [],
    );
    List<String> newlyUploadedFileIdsForRollback = [];
    try {
      if (imageFileIdsToDelete.isNotEmpty) {
        for (String fileId in imageFileIdsToDelete) {
          try {
            await _appwriteService.storage.deleteFile(
              bucketId: bucketId,
              fileId: fileId,
            );
            finalImageFileIds.remove(fileId);
            finalImageUrls.removeWhere((url) => url.contains('/$fileId/'));
          } catch (e) {
            LoggerService.logWarning(
              _className,
              methodName,
              "Failed to delete image $fileId: $e",
            );
          }
        }
      }
      if (newImagesToUpload.isNotEmpty) {
        for (XFile imageFile in newImagesToUpload) {
          final String originalFileName = Uri.file(
            imageFile.path,
          ).pathSegments.last;
          final String sanitizedFileName = originalFileName.replaceAll(
            RegExp(r'[^a-zA-Z0-9._-]'),
            '_',
          );
          final String uniqueFileName =
              '${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
          final appwrite_sdk.InputFile appwriteFile =
              appwrite_sdk.InputFile.fromPath(
                path: imageFile.path,
                filename: uniqueFileName,
              );
          final List<String> filePermissions = [
            appwrite_sdk.Permission.read(appwrite_sdk.Role.any()),
            appwrite_sdk.Permission.update(
              appwrite_sdk.Role.user(updatedItemData.sellerId),
            ),
            appwrite_sdk.Permission.delete(
              appwrite_sdk.Role.user(updatedItemData.sellerId),
            ),
          ];
          final uploadedFile = await _appwriteService.storage.createFile(
            bucketId: bucketId,
            fileId: appwrite_sdk.ID.unique(),
            file: appwriteFile,
            permissions: filePermissions,
          );
          newlyUploadedFileIdsForRollback.add(uploadedFile.$id);
          finalImageFileIds.add(uploadedFile.$id);
          final String imageUrlString =
              "${AppwriteService.projectEndpoint}/storage/buckets/$bucketId/files/${uploadedFile.$id}/view?project=${AppwriteService.projectId}&mode=public";
          finalImageUrls.add(imageUrlString);
        }
      }
      final ItemModel itemToSave = updatedItemData.copyWith(
        imageFileIds: finalImageFileIds,
        imageUrls: finalImageUrls,
      );
      final updatedDocument = await _databaseProvider.updateDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.itemsCollectionId,
        documentId: itemToSave.id,
        data: itemToSave.toJson(),
      );
      return ItemModel.fromJson(updatedDocument.data, updatedDocument.$id);
    } catch (e, s) {
      LoggerService.logError(_className, methodName, "Error: $e", s);
      for (String fileId in newlyUploadedFileIdsForRollback) {
        try {
          await _appwriteService.storage.deleteFile(
            bucketId: bucketId,
            fileId: fileId,
          );
        } catch (cleanupError) {
          LoggerService.logError(
            _className,
            methodName,
            "Rollback cleanup error for $fileId: $cleanupError",
          );
        }
      }
      rethrow;
    }
  }
  Future<void> _deleteItemFromBackend(
    String itemId,
    List<String>? imageFileIds,
    String bucketId,
  ) async {
    const String methodName = '_deleteItemFromBackend';
    if (imageFileIds != null && imageFileIds.isNotEmpty) {
      for (String fileId in imageFileIds) {
        try {
          await _appwriteService.storage.deleteFile(
            bucketId: bucketId,
            fileId: fileId,
          );
        } catch (e, s) {
          LoggerService.logError(
            _className,
            methodName,
            "Failed to delete image $fileId for $itemId: $e",
            s,
          );
        }
      }
    }
    try {
      await _databaseProvider.deleteAppwriteDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.itemsCollectionId,
        documentId: itemId,
      );
    } on appwrite_sdk.AppwriteException catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        "AppwriteException deleting $itemId: ${e.message}",
        s,
      );
      throw Exception("Failed to delete ad from database: ${e.message}");
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        "Unknown error deleting $itemId: $e",
        s,
      );
      throw Exception("An unexpected error occurred while deleting the ad.");
    }
  }

  Future<List<ItemModel>> getItemsByCategory(
    String categoryId, {
    bool excludeRentals = true,
  }) async {
    const String methodName = 'getItemsByCategory';
    LoggerService.logInfo(
      _className,
      methodName,
      'Fetching items for category ID: $categoryId',
    );
    final String itemType = excludeRentals ? 'marketplace' : 'all_items';
    try {
      final documents = await _itemProvider.getPublicFilteredItems(
        itemType,
        categoryId: categoryId,
      );
      return documents
          .map((doc) => ItemModel.fromJson(doc.data, doc.$id))
          .toList();
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        'Error fetching items for category $categoryId: $e',
        s,
      );
      return [];
    }
  }
  Future<List<ItemModel>> searchItems({
    required String itemType,
    String? searchQuery,
    List<String>? categoryIds,
    String? collegeId,
    int? limit,
    int? offset,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
  }) async {
    const String methodName = 'searchItems';
    try {
      final documents = await _itemProvider.searchPublicFilteredItems(
        itemType: itemType,
        searchQuery: searchQuery,
        categoryIds: categoryIds,
        collegeId: collegeId,
        limit: limit,
        offset: offset,
        sortBy: sortBy,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
      return documents
          .map((doc) => ItemModel.fromJson(doc.data, doc.$id))
          .toList();
    } catch (e, s) {
      LoggerService.logError(_className, methodName, 'Error: $e', s);
      return [];
    }
  }
}
