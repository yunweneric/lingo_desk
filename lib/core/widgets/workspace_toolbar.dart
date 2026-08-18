import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/lingo_desk_tokens.dart';
import 'lingo_desk_icon.dart';

/// Bordered 42px control used for header toolbar affordances.
class WorkspaceToolbarButton extends StatelessWidget {
  const WorkspaceToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    this.compact = false,
  });

  final List<List<dynamic>> icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Container(
      constraints: BoxConstraints(minWidth: compact ? 42 : 0),
      height: 42,
      padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 13),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(12),
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

/// Icon + label row used inside popup menus.
class WorkspaceMenuOption extends StatelessWidget {
  const WorkspaceMenuOption({
    super.key,
    required this.icon,
    required this.label,
  });

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

/// Quick System/Light/Dark switch for page headers. The full control
/// lives on the settings page.
class ThemeModeSwitcher extends StatelessWidget {
  const ThemeModeSwitcher({
    super.key,
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
              child: WorkspaceMenuOption(
                icon: HugeIcons.strokeRoundedComputerSettings,
                label: 'System',
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.light,
              child: WorkspaceMenuOption(
                icon: HugeIcons.strokeRoundedSun03,
                label: 'Light',
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: WorkspaceMenuOption(
                icon: HugeIcons.strokeRoundedMoon02,
                label: 'Dark',
              ),
            ),
          ],
      child: WorkspaceToolbarButton(
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
