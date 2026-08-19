import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import '../widgets/code_panel.dart';
import '../widgets/landing_layout.dart';
import '../widgets/reveal.dart';

/// The before/after beat: the same strings as scattered files, then as
/// one grid. Both sides are drawn live rather than screenshot, so they
/// re-theme with the page and stay sharp at any zoom.
class ProblemSection extends StatelessWidget {
  const ProblemSection({super.key, this.anchor});

  final GlobalKey? anchor;

  // Deliberately short: the point is that the same two keys live in
  // three places, not what a full locale file looks like. Inlining the
  // nested object keeps the shape visible in four lines instead of
  // seven, so the "before" column stays the height of the grid it is
  // being compared against.
  static const _en = [
    JsonLine('{'),
    JsonLine('"nav": { "home": "Home" },', indent: 1),
    JsonLine('"cta": "Get started"', indent: 1),
    JsonLine('}'),
  ];

  static const _fr = [
    JsonLine('{'),
    JsonLine('"nav": { "home": "Accueil" },', indent: 1),
    JsonLine('"cta": ""', indent: 1, missing: true),
    JsonLine('}'),
  ];

  static const _es = [
    JsonLine('{'),
    JsonLine('"nav": { "home": "" },', indent: 1, missing: true),
    JsonLine('"cta": "Empezar"', indent: 1),
    JsonLine('}'),
  ];

  static const _rows = [
    GridRow('nav.home', ['Accueil', null]),
    GridRow('cta', [null, 'Empezar']),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final stacked = context.windowSize.isBelow(WindowSizeClass.expanded);

    const before = _Side(
      eyebrow: 'Without LingoDesk',
      title: 'Three files, three tabs, one missing string you find in review.',
      child: Column(
        children: [
          JsonPanel(filename: 'en.json', lines: _en),
          SizedBox(height: 10),
          JsonPanel(filename: 'fr.json', lines: _fr, flagged: true),
          SizedBox(height: 10),
          JsonPanel(filename: 'es.json', lines: _es, flagged: true),
        ],
      ),
    );

    final after = _Side(
      eyebrow: 'With LingoDesk',
      title: 'One grid. The holes announce themselves.',
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GridPanel(rows: _rows, locales: ['FR', 'ES']),
          const SizedBox(height: 18),
          Row(
            children: [
              LingoDeskIcon(
                HugeIcons.strokeRoundedDatabaseExport,
                size: 16,
                color: tokens.accent,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Export rebuilds the nested shape, file by file, exactly '
                  'as your app expects it.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: tokens.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return LandingSection(
      anchor: anchor,
      child: Column(
        children: [
          const SectionHeading(
            eyebrow: 'The problem',
            title: 'Localization files drift the moment you add a key.',
            body:
                'Adding one string means opening every locale file and '
                'remembering every one of them. LingoDesk makes that a '
                'single row instead.',
          ),
          const SizedBox(height: 56),
          Reveal(
            child: stacked
                ? Column(children: [before, const SizedBox(height: 40), after])
                // The two sides are unequal by construction — three files
                // against one grid is the whole argument — so the short side
                // is centred against the tall one. Aligned to the top it
                // read as a layout fault, with the height difference dumped
                // as dead space under the grid.
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(child: before),
                      const SizedBox(width: 32),
                      Expanded(child: after),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.eyebrow,
    required this.title,
    required this.child,
    this.highlight = false,
  });

  final String eyebrow;
  final String title;
  final Widget child;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
            color: highlight ? tokens.accent : tokens.muted,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            height: 1.35,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: tokens.foreground,
          ),
        ),
        const SizedBox(height: 22),
        child,
      ],
    );
  }
}
