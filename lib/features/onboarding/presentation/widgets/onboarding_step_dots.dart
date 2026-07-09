import 'package:flutter/material.dart';

import '../../../../core/theme/lingo_desk_theme.dart';

class OnboardingStepDots extends StatelessWidget {
  const OnboardingStepDots({
    super.key,
    required this.length,
    required this.currentIndex,
  });

  final int length;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(length, (index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(right: 8),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                isActive
                    ? LingoDeskColors.brandBlue
                    : (isDark ? Colors.white24 : LingoDeskColors.border),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
