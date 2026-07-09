import 'package:flutter/material.dart';

import '../../../../core/widgets/lingo_desk_mark.dart';

class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key, required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const LingoDeskMark(size: 32, showWordmark: true),
        const Spacer(),
        TextButton(onPressed: onSkip, child: const Text('Skip')),
      ],
    );
  }
}
