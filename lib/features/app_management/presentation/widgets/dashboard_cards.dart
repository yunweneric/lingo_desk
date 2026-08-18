part of '../pages/app_dashboard_page.dart';

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, required this.index});

  final _Metric metric;

  /// Position in the row, for the entrance stagger.
  final int index;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return FadeSlideIn.staggered(
      index: index,
      child: HoverLift(
        child: WorkspaceSurface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      metric.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  LingoDeskIcon(metric.icon, color: tokens.muted, size: 18),
                ],
              ),
              const Spacer(),
              AnimatedCountText(
                value: metric.value,
                suffix: metric.suffix,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  LingoDeskIcon(
                    metric.isPositive
                        ? HugeIcons.strokeRoundedArrowUpRight02
                        : HugeIcons.strokeRoundedArrowDownRight02,
                    size: 16,
                    color: metric.isPositive
                        ? LingoDeskColors.complete
                        : LingoDeskColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      metric.detail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.muted,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverageCard extends StatelessWidget {
  const _CoverageCard({required this.state});

  final AppManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    // Most recently active apps first, capped to keep the chart readable.
    // Eight bars across a phone is 33px each — present, but not a chart
    // you can read. Fewer, wider bars say the same thing.
    final apps = state.overviews
        .take(context.windowSize.isCompact ? 4 : 8)
        .toList();
    final translated = state.totalCells - state.totalMissing;

    return WorkspaceSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceCardHeader(
            title: 'Coverage by app',
            subtitle: 'Translated share of target strings per app',
            icon: HugeIcons.strokeRoundedChartArea,
          ),
          const SizedBox(height: 26),
          SizedBox(
            // A phone has the height to spare far less than a desktop
            // window does, and the bars are read by their proportions
            // rather than their absolute size.
            height: context.windowSize.isCompact ? 150.0 : 220.0,
            child: apps.isEmpty
                ? Center(
                    child: Text(
                      'Create an app to see coverage here.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var index = 0; index < apps.length; index++) ...[
                        Expanded(
                          child: _ChartBar(
                            value: apps[index].progress,
                            label: apps[index].app.initials,
                            name: apps[index].app.name,
                            index: index,
                          ),
                        ),
                        if (index != apps.length - 1) const SizedBox(width: 10),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Divider(color: tokens.border),
          const SizedBox(height: 12),
          Text(
            state.totalCells == 0
                ? 'No translation data yet. Upload JSON files to get started.'
                : '$translated strings translated. ${state.totalMissing} are '
                      'still missing across active target languages.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
          ),
        ],
      ),
    );
  }
}

/// One column of the coverage chart.
///
/// Bars grow up from the axis in sequence when the chart appears, which
/// is what makes the block read as a chart rather than a block of colour.
/// Hovering brightens the bar and names the app it belongs to.
class _ChartBar extends StatefulWidget {
  const _ChartBar({
    required this.value,
    required this.label,
    required this.name,
    required this.index,
  });

  final double value;
  final String label;
  final String name;
  final int index;

  @override
  State<_ChartBar> createState() => _ChartBarState();
}

class _ChartBarState extends State<_ChartBar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    // Keep a sliver of bar visible for 0% apps.
    final target = widget.value.clamp(0.02, 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: '${widget.name} - ${(widget.value * 100).round()}%',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: target),
                  // Each bar takes slightly longer than the one to its
                  // left, so they land in a wave without needing timers.
                  duration:
                      LingoDeskMotion.slow +
                      LingoDeskMotion.delayFor(widget.index),
                  curve: LingoDeskMotion.entrance,
                  builder: (context, height, _) {
                    return FractionallySizedBox(
                      heightFactor: height,
                      widthFactor: 1,
                      child: AnimatedContainer(
                        duration: LingoDeskMotion.fast,
                        curve: LingoDeskMotion.curve,
                        decoration: BoxDecoration(
                          color: _hovered
                              ? tokens.accent
                              : tokens.accent.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedTint(
              color: _hovered ? tokens.foreground : tokens.muted,
              builder: (context, tint) => Text(
                widget.label,
                style: LingoDeskTheme.codeStyle.copyWith(
                  color: tint,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageHealthCard extends StatelessWidget {
  const _LanguageHealthCard({required this.state});

  final AppManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final health = state.languageHealth.take(6).toList();
    final nextReview = state.overviews
        .where((overview) => overview.missingCount > 0)
        .toList();

    return WorkspaceSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceCardHeader(
            title: 'Language health',
            subtitle: 'Coverage by target locale',
            icon: HugeIcons.strokeRoundedLanguageSquare,
          ),
          const SizedBox(height: 22),
          if (health.isEmpty)
            Text(
              'No target languages yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
            )
          else
            for (var index = 0; index < health.length; index++) ...[
              FadeSlideIn.staggered(
                index: index,
                child: _LanguageProgress(
                  language:
                      '${SupportedLanguages.flagOf(health[index].language)}  '
                      '${health[index].language.toUpperCase()}',
                  progress: health[index].progress,
                  missing: health[index].missing,
                ),
              ),
              if (index != health.length - 1) const SizedBox(height: 18),
            ],
          const SizedBox(height: 22),
          Divider(color: tokens.border),
          const SizedBox(height: 16),
          Row(
            children: [
              LingoDeskIcon(
                HugeIcons.strokeRoundedClock03,
                color: tokens.muted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nextReview.isEmpty
                      ? 'All apps are fully translated.'
                      : 'Next review: ${nextReview.first.app.name}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageProgress extends StatelessWidget {
  const _LanguageProgress({
    required this.language,
    required this.progress,
    required this.missing,
  });

  final String language;
  final double progress;
  final int missing;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              language,
              style: LingoDeskTheme.codeStyle.copyWith(
                color: tokens.foreground,
              ),
            ),
            const Spacer(),
            Text(
              missing == 0 ? 'Complete' : '$missing missing',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        WorkspaceProgressBar(value: progress, isComplete: missing == 0),
      ],
    );
  }
}
