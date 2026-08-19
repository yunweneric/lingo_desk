import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/lingo_desk_motion.dart';
import '../theme/lingo_desk_theme.dart';
import '../theme/lingo_desk_tokens.dart';
import 'lingo_desk_animations.dart';
import 'lingo_desk_icon.dart';
import '../localization/export.dart';

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
    final target = isComplete ? LingoDeskColors.complete : tokens.accent;

    // The fill sweeps to its value on first paint and slides between
    // values afterwards, so translating a key visibly moves the bar
    // instead of teleporting it. The colour tweens too, so crossing into
    // "complete" is a wash from teal to green rather than a snap.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: LingoDeskMotion.slow,
      curve: LingoDeskMotion.entrance,
      builder: (context, animated, _) {
        final bar = TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: target),
          duration: LingoDeskMotion.standard,
          curve: LingoDeskMotion.curve,
          builder: (context, color, _) {
            return LinearProgressIndicator(
              value: animated,
              minHeight: minHeight,
              borderRadius: BorderRadius.circular(99),
              color: color ?? target,
              backgroundColor: backgroundColor ?? tokens.active,
            );
          },
        );

        if (!showPercentage) {
          return bar;
        }

        return Row(
          children: [
            Expanded(child: bar),
            const SizedBox(width: 10),
            Text(
              '${(animated * 100).round()}%',
              style: LingoDeskTheme.codeStyle.copyWith(
                color: tokens.foreground,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
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
    this.height = 54,
  });

  final String label;
  final String value;
  final List<List<dynamic>> icon;
  final double width;

  /// Overridden where the tile shares a row with fields and buttons and
  /// has to match their height.
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.active,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
      // An empty state is the one place with nothing to look at, so its
      // three parts arrive in reading order instead of all at once.
      child: Column(
        children: [
          FadeSlideIn(
            offset: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.85, end: 1),
              duration: LingoDeskMotion.slow,
              curve: LingoDeskMotion.entrance,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tokens.accent.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: LingoDeskIcon(icon, color: tokens.accent, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn.staggered(
            index: 1,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
          FadeSlideIn.staggered(
            index: 2,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
            ),
          ),
          if (label != null && onAction != null) ...[
            const SizedBox(height: 20),
            FadeSlideIn.staggered(
              index: 3,
              child: FilledButton.icon(
                onPressed: onAction,
                icon: LingoDeskIcon(
                  actionIcon ?? icon,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(label),
              ),
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
      child: FadeSlideIn(
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
              LocaleKeys.commonErrorPrefix.tr(namedArgs: {'message': message}),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(LocaleKeys.commonRetry.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
