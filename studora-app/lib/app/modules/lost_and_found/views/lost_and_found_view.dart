import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:studora/app/modules/lost_and_found/controllers/lost_and_found_controller.dart';
import 'package:studora/app/data/models/lost_found_item_model.dart';
import 'package:studora/app/data/models/category_model.dart'
    as app_category_model;
import 'package:studora/app/shared_components/widgets/custom_segmented_control.dart';
import 'package:studora/app/shared_components/widgets/animated_fade_slide.dart';
import 'package:studora/app/shared_components/widgets/shimmer_widgets/minimal_lost_found_item_card_shimmer.dart';
import 'package:studora/app/shared_components/widgets/minimal_lost_found_item_card.dart';

enum _FilterModalSectionInternal { category, date }

class LostAndFoundView extends StatefulWidget {
  const LostAndFoundView({super.key});
  @override
  State<LostAndFoundView> createState() => _LostAndFoundViewState();
}

class _LostAndFoundViewState extends State<LostAndFoundView> {
  final LostAndFoundController controller = Get.find<LostAndFoundController>();
  final ScrollController _lostScrollController = ScrollController();
  final ScrollController _foundScrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _lostScrollController.addListener(() {
      if (_lostScrollController.position.pixels >=
          _lostScrollController.position.maxScrollExtent - 200) {
        controller.fetchLostItems();
      }
    });
    _foundScrollController.addListener(() {
      if (_foundScrollController.position.pixels >=
          _foundScrollController.position.maxScrollExtent - 200) {
        controller.fetchFoundItems();
      }
    });
  }

  @override
  void dispose() {
    _lostScrollController.dispose();
    _foundScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lost & Found"),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.add_circled,
              color: theme.colorScheme.primary,
              size: 26,
            ),
            tooltip: "Report an Item",
            onPressed: () => _showReportOptions(context, theme),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshItems,
        color: theme.colorScheme.primary,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => CustomSegmentedControl(
                        segments: const ["Lost Items", "Found Items"],
                        selectedIndex: controller.selectedTabIndex.value,
                        onSegmentTapped: (index) =>
                            controller.tabController.animateTo(index),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() {
                    int activeFilterCount =
                        controller.selectedFilterCategoryIds.length +
                        (controller.selectedDateFilter.value !=
                                DateFilterOption.any
                            ? 1
                            : 0);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.all(8.0),
                          onPressed: () =>
                              _showFilterOptionsSheet(context, theme),
                          minimumSize: Size(0, 0),
                          child: Icon(
                            CupertinoIcons.slider_horizontal_3,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                        if (activeFilterCount > 0)
                          Positioned(
                            top: 6,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 17,
                                minHeight: 17,
                              ),
                              child: Center(
                                child: Text(
                                  activeFilterCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: controller.tabController,
                children: [
                  _buildItemsList(isLostTab: true),
                  _buildItemsList(isLostTab: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList({required bool isLostTab}) {
    final theme = Theme.of(context);
    return Obx(() {
      final items = isLostTab ? controller.lostItems : controller.foundItems;
      final isLoading = isLostTab
          ? controller.isLoadingLost.value
          : controller.isLoadingFound.value;
      final isLoadingMore = isLostTab
          ? controller.isLoadingMoreLost.value
          : controller.isLoadingMoreFound.value;
      final scrollController = isLostTab
          ? _lostScrollController
          : _foundScrollController;
      if (isLoading && items.isEmpty) {
        return _buildLoadingShimmer();
      }
      if (items.isEmpty) {
        String emptyMessageTitle = isLostTab
            ? "No Lost Items Match Filters"
            : "No Found Items Match Filters";
        String emptyMessageSubtitle =
            "Try adjusting your filters or report an item using the '+' button.";
        return _buildInfoState(
          theme,
          isLostTab
              ? CupertinoIcons.search_circle_fill
              : CupertinoIcons.flag_circle_fill,
          emptyMessageTitle,
          emptyMessageSubtitle,
        );
      }
      return ListView.builder(
        controller: scrollController,
        key: PageStorageKey<String>(isLostTab ? "lost_list" : "found_list"),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16.0),
        itemCount: items.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (ctx, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(child: CupertinoActivityIndicator()),
            );
          }
          final item = items[index];
          bool showDateSeparator = _shouldInsertLFDateSeparator(items, index);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDateSeparator)
                _buildMinimalLFDateSeparator(item.dateReported, theme),
              AnimatedFadeSlide(
                delay: Duration(milliseconds: 60 * (index % 12)),
                offset: const Offset(0, 0.025),
                duration: const Duration(milliseconds: 350),
                child: MinimalLostFoundItemCard(
                  item: item,
                  onTapItem: () =>
                      controller.navigateToLostFoundDetailScreen(item),
                  getCategoryIconById: (categoryId) {
                    final category = controller.fetchedLfCategories
                        .firstWhereOrNull((c) => c.id == categoryId);
                    return _getIconDataFromString(category?.iconId);
                  },
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 8,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16.0),
      itemBuilder: (context, index) => const MinimalLostFoundItemCardShimmer(),
    );
  }

  Widget _buildInfoState(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 60,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalLFDateSeparator(DateTime date, ThemeData theme) {
    String formattedDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDateComparable = DateTime(date.year, date.month, date.day);
    if (itemDateComparable == today) {
      formattedDate = "Reported Today";
    } else if (itemDateComparable == yesterday) {
      formattedDate = "Reported Yesterday";
    } else if (now.year == date.year) {
      formattedDate = DateFormat('MMMM d').format(date);
    } else {
      formattedDate = DateFormat('MMMM d, yyyy').format(date);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Text(
        formattedDate,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  bool _shouldInsertLFDateSeparator(
    List<LostFoundItemModel> items,
    int currentIndex,
  ) {
    if (currentIndex == 0) return true;
    if (items.isEmpty || currentIndex >= items.length || currentIndex < 1) {
      return false;
    }
    final currentItemDate = items[currentIndex].dateReported;
    final previousItemDate = items[currentIndex - 1].dateReported;
    return !(currentItemDate.year == previousItemDate.year &&
        currentItemDate.month == previousItemDate.month &&
        currentItemDate.day == previousItemDate.day);
  }

  IconData? _getIconDataFromString(String? iconString) {
    if (iconString == null || iconString.isEmpty) {
      return CupertinoIcons.question_circle;
    }
    final Map<String, IconData> iconMap = {
      'cupertinosquare_grid_2x2_fill': CupertinoIcons.square_grid_2x2_fill,
      'cupertinodevice_phone_portrait': CupertinoIcons.device_phone_portrait,
      'cupertinolock_fill': CupertinoIcons.lock_fill,
      'cupertinocreditcard_fill': CupertinoIcons.creditcard_fill,
      'cupertinobook_fill': CupertinoIcons.book_fill,
      'cupertinobag_fill': CupertinoIcons.bag_fill,
      'cupertinotag_fill': CupertinoIcons.tag_fill,
      'cupertinopencil_outline': CupertinoIcons.pencil_outline,
      'cupertinosmiley_fill': CupertinoIcons.smiley_fill,
      'cupertinoellipsis_circle_fill': CupertinoIcons.ellipsis_circle_fill,
      'cupertinosearch': CupertinoIcons.search,
      'cupertinoflag': CupertinoIcons.flag,
    };
    return iconMap[iconString.toLowerCase()] ?? CupertinoIcons.tag_solid;
  }

  void _showReportOptions(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext modalCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Report an Item",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Please choose an option below to proceed with your report.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Icon(
                    CupertinoIcons.search_circle_fill,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  title: Text(
                    'I Lost Something',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(modalCtx);
                    controller.navigateToReportLostItem();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  tileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: Icon(
                    CupertinoIcons.flag_circle_fill,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  title: Text(
                    'I Found Something',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(modalCtx);
                    controller.navigateToReportFoundItem();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  tileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: Icon(
                    Icons.cancel_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  title: Text(
                    'Cancel',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => Navigator.pop(modalCtx),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  tileColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterOptionsSheet(BuildContext context, ThemeData theme) {
    Set<String> tempSelectedCategoryIds = Set.from(
      controller.selectedFilterCategoryIds,
    );
    DateFilterOption tempDateFilter = controller.selectedDateFilter.value;
    DateTimeRange? tempCustomDateRange = controller.customDateRange.value;
    ValueNotifier<_FilterModalSectionInternal?> expandedFilterType =
        ValueNotifier(null);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext _, StateSetter setModalState) {
            Widget buildCategoryOptions() {
              return Obx(() {
                if (controller.fetchedLfCategories.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "No L&F categories found.",
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  child: Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: controller.fetchedLfCategories.map((
                      app_category_model.CategoryModel category,
                    ) {
                      final bool isSelected = tempSelectedCategoryIds.contains(
                        category.id,
                      );
                      IconData? categoryIcon = _getIconDataFromString(
                        category.iconId,
                      );
                      return FilterChip(
                        label: Text(
                          category.name,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                        avatar: categoryIcon != null
                            ? Icon(
                                categoryIcon,
                                size: 18,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary,
                              )
                            : null,
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (bool selected) {
                          setModalState(() {
                            if (selected) {
                              tempSelectedCategoryIds.add(category.id);
                            } else {
                              tempSelectedCategoryIds.remove(category.id);
                            }
                          });
                        },
                        backgroundColor:
                            theme.colorScheme.surfaceContainerLowest,
                        selectedColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.dividerColor.withValues(alpha: 0.4),
                            width: 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 10.0,
                        ),
                      );
                    }).toList(),
                  ),
                );
              });
            }

            Widget buildDateOptions() {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: DateFilterOption.values.map((option) {
                  String title = option
                      .toString()
                      .split('.')
                      .last
                      .replaceAllMapped(
                        RegExp(r'[A-Z]'),
                        (match) => ' ${match.group(0)}',
                      )
                      .trim();
                  if (option == DateFilterOption.custom &&
                      tempCustomDateRange != null) {
                    title =
                        "Custom: ${DateFormat.yMd().format(tempCustomDateRange!.start)} - ${DateFormat.yMd().format(tempCustomDateRange!.end)}";
                  } else if (option == DateFilterOption.custom) {
                    title = "Custom Range";
                  }
                  return RadioListTile<DateFilterOption>(
                    title: Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                    ),
                    value: option,
                    groupValue: tempDateFilter,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (DateFilterOption? value) async {
                      if (value == DateFilterOption.custom) {
                        final DateTimeRange? pickedRange =
                            await showDateRangePicker(
                              context: modalContext,
                              firstDate: DateTime(DateTime.now().year - 2),
                              lastDate: DateTime.now(),
                              initialDateRange:
                                  tempCustomDateRange ??
                                  DateTimeRange(
                                    start: DateTime.now().subtract(
                                      const Duration(days: 7),
                                    ),
                                    end: DateTime.now(),
                                  ),
                              builder: (pickerContext, child) => Theme(
                                data: Theme.of(pickerContext).copyWith(
                                  colorScheme: Theme.of(pickerContext)
                                      .colorScheme
                                      .copyWith(
                                        primary: theme.colorScheme.primary,
                                        onPrimary: theme.colorScheme.onPrimary,
                                      ),
                                ),
                                child: child!,
                              ),
                            );
                        if (pickedRange != null) {
                          setModalState(() {
                            tempDateFilter = value!;
                            tempCustomDateRange = pickedRange;
                          });
                        } else if (tempCustomDateRange == null) {
                          setModalState(() {
                            tempDateFilter = DateFilterOption.any;
                          });
                        }
                      } else {
                        setModalState(() {
                          tempDateFilter = value!;
                          tempCustomDateRange = null;
                        });
                      }
                    },
                    controlAffinity: ListTileControlAffinity.trailing,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 0,
                    ),
                  );
                }).toList(),
              );
            }

            Widget buildFilterSectionToggle(
              String title,
              IconData icon,
              _FilterModalSectionInternal type,
            ) {
              bool isCurrentlyExpanded = expandedFilterType.value == type;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setModalState(() {
                      expandedFilterType.value = isCurrentlyExpanded
                          ? null
                          : type;
                    });
                  },
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: isCurrentlyExpanded
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.surfaceContainer,
                      border: Border.all(
                        color: isCurrentlyExpanded
                            ? theme.colorScheme.primary.withValues(alpha: 0.3)
                            : theme.dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              icon,
                              color: isCurrentlyExpanded
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isCurrentlyExpanded
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          isCurrentlyExpanded
                              ? CupertinoIcons.chevron_up
                              : CupertinoIcons.chevron_down,
                          size: 18,
                          color: isCurrentlyExpanded
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(modalContext).padding.bottom +
                    MediaQuery.of(modalContext).viewInsets.bottom +
                    16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filter Options",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          controller.clearAllFiltersFromModal();
                          Navigator.pop(modalContext);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        ),
                        child: Text(
                          "Clear All & Close",
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  buildFilterSectionToggle(
                    "Category",
                    CupertinoIcons.tag_fill,
                    _FilterModalSectionInternal.category,
                  ),
                  ValueListenableBuilder<_FilterModalSectionInternal?>(
                    valueListenable: expandedFilterType,
                    builder: (context, value, child) {
                      return AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Visibility(
                          visible:
                              value == _FilterModalSectionInternal.category,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: buildCategoryOptions(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12.0),
                  buildFilterSectionToggle(
                    "Date Posted",
                    CupertinoIcons.calendar,
                    _FilterModalSectionInternal.date,
                  ),
                  ValueListenableBuilder<_FilterModalSectionInternal?>(
                    valueListenable: expandedFilterType,
                    builder: (context, value, child) {
                      return AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Visibility(
                          visible: value == _FilterModalSectionInternal.date,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: buildDateOptions(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        CupertinoIcons.checkmark_alt_circle_fill,
                        size: 20,
                      ),
                      label: const Text("Apply Filters"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        controller.applyFiltersFromModal(
                          tempSelectedCategoryIds: tempSelectedCategoryIds,
                          tempDateFilter: tempDateFilter,
                          tempCustomDateRange: tempCustomDateRange,
                        );
                        Navigator.pop(modalContext);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
