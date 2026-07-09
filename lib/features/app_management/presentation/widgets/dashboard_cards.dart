part of '../pages/app_dashboard_page.dart';

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final tokens = _DashboardTokens.of(context);

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

class _VelocityCard extends StatelessWidget {
  const _VelocityCard();

  static const _bars = [0.34, 0.58, 0.46, 0.72, 0.66, 0.92, 0.78, 0.88];

  @override
  Widget build(BuildContext context) {
    final tokens = _DashboardTokens.of(context);

    return _Surface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Translation velocity',
            subtitle: 'Completed strings over the last 8 sessions',
            icon: HugeIcons.strokeRoundedChartArea,
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < _bars.length; index++) ...[
                  Expanded(
                    child: _ChartBar(
                      value: _bars[index],
                      label: 'S${index + 1}',
                    ),
                  ),
                  if (index != _bars.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: tokens.border),
          const SizedBox(height: 12),
          Text(
            '92 strings completed this week. 39 are still missing across active target languages.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
          ),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({required this.value, required this.label});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = _DashboardTokens.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: value,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: LingoDeskColors.brandBlue,
                  borderRadius: BorderRadius.circular(6),
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
  const _LanguageHealthCard();

  @override
  Widget build(BuildContext context) {
    final tokens = _DashboardTokens.of(context);

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
          const _LanguageProgress(language: 'FR', progress: 0.94, missing: 8),
          const SizedBox(height: 18),
          const _LanguageProgress(language: 'ES', progress: 0.89, missing: 12),
          const SizedBox(height: 18),
          const _LanguageProgress(language: 'UK', progress: 0.81, missing: 19),
          const SizedBox(height: 18),
          const _LanguageProgress(language: 'DE', progress: 0.78, missing: 19),
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
                  'Next review: Customer Portal',
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
    final tokens = _DashboardTokens.of(context);

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
              '$missing missing',
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
          color: LingoDeskColors.brandBlue,
          backgroundColor: tokens.active,
        ),
      ],
    );
  }
}
