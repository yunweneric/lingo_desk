import 'package:flutter/material.dart';

import 'lingo_desk_palette.dart';
import 'lingo_desk_theme.dart';

/// Semantic colour tokens for the active theme variant and brightness.
///
/// Resolved from the [LingoDeskPalette] carried on [ThemeData], so
/// switching variants in Settings → Appearance repaints every widget
/// that reads tokens — which is all of them.
class LingoDeskTokens {
  const LingoDeskTokens({required this.palette, required this.isDark})
    : _scheme = isDark ? palette.dark : palette.light;

  final LingoDeskPalette palette;
  final bool isDark;
  final LingoDeskScheme _scheme;

  LingoDeskThemeVariant get variant => palette.variant;

  /// The always-dark scheme, for panes that stay dark in both modes
  /// (the onboarding stage).
  LingoDeskScheme get darkStage => palette.dark;

  Color get brand => _scheme.brand;
  Color get onBrand => _scheme.onBrand;
  Color get accent => _scheme.accent;
  Color get brandFill => _scheme.brandFill;
  Color get brandFillBorder => _scheme.brandFillBorder;
  Color get onBrandFill => _scheme.onBrandFill;
  Color get background => _scheme.background;
  Color get sidebar => _scheme.sidebar;
  Color get card => _scheme.card;
  Color get border => _scheme.border;
  Color get foreground => _scheme.foreground;
  Color get muted => _scheme.muted;
  Color get active => _scheme.active;

  static LingoDeskTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return LingoDeskTokens(
      // A theme built outside LingoDeskTheme (a bare MaterialApp in a
      // widget preview) carries no extension — fall back to the house look.
      palette: theme.extension<LingoDeskPalette>() ?? LingoDeskPalettes.teal,
      isDark: theme.brightness == Brightness.dark,
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
/// Success/error/warning are variant-independent — a failure is red in
/// every palette — while info follows the active brand.
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
          accent: isDark
              ? LingoDeskColors.successLift
              : LingoDeskColors.complete,
          fill: isDark
              ? LingoDeskColors.successDeep
              : LingoDeskColors.successSoft,
          border: isDark
              ? LingoDeskColors.successDeepBorder
              : LingoDeskColors.successSoftBorder,
          foreground: tokens.foreground,
        );
      case LingoDeskStatus.error:
        return LingoDeskStatusStyle(
          accent: isDark ? LingoDeskColors.errorLift : LingoDeskColors.error,
          fill: isDark ? LingoDeskColors.errorDeep : LingoDeskColors.errorSoft,
          border: isDark
              ? LingoDeskColors.errorDeepBorder
              : LingoDeskColors.errorSoftBorder,
          foreground: tokens.foreground,
        );
      case LingoDeskStatus.warning:
        return LingoDeskStatusStyle(
          accent: isDark ? LingoDeskColors.warningLift : LingoDeskColors.warning,
          fill: isDark
              ? LingoDeskColors.warningDeep
              : LingoDeskColors.warningSoft,
          border: isDark
              ? LingoDeskColors.warningDeepBorder
              : LingoDeskColors.warningSoftBorder,
          foreground: tokens.foreground,
        );
      case LingoDeskStatus.info:
        return LingoDeskStatusStyle(
          accent: tokens.accent,
          fill: tokens.brandFill,
          border: tokens.brandFillBorder,
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
