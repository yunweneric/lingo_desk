import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/widgets/lingo_desk_icon.dart';
import 'onboarding_step_dots.dart';

class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({
    super.key,
    required this.currentIndex,
    required this.length,
    required this.onBack,
    required this.onNext,
    required this.onSelect,
    this.compact = false,
  });

  final int currentIndex;
  final int length;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final ValueChanged<int> onSelect;

  /// Narrow windows stack the dots above the buttons rather than letting
  /// the row squeeze the labels.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isLast = currentIndex == length - 1;

    final dots = OnboardingStepDots(
      length: length,
      currentIndex: currentIndex,
      onSelect: onSelect,
    );

    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: currentIndex == 0 ? null : onBack,
          child: const Text('Back'),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: onNext,
          icon: LingoDeskIcon(
            isLast
                ? HugeIcons.strokeRoundedCheckmarkCircle02
                : HugeIcons.strokeRoundedArrowRight02,
            color: Colors.white,
            size: 18,
          ),
          label: Text(isLast ? 'Start setup' : 'Next'),
        ),
      ],
    );

    if (compact) {
      // Full-width buttons rather than a squeezed row: at this width the
      // labels are what stops "Next" being a mystery arrow.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerLeft, child: dots),
          const SizedBox(height: 8),
          Row(
            children: [
              if (currentIndex > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBack,
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: onNext,
                  icon: LingoDeskIcon(
                    isLast
                        ? HugeIcons.strokeRoundedCheckmarkCircle02
                        : HugeIcons.strokeRoundedArrowRight02,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(isLast ? 'Start setup' : 'Next'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(children: [dots, const Spacer(), buttons]);
  }
}
