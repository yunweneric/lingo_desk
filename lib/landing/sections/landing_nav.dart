import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_theme.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import '../../core/widgets/lingo_desk_mark.dart';
import '../data/github_release.dart';
import '../state/landing_controller.dart';
import '../widgets/glass_panel.dart';
import '../widgets/landing_button.dart';
import '../widgets/language_menu.dart';
import '../widgets/theme_menu.dart';
import '../../core/localization/export.dart';

/// Every control in the bar is this tall, so the right-hand cluster reads
/// as one row of objects rather than three sizes stacked side by side.
const double kNavControlHeight = 40.0;

/// The floating bar's own metrics. It rides above the page rather than
/// spanning it, and draws in as the page scrolls so it takes less room
/// the further down you are.
const double kNavRestWidth = 1180.0;
const double kNavShrunkWidth = 940.0;
const double kNavRestHeight = 68.0;
const double kNavShrunkHeight = 58.0;
const double kNavRestTop = 18.0;
const double kNavShrunkTop = 10.0;

/// One entry in the navigation.
class NavTarget {
  const NavTarget(this.id, this.label, this.onTap);

  /// Matches the anchor name the page reports as active.
  final String id;

  final String label;
  final VoidCallback onTap;
}

/// A floating glass bar: wordmark on the left, destinations centred,
/// actions on the right.
///
/// The centre stays optically centred against the window rather than
/// against whatever is left over, because both flanks are [Expanded] —
/// the links do not drift when the star count arrives and widens the
/// right-hand side.
class LandingNav extends StatelessWidget {
  const LandingNav({
    super.key,
    required this.controller,
    required this.targets,
    required this.scrolled,
    required this.activeId,
    required this.onDownload,
  });

  final LandingController controller;
  final List<NavTarget> targets;
  final bool scrolled;

  /// The section currently under the reading line, or null while the hero
  /// still owns the screen.
  final String? activeId;

  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final size = context.windowSize;

    // Below `large` the five destinations plus the full control cluster no
    // longer fit, so the bar collapses to a menu.
    final collapsed = size.isBelow(WindowSizeClass.large);
    final gutter = size.resolve<double>(compact: 12, medium: 20, expanded: 28);

    final height = scrolled ? kNavShrunkHeight : kNavRestHeight;
    final radius = BorderRadius.circular(height / 2);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedContainer(
          duration: LingoDeskMotion.standard,
          curve: LingoDeskMotion.curve,
          margin: EdgeInsets.only(top: scrolled ? kNavShrunkTop : kNavRestTop),
          width: scrolled ? kNavShrunkWidth : kNavRestWidth,
          height: height,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: (tokens.isDark ? 0.44 : 0.12) * (scrolled ? 1 : 0.5),
                ),
                blurRadius: scrolled ? 30 : 18,
                offset: Offset(0, scrolled ? 10 : 6),
              ),
            ],
          ),
          child: GlassPanel(
            borderRadius: radius,
            blur: scrolled ? 26 : 16,
            // Nearly clear over the hero, solid once there is content
            // moving underneath that the labels have to stay legible on.
            opacity: scrolled ? 1 : 0.72,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: scrolled ? 14 : 18),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: LingoDeskMark(
                        size: scrolled ? 26 : 29,
                        showWordmark: true,
                      ),
                    ),
                  ),
                  if (!collapsed)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final target in targets)
                          _NavLink(
                            target: target,
                            active: target.id == activeId,
                            compact: scrolled,
                          ),
                      ],
                    ),
                  // Both flanks are equal shares of whatever the centred
                  // links leave behind, so this cluster cannot borrow width
                  // from the roomier left-hand side: everything in it has
                  // to earn its place. The language trigger is a flag and a
                  // chevron for that reason, and the download button's
                  // label is the one thing here that can give way.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const LanguageMenuButton(
                            height: kNavControlHeight,
                            showLabel: false,
                          ),
                          const SizedBox(width: 8),
                          ThemeMenuButton(
                            controller: controller,
                            height: kNavControlHeight,
                            showLabel: false,
                          ),
                          const SizedBox(width: 8),
                          if (!collapsed) ...[
                            _StarChip(stars: controller.stars),
                            const SizedBox(width: 8),
                            LandingButton(
                              label: LocaleKeys.landingNavDownload.tr(),
                              icon: HugeIcons.strokeRoundedDownload04,
                              height: kNavControlHeight,
                              // Once the bar has drawn in, the label is
                              // the first thing that stops fitting.
                              iconOnly: scrolled,
                              onPressed: onDownload,
                            ),
                          ] else
                            _IconAction(
                              icon: HugeIcons.strokeRoundedMenu01,
                              tooltip: LocaleKeys.landingNavMenu.tr(),
                              onTap: () => _openMenu(context),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openMenu(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final target in targets)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    target.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: target.id == activeId
                          ? tokens.accent
                          : tokens.foreground,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    target.onTap();
                  },
                ),
              const SizedBox(height: 12),
              LandingButton(
                label: LocaleKeys.landingNavDownload.tr(),
                icon: HugeIcons.strokeRoundedDownload04,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onDownload();
                },
              ),
              const SizedBox(height: 10),
              LandingButton(
                label: LocaleKeys.landingViewOnGithub.tr(),
                icon: HugeIcons.strokeRoundedGithub,
                kind: LandingButtonKind.secondary,
                url: GithubRepo.url,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A destination. The section you are reading wears a filled pill, so the
/// bar answers "where am I" without being asked.
class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.target,
    required this.active,
    required this.compact,
  });

  final NavTarget target;
  final bool active;
  final bool compact;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final active = widget.active;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.target.onTap,
        child: AnimatedContainer(
          duration: LingoDeskMotion.standard,
          curve: LingoDeskMotion.curve,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 12 : 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: active
                ? tokens.brandFill
                : (_hovered
                      ? tokens.foreground.withValues(alpha: 0.07)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? tokens.brandFillBorder : Colors.transparent,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: LingoDeskMotion.fast,
            style: TextStyle(
              fontSize: widget.compact ? 13.5 : 14,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active
                  ? tokens.onBrandFill
                  : (_hovered ? tokens.foreground : tokens.muted),
            ),
            child: Text(widget.target.label),
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatefulWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: LingoDeskMotion.fast,
            width: kNavControlHeight,
            height: kNavControlHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered
                  ? tokens.foreground.withValues(alpha: 0.09)
                  : tokens.foreground.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
              border: Border.all(
                color: tokens.foreground.withValues(alpha: 0.10),
              ),
            ),
            child: LingoDeskIcon(
              widget.icon,
              size: 18,
              color: tokens.foreground,
            ),
          ),
        ),
      ),
    );
  }
}

/// Live star count, hidden until GitHub answers so the bar never shows a
/// zero that is really "unknown".
class _StarChip extends StatefulWidget {
  const _StarChip({required this.stars});

  final int? stars;

  @override
  State<_StarChip> createState() => _StarChipState();
}

class _StarChipState extends State<_StarChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final count = widget.stars;
    if (count == null) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: LocaleKeys.landingStarOnGithubTooltip.tr(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => openLink(GithubRepo.url),
          child: AnimatedContainer(
            duration: LingoDeskMotion.fast,
            height: kNavControlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _hovered
                  ? tokens.foreground.withValues(alpha: 0.09)
                  : tokens.foreground.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
              border: Border.all(
                color: tokens.foreground.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LingoDeskIcon(
                  HugeIcons.strokeRoundedGithub,
                  size: 16,
                  color: tokens.foreground,
                ),
                const SizedBox(width: 7),
                LingoDeskIcon(
                  HugeIcons.strokeRoundedStar,
                  size: 13,
                  color: tokens.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tokens.foreground,
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
