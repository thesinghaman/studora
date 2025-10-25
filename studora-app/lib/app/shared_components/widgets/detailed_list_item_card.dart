import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';

class DetailedListItemCard extends StatelessWidget {
  final ItemModel item;
  final String currentLoggedInUserId;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;
  final bool isUserAd;
  final bool isFavorite;
  const DetailedListItemCard({
    super.key,
    required this.item,
    required this.currentLoggedInUserId,
    this.onFavoriteTap,
    this.onTap,
    required this.isUserAd,
    required this.isFavorite,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AuthRepository authRepository = Get.find();
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
    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: itemIsTrulyActive
          ? theme.colorScheme.surfaceContainerLowest
          : theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.6),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: theme.colorScheme.surfaceContainer,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child:
                      displayImageUrl != null &&
                          displayImageUrl.startsWith('http')
                      ? Image.network(
                          displayImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              CupertinoIcons.photo_camera,
                              color: theme.hintColor.withValues(alpha: 0.5),
                              size: 36,
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CupertinoActivityIndicator(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            );
                          },
                        )
                      : Icon(
                          item.isRental
                              ? CupertinoIcons.house_fill
                              : CupertinoIcons.tag_fill,
                          color: theme.hintColor.withValues(alpha: 0.5),
                          size: 36,
                        ),
                ),
              ),
              const SizedBox(width: 12.0),

              Expanded(
                child: SizedBox(
                  height: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          fontSize: 14.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Posted by: ${item.sellerName}",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            currencyFormatter.format(item.price) +
                                (item.isRental
                                    ? " ${item.rentalTerm ?? '/mo'}"
                                    : ""),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (showFavoriteButton)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 0),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isFavorite
                          ? CupertinoIcons.heart_fill
                          : CupertinoIcons.heart,
                      color: isFavorite
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    onPressed: onFavoriteTap,
                  ),
                )
              else if (isUserAd)
                const SizedBox(width: 40)
              else
                const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }
}
