import 'package:flutter/material.dart';

import 'package:shimmer/shimmer.dart';

class CategoryCardShimmerWidget extends StatelessWidget {
  const CategoryCardShimmerWidget({super.key});
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color highlightColor = isDarkMode
        ? Colors.grey[700]!
        : Colors.grey[100]!;
    final Color placeholderColor = Colors.white;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: placeholderColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 10),
            Container(height: 12, width: 60, color: placeholderColor),
          ],
        ),
      ),
    );
  }
}
