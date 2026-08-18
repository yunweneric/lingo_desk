/// A language option selectable as source or target locale.
class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
  });

  final String code;
  final String name;

  /// Emoji flag of a representative country for the language.
  final String flag;
}

/// Locales offered in the app settings screens.
class SupportedLanguages {
  const SupportedLanguages._();

  static const all = [
    LanguageOption(code: 'en', name: 'English', flag: '🇬🇧'),
    LanguageOption(code: 'fr', name: 'French', flag: '🇫🇷'),
    LanguageOption(code: 'es', name: 'Spanish', flag: '🇪🇸'),
    LanguageOption(code: 'de', name: 'German', flag: '🇩🇪'),
    LanguageOption(code: 'it', name: 'Italian', flag: '🇮🇹'),
    LanguageOption(code: 'pt', name: 'Portuguese', flag: '🇵🇹'),
    LanguageOption(code: 'nl', name: 'Dutch', flag: '🇳🇱'),
    LanguageOption(code: 'pl', name: 'Polish', flag: '🇵🇱'),
    LanguageOption(code: 'uk', name: 'Ukrainian', flag: '🇺🇦'),
    LanguageOption(code: 'ru', name: 'Russian', flag: '🇷🇺'),
    LanguageOption(code: 'tr', name: 'Turkish', flag: '🇹🇷'),
    LanguageOption(code: 'ar', name: 'Arabic', flag: '🇸🇦'),
    LanguageOption(code: 'zh', name: 'Chinese', flag: '🇨🇳'),
    LanguageOption(code: 'ja', name: 'Japanese', flag: '🇯🇵'),
    LanguageOption(code: 'ko', name: 'Korean', flag: '🇰🇷'),
    LanguageOption(code: 'hi', name: 'Hindi', flag: '🇮🇳'),
    LanguageOption(code: 'sv', name: 'Swedish', flag: '🇸🇪'),
    LanguageOption(code: 'cs', name: 'Czech', flag: '🇨🇿'),
    LanguageOption(code: 'ro', name: 'Romanian', flag: '🇷🇴'),
    LanguageOption(code: 'vi', name: 'Vietnamese', flag: '🇻🇳'),
  ];

  /// Whether [code] is one of the supported locales.
  static bool supports(String code) {
    return all.any((option) => option.code == code);
  }

  /// Display name for a language code, falling back to the code itself.
  static String nameOf(String code) {
    for (final option in all) {
      if (option.code == code) {
        return option.name;
      }
    }
    return code;
  }

  /// Emoji flag for a language code; a globe when the code is unknown.
  static String flagOf(String code) {
    for (final option in all) {
      if (option.code == code) {
        return option.flag;
      }
    }
    return '🌐';
  }
}
