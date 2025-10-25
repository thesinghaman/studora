import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import 'package:studora/app/data/models/lost_found_item_model.dart';
import 'package:studora/app/shared_components/utils/enums.dart';

class MinimalLostFoundItemCard extends StatelessWidget {
  final LostFoundItemModel item;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTapItem;
  final VoidCallback? onLongPressItem;
  final IconData? Function(String categoryId) getCategoryIconById;
  const MinimalLostFoundItemCard({
    super.key,
    required this.item,
    this.onTapItem,
    this.onLongPressItem,
    required this.getCategoryIconById,
    this.isSelectionMode = false,
    this.isSelected = false,
  });
  Widget _buildCardInfoRow(
    BuildContext context,
    IconData icon,
    String text,
    Color color, {
    bool isStrong = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 12, color: color.withValues(alpha: 0.9)),
        const SizedBox(width: 6.0),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 12,
              height: 1.3,
              fontWeight: isStrong ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color textColor = theme.colorScheme.onSurface;
    final Color subtleTextColor = theme.colorScheme.onSurfaceVariant;

    final Color itemTypeSpecificColor = item.type == LostFoundType.lost
        ? (isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700)
        : (isDarkMode ? Colors.green.shade300 : Colors.green.shade600);
    final String? displayImageUrl =
        (item.imageUrls != null && item.imageUrls!.isNotEmpty)
        ? item.imageUrls!.first
        : null;
    final bool isActive = item.postStatus.toLowerCase() == 'active';
    final bool isResolved = item.postStatus.toLowerCase() == "resolved";
    final Color cardBgColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.2)
        : theme.colorScheme.surfaceContainerLowest;
    final BorderSide cardBorderSide = isSelected
        ? BorderSide(color: theme.colorScheme.primary, width: 2.0)
        : BorderSide(
            color: theme.dividerColor.withValues(alpha: isDarkMode ? 0.2 : 0.3),
            width: 1.0,
          );
    IconData categoryDisplayIcon =
        getCategoryIconById(item.categoryId) ??
        (item.type == LostFoundType.lost
            ? CupertinoIcons.search
            : CupertinoIcons.flag);
    final Color shimmerBaseColor = isDarkMode
        ? Colors.grey[700]!
        : Colors.grey[300]!;
    final Color shimmerHighlightColor = isDarkMode
        ? Colors.grey[600]!
        : Colors.grey[100]!;
    double cardOpacity = (isResolved || !isActive) ? 0.75 : 1.0;
    return Opacity(
      opacity: cardOpacity,
      child: Card(
        elevation: isSelected ? 2.0 : 1.0,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: cardBorderSide,
        ),
        color: cardBgColor,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTapItem,
          onLongPress: onLongPressItem,
          borderRadius: BorderRadius.circular(12.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: theme.colorScheme.surfaceContainer,
                      ),
                      child:
                          (displayImageUrl != null &&
                              displayImageUrl.startsWith('http'))
                          ? Image.network(
                              displayImageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              loadingBuilder: (ctx, child, progress) =>
                                  progress == null
                                  ? child
                                  : Shimmer.fromColors(
                                      baseColor: shimmerBaseColor,
                                      highlightColor: shimmerHighlightColor,
                                      child: Container(
                                        width: 70,
                                        height: 70,
                                        color: shimmerBaseColor,
                                      ),
                                    ),
                              errorBuilder: (ctx, ex, st) => Center(
                                child: Icon(
                                  categoryDisplayIcon,
                                  color: itemTypeSpecificColor.withValues(
                                    alpha: 0.7,
                                  ),
                                  size: 30,
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                categoryDisplayIcon,
                                color: itemTypeSpecificColor.withValues(
                                  alpha: 0.7,
                                ),
                                size: 30,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    height: 1.3,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (!isSelectionMode)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7.0,
                                    vertical: 3.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: itemTypeSpecificColor.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Text(
                                    item.type
                                        .toString()
                                        .split('.')
                                        .last
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.bold,
                                      color: itemTypeSpecificColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildCardInfoRow(
                            context,
                            CupertinoIcons.location_solid,
                            item.location.isNotEmpty
                                ? item.location
                                : "Location not specified",
                            subtleTextColor,
                          ),
                          const SizedBox(height: 4),
                          _buildCardInfoRow(
                            context,
                            CupertinoIcons.calendar_today,
                            "Reported: ${DateFormat('d MMM, yy').format(item.dateReported)}",
                            subtleTextColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelectionMode && isSelected)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
