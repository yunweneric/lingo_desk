import 'package:flutter/material.dart';

class LingoDeskColors {
  const LingoDeskColors._();

  static const brandBlue = Color(0xFF0067CD);
  static const brandBlueSoft = Color(0xFFEAF4FF);
  static const ink = Color(0xFF030712);
  static const darkInk = Color(0xFF070B14);
  static const slate = Color(0xFF6B7280);
  static const slateLight = Color(0xFFCBD5E1);
  static const surface = Color(0xFFF9FAFB);
  static const darkSurface = Color(0xFF0D111B);
  static const missing = Color(0xFFFEF3C7);
  static const complete = Color(0xFF16A34A);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFB45309);
  static const border = Color(0xFFE5E7EB);
}

class LingoDeskTheme {
  const LingoDeskTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : LingoDeskColors.ink;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: LingoDeskColors.brandBlue,
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
      fontFamily: 'IBM Plex Sans',
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
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isDark ? Colors.white12 : LingoDeskColors.border,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor:
            isDark ? const Color(0xFF151B27) : LingoDeskColors.surface,
        selectedColor: LingoDeskColors.missing,
        side: BorderSide(
          color: isDark ? Colors.white12 : LingoDeskColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: TextStyle(
          color: isDark ? Colors.white : LingoDeskColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : LingoDeskColors.border,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LingoDeskColors.brandBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: textColor,
            displayColor: textColor,
            fontFamily: 'IBM Plex Sans',
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

  static const codeStyle = TextStyle(
    color: LingoDeskColors.ink,
    fontFamily: 'IBM Plex Mono',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
}
