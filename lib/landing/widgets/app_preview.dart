import 'package:flutter/material.dart';

import '../../core/theme/lingo_desk_tokens.dart';
import '../preview/pane_ai_providers.dart';
import '../preview/pane_appearance.dart';
import '../preview/pane_dashboard.dart';
import '../preview/pane_editor.dart';
import '../preview/pane_projects.dart';
import '../preview/preview_chrome.dart';
import '../preview/preview_workspace.dart';
import '../state/landing_controller.dart';
import '../../core/localization/export.dart';

export '../preview/preview_workspace.dart' show PreviewScreen, PreviewWorkspace;

/// The size the preview is composed at, then scaled to whatever the page
/// gives it.
///
/// Composing at a fixed desktop size and scaling is what keeps this
/// reading as a desktop app: laying it out at the container's real width
/// would trip the app's own responsive breakpoints and collapse the
/// screens into their phone arrangement inside a wide frame.
const double kPreviewWidth = 1240;
const double kPreviewHeight = 830;

/// A live, usable LingoDesk window, built from the same tokens, cards,
/// tables and progress bars as the real app.
///
/// This replaces what used to be a set of PNG captures. A capture is
/// frozen in whatever palette it was taken in and cannot be poked at;
/// this repaints with the page and answers the pointer. Depending on the
/// screen, a visitor can type translations, filter to what is missing,
/// expand an app, switch the active AI key, or change the site's theme
/// from inside the product's own settings screen.
///
/// Pass [interactive] false where the window is decoration rather than a
/// demo — the hero tilts it in 3D, and a skewed hit area that swallows
/// clicks is worse than no interaction at all.
class LandingAppPreview extends StatefulWidget {
  const LandingAppPreview({
    super.key,
    required this.controller,
    this.screen = PreviewScreen.dashboard,
    this.workspace,
    this.onNavigate,
    this.interactive = true,
    this.glow = true,
  });

  final LandingController controller;
  final PreviewScreen screen;

  /// Supply one to share edits across several previews, or leave null and
  /// this widget owns its own.
  final PreviewWorkspace? workspace;

  /// Called when something inside the window navigates — the sidebar, or a
  /// metric card. Null leaves the window on [screen].
  final ValueChanged<PreviewScreen>? onNavigate;

  final bool interactive;
  final bool glow;

  @override
  State<LandingAppPreview> createState() => _LandingAppPreviewState();
}

class _LandingAppPreviewState extends State<LandingAppPreview> {
  PreviewWorkspace? _owned;

  PreviewWorkspace get _workspace =>
      widget.workspace ?? (_owned ??= PreviewWorkspace());

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    Widget window = AnimatedBuilder(
      animation: _workspace,
      builder: (context, _) => _PreviewWindow(
        controller: widget.controller,
        workspace: _workspace,
        screen: widget.screen,
        onNavigate: widget.interactive ? widget.onNavigate : null,
      ),
    );

    if (!widget.interactive) {
      // One label for the whole thing, and no way for a pointer or a
      // screen reader to wander into a dashboard that does not work.
      window = Semantics(
        label: LocaleKeys.landingPreviewSemantics.tr(),
        image: true,
        excludeSemantics: true,
        child: IgnorePointer(child: window),
      );
    }

    return AspectRatio(
      aspectRatio: kPreviewWidth / kPreviewHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: widget.glow
              ? [
                  BoxShadow(
                    color: tokens.brand.withValues(alpha: 0.28),
                    blurRadius: 90,
                    spreadRadius: -20,
                    offset: const Offset(0, 30),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: tokens.isDark ? 0.55 : 0.14,
                    ),
                    blurRadius: 40,
                    spreadRadius: -12,
                    offset: const Offset(0, 18),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: kPreviewWidth,
            height: kPreviewHeight,
            child: window,
          ),
        ),
      ),
    );
  }
}

class _PreviewWindow extends StatelessWidget {
  const _PreviewWindow({
    required this.controller,
    required this.workspace,
    required this.screen,
    required this.onNavigate,
  });

  final LandingController controller;
  final PreviewWorkspace workspace;
  final PreviewScreen screen;
  final ValueChanged<PreviewScreen>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ColoredBox(
          color: tokens.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PreviewTitleBar(title: screen.windowTitle.tr()),
              Expanded(
                child: Row(
                  children: [
                    PreviewSidebar(screen: screen, onNavigate: onNavigate),
                    Expanded(child: _pane()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pane() => switch (screen) {
    PreviewScreen.dashboard => PreviewDashboardPane(
      workspace: workspace,
      onNavigate: onNavigate,
    ),
    PreviewScreen.editor => PreviewEditorPane(workspace: workspace),
    PreviewScreen.projects => PreviewProjectsPane(
      workspace: workspace,
      onNavigate: onNavigate,
    ),
    PreviewScreen.aiProviders => PreviewAiProvidersPane(workspace: workspace),
    PreviewScreen.appearance => PreviewAppearancePane(controller: controller),
  };
}
