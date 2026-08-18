import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/lingo_desk_motion.dart';
import '../theme/lingo_desk_theme.dart';
import '../theme/lingo_desk_tokens.dart';
import '../router/app_router.dart';
import 'app_shell_scope.dart';
import 'lingo_desk_animations.dart';
import 'lingo_desk_icon.dart';

/// Bordered header band for the pages rendered inside [AppShell]:
/// breadcrumb on the left, toolbar actions on the right, and an optional
/// hero [child] underneath. Adds a drawer button when the shell is narrow.
class WorkspacePageHeader extends StatelessWidget {
  const WorkspacePageHeader({
    super.key,
    required this.breadcrumb,
    this.actions = const [],
    this.child,
  });

  /// Path segments, e.g. `[Crumb.workspace, Crumb('Apps')]`. Segments
  /// with a route navigate there when tapped.
  final List<Crumb> breadcrumb;

  final List<Widget> actions;

  /// Optional block rendered below the breadcrumb row.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final shell = AppShellScope.maybeOf(context);
    final hero = child;
    // Wrapped here rather than at each call site, so every page's header
    // buttons answer a press the same way.
    final pressableActions = [
      for (final action in actions) PressableScale(child: action),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.background,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 780;
          final horizontalPadding = isCompact ? 16.0 : 24.0;

          final leading = <Widget>[
            if (shell != null && shell.hasDrawer) ...[
              IconButton(
                tooltip: 'Menu',
                onPressed: shell.openDrawer,
                icon: LingoDeskIcon(
                  HugeIcons.strokeRoundedMenu01,
                  color: tokens.foreground,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ];

          if (isCompact) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                14,
                horizontalPadding,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ...leading,
                      Expanded(child: _Breadcrumb(segments: breadcrumb)),
                    ],
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, runSpacing: 8, children: pressableActions),
                  ],
                  if (hero != null) ...[const SizedBox(height: 16), hero],
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              hero == null ? 16 : 20,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ...leading,
                    Expanded(child: _Breadcrumb(segments: breadcrumb)),
                    for (final action in pressableActions) ...[
                      const SizedBox(width: 8),
                      action,
                    ],
                  ],
                ),
                if (hero != null) ...[const SizedBox(height: 20), hero],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One breadcrumb segment. A [route] makes it a link back to that page;
/// without one it is plain text (the current page, or a bare label).
class Crumb {
  const Crumb(this.label, {this.route});

  /// The root segment every page hangs off.
  static const workspace = Crumb('Workspace', route: AppRoutes.dashboard);

  final String label;
  final String? route;
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.segments});

  final List<Crumb> segments;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Row(
      children: [
        for (var index = 0; index < segments.length; index++) ...[
          if (index != 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Text('/', style: TextStyle(color: tokens.muted)),
            ),
          Flexible(
            child: _CrumbLabel(
              crumb: segments[index],
              // The page you are on is never a link, even if it has a
              // route of its own.
              isCurrent: index == segments.length - 1,
            ),
          ),
        ],
      ],
    );
  }
}

class _CrumbLabel extends StatelessWidget {
  const _CrumbLabel({required this.crumb, required this.isCurrent});

  final Crumb crumb;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final route = isCurrent ? null : crumb.route;

    final label = Text(
      crumb.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style:
          isCurrent
              ? Theme.of(context).textTheme.labelLarge
              : Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: route == null ? tokens.muted : tokens.foreground,
                fontWeight: FontWeight.w600,
              ),
    );

    if (route == null) {
      // The same 3px the link reserves for its underline, so a trail of
      // links and plain labels still shares one baseline.
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [label, const SizedBox(height: 3)],
      );
    }

    return _CrumbLink(route: route, label: crumb.label);
  }
}

/// A crumb that is a link. Under the pointer it takes on the brand colour
/// and grows an underline out from its left edge — enough to say "this
/// navigates" without decorating the whole trail at rest.
class _CrumbLink extends StatefulWidget {
  const _CrumbLink({required this.route, required this.label});

  final String route;
  final String label;

  @override
  State<_CrumbLink> createState() => _CrumbLinkState();
}

class _CrumbLinkState extends State<_CrumbLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final color = _hovered ? LingoDeskColors.brandTeal : tokens.foreground;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedDefaultTextStyle(
              duration: LingoDeskMotion.fast,
              curve: LingoDeskMotion.curve,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ) ??
                  TextStyle(color: color),
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            _CrumbUnderline(visible: _hovered),
          ],
        ),
      ),
    );
  }
}

/// The 1px rule that wipes in under a hovered crumb.
class _CrumbUnderline extends StatelessWidget {
  const _CrumbUnderline({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: visible ? 1 : 0),
      duration: LingoDeskMotion.standard,
      curve: LingoDeskMotion.curve,
      builder: (context, extent, _) {
        return FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: extent,
          child: Container(
            height: 1,
            color: LingoDeskColors.brandTeal.withValues(alpha: extent),
          ),
        );
      },
    );
  }
}
