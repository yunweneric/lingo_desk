import 'package:flutter/material.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import 'onboarding_step.dart';

/// The proof list under a step's body: three claims, each with the
/// machine string that backs it. This replaces the old decorative code
/// pill — same machine-string voice, but it now says something.
class OnboardingHighlights extends StatelessWidget {
  const OnboardingHighlights({super.key, required this.highlights});

  final List<OnboardingHighlight> highlights;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < highlights.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _HighlightRow(highlight: highlights[i]),
        ],
      ],
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.highlight});

  final OnboardingHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = LingoDeskTokens.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color:
                tokens.isDark
                    ? LingoDeskColors.activeDeep
                    : LingoDeskColors.brandTealSoft,
            borderRadius: BorderRadius.circular(LingoDeskTheme.radiusSm),
            border: Border.all(
              color:
                  tokens.isDark
                      ? Colors.white12
                      : LingoDeskColors.brandTealSoftBorder,
            ),
          ),
          child: SizedBox.square(
            dimension: 34,
            child: Center(
              child: LingoDeskIcon(
                highlight.icon,
                size: 17,
                color: tokens.isDark ? Colors.white : LingoDeskColors.brandTeal,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                highlight.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                highlight.detail,
                style: LingoDeskTheme.codeStyle.copyWith(
                  color: tokens.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
