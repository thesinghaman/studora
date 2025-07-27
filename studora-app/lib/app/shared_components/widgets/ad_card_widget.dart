import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';

class AdCardWidget extends StatelessWidget {
  final ItemModel item;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;
  final bool isUserAd;
  final String currentLoggedInUserId;
  const AdCardWidget({
    super.key,
    required this.item,
    required this.isFavorite,
    this.onFavoriteTap,
    this.onTap,
    this.isUserAd = false,
    required this.currentLoggedInUserId,
  });
  @override
  Widget build(BuildContext context) {
    final AuthRepository authRepository = Get.find();
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackgroundColor = Theme.of(context).cardColor;
    final Color textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color subtleTextColor = textColor.withValues(alpha: 0.7);
    final Color shimmerBaseColor = isDarkMode
        ? Colors.grey[800]!
        : Colors.grey[300]!;
    final Color shimmerHighlightColor = isDarkMode
        ? Colors.grey[700]!
        : Colors.grey[100]!;
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: authRepository.currencySymbol,
      decimalDigits: (item.price.truncateToDouble() == item.price) ? 0 : 2,
    );
    final String? displayImageUrl =
        (item.imageUrls != null && item.imageUrls!.isNotEmpty)
        ? item.imageUrls!.first
        : null;
    final bool showFavoriteButton = !isUserAd && onFavoriteTap != null;
    final bool itemIsTrulyActive =
        item.isActive && (item.adStatus.toLowerCase()) == "active";
    return GestureDetector(
      onTap:
          onTap ??
          () {
            Get.toNamed(
              AppRoutes.ITEM_DETAIL,
              arguments: {
                'ad': item,
                'openedFromChatFlow': false,
                'originatingConversationId': null,
              },
            );
          },
      child: Container(
        decoration: BoxDecoration(
          color: itemIsTrulyActive
              ? cardBackgroundColor
              : cardBackgroundColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.12 : 0.07),
              blurRadius: 10.0,
              spreadRadius: -1.0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12.0),
                      ),
                      child: Container(
                        color: isDarkMode
                            ? Colors.grey[850]!
                            : Colors.grey[200]!,
                        child:
                            (displayImageUrl != null &&
                                displayImageUrl.startsWith('http'))
                            ? Image.network(
                                displayImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  LoggerService.logError(
                                    "AdCardWidget",
                                    "Image.network error for item ${item.id}",
                                    "URL: $displayImageUrl, Error: $error",
                                    stackTrace,
                                  );
                                  return Center(
                                    child: Icon(
                                      CupertinoIcons.photo_camera,
                                      color: Colors.grey[400],
                                      size: 30,
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Shimmer.fromColors(
                                        baseColor: shimmerBaseColor,
                                        highlightColor: shimmerHighlightColor,
                                        child: Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          color: Colors.white.withValues(
                                            alpha: isDarkMode ? 0.1 : 0.7,
                                          ),
                                        ),
                                      );
                                    },
                              )
                            : Center(
                                child: Icon(
                                  CupertinoIcons.photo_camera_solid,
                                  color: Colors.grey[400],
                                  size: 30,
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (showFavoriteButton)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onFavoriteTap,
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart,
                              color: isFavorite
                                  ? Colors.red.shade400
                                  : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!itemIsTrulyActive)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (item.adStatus).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          height: 1.25,
                          fontSize: 13.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3.0, bottom: 3.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.person_circle_fill,
                                size: 12,
                                color: subtleTextColor.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 5.0),
                              Expanded(
                                child: Text(
                                  item.sellerName,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: subtleTextColor.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormatter.format(item.price) +
                              (item.isRental
                                  ? " ${item.rentalTerm ?? '/mo'}"
                                  : ""),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
}
