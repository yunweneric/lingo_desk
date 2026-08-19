import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import '../../features/ai_translation/domain/entities/ai_provider.dart';
import '../../features/ai_translation/presentation/widgets/ai_provider_logo.dart';
import '../widgets/landing_layout.dart';
import '../widgets/reveal.dart';
import '../../core/localization/export.dart';

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
        title: LocaleKeys.landingFeature1Title,
        body: LocaleKeys.landingFeature1Body,
      ),
      _Feature(
        icon: HugeIcons.strokeRoundedFilter,
        title: LocaleKeys.landingFeature2Title,
        body: LocaleKeys.landingFeature2Body,
      ),
      _Feature(
        icon: HugeIcons.strokeRoundedSparkles,
        title: LocaleKeys.landingFeature3Title,
        body: LocaleKeys.landingFeature3Body,
        providers: true,
      ),
      _Feature(
        icon: HugeIcons.strokeRoundedShield01,
        title: LocaleKeys.landingFeature4Title,
        body: LocaleKeys.landingFeature4Body,
      ),
      _Feature(
        icon: HugeIcons.strokeRoundedFolderSync,
        title: LocaleKeys.landingFeature5Title,
        body: LocaleKeys.landingFeature5Body,
      ),
      _Feature(
        icon: HugeIcons.strokeRoundedPaintBoard,
        title: LocaleKeys.landingFeature6Title,
        body: LocaleKeys.landingFeature6Body,
      ),
    ];

    return LandingSection(
      anchor: anchor,
      tinted: true,
      child: Column(
        children: [
          SectionHeading(
            eyebrow: LocaleKeys.landingFeaturesEyebrow.tr(),
            title: LocaleKeys.landingFeaturesTitle.tr(),
            body: LocaleKeys.landingFeaturesBody.tr(),
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

  final List<List<dynamic>> icon;
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
              // Without an alignment the tile hands the icon its own tight
              // 42x42, which overrides `size` and scales the glyph to the
              // full tile. Centring loosens the constraints so the icon is
              // drawn at 20 with even padding around it.
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tokens.brandFill,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: tokens.brandFillBorder),
              ),
              child: LingoDeskIcon(
                feature.icon,
                size: 20,
                color: tokens.onBrandFill,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              feature.title.tr(),
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
              feature.body.tr(),
              style: TextStyle(
                fontSize: 14.5,
                height: 1.6,
                color: tokens.muted,
              ),
            ),
            if (feature.providers) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  for (final provider in AiProvider.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: AiProviderLogo(provider: provider, size: 20),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
