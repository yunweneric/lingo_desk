import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'lingo_desk_motion.dart';

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
  static const brandTealDeep = Color(0xFF14433D); // dark-mode selected fill
  static const brandTealDeepBorder = Color(0xFF2A7F73);
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

  /// Info borrows the brand teal wholesale; only the dark-stage accent
  /// needs its own value.
  static const infoLift = Color(0xFF5EEAD4);
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
    // Urbanist is the app's only family — declared once, here.
    final urbanist = GoogleFonts.urbanist();
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
      scaffoldBackgroundColor: isDark
          ? LingoDeskColors.darkInk
          : LingoDeskColors.surface,
      fontFamily: urbanist.fontFamily,
      fontFamilyFallback: urbanist.fontFamilyFallback,
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
      // Round, so every checkbox in the app reads as one family with the
      // radios and the selection dots instead of a stray square.
      checkboxTheme: base.checkboxTheme.copyWith(
        shape: const CircleBorder(),
        side: BorderSide(
          color: isDark ? Colors.white38 : LingoDeskColors.border,
          width: 1.4,
        ),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (!states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return states.contains(WidgetState.disabled)
              ? LingoDeskColors.brandTeal.withValues(alpha: 0.4)
              : LingoDeskColors.brandTeal;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
      ),
      chipTheme: base.chipTheme.copyWith(
        // Resolved per state so selected chips stay legible in both
        // brightnesses: a mint fill with teal ink in light, a deep teal
        // fill with mint ink in dark.
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark
                ? LingoDeskColors.brandTealDeep
                : LingoDeskColors.brandTealSoft;
          }
          if (states.contains(WidgetState.disabled)) {
            return isDark
                ? LingoDeskColors.darkSurface
                : LingoDeskColors.surface;
          }
          return isDark ? LingoDeskColors.activeDeep : Colors.white;
        }),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide(
              color: isDark
                  ? LingoDeskColors.brandTealDeepBorder
                  : LingoDeskColors.brandTealSoftBorder,
            );
          }
          return BorderSide(
            color: states.contains(WidgetState.disabled)
                ? (isDark ? Colors.white10 : LingoDeskColors.border)
                : (isDark ? Colors.white24 : LingoDeskColors.border),
          );
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        checkmarkColor: isDark
            ? LingoDeskColors.brandTealSoft
            : LingoDeskColors.brandTeal,
        labelStyle: GoogleFonts.urbanist(
          color: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark
                  ? LingoDeskColors.brandTealSoft
                  : LingoDeskColors.brandTeal;
            }
            if (states.contains(WidgetState.disabled)) {
              return isDark ? Colors.white38 : LingoDeskColors.slate;
            }
            return isDark ? Colors.white : LingoDeskColors.ink;
          }),
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
      // Primary actions pick up a soft teal glow under the pointer and
      // settle flat again when pressed.
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: LingoDeskColors.brandTeal,
              foregroundColor: Colors.white,
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
                LingoDeskColors.brandTeal.withValues(alpha: 0.5),
              ),
            ),
      ),
      // Secondary actions answer the pointer by taking on the brand
      // border instead of changing weight or size.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : LingoDeskColors.ink,
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
                  return BorderSide(
                    color: isDark ? Colors.white10 : LingoDeskColors.border,
                  );
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused) ||
                    states.contains(WidgetState.pressed)) {
                  return const BorderSide(color: LingoDeskColors.brandTeal);
                }
                return BorderSide(
                  color: isDark ? Colors.white24 : LingoDeskColors.border,
                );
              }),
            ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: isDark ? LingoDeskColors.activeDeep : LingoDeskColors.ink,
          borderRadius: BorderRadius.circular(radiusSm),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.transparent,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: GoogleFonts.urbanist(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        selectionColor: LingoDeskColors.brandTealSoft,
        cursorColor: LingoDeskColors.brandTeal,
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
  /// and small so keys still read as machine text.
  static TextStyle codeStyle = GoogleFonts.urbanist(
    color: LingoDeskColors.ink,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
}
