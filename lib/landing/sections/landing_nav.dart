import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import '../../core/widgets/lingo_desk_mark.dart';
import '../data/github_release.dart';
import '../state/landing_controller.dart';
import '../widgets/landing_button.dart';
import '../widgets/landing_layout.dart';

/// One entry in the navigation.
class NavTarget {
  const NavTarget(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;
}

/// The sticky bar across the top of the page.
///
/// Transparent over the hero and opaque once the page has moved, so the
/// hero reads full-bleed without the bar ever sitting on top of copy it
/// cannot be read against.
class LandingNav extends StatelessWidget {
  const LandingNav({
    super.key,
    required this.controller,
    required this.targets,
    required this.scrolled,
    required this.onDownload,
  });

  final LandingController controller;
  final List<NavTarget> targets;
  final bool scrolled;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final compact = context.windowSize.isBelow(WindowSizeClass.expanded);

    return AnimatedContainer(
      duration: LingoDeskMotion.standard,
      curve: LingoDeskMotion.curve,
      height: kLandingNavHeight,
      decoration: BoxDecoration(
        color: scrolled
            ? tokens.background.withValues(alpha: 0.92)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: scrolled ? tokens.border : Colors.transparent,
          ),
        ),
      ),
      child: LandingContainer(
        child: Row(
          children: [
            const LingoDeskMark(size: 30, showWordmark: true),
            const Spacer(),
            if (!compact) ...[
              for (final target in targets) ...[
                _NavLink(target: target),
                const SizedBox(width: 26),
              ],
              _BrightnessToggle(controller: controller),
              const SizedBox(width: 10),
              _StarChip(stars: controller.stars),
              const SizedBox(width: 12),
              LandingButton(
                label: 'Download',
                icon: HugeIcons.strokeRoundedDownload04,
                onPressed: onDownload,
              ),
            ] else ...[
              _BrightnessToggle(controller: controller),
              const SizedBox(width: 6),
              _IconAction(
                icon: HugeIcons.strokeRoundedMenu01,
                tooltip: 'Menu',
                onTap: () => _openMenu(context),
              ),
            ],
          ],
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
                      color: tokens.foreground,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    target.onTap();
                  },
                ),
              const SizedBox(height: 12),
              LandingButton(
                label: 'Download',
                icon: HugeIcons.strokeRoundedDownload04,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onDownload();
                },
              ),
              const SizedBox(height: 10),
              const LandingButton(
                label: 'View on GitHub',
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

class _NavLink extends StatefulWidget {
  const _NavLink({required this.target});

  final NavTarget target;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.target.onTap,
        child: AnimatedDefaultTextStyle(
          duration: LingoDeskMotion.fast,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: _hovered ? tokens.foreground : tokens.muted,
          ),
          child: Text(widget.target.label),
        ),
      ),
    );
  }
}

class _BrightnessToggle extends StatelessWidget {
  const _BrightnessToggle({required this.controller});

  final LandingController controller;

  @override
  Widget build(BuildContext context) {
    return _IconAction(
      icon: controller.isDark
          ? HugeIcons.strokeRoundedSun03
          : HugeIcons.strokeRoundedMoon02,
      tooltip: controller.isDark ? 'Switch to light' : 'Switch to dark',
      onTap: controller.toggleBrightness,
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _hovered ? tokens.active : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: LingoDeskIcon(
              widget.icon,
              size: 19,
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
class _StarChip extends StatelessWidget {
  const _StarChip({required this.stars});

  final int? stars;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final count = stars;
    if (count == null) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => openLink(GithubRepo.url),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: tokens.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tokens.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LingoDeskIcon(
                HugeIcons.strokeRoundedGithub,
                size: 15,
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
    );
  }
}
