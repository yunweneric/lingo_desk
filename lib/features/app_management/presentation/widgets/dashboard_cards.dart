part of '../pages/app_dashboard_page.dart';

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return _Surface(
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
          Text(
            metric.value,
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
                color:
                    metric.isPositive
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
    final apps = state.overviews.take(8).toList();
    final translated = state.totalCells - state.totalMissing;

    return _Surface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Coverage by app',
            subtitle: 'Translated share of target strings per app',
            icon: HugeIcons.strokeRoundedChartArea,
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 220,
            child:
                apps.isEmpty
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
                              label: _appInitials(apps[index].app.name),
                            ),
                          ),
                          if (index != apps.length - 1)
                            const SizedBox(width: 10),
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

  static String _appInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      final word = words.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({required this.value, required this.label});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              // Keep a sliver of bar visible for 0% apps.
              heightFactor: value.clamp(0.02, 1.0),
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: LingoDeskColors.brandTeal,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: LingoDeskTheme.codeStyle.copyWith(
            color: tokens.muted,
            fontSize: 11,
          ),
        ),
      ],
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
    final nextReview =
        state.overviews.where((overview) => overview.missingCount > 0).toList();

    return _Surface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
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
            for (final stat in health) ...[
              _LanguageProgress(
                language: stat.language.toUpperCase(),
                progress: stat.progress,
                missing: stat.missing,
              ),
              if (stat != health.last) const SizedBox(height: 18),
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
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(99),
          color:
              missing == 0
                  ? LingoDeskColors.complete
                  : LingoDeskColors.brandTeal,
          backgroundColor: tokens.active,
        ),
      ],
    );
  }
}
