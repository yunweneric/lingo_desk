/// A staged upload after validation and parsing.
///
/// When [error] is non-null the file cannot be imported; otherwise
/// [translations] holds the flattened `dot.key -> value` content.
class UploadedTranslationFile {
  const UploadedTranslationFile({
    required this.fileName,
    required this.languageCode,
    this.translations = const {},
    this.error,
  });

  final String fileName;
  final String languageCode;
  final Map<String, String> translations;
  final String? error;

  bool get isValid => error == null;

  int get keyCount => translations.length;
}
