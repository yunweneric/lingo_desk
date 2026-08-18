import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'lingo_desk_motion.dart';
import 'lingo_desk_palette.dart';
import 'lingo_desk_tokens.dart';

/// Status colours — the one part of the palette that does *not* follow the
/// chosen theme variant. A failure is red and a complete language is green
/// in all six looks; only the brand roles change, and those live on
/// [LingoDeskPalette] / [LingoDeskTokens].
class LingoDeskColors {
  const LingoDeskColors._();

  static const missing = Color(0xFFFEF3C7);
  static const complete = Color(0xFF15803D);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFB45309);

  // Status tints. Each status carries a soft fill and hairline for the
  // light chassis, a deep fill and hairline for the dark stage, and a
  // lifted accent bright enough to stay legible against that deep fill —
  // the literal `complete`/`error`/`warning` hues go muddy on dark ink.
  static const successSoft = Color(0xFFE8F3EB);
  static const successSoftBorder = Color(0xFFC6E2D0);
  static const successDeep = Color(0xFF10301E);
  static const successDeepBorder = Color(0xFF2E7D4F);
  static const successLift = Color(0xFF4ADE80);

  static const errorSoft = Color(0xFFFDECEC);
  static const errorSoftBorder = Color(0xFFF6CFCF);
  static const errorDeep = Color(0xFF351A1A);
  static const errorDeepBorder = Color(0xFF9B3A3A);
  static const errorLift = Color(0xFFF87171);

  static const warningSoft = Color(0xFFFDF2E3);
  static const warningSoftBorder = Color(0xFFF0D9B4);
  static const warningDeep = Color(0xFF33240F);
  static const warningDeepBorder = Color(0xFF8E5F1E);
  static const warningLift = Color(0xFFFBBF24);
}

class LingoDeskTheme {
  const LingoDeskTheme._();

  /// 12px does almost all the work; 8px nested, 16px dialogs/hero panes.
  static const radius = 12.0;
  static const radiusSm = 8.0;
  static const radiusLg = 16.0;

  static ThemeData light(LingoDeskPalette palette) =>
      _build(Brightness.light, palette);

  static ThemeData dark(LingoDeskPalette palette) =>
      _build(Brightness.dark, palette);

  static ThemeData _build(Brightness brightness, LingoDeskPalette palette) {
    final isDark = brightness == Brightness.dark;
    final t = LingoDeskTokens(palette: palette, isDark: isDark);
    // Urbanist is the app's only family — declared once, here.
    final urbanist = GoogleFonts.urbanist();
    final textColor = t.foreground;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: t.brand,
      onPrimary: t.onBrand,
      secondary: t.foreground,
      onSecondary: t.background,
      error: LingoDeskColors.error,
      onError: Colors.white,
      surface: t.card,
      onSurface: t.foreground,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: t.background,
      fontFamily: urbanist.fontFamily,
      fontFamilyFallback: urbanist.fontFamilyFallback,
      textTheme: GoogleFonts.urbanistTextTheme(),
      // Carried on the theme so LingoDeskTokens.of(context) — and every
      // widget through it — resolves the palette the user picked.
      extensions: [palette],
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? t.background : t.card,
        foregroundColor: t.foreground,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: t.card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: t.border),
        ),
      ),
      // Round, so every checkbox in the app reads as one family with the
      // radios and the selection dots instead of a stray square.
      checkboxTheme: base.checkboxTheme.copyWith(
        shape: const CircleBorder(),
        side: BorderSide(color: isDark ? Colors.white38 : t.border, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (!states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return states.contains(WidgetState.disabled)
              ? t.brand.withValues(alpha: 0.4)
              : t.brand;
        }),
        checkColor: WidgetStatePropertyAll(t.onBrand),
      ),
      chipTheme: base.chipTheme.copyWith(
        // Resolved per state so selected chips stay legible in both
        // brightnesses: a tinted fill with brand ink in light, a deep
        // brand fill with a lifted ink in dark.
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return t.brandFill;
          }
          if (states.contains(WidgetState.disabled)) {
            return isDark ? t.card : t.background;
          }
          return isDark ? t.active : t.card;
        }),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide(color: t.brandFillBorder);
          }
          return BorderSide(
            color: states.contains(WidgetState.disabled)
                ? (isDark ? Colors.white10 : t.border)
                : (isDark ? Colors.white24 : t.border),
          );
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        checkmarkColor: t.onBrandFill,
        labelStyle: GoogleFonts.urbanist(
          color: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return t.onBrandFill;
            }
            if (states.contains(WidgetState.disabled)) {
              return t.muted;
            }
            return t.foreground;
          }),
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: t.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: t.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),
      // Primary actions pick up a soft brand glow under the pointer and
      // settle flat again when pressed.
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: t.brand,
              foregroundColor: t.onBrand,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
              textStyle: GoogleFonts.urbanist(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
              animationDuration: LingoDeskMotion.fast,
            ).copyWith(
              elevation: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled) ||
                    states.contains(WidgetState.pressed)) {
                  return 0.0;
                }
                return states.contains(WidgetState.hovered) ? 4.0 : 0.0;
              }),
              shadowColor: WidgetStatePropertyAll(
                t.brand.withValues(alpha: 0.5),
              ),
            ),
      ),
      // Secondary actions answer the pointer by taking on the brand
      // border instead of changing weight or size.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: t.foreground,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
              textStyle: GoogleFonts.urbanist(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
              animationDuration: LingoDeskMotion.fast,
            ).copyWith(
              side: WidgetStateBorderSide.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return BorderSide(color: isDark ? Colors.white10 : t.border);
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused) ||
                    states.contains(WidgetState.pressed)) {
                  return BorderSide(color: t.accent);
                }
                return BorderSide(color: isDark ? Colors.white24 : t.border);
              }),
            ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: isDark ? t.active : t.foreground,
          borderRadius: BorderRadius.circular(radiusSm),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.transparent,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: GoogleFonts.urbanist(
          color: isDark ? Colors.white : t.background,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: t.brandFill,
        cursorColor: t.accent,
      ),
      textTheme: base.textTheme
          .copyWith(
            headlineLarge: GoogleFonts.urbanist(
              color: textColor,
              fontSize: 40,
              height: 1.05,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            headlineMedium: GoogleFonts.urbanist(
              color: textColor,
              fontSize: 30,
              height: 1.12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            titleLarge: GoogleFonts.urbanist(
              color: textColor,
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            bodyLarge: GoogleFonts.urbanist(
              color: textColor,
              fontSize: 16,
              height: 1.55,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
            bodyMedium: GoogleFonts.urbanist(
              color: textColor,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
            labelLarge: GoogleFonts.urbanist(
              color: textColor,
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          )
          // Applied last so every style above — and every style the
          // Material defaults bring along — resolves to Urbanist.
          .apply(
            bodyColor: textColor,
            displayColor: textColor,
            fontFamily: urbanist.fontFamily,
            fontFamilyFallback: urbanist.fontFamilyFallback,
          ),
    );
  }

  /// Machine strings: same Urbanist family as everything else, set bold
  /// and small so keys still read as machine text. No colour — it
  /// inherits the surrounding text colour, which is what keeps keys
  /// legible across all six variants in both brightnesses.
  static TextStyle codeStyle = GoogleFonts.urbanist(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
}
