import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/lingo_desk_theme.dart';
import '../theme/lingo_desk_tokens.dart';
import 'lingo_desk_icon.dart';

/// Icon + title + subtitle heading used at the top of every card.
class WorkspaceCardHeader extends StatelessWidget {
  const WorkspaceCardHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Row(
      children: [
        LingoDeskIcon(icon, color: tokens.muted, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Completion bar shared by the apps table, the dashboard cards and the
/// editor's per-language header.
class WorkspaceProgressBar extends StatelessWidget {
  const WorkspaceProgressBar({
    super.key,
    required this.value,
    required this.isComplete,
    this.showPercentage = false,
    this.minHeight = 8,
    this.backgroundColor,
  });

  final double value;

  /// Drives the teal (in progress) vs green (done) fill colour.
  final bool isComplete;

  /// Appends a monospaced `NN%` label to the right of the bar.
  final bool showPercentage;

  final double minHeight;

  /// Defaults to the theme's `active` surface.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    final bar = LinearProgressIndicator(
      value: value,
      minHeight: minHeight,
      borderRadius: BorderRadius.circular(99),
      color: isComplete ? LingoDeskColors.complete : LingoDeskColors.brandTeal,
      backgroundColor: backgroundColor ?? tokens.active,
    );

    if (!showPercentage) {
      return bar;
    }

    return Row(
      children: [
        Expanded(child: bar),
        const SizedBox(width: 10),
        Text(
          '${(value * 100).round()}%',
          style: LingoDeskTheme.codeStyle.copyWith(
            color: tokens.foreground,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Compact label/value tile with a leading icon, used in page hero blocks
/// and the workspace totals card.
class WorkspaceMetaTile extends StatelessWidget {
  const WorkspaceMetaTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.width = 104,
  });

  final String label;
  final String value;
  final List<List<dynamic>> icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return SizedBox(
      width: width,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.active,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              LingoDeskIcon(icon, size: 17, color: tokens.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered placeholder card with an optional primary action.
class WorkspaceEmptyState extends StatelessWidget {
  const WorkspaceEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<List<dynamic>>? actionIcon;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final label = actionLabel;

    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LingoDeskColors.brandTeal.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LingoDeskIcon(
              icon,
              color: LingoDeskColors.brandTeal,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
          ),
          if (label != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: LingoDeskIcon(
                actionIcon ?? icon,
                color: Colors.white,
                size: 18,
              ),
              label: Text(label),
            ),
          ],
        ],
      ),
    );
  }
}

/// Centered failure message with a retry action.
class WorkspaceErrorState extends StatelessWidget {
  const WorkspaceErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LingoDeskIcon(
            HugeIcons.strokeRoundedAlertCircle,
            color: LingoDeskColors.error,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Error: $message',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
