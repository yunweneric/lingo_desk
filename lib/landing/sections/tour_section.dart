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
import '../../core/localization/export.dart';

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

  /// Translation keys, resolved against the active locale where the
  /// caption under the preview is drawn.
  static const Map<PreviewScreen, String> _captions = {
    PreviewScreen.dashboard: LocaleKeys.landingTourDashboard,
    PreviewScreen.editor: LocaleKeys.landingTourEditor,
    PreviewScreen.projects: LocaleKeys.landingTourProjects,
    PreviewScreen.aiProviders: LocaleKeys.landingTourAiProviders,
    PreviewScreen.appearance: LocaleKeys.landingTourAppearance,
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
          SectionHeading(
            eyebrow: LocaleKeys.landingTourEyebrow.tr(),
            title: LocaleKeys.landingTourTitle.tr(),
            body: LocaleKeys.landingTourBody.tr(),
          ),
          const SizedBox(height: 20),
          Reveal(
            child: LandingPill(
              label: LocaleKeys.landingTourPill.tr(),
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
                    label: screen.label.tr(),
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
                _captions[_screen]!.tr(),
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
