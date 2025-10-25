import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:studora/app/data/models/lost_found_item_model.dart';
import 'package:studora/app/data/models/category_model.dart'
    as app_category_model;
import 'package:studora/app/data/repositories/lost_and_found_repository.dart';
import 'package:studora/app/data/repositories/category_repository.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/shared_components/utils/enums.dart';

enum DateFilterOption { any, today, last7Days, last30Days, custom }

class LostAndFoundController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static const String _className = 'LostAndFoundController';

  final LostAndFoundRepository _repository = Get.find<LostAndFoundRepository>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();

  late TabController tabController;
  var selectedTabIndex = 0.obs;
  var isLoadingLost = true.obs;
  var isLoadingFound = true.obs;
  var isLoadingMoreLost = false.obs;
  var isLoadingMoreFound = false.obs;
  var lostItems = <LostFoundItemModel>[].obs;
  var foundItems = <LostFoundItemModel>[].obs;
  var hasMoreLostItems = true.obs;
  var hasMoreFoundItems = true.obs;
  int _currentLostPage = 0;
  int _currentFoundPage = 0;
  final int _itemsPerPage = 15;
  String? _currentUserCollegeId;
  String get currentUserId => _authRepository.appUser.value?.userId ?? '';
  var fetchedLfCategories = <app_category_model.CategoryModel>[].obs;
  var selectedFilterCategoryIds = <String>{}.obs;
  var selectedDateFilter = DateFilterOption.any.obs;
  var customDateRange = Rxn<DateTimeRange>();
  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    _initializeController();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> _initializeController() async {
    _currentUserCollegeId = _authRepository.appUser.value?.collegeId;
    tabController.addListener(
      () => selectedTabIndex.value = tabController.index,
    );
    await _fetchLfCategories();

    await refreshItems();
  }

  Future<void> _fetchLfCategories() async {
    try {
      final categories = await _categoryRepository.getCategories(type: "lf");
      fetchedLfCategories.assignAll(categories);
    } catch (e) {
      LoggerService.logError(
        _className,
        '_fetchLfCategories',
        'Failed to load L&F categories: $e',
      );
    }
  }

  Future<void> refreshItems() async {
    await Future.wait([
      fetchLostItems(isRefresh: true),
      fetchFoundItems(isRefresh: true),
    ]);
  }

  Future<void> fetchLostItems({bool isRefresh = false}) async {
    if (!isRefresh &&
        (isLoadingLost.value ||
            isLoadingMoreLost.value ||
            !hasMoreLostItems.value)) {
      return;
    }
    if (isRefresh) {
      _currentLostPage = 0;
      hasMoreLostItems.value = true;
      isLoadingLost.value = true;
      lostItems.clear();
    } else {
      isLoadingMoreLost.value = true;
    }
    try {
      final dateFilters = _calculateDateFilter();
      final newItems = await _repository.getLostItems(
        collegeId: _currentUserCollegeId,
        categoryIds: selectedFilterCategoryIds.isEmpty
            ? null
            : selectedFilterCategoryIds.toList(),
        limit: _itemsPerPage,
        offset: _currentLostPage * _itemsPerPage,
        startDate: dateFilters['startDate'],
        endDate: dateFilters['endDate'],
      );
      if (newItems.length < _itemsPerPage) {
        hasMoreLostItems.value = false;
      }
      lostItems.addAll(newItems);
      _currentLostPage++;
    } catch (e, s) {
      LoggerService.logError(_className, 'fetchLostItems', 'Error: $e', s);
    } finally {
      isLoadingLost.value = false;
      isLoadingMoreLost.value = false;
    }
  }

  Future<void> fetchFoundItems({bool isRefresh = false}) async {
    if (!isRefresh &&
        (isLoadingFound.value ||
            isLoadingMoreFound.value ||
            !hasMoreFoundItems.value)) {
      return;
    }
    if (isRefresh) {
      _currentFoundPage = 0;
      hasMoreFoundItems.value = true;
      isLoadingFound.value = true;
      foundItems.clear();
    } else {
      isLoadingMoreFound.value = true;
    }
    try {
      final dateFilters = _calculateDateFilter();
      final newItems = await _repository.getFoundItems(
        collegeId: _currentUserCollegeId,
        categoryIds: selectedFilterCategoryIds.isEmpty
            ? null
            : selectedFilterCategoryIds.toList(),
        limit: _itemsPerPage,
        offset: _currentFoundPage * _itemsPerPage,
        startDate: dateFilters['startDate'],
        endDate: dateFilters['endDate'],
      );
      if (newItems.length < _itemsPerPage) {
        hasMoreFoundItems.value = false;
      }
      foundItems.addAll(newItems);
      _currentFoundPage++;
    } catch (e, s) {
      LoggerService.logError(_className, 'fetchFoundItems', 'Error: $e', s);
    } finally {
      isLoadingFound.value = false;
      isLoadingMoreFound.value = false;
    }
  }

  void applyFiltersFromModal({
    required Set<String> tempSelectedCategoryIds,
    required DateFilterOption tempDateFilter,
    required DateTimeRange? tempCustomDateRange,
  }) {
    selectedFilterCategoryIds.assignAll(tempSelectedCategoryIds);
    selectedDateFilter.value = tempDateFilter;
    customDateRange.value = tempCustomDateRange;
    refreshItems();
  }

  void clearAllFiltersFromModal() {
    selectedFilterCategoryIds.clear();
    selectedDateFilter.value = DateFilterOption.any;
    customDateRange.value = null;
    refreshItems();
  }

  Map<String, DateTime?> _calculateDateFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (selectedDateFilter.value) {
      case DateFilterOption.today:
        return {'startDate': today, 'endDate': endOfToday};
      case DateFilterOption.last7Days:
        return {
          'startDate': today.subtract(const Duration(days: 6)),
          'endDate': endOfToday,
        };
      case DateFilterOption.last30Days:
        return {
          'startDate': today.subtract(const Duration(days: 29)),
          'endDate': endOfToday,
        };
      case DateFilterOption.custom:
        if (customDateRange.value != null) {
          final end = customDateRange.value!.end;
          return {
            'startDate': customDateRange.value!.start,
            'endDate': DateTime(end.year, end.month, end.day, 23, 59, 59),
          };
        }
        return {'startDate': null, 'endDate': null};
      case DateFilterOption.any:
        return {'startDate': null, 'endDate': null};
    }
  }

  void navigateToLostFoundDetailScreen(LostFoundItemModel item) async {
    final listToUpdate = item.type == LostFoundType.lost
        ? lostItems
        : foundItems;

    await Get.toNamed(AppRoutes.LOST_FOUND_ITEM_DETAIL, arguments: item);

    final LostFoundItemModel updatedItem = await _repository
        .getLostFoundItemById(item.id!);

    final index = listToUpdate.indexWhere((i) => i.id == item.id);

    if (index == -1) {
      LoggerService.logInfo(
        _className,
        'navigateToLostFoundDetailScreen',
        'Item ${item.id} no longer in the list.',
      );
      return;
    }

    if (!updatedItem.isActive) {
      LoggerService.logInfo(
        _className,
        'navigateToLostFoundDetailScreen',
        'Item ${item.id} is no longer active. Removing from list.',
      );
      listToUpdate.removeAt(index);
      return;
    }

    LoggerService.logInfo(
      _className,
      'navigateToLostFoundDetailScreen',
      'Updating item ${item.id} in place.',
    );

    listToUpdate[index] = updatedItem;
  }

  void navigateToReportLostItem() async {
    final result = await Get.toNamed(
      AppRoutes.REPORT_LOST_ITEM,
      arguments: {'categories': fetchedLfCategories.toList()},
    );
    if (result == true) await refreshItems();
  }

  void navigateToReportFoundItem() async {
    final result = await Get.toNamed(
      AppRoutes.REPORT_FOUND_ITEM,
      arguments: {'categories': fetchedLfCategories.toList()},
    );
    if (result == true) await refreshItems();
  }
}
