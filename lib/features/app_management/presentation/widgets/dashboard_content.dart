part of '../pages/app_dashboard_page.dart';

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.scrollController,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.showMobileBrand,
  });

  final ScrollController scrollController;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;
  final bool showMobileBrand;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return ColoredBox(
      color: tokens.background,
      child: SafeArea(
        child: BlocBuilder<AppManagementBloc, AppManagementState>(
          builder: (context, state) {
            return Column(
              children: [
                _SiteHeader(
                  state: state,
                  themeMode: themeMode,
                  onThemeModeChanged: onThemeModeChanged,
                  selectedLanguage: selectedLanguage,
                  onLanguageChanged: onLanguageChanged,
                  showMobileBrand: showMobileBrand,
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
      return _DashboardError(message: state.message);
    }
    if (state is! AppManagementLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return _DashboardBody(
      state: state,
      showMobileBrand: showMobileBrand,
      scrollController: scrollController,
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.state,
    required this.showMobileBrand,
    required this.scrollController,
  });

  final AppManagementLoaded state;
  final bool showMobileBrand;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final metrics = _dashboardMetrics(state);

    return CustomScrollView(
      controller: scrollController,
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
          padding: EdgeInsets.fromLTRB(
            showMobileBrand ? 16 : 24,
            16,
            showMobileBrand ? 16 : 24,
            28,
          ),
          sliver: SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _appsSectionKey,
              child:
                  state.overviews.isEmpty
                      ? const _EmptyAppsCard()
                      : _ProjectsTable(state: state),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message});

  final String message;

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
          FilledButton(
            onPressed:
                () => context.read<AppManagementBloc>().add(LoadAppsEvent()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyAppsCard extends StatelessWidget {
  const _EmptyAppsCard();

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return _Surface(
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
            child: const LingoDeskIcon(
              HugeIcons.strokeRoundedFolder02,
              color: LingoDeskColors.brandTeal,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Create your first app',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'An app groups the translation files of one project. '
            'Set a source language, pick your targets, and start translating.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _openCreateApp(context),
            icon: const LingoDeskIcon(
              HugeIcons.strokeRoundedAdd01,
              color: Colors.white,
              size: 18,
            ),
            label: const Text('New app'),
          ),
        ],
      ),
    );
  }
}
