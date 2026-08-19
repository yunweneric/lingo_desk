import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_theme.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import '../../core/widgets/lingo_desk_mark.dart';
import 'preview_workspace.dart';

/// Desktop window chrome, drawn rather than captured.
class PreviewTitleBar extends StatelessWidget {
  const PreviewTitleBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Container(
      width: double.infinity,
      height: 38,
      decoration: BoxDecoration(
        color: tokens.sidebar,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'LingoDesk — $title',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: tokens.muted,
            ),
          ),
          Positioned(
            left: 14,
            child: Row(
              children: [
                for (final color in const [
                  Color(0xFFFF5F57),
                  Color(0xFFFEBC2E),
                  Color(0xFF28C840),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 11),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The preview's own navigation rail. Its items really do navigate — the
/// destination is the same [PreviewScreen] the tour's tab strip drives,
/// so clicking "Appearance" in here moves the tabs above too.
class PreviewSidebar extends StatelessWidget {
  const PreviewSidebar({
    super.key,
    required this.screen,
    required this.onNavigate,
  });

  final PreviewScreen screen;
  final ValueChanged<PreviewScreen>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Container(
      width: 236,
      decoration: BoxDecoration(
        color: tokens.sidebar,
        border: Border(right: BorderSide(color: tokens.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: LingoDeskMark(size: 30, showWordmark: true),
          ),
          const SizedBox(height: 26),
          const _NavLabel('Workspace'),
          _NavItem(
            label: 'Dashboard',
            icon: HugeIcons.strokeRoundedDashboardSquare01,
            target: PreviewScreen.dashboard,
            screen: screen,
            onNavigate: onNavigate,
          ),
          _NavItem(
            label: 'Apps',
            icon: HugeIcons.strokeRoundedFolder02,
            target: PreviewScreen.projects,
            screen: screen,
            onNavigate: onNavigate,
          ),
          _NavItem(
            label: 'Editor',
            icon: HugeIcons.strokeRoundedTable02,
            target: PreviewScreen.editor,
            screen: screen,
            onNavigate: onNavigate,
          ),
          const SizedBox(height: 18),
          const _NavLabel('Settings'),
          _NavItem(
            label: 'Profile',
            icon: HugeIcons.strokeRoundedUser,
            screen: screen,
          ),
          _NavItem(
            label: 'Appearance',
            icon: HugeIcons.strokeRoundedPaintBoard,
            target: PreviewScreen.appearance,
            screen: screen,
            onNavigate: onNavigate,
          ),
          _NavItem(
            label: 'Languages',
            icon: HugeIcons.strokeRoundedLanguageSquare,
            screen: screen,
          ),
          _NavItem(
            label: 'AI providers',
            icon: HugeIcons.strokeRoundedSparkles,
            target: PreviewScreen.aiProviders,
            screen: screen,
            onNavigate: onNavigate,
          ),
          const Spacer(),
          _WorkspaceFooter(tokens: tokens),
        ],
      ),
    );
  }
}

class _NavLabel extends StatelessWidget {
  const _NavLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: LingoDeskTokens.of(context).muted,
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.screen,
    this.target,
    this.onNavigate,
  });

  final String label;
  final List<List<dynamic>> icon;
  final PreviewScreen screen;

  /// Null for the two destinations the tour does not cover; those render
  /// as real rows but do nothing, rather than pretending to be missing.
  final PreviewScreen? target;

  final ValueChanged<PreviewScreen>? onNavigate;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final active = widget.target == widget.screen;
    final enabled = widget.target != null && widget.onNavigate != null;
    final foreground = active || _hovered ? tokens.foreground : tokens.muted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: enabled ? () => widget.onNavigate!(widget.target!) : null,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: LingoDeskMotion.fast,
                curve: LingoDeskMotion.curve,
                height: 42,
                decoration: BoxDecoration(
                  color: active
                      ? tokens.active
                      : (_hovered && enabled
                            ? tokens.active.withValues(alpha: 0.55)
                            : Colors.transparent),
                  borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    LingoDeskIcon(widget.icon, size: 18, color: foreground),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // The rail marker the real sidebar paints beside the
              // selected destination.
              if (active)
                Positioned(
                  left: 0,
                  top: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.accent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const SizedBox(width: 3, height: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceFooter extends StatelessWidget {
  const _WorkspaceFooter({required this.tokens});

  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
        border: Border.all(color: tokens.border),
      ),
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.brand,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'LW',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: tokens.onBrand,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local workspace',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tokens.foreground,
                  ),
                ),
                Text(
                  'Local storage',
                  style: TextStyle(fontSize: 11.5, color: tokens.muted),
                ),
              ],
            ),
          ),
          LingoDeskIcon(
            HugeIcons.strokeRoundedMoreHorizontal,
            size: 16,
            color: tokens.muted,
          ),
        ],
      ),
    );
  }
}

/// `Workspace / Apps / Editor` — the breadcrumb band every pane opens with.
class PreviewBreadcrumb extends StatelessWidget {
  const PreviewBreadcrumb({
    super.key,
    required this.segments,
    this.actions = const [],
  });

  final List<String> segments;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i != 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '/',
                      style: TextStyle(fontSize: 13.5, color: tokens.border),
                    ),
                  ),
                Flexible(
                  child: Text(
                    segments[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: i == segments.length - 1
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: i == segments.length - 1
                          ? tokens.foreground
                          : tokens.muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        for (final action in actions)
          Padding(padding: const EdgeInsets.only(left: 8), child: action),
      ],
    );
  }
}

/// A toolbar button in the preview: secondary by default, brand-filled
/// when [primary], and clickable when given an [onTap].
class PreviewButton extends StatefulWidget {
  const PreviewButton({
    super.key,
    required this.label,
    this.icon,
    this.primary = false,
    this.onTap,
    this.height = 40,
  });

  final String label;
  final List<List<dynamic>>? icon;
  final bool primary;
  final VoidCallback? onTap;

  /// Raised where the button sits in a row of taller controls.
  final double height;

  @override
  State<PreviewButton> createState() => _PreviewButtonState();
}

class _PreviewButtonState extends State<PreviewButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final primary = widget.primary;
    final foreground = primary
        ? tokens.onBrand
        : (_hovered ? tokens.foreground : tokens.muted);

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: primary ? tokens.brand : tokens.card,
            borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
            border: Border.all(
              color: primary
                  ? tokens.brand
                  : (_hovered ? tokens.accent : tokens.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                LingoDeskIcon(widget.icon!, size: 17, color: foreground),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Column headings for the preview's tables.
class PreviewTableHeader extends StatelessWidget {
  const PreviewTableHeader({super.key, required this.cells});

  /// Each entry is a flex weight and its label.
  final List<(int, String)> cells;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: tokens.active,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: Row(
        children: [
          for (final (flex, label) in cells)
            Expanded(
              flex: flex,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: tokens.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
