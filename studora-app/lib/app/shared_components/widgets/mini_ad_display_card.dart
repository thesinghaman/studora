import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';

class MiniAdDisplayCard extends StatelessWidget {
  final ItemModel adItem;
  final VoidCallback? onTapOverride;
  const MiniAdDisplayCard({
    super.key,
    required this.adItem,
    this.onTapOverride,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AuthRepository authRepository = Get.find();
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: authRepository.currencySymbol,
      decimalDigits: (adItem.price.truncateToDouble() == adItem.price) ? 0 : 2,
    );
    final String? displayImageUrl =
        (adItem.imageUrls != null && adItem.imageUrls!.isNotEmpty)
        ? adItem.imageUrls!.first
        : null;
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap:
            onTapOverride ??
            () {
              Get.toNamed(AppRoutes.ITEM_DETAIL, arguments: {'ad': adItem});
            },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: theme.colorScheme.surfaceContainer,
                  image:
                      displayImageUrl != null &&
                          displayImageUrl.startsWith('http')
                      ? DecorationImage(
                          image: NetworkImage(displayImageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child:
                    (displayImageUrl == null ||
                        !displayImageUrl.startsWith('http'))
                    ? Icon(
                        CupertinoIcons.photo_fill,
                        color: theme.hintColor.withValues(alpha: 0.5),
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      adItem.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      currencyFormatter.format(adItem.price) +
                          (adItem.isRental
                              ? " ${adItem.rentalTerm ?? '/mo'}"
                              : ""),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
