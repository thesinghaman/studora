import 'package:flutter/material.dart';

class CustomSegmentedControl extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final Function(int) onSegmentTapped;
  final double height;
  final double horizontalPadding;
  final double segmentSpacing;
  const CustomSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onSegmentTapped,
    this.height = 42,
    this.horizontalPadding = 16.0,
    this.segmentSpacing = 3.0,
  });
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color controlBackgroundColor = Theme.of(
      context,
    ).colorScheme.surfaceContainer;
    final Color selectedTextColor = isDarkMode ? Colors.black : Colors.white;
    final Color unselectedTextColor = Theme.of(
      context,
    ).textTheme.bodyLarge!.color!.withValues(alpha: 0.8);
    return Container(
      height: height,
      margin: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: controlBackgroundColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double segmentWidth =
              (constraints.maxWidth - (segmentSpacing * 2)) / segments.length;
          double indicatorLeft = selectedIndex * segmentWidth + segmentSpacing;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: indicatorLeft,
                top: segmentSpacing,
                bottom: segmentSpacing,
                width:
                    segmentWidth -
                    (segmentSpacing *
                        (segments.length > 1
                            ? ((segments.length - 1) / segments.length)
                            : 0)),
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                children: List.generate(segments.length, (index) {
                  bool isSelected = selectedIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onSegmentTapped(index),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isSelected
                                ? selectedTextColor
                                : unselectedTextColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                          child: Text(segments[index]),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
