/// A language option selectable as source or target locale.
class LanguageOption {
  const LanguageOption({required this.code, required this.name});

  final String code;
  final String name;
}

/// Locales offered in the app settings screens.
class SupportedLanguages {
  const SupportedLanguages._();

  static const all = [
    LanguageOption(code: 'en', name: 'English'),
    LanguageOption(code: 'fr', name: 'French'),
    LanguageOption(code: 'es', name: 'Spanish'),
    LanguageOption(code: 'de', name: 'German'),
    LanguageOption(code: 'it', name: 'Italian'),
    LanguageOption(code: 'pt', name: 'Portuguese'),
    LanguageOption(code: 'nl', name: 'Dutch'),
    LanguageOption(code: 'pl', name: 'Polish'),
    LanguageOption(code: 'uk', name: 'Ukrainian'),
    LanguageOption(code: 'ru', name: 'Russian'),
    LanguageOption(code: 'tr', name: 'Turkish'),
    LanguageOption(code: 'ar', name: 'Arabic'),
    LanguageOption(code: 'zh', name: 'Chinese'),
    LanguageOption(code: 'ja', name: 'Japanese'),
    LanguageOption(code: 'ko', name: 'Korean'),
    LanguageOption(code: 'hi', name: 'Hindi'),
    LanguageOption(code: 'sv', name: 'Swedish'),
    LanguageOption(code: 'cs', name: 'Czech'),
    LanguageOption(code: 'ro', name: 'Romanian'),
    LanguageOption(code: 'vi', name: 'Vietnamese'),
  ];

  /// Display name for a language code, falling back to the code itself.
  static String nameOf(String code) {
    for (final option in all) {
      if (option.code == code) {
        return option.name;
      }
    }
    return code;
  }
}
