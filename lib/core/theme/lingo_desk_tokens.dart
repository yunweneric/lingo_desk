import 'package:flutter/material.dart';

import 'lingo_desk_theme.dart';

/// Semantic color tokens derived from the current theme brightness.
///
/// Light is the brand's primary chassis; dark maps to the design
/// system's deep teal-ink stage values.
class LingoDeskTokens {
  const LingoDeskTokens({
    required this.isDark,
    required this.background,
    required this.sidebar,
    required this.card,
    required this.border,
    required this.foreground,
    required this.muted,
    required this.active,
  });

  final bool isDark;
  final Color background;
  final Color sidebar;
  final Color card;
  final Color border;
  final Color foreground;
  final Color muted;
  final Color active;

  static LingoDeskTokens of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LingoDeskTokens(
      isDark: isDark,
      background: isDark ? LingoDeskColors.darkInk : LingoDeskColors.surface,
      sidebar: isDark ? LingoDeskColors.sidebarDeep : Colors.white,
      card: isDark ? LingoDeskColors.darkSurface : Colors.white,
      border: isDark ? Colors.white12 : LingoDeskColors.border,
      foreground: isDark ? Colors.white : LingoDeskColors.ink,
      muted: isDark ? Colors.white70 : LingoDeskColors.slate,
      active: isDark ? LingoDeskColors.activeDeep : LingoDeskColors.activeLight,
    );
  }
}
