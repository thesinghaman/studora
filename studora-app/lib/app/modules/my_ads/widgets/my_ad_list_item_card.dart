import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';

class MyAdListItemCard extends StatelessWidget {
  final ItemModel item;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const MyAdListItemCard({
    super.key,
    required this.item,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
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
        Icon(icon, size: 11, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 5.0),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 11.5,
              height: 1.2,
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
    final AuthRepository authRepository = Get.find();
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color subtleBorderColor = theme.dividerColor.withValues(
      alpha: isDarkMode ? 0.2 : 0.3,
    );
    final Color textColor = theme.colorScheme.onSurface;
    final Color subtleTextColor = theme.colorScheme.onSurfaceVariant;
    final Color primaryColor = theme.colorScheme.primary;
    final Color errorColor = theme.colorScheme.error;
    final Color soldRentedColor = Colors.blueGrey.shade500;
    final Color inactiveColor = Colors.orange.shade700;
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: authRepository.currencySymbol,
      decimalDigits: (item.price == item.price.roundToDouble()) ? 0 : 2,
    );
    final String? displayImageUrl =
        (item.imageUrls != null && item.imageUrls!.isNotEmpty)
        ? item.imageUrls!.first
        : null;
    String statusText;
    Color statusChipColor;
    bool isRealExpired = item.expiryDate.isBefore(DateTime.now());
    if (item.adStatus.toLowerCase() == "sold" ||
        item.adStatus.toLowerCase() == "rented") {
      statusText = item.adStatus;
      statusChipColor = soldRentedColor;
    } else if (item.adStatus.toLowerCase() == "expired" ||
        (item.isActive && isRealExpired)) {
      statusText = "Expired";
      statusChipColor = errorColor;
    } else if (item.adStatus.toLowerCase() == "inactive" || !item.isActive) {
      statusText = "Inactive";
      statusChipColor = inactiveColor;
    } else {
      statusText = "Active";
      statusChipColor = primaryColor;
    }
    double cardOpacity = 1.0;
    if (statusText != "Active") {
      cardOpacity = 0.75;
    }
    Color cardBgColor = isSelected
        ? primaryColor.withValues(alpha: 0.2)
        : theme.cardTheme.color ?? theme.colorScheme.surface;
    Border cardBorder = isSelected
        ? Border.all(color: primaryColor, width: 2.0)
        : Border.all(color: subtleBorderColor, width: 1.0);
    return Opacity(
      opacity: cardOpacity,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(12.0),
            border: cardBorder,
            boxShadow: (statusText == "Active" && !isSelected)
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDarkMode ? 0.05 : 0.03,
                      ),
                      blurRadius: 5.0,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: theme.colorScheme.surfaceContainer,
                    ),
                    child:
                        displayImageUrl != null &&
                            displayImageUrl.startsWith('http')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: Image.network(
                              displayImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, st) => Icon(
                                CupertinoIcons.photo_fill_on_rectangle_fill,
                                color: subtleTextColor.withValues(alpha: 0.5),
                                size: 28,
                              ),
                              loadingBuilder: (ctx, child, progress) =>
                                  progress == null
                                  ? child
                                  : const Center(
                                      child: CupertinoActivityIndicator(
                                        radius: 10,
                                      ),
                                    ),
                            ),
                          )
                        : Icon(
                            item.categoryId == 'electronics'
                                ? CupertinoIcons.device_phone_portrait
                                : item.categoryId == 'books'
                                ? CupertinoIcons.book_fill
                                : item.categoryId == 'furniture'
                                ? CupertinoIcons.house_alt_fill
                                : CupertinoIcons.cube_box_fill,
                            color: primaryColor.withValues(alpha: 0.7),
                            size: 28,
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
                                  color: textColor.withValues(
                                    alpha: cardOpacity,
                                  ),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (!isSelectionMode)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusChipColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text(
                                  statusText.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: statusChipColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          currencyFormatter.format(item.price),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: primaryColor.withValues(alpha: cardOpacity),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (item.adStatus.toLowerCase() != "sold" &&
                            item.adStatus.toLowerCase() != "rented")
                          _buildCardInfoRow(
                            context,
                            CupertinoIcons.time,
                            "Expires: ${DateFormat('d MMM, yy').format(item.expiryDate)}",
                            (statusText == "Expired")
                                ? errorColor.withValues(alpha: 0.9)
                                : subtleTextColor.withValues(
                                    alpha: cardOpacity,
                                  ),
                            isStrong: (statusText == "Expired"),
                          )
                        else if (item.location != null &&
                            item.location!.isNotEmpty)
                          _buildCardInfoRow(
                            context,
                            CupertinoIcons.location_solid,
                            item.location!,
                            subtleTextColor.withValues(alpha: cardOpacity),
                          )
                        else
                          _buildCardInfoRow(
                            context,
                            CupertinoIcons.calendar_today,
                            "Posted: ${DateFormat('d MMM, yy').format(item.datePosted)}",
                            subtleTextColor.withValues(alpha: cardOpacity),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isSelectionMode && isSelected)
                Positioned(
                  top: -4,
                  right: -4,
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
                      color: primaryColor,
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
