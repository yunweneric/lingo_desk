import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/lingo_desk_motion.dart';
import '../theme/lingo_desk_theme.dart';
import '../theme/lingo_desk_tokens.dart';
import 'lingo_desk_animations.dart';
import 'lingo_desk_icon.dart';
import 'lingo_desk_menu.dart';

/// Bordered 42px control used for header toolbar affordances.
///
/// It sits inside a popup trigger rather than a real button, so it draws
/// its own hover state: the border picks up the brand colour and the icon
/// comes up with it, matching what an [OutlinedButton] beside it does.
class WorkspaceToolbarButton extends StatefulWidget {
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
  State<WorkspaceToolbarButton> createState() => _WorkspaceToolbarButtonState();
}

class _WorkspaceToolbarButtonState extends State<WorkspaceToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final compact = widget.compact;
    final accent = _hovered ? LingoDeskColors.brandTeal : tokens.muted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: LingoDeskMotion.fast,
        curve: LingoDeskMotion.curve,
        constraints: BoxConstraints(minWidth: compact ? 42 : 0),
        height: 42,
        padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 13),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? LingoDeskColors.brandTeal : tokens.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The icon swaps whenever the value behind it changes (theme
            // mode, mostly); cross-fading keeps that from reading as a
            // glitch.
            AnimatedTint(
              color: accent,
              builder:
                  (context, tint) => AnimatedSwitcher(
                    duration: LingoDeskMotion.standard,
                    switchInCurve: LingoDeskMotion.curve,
                    transitionBuilder:
                        (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.7,
                              end: 1,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                    child: LingoDeskIcon(
                      widget.icon,
                      key: ValueKey<String>(widget.label),
                      color: tint,
                      size: 18,
                    ),
                  ),
            ),
            if (!compact) ...[
              const SizedBox(width: 8),
              // Deliberately not animated: this button opens a menu, and a
              // trigger whose width glides drags every neighbouring header
              // button sideways while you are aiming at one.
              Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ],
        ),
      ),
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
    return LingoDeskMenuButton<ThemeMode>(
      tooltip: 'Theme',
      selectedValue: themeMode,
      menuWidth: 180,
      onSelected: onChanged,
      items: const [
        LingoDeskMenuItem(
          value: ThemeMode.system,
          label: 'System',
          icon: HugeIcons.strokeRoundedComputerSettings,
        ),
        LingoDeskMenuItem(
          value: ThemeMode.light,
          label: 'Light',
          icon: HugeIcons.strokeRoundedSun03,
        ),
        LingoDeskMenuItem(
          value: ThemeMode.dark,
          label: 'Dark',
          icon: HugeIcons.strokeRoundedMoon02,
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
