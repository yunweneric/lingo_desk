import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_mark.dart';
import 'onboarding_step.dart';

/// The deep-ink stage that carries the brand lockup, the step's
/// photograph, and a quiet proof strip.
///
/// The photo is *framed* rather than full-bleed: all three assets are 3:2
/// and the frame keeps that ratio at every window size, so a tall pane
/// never crops a photograph into an unreadable zoom.
class OnboardingStage extends StatelessWidget {
  const OnboardingStage({super.key, required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: LingoDeskTokens.of(context).darkStage.background,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(48, 40, 48, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LingoDeskMark(size: 30, reversed: true, showWordmark: true),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    child: OnboardingPhoto(
                      key: ValueKey(step.photoAsset),
                      step: step,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Text(
                  'One desk for every locale file.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Text(
                  'No accounts, no sync, no spreadsheet sprawl - just your '
                  'JSON, on your machine.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),
              const _ProofStrip(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 3:2 photograph in a hairline frame, with its caption and credit set
/// underneath. Sizes itself to whichever of width/height binds first.
class OnboardingPhoto extends StatelessWidget {
  const OnboardingPhoto({super.key, required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Reserve room for the caption block before solving for the frame.
        const captionBlock = 44.0;
        final availableHeight = math.max(
          0.0,
          constraints.maxHeight - captionBlock,
        );
        final width = math.min(constraints.maxWidth, availableHeight * 3 / 2);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: width,
              height: width * 2 / 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
                  border: Border.all(color: Colors.white24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    LingoDeskTheme.radius - 1,
                  ),
                  child: Image.asset(
                    step.photoAsset,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: width,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      step.photoCaption,
                      overflow: TextOverflow.ellipsis,
                      style: LingoDeskTheme.codeStyle.copyWith(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    step.photoCredit,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white38,
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Three standing facts about the product — they do not change with the
/// step, so the stage always says what LingoDesk is.
class _ProofStrip extends StatelessWidget {
  const _ProofStrip();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        _ProofItem('Local-first'),
        _ProofItem('Nested JSON'),
        _ProofItem('20 locales'),
      ],
    );
  }
}

class _ProofItem extends StatelessWidget {
  const _ProofItem(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _AccentDot(),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LingoDeskTokens.of(context).accent,
        shape: BoxShape.circle,
      ),
      child: const SizedBox.square(dimension: 6),
    );
  }
}

/// The compact-layout counterpart to [OnboardingStage]: the same
/// photograph as a banner above the copy, framed and captioned the same
/// way so the two layouts read as one design.
class OnboardingBanner extends StatelessWidget {
  const OnboardingBanner({super.key, required this.step, required this.height});

  final OnboardingStep step;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              // darkInk only shows while the asset decodes.
              color: tokens.darkStage.background,
              borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
              border: Border.all(color: tokens.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(LingoDeskTheme.radius - 1),
              child: Image.asset(
                step.photoAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Below this width the credit crowds the caption into an ellipsis;
        // attribution is not required by the Unsplash licence, so drop it.
        LayoutBuilder(
          builder: (context, constraints) {
            final showCredit = constraints.maxWidth >= 420;

            return Row(
              children: [
                Flexible(
                  child: Text(
                    step.photoCaption,
                    overflow: TextOverflow.ellipsis,
                    style: LingoDeskTheme.codeStyle.copyWith(
                      color: tokens.isDark ? Colors.white54 : tokens.muted,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (showCredit) ...[
                  const SizedBox(width: 12),
                  Text(
                    step.photoCredit,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.isDark ? Colors.white38 : tokens.muted,
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
