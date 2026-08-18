import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LingoDesk palette — teal rebrand (Aug 2026).
///
/// One saturated accent (`brandTeal`), warm stone neutrals, literal
/// status colors, and deep teal-ink stage surfaces. Values mirror the
/// design system's `tokens/colors.css`.
class LingoDeskColors {
  const LingoDeskColors._();

  static const brandTeal = Color(0xFF0F766E);
  static const brandTealSoft = Color(0xFFE7F3F0);
  static const brandTealSoftBorder = Color(0xFFCFE6E0);
  static const ink = Color(0xFF1C1917);
  static const darkInk = Color(0xFF0E1B18); // deep-ink stage pane
  static const slate = Color(0xFF78716C);
  static const slateLight = Color(0xFFD6D3D1);
  static const surface = Color(0xFFFAFAF9);
  static const darkSurface = Color(0xFF16241F); // deep-surface
  static const sidebarDeep = Color(0xFF0C1714);
  static const activeLight = Color(0xFFF0EFEC);
  static const activeDeep = Color(0xFF1C2B26);
  static const missing = Color(0xFFFEF3C7);
  static const complete = Color(0xFF15803D);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFB45309);
  static const border = Color(0xFFE7E5E4);
}

class LingoDeskTheme {
  const LingoDeskTheme._();

  /// 12px does almost all the work; 8px nested, 16px dialogs/hero panes.
  static const radius = 12.0;
  static const radiusSm = 8.0;
  static const radiusLg = 16.0;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : LingoDeskColors.ink;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: LingoDeskColors.brandTeal,
      onPrimary: Colors.white,
      secondary: isDark ? Colors.white : LingoDeskColors.ink,
      onSecondary: isDark ? LingoDeskColors.ink : Colors.white,
      error: LingoDeskColors.error,
      onError: Colors.white,
      surface: isDark ? LingoDeskColors.darkSurface : Colors.white,
      onSurface: isDark ? Colors.white : LingoDeskColors.ink,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor:
          isDark ? LingoDeskColors.darkInk : LingoDeskColors.surface,
      fontFamily: GoogleFonts.urbanist().fontFamily,
      textTheme: GoogleFonts.urbanistTextTheme(),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? LingoDeskColors.darkInk : Colors.white,
        foregroundColor: isDark ? Colors.white : LingoDeskColors.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? LingoDeskColors.darkSurface : Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: isDark ? Colors.white12 : LingoDeskColors.border,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor:
            isDark ? LingoDeskColors.activeDeep : LingoDeskColors.surface,
        selectedColor: LingoDeskColors.brandTealSoft,
        side: BorderSide(
          color: isDark ? Colors.white12 : LingoDeskColors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.white : LingoDeskColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: isDark ? LingoDeskColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(
            color: isDark ? Colors.white12 : LingoDeskColors.border,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : LingoDeskColors.border,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LingoDeskColors.brandTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : LingoDeskColors.ink,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(
            color: isDark ? Colors.white24 : LingoDeskColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        selectionColor: LingoDeskColors.brandTealSoft,
        cursorColor: LingoDeskColors.brandTeal,
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: textColor,
            displayColor: textColor,
            fontFamily: GoogleFonts.urbanist().fontFamily,
          )
          .copyWith(
            headlineLarge: TextStyle(
              color: textColor,
              fontSize: 40,
              height: 1.05,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            headlineMedium: TextStyle(
              color: textColor,
              fontSize: 30,
              height: 1.12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            titleLarge: TextStyle(
              color: textColor,
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            bodyLarge: TextStyle(
              color: textColor,
              fontSize: 16,
              height: 1.55,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
            bodyMedium: TextStyle(
              color: textColor,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
            labelLarge: TextStyle(
              color: textColor,
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
    );
  }

  /// Machine strings: Space Mono ships 400/700 only — bold it is.
  static const codeStyle = TextStyle(
    color: LingoDeskColors.ink,
    fontFamily: 'Space Mono',
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
}
