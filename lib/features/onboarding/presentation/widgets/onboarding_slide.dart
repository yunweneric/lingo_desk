import 'package:flutter/material.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import 'onboarding_highlights.dart';
import 'onboarding_stage.dart';
import 'onboarding_step.dart';

/// One page of the onboarding narrative: eyebrow, headline, body, proof.
///
/// On compact layouts the step's photograph rides along at the top of the
/// slide so it swipes with the copy; on wide layouts the photo lives in
/// the persistent [OnboardingStage] instead.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
    required this.step,
    required this.isWide,
    required this.isTablet,
  });

  final OnboardingStep step;
  final bool isWide;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = LingoDeskTokens.of(context);

    final titleSize = isWide ? 44.0 : (isTablet ? 36.0 : 28.0);
    final bodySize = isWide || isTablet ? 17.0 : 15.0;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isWide) ...[
          OnboardingBanner(step: step, height: isTablet ? 240 : 168),
          SizedBox(height: isTablet ? 32 : 26),
        ],
        _EyebrowChip(label: step.eyebrow),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            step.title,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: titleSize,
              height: 1.06,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            step.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: tokens.muted,
              fontSize: bodySize,
            ),
          ),
        ),
        SizedBox(height: isWide ? 36 : 30),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: OnboardingHighlights(highlights: step.highlights),
        ),
      ],
    );

    final scroller = SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(top: isWide ? 0 : 4, bottom: 8),
      child: content,
    );

    // Wide panes centre the copy against the stage; compact layouts start
    // at the top so the photo sits directly under the header.
    return isWide ? Center(child: scroller) : scroller;
  }
}

class _EyebrowChip extends StatelessWidget {
  const _EyebrowChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return DecoratedBox(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: tokens.isDark ? Colors.white : LingoDeskColors.brandTeal,
            fontSize: 11,
            height: 1,
          ),
        ),
      ),
    );
  }
}
