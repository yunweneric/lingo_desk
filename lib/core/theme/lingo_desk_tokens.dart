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

/// The handful of things the app ever needs to say about an outcome.
///
/// One vocabulary shared by toasts, badges and inline banners, so a
/// success in a toast and a success in a table cell are the same green.
enum LingoDeskStatus { success, error, warning, info, neutral }

/// Colours for one [LingoDeskStatus] at the current brightness.
///
/// Light gets a soft tinted fill; dark gets a deep fill with a lifted
/// accent, because the literal status hues lose contrast on deep ink.
class LingoDeskStatusStyle {
  const LingoDeskStatusStyle({
    required this.accent,
    required this.fill,
    required this.border,
    required this.foreground,
  });

  /// Icons, emphasis, and the toast lifetime bar.
  final Color accent;

  /// Surface tint behind the content.
  final Color fill;

  /// Hairline around [fill].
  final Color border;

  /// Body text on [fill].
  final Color foreground;

  static LingoDeskStatusStyle of(
    BuildContext context,
    LingoDeskStatus status,
  ) => resolve(LingoDeskTokens.of(context), status);

  static LingoDeskStatusStyle resolve(
    LingoDeskTokens tokens,
    LingoDeskStatus status,
  ) {
    final isDark = tokens.isDark;
    switch (status) {
      case LingoDeskStatus.success:
        return LingoDeskStatusStyle(
          accent:
              isDark ? LingoDeskColors.successLift : LingoDeskColors.complete,
          fill:
              isDark
                  ? LingoDeskColors.successDeep
                  : LingoDeskColors.successSoft,
          border:
              isDark
                  ? LingoDeskColors.successDeepBorder
                  : LingoDeskColors.successSoftBorder,
          foreground: tokens.foreground,
        );
      case LingoDeskStatus.error:
        return LingoDeskStatusStyle(
          accent: isDark ? LingoDeskColors.errorLift : LingoDeskColors.error,
          fill: isDark ? LingoDeskColors.errorDeep : LingoDeskColors.errorSoft,
          border:
              isDark
                  ? LingoDeskColors.errorDeepBorder
                  : LingoDeskColors.errorSoftBorder,
          foreground: tokens.foreground,
        );
      case LingoDeskStatus.warning:
        return LingoDeskStatusStyle(
          accent:
              isDark ? LingoDeskColors.warningLift : LingoDeskColors.warning,
          fill:
              isDark
                  ? LingoDeskColors.warningDeep
                  : LingoDeskColors.warningSoft,
          border:
              isDark
                  ? LingoDeskColors.warningDeepBorder
                  : LingoDeskColors.warningSoftBorder,
          foreground: tokens.foreground,
        );
      case LingoDeskStatus.info:
        return LingoDeskStatusStyle(
          accent: isDark ? LingoDeskColors.infoLift : LingoDeskColors.brandTeal,
          fill:
              isDark
                  ? LingoDeskColors.brandTealDeep
                  : LingoDeskColors.brandTealSoft,
          border:
              isDark
                  ? LingoDeskColors.brandTealDeepBorder
                  : LingoDeskColors.brandTealSoftBorder,
          foreground: tokens.foreground,
        );
      case LingoDeskStatus.neutral:
        return LingoDeskStatusStyle(
          accent: tokens.muted,
          fill: tokens.card,
          border: tokens.border,
          foreground: tokens.foreground,
        );
    }
  }
}
