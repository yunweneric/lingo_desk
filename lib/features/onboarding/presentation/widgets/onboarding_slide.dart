import 'package:flutter/material.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import 'onboarding_code_pill.dart';
import 'onboarding_preview.dart';
import 'onboarding_step.dart';

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
    final mutedColor =
        theme.brightness == Brightness.dark
            ? LingoDeskColors.slateLight
            : LingoDeskColors.slate;
    final titleStyle = (isWide
            ? theme.textTheme.headlineLarge
            : theme.textTheme.headlineMedium)
        ?.copyWith(
          fontSize: isWide ? 50 : (isTablet ? 42 : 32),
          height: 1.04,
        );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: isWide ? 560 : (isTablet ? 690 : 600),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              isWide ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (!isWide) ...[
              const SizedBox(height: 26),
              OnboardingPreviewStage(step: step, isTablet: isTablet),
              SizedBox(height: isTablet ? 44 : 32),
            ],
            DecoratedBox(
              decoration: BoxDecoration(
                color:
                    theme.brightness == Brightness.dark
                        ? const Color(0xFF111827)
                        : LingoDeskColors.brandBlueSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      theme.brightness == Brightness.dark
                          ? Colors.white12
                          : const Color(0xFFD5E9FF),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Text(
                  step.eyebrow.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: LingoDeskColors.brandBlue,
                    fontSize: 11,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text(step.title, style: titleStyle),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                step.body,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: mutedColor,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
            ),
            const SizedBox(height: 28),
            OnboardingCodePill(text: step.code),
          ],
        ),
      ),
    );
  }
}
