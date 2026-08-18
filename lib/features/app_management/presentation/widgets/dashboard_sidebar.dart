part of '../pages/app_dashboard_page.dart';

class _AppSidebar extends StatelessWidget {
  const _AppSidebar({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.sidebar,
        border: Border(right: BorderSide(color: tokens.border)),
      ),
      child: SizedBox(
        width: 284,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                  child: LingoDeskMark(
                    size: 34,
                    reversed: tokens.isDark,
                    showWordmark: true,
                  ),
                ),
                _SidebarSection(
                  title: 'Platform',
                  items: [
                    _SidebarItemData(
                      label: 'Dashboard',
                      icon: HugeIcons.strokeRoundedDashboardSquare01,
                      isActive: true,
                      onTap: _scrollToTop,
                    ),
                    _SidebarItemData(
                      label: 'Apps',
                      icon: HugeIcons.strokeRoundedFolder02,
                      onTap:
                          () => _scrollToSection(
                            scrollController,
                            _appsSectionKey,
                          ),
                    ),
                    _SidebarItemData(
                      label: 'Imports',
                      icon: HugeIcons.strokeRoundedFileUpload,
                      onTap: () => _openImportsFromSidebar(context),
                    ),
                    _SidebarItemData(
                      label: 'Editor',
                      icon: HugeIcons.strokeRoundedTableRowsSplit,
                      onTap: () => _openEditorFromSidebar(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SidebarSection(
                  title: 'Tools',
                  items: [
                    _SidebarItemData(
                      label: 'Languages',
                      icon: HugeIcons.strokeRoundedLanguageSquare,
                      onTap:
                          () => _scrollToSection(
                            scrollController,
                            _languageHealthKey,
                          ),
                    ),
                    _SidebarItemData(
                      label: 'Settings',
                      icon: HugeIcons.strokeRoundedSettings01,
                      onTap: () => _showPreferencesDialog(context),
                    ),
                  ],
                ),
                const Spacer(),
                _SidebarFooter(tokens: tokens),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _openImportsFromSidebar(BuildContext context) async {
    final overview = await _pickApp(context);
    if (overview != null && context.mounted) {
      _openFileUpload(context, overview);
    }
  }

  Future<void> _openEditorFromSidebar(BuildContext context) async {
    final overview = await _pickApp(context);
    if (overview != null && context.mounted) {
      _openEditor(context, overview);
    }
  }

  void _showPreferencesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _PreferencesDialog(),
    );
  }
}

/// App-level preferences (theme mode + UI language), opened from the
/// sidebar's Settings item.
class _PreferencesDialog extends StatelessWidget {
  const _PreferencesDialog();

  @override
  Widget build(BuildContext context) {
    final settings = getIt<AppSettingsController>();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return AlertDialog(
          title: const Text('Preferences'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 10),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                    ),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged:
                      (selection) => settings.setThemeMode(selection.first),
                ),
                const SizedBox(height: 24),
                Text(
                  'UI language',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: settings.uiLanguage,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'fr', child: Text('French')),
                    DropdownMenuItem(value: 'es', child: Text('Spanish')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      settings.setUiLanguage(value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }
}

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({required this.title, required this.items});

  final String title;
  final List<_SidebarItemData> items;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tokens.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final item in items) _SidebarItem(item: item),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.item});

  final _SidebarItemData item;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: item.isActive ? tokens.active : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              LingoDeskIcon(
                item.icon,
                size: 18,
                color: item.isActive ? tokens.foreground : tokens.muted,
              ),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: item.isActive ? tokens.foreground : tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.tokens});

  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LingoDeskColors.brandTeal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'LD',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local workspace',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  'Browser storage',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          LingoDeskIcon(
            HugeIcons.strokeRoundedMoreHorizontal,
            size: 18,
            color: tokens.muted,
          ),
        ],
      ),
    );
  }
}
