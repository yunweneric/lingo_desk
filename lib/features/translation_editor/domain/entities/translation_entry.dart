/// One translation key with its value in every language.
///
/// [values] maps a language code to the translated string; a missing or
/// empty value means the key is untranslated for that language.
class TranslationEntry {
  const TranslationEntry({required this.key, required this.values});

  final String key;
  final Map<String, String> values;

  String valueFor(String language) => values[language] ?? '';

  bool isMissingFor(String language) => valueFor(language).trim().isEmpty;

  /// True when any of [languages] has no value yet.
  bool isMissingForAny(Iterable<String> languages) =>
      languages.any(isMissingFor);

  TranslationEntry copyWithValue(String language, String value) {
    return TranslationEntry(key: key, values: {...values, language: value});
  }
}
