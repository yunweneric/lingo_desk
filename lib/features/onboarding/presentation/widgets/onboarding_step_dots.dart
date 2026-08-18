import 'package:flutter/material.dart';

import '../../../../core/theme/lingo_desk_tokens.dart';

/// Progress dots that also work as a control — tapping one jumps
/// straight to that step.
class OnboardingStepDots extends StatelessWidget {
  const OnboardingStepDots({
    super.key,
    required this.length,
    required this.currentIndex,
    required this.onSelect,
  });

  final int length;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(length, (index) {
        final isActive = index == currentIndex;

        return Semantics(
          selected: isActive,
          button: true,
          label: 'Step ${index + 1} of $length',
          child: InkWell(
            onTap: isActive ? null : () => onSelect(index),
            borderRadius: BorderRadius.circular(999),
            // Keep the tap target usable without inflating the visual dot.
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: isActive ? 26 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? tokens.accent
                      : (tokens.isDark ? Colors.white24 : tokens.border),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
