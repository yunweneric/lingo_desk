import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import 'onboarding_step.dart';

class OnboardingPreview extends StatelessWidget {
  const OnboardingPreview({
    super.key,
    required this.step,
    this.compact = false,
  });

  final OnboardingStep step;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 10.0 : 14.0;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 560 : 650),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33030712),
              blurRadius: 34,
              offset: Offset(0, 22),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PreviewToolbar(step: step),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  step.illustrationAsset,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPreviewStage extends StatelessWidget {
  const OnboardingPreviewStage({
    super.key,
    required this.step,
    this.isTablet = false,
  });

  final OnboardingStep step;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 580 : 420),
        child: AspectRatio(
          aspectRatio: isTablet ? 1.24 : 1.05,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: LingoDeskColors.darkInk,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 14),
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: isTablet ? 540 : 390,
                  child: OnboardingPreview(step: step, compact: true),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewToolbar extends StatelessWidget {
  const _PreviewToolbar({required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _WindowDots(),
        const SizedBox(width: 12),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: LingoDeskColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LingoDeskColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  const LingoDeskIcon(
                    HugeIcons.strokeRoundedFolderLibrary,
                    size: 15,
                    color: LingoDeskColors.slate,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.code,
                      overflow: TextOverflow.ellipsis,
                      style: LingoDeskTheme.codeStyle.copyWith(
                        color: LingoDeskColors.slate,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _MetricBadge(label: step.metricLabel, value: step.metricValue),
      ],
    );
  }
}

class _WindowDots extends StatelessWidget {
  const _WindowDots();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _Dot(color: Color(0xFFEF4444)),
        SizedBox(width: 6),
        _Dot(color: Color(0xFFF59E0B)),
        SizedBox(width: 6),
        _Dot(color: Color(0xFF22C55E)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const SizedBox.square(dimension: 9),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LingoDeskColors.brandBlueSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD5E9FF)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: LingoDeskColors.brandBlue,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: LingoDeskColors.brandBlue,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
