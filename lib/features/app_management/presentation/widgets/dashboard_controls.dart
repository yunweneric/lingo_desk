part of '../pages/app_dashboard_page.dart';

class _ThemeSwitcher extends StatelessWidget {
  const _ThemeSwitcher({
    required this.themeMode,
    required this.onChanged,
    this.compact = false,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme',
      onSelected: onChanged,
      itemBuilder:
          (context) => const [
            PopupMenuItem(
              value: ThemeMode.system,
              child: _MenuOption(
                icon: HugeIcons.strokeRoundedComputerSettings,
                label: 'System',
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.light,
              child: _MenuOption(
                icon: HugeIcons.strokeRoundedSun03,
                label: 'Light',
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: _MenuOption(
                icon: HugeIcons.strokeRoundedMoon02,
                label: 'Dark',
              ),
            ),
          ],
      child: _ToolbarButton(
        icon: switch (themeMode) {
          ThemeMode.light => HugeIcons.strokeRoundedSun03,
          ThemeMode.dark => HugeIcons.strokeRoundedMoon02,
          ThemeMode.system => HugeIcons.strokeRoundedComputerSettings,
        },
        label: switch (themeMode) {
          ThemeMode.light => 'Light',
          ThemeMode.dark => 'Dark',
          ThemeMode.system => 'System',
        },
        compact: compact,
      ),
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher({
    required this.selectedLanguage,
    required this.onChanged,
    this.compact = false,
  });

  final String selectedLanguage;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Language',
      onSelected: onChanged,
      itemBuilder:
          (context) => const [
            PopupMenuItem(
              value: 'en',
              child: _MenuOption(
                icon: HugeIcons.strokeRoundedLanguageSquare,
                label: 'English',
              ),
            ),
            PopupMenuItem(
              value: 'fr',
              child: _MenuOption(
                icon: HugeIcons.strokeRoundedLanguageSquare,
                label: 'French',
              ),
            ),
            PopupMenuItem(
              value: 'es',
              child: _MenuOption(
                icon: HugeIcons.strokeRoundedLanguageSquare,
                label: 'Spanish',
              ),
            ),
          ],
      child: _ToolbarButton(
        icon: HugeIcons.strokeRoundedGlobe02,
        label: selectedLanguage.toUpperCase(),
        compact: compact,
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  const _MenuOption({required this.icon, required this.label});

  final List<List<dynamic>> icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LingoDeskIcon(icon, size: 18),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.compact = false,
  });

  final List<List<dynamic>> icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = _DashboardTokens.of(context);

    return Container(
      constraints: BoxConstraints(minWidth: compact ? 42 : 0),
      height: 42,
      padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 13),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LingoDeskIcon(icon, color: tokens.muted, size: 18),
          if (!compact) ...[
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ],
      ),
    );
  }
}
