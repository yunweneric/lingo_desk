import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import '../state/landing_controller.dart';
import '../widgets/app_preview.dart';
import '../widgets/landing_layout.dart';
import '../widgets/landing_pill.dart';
import '../widgets/reveal.dart';

/// A walk through the real screens — running, not photographed.
///
/// The tabs pick a screen; the window below is the app itself, built from
/// the product's own widgets against an invented workspace. Visitors can
/// type into the translation table, filter to what is missing, expand an
/// app, change the active AI key, and — on the Appearance tab — restyle
/// this entire website from the product's own settings screen.
///
/// The window's sidebar navigates too, so the tabs and the rail stay in
/// sync whichever one you use.
class TourSection extends StatefulWidget {
  const TourSection({super.key, required this.controller, this.anchor});

  final LandingController controller;
  final GlobalKey? anchor;

  @override
  State<TourSection> createState() => _TourSectionState();
}

class _TourSectionState extends State<TourSection> {
  /// Owned here rather than by the window, so an edit made on the Editor
  /// tab is still there when you come back from the Dashboard — and shows
  /// up in the dashboard's numbers on the way past.
  final PreviewWorkspace _workspace = PreviewWorkspace();

  PreviewScreen _screen = PreviewScreen.dashboard;

  static const Map<PreviewScreen, String> _captions = {
    PreviewScreen.dashboard:
        'Coverage, key counts and language health for every project, the '
        'moment you open the app. The numbers come from the same cells the '
        'editor writes to — fill one in and watch them move.',
    PreviewScreen.editor:
        'Keys down the side, locales across the top. Every cell here is a '
        'real field: type a translation, search, or filter to only what is '
        'still missing.',
    PreviewScreen.projects:
        'One workspace per app, each with its own source language and '
        'target locales. Click a row to open it up.',
    PreviewScreen.aiProviders:
        'Bring your own key for Anthropic, OpenAI or Gemini. Pick one and '
        'it becomes the key every AI action in the editor uses.',
    PreviewScreen.appearance:
        'Six full palettes and a light/dark switch. This is the live '
        'setting, not a picture of one — choose a theme and the whole site '
        'repaints with it.',
  };

  @override
  void dispose() {
    _workspace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return LandingSection(
      anchor: widget.anchor,
      child: Column(
        children: [
          const SectionHeading(
            eyebrow: 'A look inside',
            title: 'Built like a desktop app, because it is one.',
            body:
                'This is not a screenshot. It is the app, compiled to this '
                'page — click around it.',
          ),
          const SizedBox(height: 20),
          const Reveal(
            child: LandingPill(
              label: 'Live · nothing you do here is saved',
              icon: HugeIcons.strokeRoundedCursor01,
              emphasis: true,
            ),
          ),
          const SizedBox(height: 28),
          Reveal(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final screen in PreviewScreen.values)
                  _TourTab(
                    label: screen.label,
                    selected: screen == _screen,
                    onTap: () => setState(() => _screen = screen),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Reveal(
            child: LandingAppPreview(
              controller: widget.controller,
              screen: _screen,
              workspace: _workspace,
              onNavigate: (screen) => setState(() => _screen = screen),
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: AnimatedSwitcher(
              duration: LingoDeskMotion.standard,
              switchInCurve: LingoDeskMotion.entrance,
              child: Text(
                _captions[_screen]!,
                key: ValueKey(_screen),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: tokens.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourTab extends StatefulWidget {
  const _TourTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_TourTab> createState() => _TourTabState();
}

class _TourTabState extends State<_TourTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final selected = widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? tokens.brandFill : tokens.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? tokens.brandFillBorder
                  : (_hovered ? tokens.accent : tokens.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                LingoDeskIcon(
                  HugeIcons.strokeRoundedTick02,
                  size: 15,
                  color: tokens.onBrandFill,
                ),
                const SizedBox(width: 7),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? tokens.onBrandFill
                      : (_hovered ? tokens.foreground : tokens.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
