import 'package:flutter/material.dart';

import 'package:shimmer/shimmer.dart';

class MinimalLostFoundItemCardShimmer extends StatelessWidget {
  const MinimalLostFoundItemCardShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color baseColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final Color highlightColor = isDarkMode
        ? Colors.grey[600]!
        : Colors.grey[100]!;
    final Color shimmerCardBgColor = theme.colorScheme.surfaceContainerLowest;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Card(
        elevation: 1.0,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: theme.dividerColor.withValues(alpha: isDarkMode ? 0.2 : 0.3),
            width: 1.0,
          ),
        ),
        color: shimmerCardBgColor,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: baseColor,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16.0,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    const SizedBox(height: 6),

                    Container(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
