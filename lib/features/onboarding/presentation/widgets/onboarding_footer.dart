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
  });

  final int currentIndex;
  final int length;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = currentIndex == length - 1;

    return Row(
      children: [
        OnboardingStepDots(length: length, currentIndex: currentIndex),
        const Spacer(),
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
          ),
          label: Text(isLast ? 'Start setup' : 'Next'),
        ),
      ],
    );
  }
}
