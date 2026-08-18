part of '../pages/app_dashboard_page.dart';

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.scrollController,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ScrollController scrollController;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return ColoredBox(
      color: tokens.background,
      child: SafeArea(
        child: BlocBuilder<AppManagementBloc, AppManagementState>(
          builder: (context, state) {
            final loaded = state is AppManagementLoaded ? state : null;

            return Column(
              children: [
                WorkspacePageHeader(
                  breadcrumb: const [Crumb.workspace, Crumb('Dashboard')],
                  actions: [
                    ThemeModeSwitcher(
                      themeMode: themeMode,
                      onChanged: onThemeModeChanged,
                    ),
                  ],
                  child: _HeaderOverview(loaded: loaded),
                ),
                Expanded(child: _buildBody(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppManagementState state) {
    final Widget body;
    if (state is AppManagementError) {
      body = WorkspaceErrorState(
        message: state.message,
        onRetry: () => context.read<AppManagementBloc>().add(LoadAppsEvent()),
      );
    } else if (state is! AppManagementLoaded) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = _DashboardBody(state: state, scrollController: scrollController);
    }

    // Cross-fade rather than swap: the spinner dissolving into the stats
    // is what makes a fast load feel finished instead of interrupted.
    return AnimatedSwitcher(
      duration: LingoDeskMotion.standard,
      switchInCurve: LingoDeskMotion.curve,
      switchOutCurve: LingoDeskMotion.curve,
      layoutBuilder: topAlignedSwitcherLayout,
      child: KeyedSubtree(
        key: ValueKey<String>(state.runtimeType.toString()),
        child: body,
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.state, required this.scrollController});

  final AppManagementLoaded state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final metrics = _dashboardMetrics(state);

    return ResponsiveBuilder(
      builder: (context, size, constraints) {
        final horizontal = size.pagePadding;

        return CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 0),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  // One metric per line on a phone, two once a tablet
                  // can hold a pair side by side, four across a desktop.
                  final columns = WindowSizeClass.fromWidth(
                    constraints.crossAxisExtent,
                  ).resolve(compact: 1, medium: 2, large: 4);

                  return SliverGrid.builder(
                    itemCount: metrics.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 136,
                    ),
                    itemBuilder: (context, index) {
                      return _MetricCard(metric: metrics[index], index: index);
                    },
                  );
                },
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
              sliver: SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 980;

                    final languageHealth = KeyedSubtree(
                      key: _languageHealthKey,
                      child: _LanguageHealthCard(state: state),
                    );

                    if (!isWide) {
                      return Column(
                        children: [
                          FadeSlideIn.staggered(
                            index: 4,
                            child: _CoverageCard(state: state),
                          ),
                          const SizedBox(height: 12),
                          FadeSlideIn.staggered(
                            index: 5,
                            child: languageHealth,
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: FadeSlideIn.staggered(
                            index: 4,
                            child: _CoverageCard(state: state),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: FadeSlideIn.staggered(
                            index: 5,
                            child: languageHealth,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 28),
              sliver: SliverToBoxAdapter(
                child: FadeSlideIn.staggered(
                  index: 6,
                  child: state.overviews.isEmpty
                      ? WorkspaceEmptyState(
                          icon: HugeIcons.strokeRoundedFolder02,
                          title: 'Create your first app',
                          message:
                              'An app groups the translation files of one '
                              'project. Set a source language, pick your '
                              'targets, and start translating.',
                          actionLabel: 'New app',
                          actionIcon: HugeIcons.strokeRoundedAdd01,
                          onAction: () => openCreateApp(context),
                        )
                      : _AppsShortcutCard(state: state),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Points at the apps page, which owns the full table.
class _AppsShortcutCard extends StatelessWidget {
  const _AppsShortcutCard({required this.state});

  final AppManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final appCount = state.overviews.length;

    return WorkspaceSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final header = WorkspaceCardHeader(
            title: 'Apps',
            subtitle:
                '$appCount ${appCount == 1 ? 'app' : 'apps'} - '
                '${state.completeFiles}/${state.totalFiles} translation files '
                'complete',
            icon: HugeIcons.strokeRoundedFolder02,
          );
          final action = FilledButton.icon(
            onPressed: () => context.go(AppRoutes.apps),
            icon: const LingoDeskIcon(
              HugeIcons.strokeRoundedArrowRight01,
              color: Colors.white,
              size: 18,
            ),
            label: const Text('View all apps'),
          );

          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [header, const SizedBox(height: 16), action],
            );
          }

          return Row(
            children: [
              Expanded(child: header),
              const SizedBox(width: 16),
              action,
            ],
          );
        },
      ),
    );
  }
}
