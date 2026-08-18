import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/lingo_desk_tokens.dart';
import 'app_shell_scope.dart';
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

  /// Path segments, e.g. `['Workspace', 'Apps']`.
  final List<String> breadcrumb;

  final List<Widget> actions;

  /// Optional block rendered below the breadcrumb row.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final shell = AppShellScope.maybeOf(context);
    final hero = child;

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
                    Wrap(spacing: 8, runSpacing: 8, children: actions),
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
                    for (final action in actions) ...[
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

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.segments});

  final List<String> segments;

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
            child: Text(
              segments[index],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  index == segments.length - 1
                      ? Theme.of(context).textTheme.labelLarge
                      : Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.muted,
                        fontWeight: FontWeight.w600,
                      ),
            ),
          ),
        ],
      ],
    );
  }
}
