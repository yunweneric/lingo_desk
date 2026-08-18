import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/lingo_desk_tokens.dart';
import 'lingo_desk_icon.dart';

/// Shared chrome for workspace pages (settings, upload, editor):
/// a bordered header with back button, breadcrumb-style title, and
/// optional trailing actions, above the page body.
class WorkspaceScaffold extends StatelessWidget {
  const WorkspaceScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.background,
                border: Border(bottom: BorderSide(color: tokens.border)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: LingoDeskIcon(
                        HugeIcons.strokeRoundedArrowLeft01,
                        color: tokens.foreground,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(fontSize: 18),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: tokens.muted, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    for (final action in actions) ...[
                      const SizedBox(width: 8),
                      action,
                    ],
                  ],
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Bordered card surface matching the dashboard cards.
class WorkspaceSurface extends StatelessWidget {
  const WorkspaceSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Pill badge matching the dashboard badges.
class WorkspaceBadge extends StatelessWidget {
  const WorkspaceBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(78)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
