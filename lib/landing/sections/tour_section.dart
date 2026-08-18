import 'package:flutter/material.dart';

import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../widgets/landing_layout.dart';
import '../widgets/landing_shot.dart';
import '../widgets/reveal.dart';

/// A tabbed walk through the real screens.
///
/// The captures are of the app running in its Indigo Slate theme, which
/// is why the tour says so rather than pretending the product only comes
/// in one colour.
class TourSection extends StatefulWidget {
  const TourSection({super.key, this.anchor});

  final GlobalKey? anchor;

  @override
  State<TourSection> createState() => _TourSectionState();
}

class _TourSectionState extends State<TourSection> {
  static const _screens = <_Screen>[
    _Screen(
      label: 'Dashboard',
      file: 'dashboard.png',
      caption:
          'Coverage, key counts and language health for every project, the '
          'moment you open the app.',
    ),
    _Screen(
      label: 'Editor',
      file: 'editor.png',
      caption:
          'The workspace: keys down the side, locales across the top, '
          'progress per language, and a filter for what is still missing.',
    ),
    _Screen(
      label: 'Projects',
      file: 'apps.png',
      caption:
          'One workspace per app, each with its own source language and '
          'target locales.',
    ),
    _Screen(
      label: 'AI providers',
      file: 'ai-providers.png',
      caption:
          'Bring your own key for Anthropic, OpenAI or Gemini. Keys are '
          'verified on save and kept in the OS secure store.',
    ),
    _Screen(
      label: 'Appearance',
      file: 'appearance.png',
      caption:
          'Six full palettes and a light/dark switch, applied instantly '
          'across every screen.',
    ),
  ];

  int _active = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final screen = _screens[_active];

    return LandingSection(
      anchor: widget.anchor,
      child: Column(
        children: [
          const SectionHeading(
            eyebrow: 'A look inside',
            title: 'Built like a desktop app, because it is one.',
            body:
                'Shown in Indigo Slate — one of the six themes that ship '
                'with it.',
          ),
          const SizedBox(height: 36),
          Reveal(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < _screens.length; i++)
                  _TourTab(
                    label: _screens[i].label,
                    selected: i == _active,
                    onTap: () => setState(() => _active = i),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Reveal(
            child: AnimatedSwitcher(
              duration: LingoDeskMotion.standard,
              switchInCurve: LingoDeskMotion.entrance,
              child: LandingShot(
                key: ValueKey(screen.file),
                name: screen.file,
                semanticLabel: '${screen.label} — ${screen.caption}',
              ),
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              screen.caption,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.6, color: tokens.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Screen {
  const _Screen({
    required this.label,
    required this.file,
    required this.caption,
  });

  final String label;
  final String file;
  final String caption;
}

class _TourTab extends StatelessWidget {
  const _TourTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? tokens.brandFill : tokens.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? tokens.brandFillBorder : tokens.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected ? tokens.onBrandFill : tokens.muted,
            ),
          ),
        ),
      ),
    );
  }
}
