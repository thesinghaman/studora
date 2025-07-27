import 'package:flutter/material.dart';

import 'package:shimmer/shimmer.dart';

class AdCardShimmerWidget extends StatelessWidget {
  const AdCardShimmerWidget({super.key});
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
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: placeholderColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12.0),
                  ),
                ),
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
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: placeholderColor,
                      margin: const EdgeInsets.only(bottom: 4),
                    ),
                    Container(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.3,
                      color: placeholderColor,
                    ),
                    const Spacer(),
                    Container(
                      height: 12,
                      width: MediaQuery.of(context).size.width * 0.25,
                      color: placeholderColor,
                      margin: const EdgeInsets.only(bottom: 4),
                    ),
                    Container(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.2,
                      color: placeholderColor,
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
