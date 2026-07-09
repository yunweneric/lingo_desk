import 'package:flutter/material.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/widgets/lingo_desk_mark.dart';
import 'onboarding_preview.dart';
import 'onboarding_step.dart';

class OnboardingVisualPane extends StatelessWidget {
  const OnboardingVisualPane({super.key, required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: LingoDeskColors.darkInk,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(56, 44, 56, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LingoDeskMark(size: 42, reversed: true, showWordmark: true),
              const Spacer(),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: OnboardingPreview(
                    key: ValueKey(step.illustrationAsset),
                    step: step,
                  ),
                ),
              ),
              const Spacer(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  'One translation desk for every locale file.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'A focused workspace for product teams that need clean JSON exports without spreadsheet sprawl.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
