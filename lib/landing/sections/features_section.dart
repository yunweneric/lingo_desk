import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../features/ai_translation/domain/entities/ai_provider.dart';
import '../../features/ai_translation/presentation/widgets/ai_provider_logo.dart';
import '../widgets/landing_layout.dart';
import '../widgets/reveal.dart';

/// What the product actually does, one card per capability.
///
/// Every claim here maps to a feature folder under `lib/features/`; the
/// AI card reuses [AiProviderLogo] so the marks on the site are the same
/// ones the app draws.
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key, this.anchor});

  final GlobalKey? anchor;

  @override
  Widget build(BuildContext context) {
    final size = context.windowSize;
    final columns = size.resolve<int>(compact: 1, medium: 2, large: 3);

    const features = <_Feature>[
      _Feature(
        icon: HugeIcons.strokeRoundedTable01,
        title: 'One grid for every language',
        body:
            'Nested JSON is flattened to dot-notation keys, so a string and '
            'all of its translations sit on a single row you can read across.',
      ),
      _Feature(
        icon: HugeIcons.strokeRoundedFilter,
        title: 'Missing strings, not missing bugs',
        body:
            'Live coverage per locale and a "missing only" filter that '
            'collapses hundreds of keys down to the handful still empty.',
      ),
      _Feature(
        icon: HugeIcons.strokeRoundedSparkles,
        title: 'Translate with your own AI key',
        body:
            'Batch-translate the gaps through Anthropic, OpenAI or Gemini. '
            'Your key, your account, your bill — nothing is proxied.',
        providers: true,
      ),
      _Feature(
        icon: HugeIcons.strokeRoundedShield01,
        title: 'Local-first and private',
        body:
            'No backend, no telemetry, no sign-up. Projects live on your '
            'machine and API keys go into the OS secure store.',
      ),
      _Feature(
        icon: HugeIcons.strokeRoundedFolderSync,
        title: 'Import and export in place',
        body:
            'Scan a project folder, pull in the locale files you already '
            'have, and export the nested shape straight back into the repo.',
      ),
      _Feature(
        icon: HugeIcons.strokeRoundedPaintBoard,
        title: 'Six themes, light and dark',
        body:
            'A workspace you can stand to look at all day — each theme a '
            'full palette, not just a swapped accent colour.',
      ),
    ];

    return LandingSection(
      anchor: anchor,
      tinted: true,
      child: Column(
        children: [
          const SectionHeading(
            eyebrow: 'Features',
            title: 'Everything the job needs. Nothing it does not.',
            body:
                'LingoDesk is a focused desktop tool, not a translation '
                'platform with seats and dashboards.',
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
                  for (var i = 0; i < features.length; i++)
                    SizedBox(
                      width: width,
                      child: StaggeredReveal(
                        index: i,
                        child: _FeatureCard(feature: features[i]),
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

class _Feature {
  const _Feature({
    required this.icon,
    required this.title,
    required this.body,
    this.providers = false,
  });

  final IconData icon;
  final String title;
  final String body;

  /// Shows the three AI provider marks under the copy.
  final bool providers;
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({required this.feature});

  final _Feature feature;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final feature = widget.feature;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: LingoDeskMotion.fast,
        curve: LingoDeskMotion.curve,
        transform: Matrix4.translationValues(
          0,
          _hovered ? -LingoDeskMotion.hoverLift : 0,
          0,
        ),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? tokens.brandFillBorder : tokens.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tokens.brandFill,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: tokens.brandFillBorder),
              ),
              child: Icon(feature.icon, size: 20, color: tokens.onBrandFill),
            ),
            const SizedBox(height: 20),
            Text(
              feature.title,
              style: TextStyle(
                fontSize: 17.5,
                height: 1.3,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: tokens.foreground,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              feature.body,
              style: TextStyle(fontSize: 14.5, height: 1.6,
                  color: tokens.muted),
            ),
            if (feature.providers) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  for (final provider in AiProvider.values) ...[
                    AiProviderLogo(provider: provider, size: 20),
                    const SizedBox(width: 14),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
