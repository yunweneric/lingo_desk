import '../language_resolver.dart';

/// Raw file returned by the platform file picker.
class PickedTranslationFile {
  const PickedTranslationFile({required this.fileName, required this.content});

  final String fileName;

  /// Raw UTF-8 decoded file content.
  final String content;

  /// Language code inferred from the file name (`en.json` -> `en`).
  String get inferredLanguage => languageStemOf(fileName);
}
