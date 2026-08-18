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
                  breadcrumb: const ['Workspace', 'Dashboard'],
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
    if (state is AppManagementError) {
      return WorkspaceErrorState(
        message: state.message,
        onRetry: () => context.read<AppManagementBloc>().add(LoadAppsEvent()),
      );
    }
    if (state is! AppManagementLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return _DashboardBody(state: state, scrollController: scrollController);
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.state, required this.scrollController});

  final AppManagementLoaded state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final metrics = _dashboardMetrics(state);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth < 780 ? 16.0 : 24.0;

        return CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 0),
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
                    itemCount: metrics.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 136,
                    ),
                    itemBuilder: (context, index) {
                      return _MetricCard(metric: metrics[index]);
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
                          _CoverageCard(state: state),
                          const SizedBox(height: 12),
                          languageHealth,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: _CoverageCard(state: state)),
                        const SizedBox(width: 12),
                        Expanded(flex: 4, child: languageHealth),
                      ],
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 28),
              sliver: SliverToBoxAdapter(
                child:
                    state.overviews.isEmpty
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
