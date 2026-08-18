part of '../pages/app_dashboard_page.dart';

class _SiteHeader extends StatelessWidget {
  const _SiteHeader({
    required this.state,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.showMobileBrand,
  });

  final AppManagementState state;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;
  final bool showMobileBrand;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final loaded =
        state is AppManagementLoaded ? state as AppManagementLoaded : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.background,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 780;
          final horizontalPadding = showMobileBrand ? 16.0 : 24.0;

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
                  _HeaderOverview(loaded: loaded),
                  const SizedBox(height: 12),
                  _SearchField(tokens: tokens, width: double.infinity),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openCreateApp(context),
                      icon: const LingoDeskIcon(
                        HugeIcons.strokeRoundedAdd01,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text('New app'),
                    ),
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
                const SizedBox(height: 20),
                _HeaderOverview(loaded: loaded),
              ],
            ),
          );
        },
      ),
    );
  }
}

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTight = constraints.maxWidth < 760;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Translation dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: isTight ? 24 : 28,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track coverage, review missing strings, and jump back into active localization work.',
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
              _HeaderMeta(
                label: 'Apps',
                value: appCount.toString(),
                icon: HugeIcons.strokeRoundedFolder02,
                tokens: tokens,
              ),
              _HeaderMeta(
                label: 'Keys',
                value: totalKeys.toString(),
                icon: HugeIcons.strokeRoundedKey01,
                tokens: tokens,
              ),
              _HeaderMeta(
                label: 'Locales',
                value: activeLanguages.toString(),
                icon: HugeIcons.strokeRoundedLanguageSquare,
                tokens: tokens,
              ),
              _Badge(
                label: '$missing missing strings',
                color:
                    missing == 0
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

class _HeaderMeta extends StatelessWidget {
  const _HeaderMeta({
    required this.label,
    required this.value,
    required this.icon,
    required this.tokens,
  });

  final String label;
  final String value;
  final List<List<dynamic>> icon;
  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.active,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.tokens});

  final LingoDeskTokens tokens;

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

class _SearchField extends StatefulWidget {
  const _SearchField({required this.tokens, this.width = 220});

  final LingoDeskTokens tokens;
  final double width;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    return SizedBox(
      width: widget.width,
      height: 42,
      child: TextField(
        controller: _controller,
        onChanged:
            (value) =>
                context.read<AppManagementBloc>().add(SearchAppsEvent(value)),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: tokens.foreground),
        decoration: InputDecoration(
          hintText: 'Search apps',
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
          isDense: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: LingoDeskIcon(
              HugeIcons.strokeRoundedGlobalSearch,
              color: tokens.muted,
              size: 18,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Clear',
                onPressed: () {
                  _controller.clear();
                  context.read<AppManagementBloc>().add(SearchAppsEvent(''));
                },
                icon: LingoDeskIcon(
                  HugeIcons.strokeRoundedCancel01,
                  color: tokens.muted,
                  size: 16,
                ),
              );
            },
          ),
          filled: true,
          fillColor: tokens.card,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: tokens.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: tokens.border),
          ),
        ),
      ),
    );
  }
}
