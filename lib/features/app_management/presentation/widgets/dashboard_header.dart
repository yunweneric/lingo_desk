part of '../pages/app_dashboard_page.dart';

class _SiteHeader extends StatelessWidget {
  const _SiteHeader({
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.background,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 780;
          final horizontalPadding = showMobileBrand ? 16.0 : 24.0;
          final missing = projects.fold<int>(
            0,
            (sum, app) => sum + app.missingCount,
          );

          if (isCompact) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                14,
                horizontalPadding,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child:
                            showMobileBrand
                                ? const LingoDeskMark(
                                  size: 32,
                                  showWordmark: true,
                                )
                                : _Breadcrumb(tokens: tokens),
                      ),
                      _LanguageSwitcher(
                        selectedLanguage: selectedLanguage,
                        onChanged: onLanguageChanged,
                        compact: true,
                      ),
                      const SizedBox(width: 8),
                      _ThemeSwitcher(
                        themeMode: themeMode,
                        onChanged: onThemeModeChanged,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _HeaderTitle(projects: projects),
                  const SizedBox(height: 14),
                  _SearchField(tokens: tokens, width: double.infinity),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _Badge(
                        label: '$missing missing strings',
                        color:
                            missing == 0
                                ? LingoDeskColors.complete
                                : LingoDeskColors.warning,
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const LingoDeskIcon(
                          HugeIcons.strokeRoundedAdd01,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text('New app'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              20,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _Breadcrumb(tokens: tokens)),
                    _SearchField(tokens: tokens, width: 280),
                    const SizedBox(width: 8),
                    _ThemeSwitcher(
                      themeMode: themeMode,
                      onChanged: onThemeModeChanged,
                    ),
                    const SizedBox(width: 8),
                    _LanguageSwitcher(
                      selectedLanguage: selectedLanguage,
                      onChanged: onLanguageChanged,
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const LingoDeskIcon(
                        HugeIcons.strokeRoundedAdd01,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text('New app'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _HeaderTitle(projects: projects)),
                    const SizedBox(width: 18),
                    _Badge(
                      label: '$missing missing strings',
                      color:
                          missing == 0
                              ? LingoDeskColors.complete
                              : LingoDeskColors.warning,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({required this.projects});

  final List<_ProjectSummary> projects;

  @override
  Widget build(BuildContext context) {
    final tokens = _DashboardTokens.of(context);
    final totalKeys = projects.fold<int>(0, (sum, app) => sum + app.keyCount);
    final activeLanguages =
        projects.expand((app) => app.targetLanguages).toSet().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Translation dashboard',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 28, height: 1.08),
            ),
            _HeaderMeta(label: '${projects.length} apps', tokens: tokens),
            _HeaderMeta(label: '$totalKeys keys', tokens: tokens),
            _HeaderMeta(label: '$activeLanguages locales', tokens: tokens),
          ],
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            'Track coverage, review missing strings, and jump back into active localization work.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: tokens.muted, height: 1.45),
          ),
        ),
      ],
    );
  }
}

class _HeaderMeta extends StatelessWidget {
  const _HeaderMeta({required this.label, required this.tokens});

  final String label;
  final _DashboardTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: tokens.active,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: tokens.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.tokens});

  final _DashboardTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Workspace',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: tokens.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Text('/', style: TextStyle(color: tokens.muted)),
        ),
        Text('Dashboard', style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.tokens, this.width = 220});

  final _DashboardTokens tokens;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 42,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: tokens.card,
          border: Border.all(color: tokens.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            LingoDeskIcon(
              HugeIcons.strokeRoundedGlobalSearch,
              color: tokens.muted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search projects',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.active,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: tokens.border),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  'K',
                  style: LingoDeskTheme.codeStyle.copyWith(
                    color: tokens.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
