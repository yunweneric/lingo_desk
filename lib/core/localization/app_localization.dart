import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../constants/languages.dart';

/// The app's single entry point to `easy_localization`.
///
/// Nothing outside this folder imports the package directly: call sites use
/// [LocaleKeys] constants with the `.tr()` extension from `translate.dart`,
/// and locale switching goes through [AppLocalization.setLocale]. Keeping the
/// dependency behind one wrapper means a future move to another i18n backend
/// touches these files only.
class AppLocalization {
  const AppLocalization._();

  /// Folder holding one `<code>.json` per locale, declared as an asset in
  /// `pubspec.yaml`.
  static const String translationsPath = 'assets/translations';

  /// English is the source language: every key exists here, so any gap in
  /// another locale renders English rather than a raw key.
  static const Locale fallbackLocale = Locale('en');

  /// The languages LingoDesk's own interface is available in — one entry
  /// per `<code>.json` under [translationsPath]. Adding a file here without
  /// adding its code means nobody can pick it; adding a code without the
  /// file means picking it silently falls back to English. Keep them
  /// together.
  ///
  /// This is deliberately narrower than [SupportedLanguages], which lists
  /// what *your* app can be translated into: LingoDesk can help you ship
  /// Hindi without speaking Hindi itself.
  static const List<String> interfaceLanguages = [
    'en',
    'fr',
    'es',
    'de',
    'it',
    'pt',
    'nl',
    'pl',
    'uk',
    'ru',
    'tr',
    'ar',
    'zh',
    'ja',
    'ko',
    'sv',
    'cs',
    'ro',
  ];

  /// The same list as [LanguageOption]s, for the pickers that draw a flag
  /// and a name beside each choice.
  static List<LanguageOption> get interfaceLanguageOptions => [
    for (final option in SupportedLanguages.all)
      if (interfaceLanguages.contains(option.code)) option,
  ];

  /// One [Locale] per shipped translation file, so the pickers and the
  /// localization delegates can never drift apart.
  static List<Locale> get supportedLocales => [
    for (final code in interfaceLanguages) Locale(code),
  ];

  /// Must be awaited before `runApp` — it restores the saved locale,
  /// prepares the asset loader, and loads the date symbols every supported
  /// locale needs in order to format a date.
  static Future<void> ensureInitialized() async {
    await easy.EasyLocalization.ensureInitialized();
    initializeDateFormatting();
  }

  /// Wraps [child] with the localization scope. [startLocale] pins the
  /// initial language (the product passes its persisted UI language);
  /// leaving it null lets the device locale decide.
  static Widget wrap({required Widget child, Locale? startLocale}) {
    return easy.EasyLocalization(
      supportedLocales: supportedLocales,
      path: translationsPath,
      fallbackLocale: fallbackLocale,
      startLocale: startLocale,
      useFallbackTranslations: true,
      child: child,
    );
  }

  /// Delegates and locale for `MaterialApp`. Spread as
  /// `localizationsDelegates: AppLocalization.delegatesOf(context)`.
  static List<LocalizationsDelegate<dynamic>> delegatesOf(
    BuildContext context,
  ) => easy.EasyLocalization.of(context)!.delegates;

  static List<Locale> supportedLocalesOf(BuildContext context) =>
      easy.EasyLocalization.of(context)!.supportedLocales;

  /// The active locale. Reading it also records it for [formatDate] and
  /// the other helpers that have no [BuildContext] to ask.
  static Locale localeOf(BuildContext context) {
    final locale = easy.EasyLocalization.of(context)!.locale;
    _activeLocale = locale;
    return locale;
  }

  static Locale _activeLocale = fallbackLocale;

  /// Locale used by the context-free helpers below. Kept in step by
  /// [localeOf] (which the root `MaterialApp` reads on every build) and by
  /// [setLocale].
  static Locale get activeLocale => _activeLocale;

  /// `12 Aug 2026` in English, and the equivalent ordering and month name
  /// in every other locale.
  static String formatDate(DateTime date) => DateFormat.yMMMd(
    _activeLocale.toLanguageTag(),
  ).format(date.toLocal());

  /// `12 Aug 2026, 14:05`.
  static String formatDateTime(DateTime date) => DateFormat.yMMMd(
    _activeLocale.toLanguageTag(),
  ).add_Hm().format(date.toLocal());

  /// Digit grouping in the active locale, e.g. `1,024` or `1 024`.
  static String formatNumber(num value) =>
      NumberFormat.decimalPattern(_activeLocale.toLanguageTag()).format(value);

  /// Switches the interface language. [code] is a language code from
  /// [SupportedLanguages]; unknown codes are ignored so a stale preference
  /// can't throw.
  static Future<void> setLocale(BuildContext context, String code) async {
    if (!interfaceLanguages.contains(code)) {
      return;
    }
    _activeLocale = Locale(code);
    await easy.EasyLocalization.of(context)!.setLocale(_activeLocale);
  }

  /// Language code currently in effect, e.g. `fr`.
  static String languageCodeOf(BuildContext context) =>
      localeOf(context).languageCode;

  /// Right-to-left locales among the supported set. Flutter derives text
  /// direction from the locale itself; this is for the few places that need
  /// to mirror a layout decision explicitly.
  static const Set<String> rtlLanguages = {'ar'};

  static bool isRtl(BuildContext context) =>
      rtlLanguages.contains(languageCodeOf(context));
}
