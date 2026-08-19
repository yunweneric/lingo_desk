import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import '../widgets/landing_layout.dart';
import '../widgets/reveal.dart';
import '../../core/localization/export.dart';

/// The four-step loop the product is built around, straight from the
/// app's own onboarding: create, import, fill, export.
class StepsSection extends StatelessWidget {
  const StepsSection({super.key, this.anchor});

  final GlobalKey? anchor;

  static const _steps = <_Step>[
    _Step(
      icon: HugeIcons.strokeRoundedFolderAdd,
      title: LocaleKeys.landingStep1Title,
      body: LocaleKeys.landingStep1Body,
    ),
    _Step(
      icon: HugeIcons.strokeRoundedFileUpload,
      title: LocaleKeys.landingStep2Title,
      body: LocaleKeys.landingStep2Body,
    ),
    _Step(
      icon: HugeIcons.strokeRoundedTranslate,
      title: LocaleKeys.landingStep3Title,
      body: LocaleKeys.landingStep3Body,
    ),
    _Step(
      icon: HugeIcons.strokeRoundedDatabaseExport,
      title: LocaleKeys.landingStep4Title,
      body: LocaleKeys.landingStep4Body,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = context.windowSize;
    final columns = size.resolve<int>(compact: 1, medium: 2, large: 4);

    return LandingSection(
      anchor: anchor,
      tinted: true,
      child: Column(
        children: [
          SectionHeading(
            eyebrow: LocaleKeys.landingStepsEyebrow.tr(),
            title: LocaleKeys.landingStepsTitle.tr(),
          ),
          const SizedBox(height: 56),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 20.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    SizedBox(
                      width: width,
                      child: StaggeredReveal(
                        index: i,
                        child: _StepCard(index: i, step: _steps[i]),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Step {
  const _Step({required this.icon, required this.title, required this.body});

  final List<List<dynamic>> icon;
  final String title;
  final String body;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.index, required this.step});

  final int index;
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '0${index + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: tokens.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: tokens.border, height: 1)),
          ],
        ),
        const SizedBox(height: 22),
        LingoDeskIcon(step.icon, size: 24, color: tokens.foreground),
        const SizedBox(height: 16),
        Text(
          step.title.tr(),
          style: TextStyle(
            fontSize: 17,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: tokens.foreground,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          step.body.tr(),
          style: TextStyle(fontSize: 14.5, height: 1.6, color: tokens.muted),
        ),
      ],
    );
  }
}
