import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_palette.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_mark.dart';
import '../state/landing_controller.dart';
import '../widgets/landing_layout.dart';
import '../widgets/landing_pill.dart';
import '../widgets/reveal.dart';

/// The showcase beat: the same Dart that builds the desktop app builds
/// this page, and the visitor can prove it by repainting the site.
class FlutterSection extends StatelessWidget {
  const FlutterSection({
    super.key,
    required this.controller,
    required this.onSeeDownloads,
    this.anchor,
  });

  final LandingController controller;
  final VoidCallback onSeeDownloads;
  final GlobalKey? anchor;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final size = context.windowSize;
    final narrow = size.isBelow(WindowSizeClass.expanded);

    return LandingSection(
      anchor: anchor,
      child: Column(
        children: [
          const SectionHeading(
            eyebrow: 'Built with Flutter & Dart',
            title: 'One codebase. Six platforms.\nIncluding this page.',
            body:
                'LingoDesk is written once in Dart and compiled to macOS, '
                'Windows, Linux, Android, iOS and the web. This landing page '
                'is not HTML with a Flutter demo bolted on — it is the same '
                'project, the same design tokens and the same widgets, '
                'compiled for the browser you are reading it in.',
          ),
          const SizedBox(height: 48),
          Reveal(
            child: LandingCard(
              padding: EdgeInsets.all(narrow ? 24 : 36),
              child: _ProofLayout(
                narrow: narrow,
                copy: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LandingPill(
                      label: 'Live, right now',
                      icon: HugeIcons.strokeRoundedZap,
                      emphasis: true,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Every colour on this page comes from the app.',
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: tokens.foreground,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'These are the six palettes shipped in LingoDesk, '
                      'read from the same theme extension the desktop '
                      'build reads. Pick one and the whole site repaints '
                      '— no reload, no stylesheet swap.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.62,
                        color: tokens.muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PaletteRow(controller: controller),
                  ],
                ),
                proof: const _MarkProof(),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Reveal(child: _PlatformGrid(onSeeDownloads: onSeeDownloads)),
          const SizedBox(height: 28),
          const Reveal(child: _StatRow()),
        ],
      ),
    );
  }
}

/// Two panes side by side on desktop, stacked on narrow windows.
///
/// Written as a branch rather than a [Flex] with a swapped direction
/// because [Expanded] is only legal inside the horizontal arm: in a
/// [Column] of unbounded height it has no space to expand into and
/// throws.
class _ProofLayout extends StatelessWidget {
  const _ProofLayout({
    required this.narrow,
    required this.copy,
    required this.proof,
  });

  final bool narrow;
  final Widget copy;
  final Widget proof;

  @override
  Widget build(BuildContext context) {
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [copy, const SizedBox(height: 32), proof],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: copy),
        const SizedBox(width: 40),
        Expanded(flex: 2, child: proof),
      ],
    );
  }
}

/// The six theme variants as tappable swatches.
class _PaletteRow extends StatelessWidget {
  const _PaletteRow({required this.controller});

  final LandingController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final variant in LingoDeskThemeVariant.values)
          _Swatch(
            variant: variant,
            selected: controller.variant == variant,
            isDark: tokens.isDark,
            onTap: () => controller.setVariant(variant),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.variant,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final LingoDeskThemeVariant variant;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final scheme = LingoDeskPalettes.of(variant).scheme(isDark);

    return Tooltip(
      message: variant.description,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: LingoDeskMotion.fast,
            curve: LingoDeskMotion.curve,
            padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
            decoration: BoxDecoration(
              color: selected ? tokens.brandFill : tokens.background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? tokens.brandFillBorder : tokens.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: scheme.brand,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.accent, width: 1.5),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  variant.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? tokens.onBrandFill : tokens.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The brandmark, plus the fact that it is geometry rather than an image.
class _MarkProof extends StatelessWidget {
  const _MarkProof();

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(
            child: AnimatedSize(
              duration: LingoDeskMotion.standard,
              child: LingoDeskMark(size: 88),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Not an image file',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: tokens.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The logo above is a CustomPainter drawing rounded rectangles '
            'and two circles onto a canvas — so it is crisp at any size and '
            'takes the accent of whichever theme is selected.',
            style: TextStyle(fontSize: 13.5, height: 1.6, color: tokens.muted),
          ),
        ],
      ),
    );
  }
}

class _PlatformGrid extends StatelessWidget {
  const _PlatformGrid({required this.onSeeDownloads});

  final VoidCallback onSeeDownloads;

  @override
  Widget build(BuildContext context) {
    final columns = context.windowSize.resolve<int>(
      compact: 2,
      medium: 3,
      large: 6,
    );

    final platforms = <PlatformTile>[
      PlatformTile(
        label: 'macOS',
        icon: HugeIcons.strokeRoundedApple,
        available: true,
        onTap: onSeeDownloads,
      ),
      PlatformTile(
        label: 'Windows',
        icon: HugeIcons.strokeRoundedComputer,
        available: true,
        onTap: onSeeDownloads,
      ),
      PlatformTile(
        label: 'Linux',
        icon: HugeIcons.strokeRoundedTerminal,
        available: false,
        onTap: onSeeDownloads,
      ),
      PlatformTile(
        label: 'Android',
        icon: HugeIcons.strokeRoundedAndroid,
        available: true,
        onTap: onSeeDownloads,
      ),
      PlatformTile(
        label: 'iOS',
        icon: HugeIcons.strokeRoundedSmartPhone01,
        available: false,
        onTap: onSeeDownloads,
      ),
      const PlatformTile(
        label: 'Web',
        icon: HugeIcons.strokeRoundedBrowser,
        available: true,
        note: 'You are here',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < platforms.length; i++)
              SizedBox(
                width: width,
                child: StaggeredReveal(index: i, child: platforms[i]),
              ),
          ],
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow();

  @override
  Widget build(BuildContext context) {
    final narrow = context.windowSize.isBelow(WindowSizeClass.medium);

    const stats = [
      ('1', 'codebase'),
      ('6', 'compile targets'),
      ('100%', 'Dart'),
      ('0', 'lines of JavaScript written by hand'),
    ];

    return SizedBox(
      width: double.infinity,
      child: LandingCard(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        child: Wrap(
          spacing: 44,
          runSpacing: 24,
          alignment: WrapAlignment.spaceBetween,
          children: [
            for (final (value, label) in stats)
              SizedBox(
                width: narrow ? double.infinity : null,
                child: _Stat(value: value, label: label),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 30,
            height: 1.1,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
            color: tokens.accent,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13.5, color: tokens.muted)),
      ],
    );
  }
}
