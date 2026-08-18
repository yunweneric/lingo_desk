import 'package:flutter/material.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_mark.dart';

/// Top rail of the content pane: where you are, and the way out.
///
/// Wide layouts leave the brand to the stage and lead with the step
/// counter; compact layouts carry the lockup here instead.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    super.key,
    required this.currentIndex,
    required this.length,
    required this.onSkip,
    required this.showMark,
  });

  final int currentIndex;
  final int length;
  final VoidCallback onSkip;
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    final counter = _StepCounter(currentIndex: currentIndex, length: length);

    return Row(
      children: [
        if (showMark)
          const LingoDeskMark(size: 28, showWordmark: true)
        else
          counter,
        const Spacer(),
        if (showMark) ...[counter, const SizedBox(width: 16)],
        TextButton(onPressed: onSkip, child: const Text('Skip')),
      ],
    );
  }
}

class _StepCounter extends StatelessWidget {
  const _StepCounter({required this.currentIndex, required this.length});

  final int currentIndex;
  final int length;

  String _pad(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return RichText(
      text: TextSpan(
        style: LingoDeskTheme.codeStyle.copyWith(
          color: tokens.foreground,
          fontSize: 12,
        ),
        children: [
          TextSpan(text: _pad(currentIndex + 1)),
          TextSpan(
            text: ' / ${_pad(length)}',
            style: TextStyle(color: tokens.muted),
          ),
        ],
      ),
    );
  }
}
