part of '../pages/app_dashboard_page.dart';

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.projects,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.showMobileBrand,
  });

  final List<_ProjectSummary> projects;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;
  final bool showMobileBrand;

  @override
  Widget build(BuildContext context) {
    final tokens = _DashboardTokens.of(context);

    return ColoredBox(
      color: tokens.background,
      child: SafeArea(
        child: Column(
          children: [
            _SiteHeader(
              projects: projects,
              themeMode: themeMode,
              onThemeModeChanged: onThemeModeChanged,
              selectedLanguage: selectedLanguage,
              onLanguageChanged: onLanguageChanged,
              showMobileBrand: showMobileBrand,
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      showMobileBrand ? 16 : 24,
                      20,
                      showMobileBrand ? 16 : 24,
                      0,
                    ),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.crossAxisExtent;
                        final columns =
                            width >= 1180
                                ? 4
                                : width >= 760
                                ? 2
                                : 1;

                        return SliverGrid.builder(
                          itemCount: 4,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 136,
                              ),
                          itemBuilder: (context, index) {
                            return _MetricCard(
                              metric: _dashboardMetrics(projects)[index],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      showMobileBrand ? 16 : 24,
                      16,
                      showMobileBrand ? 16 : 24,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 980;

                          if (!isWide) {
                            return const Column(
                              children: [
                                _VelocityCard(),
                                SizedBox(height: 12),
                                _LanguageHealthCard(),
                              ],
                            );
                          }

                          return const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 7, child: _VelocityCard()),
                              SizedBox(width: 12),
                              Expanded(flex: 4, child: _LanguageHealthCard()),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      showMobileBrand ? 16 : 24,
                      16,
                      showMobileBrand ? 16 : 24,
                      28,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _ProjectsTable(projects: projects),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
