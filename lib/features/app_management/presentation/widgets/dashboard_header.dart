part of '../pages/app_dashboard_page.dart';

/// Hero block under the breadcrumb: headline copy plus workspace counters.
class _HeaderOverview extends StatelessWidget {
  const _HeaderOverview({required this.loaded});

  final AppManagementLoaded? loaded;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final appCount = loaded?.overviews.length ?? 0;
    final totalKeys = loaded?.totalKeys ?? 0;
    final activeLanguages = loaded?.activeLanguages.length ?? 0;
    final missing = loaded?.totalMissing ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: ResponsiveBuilder(
        builder: (context, size, constraints) {
          // The stats block needs a tablet's width to sit beside the
          // title; below that it drops under it.
          final isTight = size.isBelow(WindowSizeClass.expanded);
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.dashboardTitle.tr(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: isTight ? 24 : 28,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                LocaleKeys.dashboardSubtitle.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: tokens.muted,
                  height: 1.45,
                ),
              ),
            ],
          );

          final stats = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: isTight ? WrapAlignment.start : WrapAlignment.end,
            children: [
              WorkspaceMetaTile(
                label: LocaleKeys.navApps.tr(),
                value: appCount.toString(),
                icon: HugeIcons.strokeRoundedFolder02,
              ),
              WorkspaceMetaTile(
                label: LocaleKeys.dashboardStatKeys.tr(),
                value: totalKeys.toString(),
                icon: HugeIcons.strokeRoundedKey01,
              ),
              WorkspaceMetaTile(
                label: LocaleKeys.dashboardStatLocales.tr(),
                value: activeLanguages.toString(),
                icon: HugeIcons.strokeRoundedLanguageSquare,
              ),
              WorkspaceBadge(
                label: '$missing missing strings',
                color: missing == 0
                    ? LingoDeskColors.complete
                    : LingoDeskColors.warning,
              ),
            ],
          );

          if (isTight) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 14), stats],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: title),
              const SizedBox(width: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: stats,
              ),
            ],
          );
        },
      ),
    );
  }
}
