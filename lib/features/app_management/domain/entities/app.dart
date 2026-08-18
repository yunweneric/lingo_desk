/// A localization project ("App"): a group of translation files that
/// share one source language and a set of target languages.
class App {
  const App({
    required this.id,
    required this.name,
    required this.sourceLanguage,
    required this.targetLanguages,
    required this.createdAt,
    required this.updatedAt,
    this.iconImage,
    this.projectPath,
    this.languageFiles = const {},
  });

  final String id;
  final String name;
  final String sourceLanguage;
  final List<String> targetLanguages;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The app's icon as a base64-encoded PNG, or null when it has none.
  ///
  /// Stored with the app rather than as a path so the icon survives the
  /// picked file being moved or deleted. Null is the normal case, and
  /// the UI falls back to [initials].
  final String? iconImage;

  /// Absolute path of the project folder this app was imported from, or
  /// null when it was created by hand.
  ///
  /// Kept so an export can write the translations straight back into the
  /// codebase they came from instead of asking where to put them.
  final String? projectPath;

  /// Language code -> path below [projectPath] of the file that language
  /// was read from, e.g. `{'en': 'src/translations/en.json'}`.
  ///
  /// A language merged from several files is recorded as one
  /// `<lang>.json` in the directory those files shared. Languages added
  /// after the import have no entry and fall back to `<lang>.json`.
  final Map<String, String> languageFiles;

  /// Whether an export can write back to disk without asking for a folder.
  bool get hasProject => (projectPath ?? '').isNotEmpty;

  /// Where [language] is written on a save back to the project.
  String projectFileFor(String language) =>
      languageFiles[language] ?? '$language.json';

  /// Source language followed by the target languages.
  List<String> get allLanguages => [sourceLanguage, ...targetLanguages];

  /// Letters shown in place of a missing icon.
  String get initials => appInitialsFor(name);
}

/// Up to two uppercase letters standing in for a missing icon: the first
/// letter of the first two words, or the first two letters of a single
/// word.
///
/// Takes a raw name rather than an [App] so the settings form can preview
/// the badge while the name is still being typed.
String appInitialsFor(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) {
    return '?';
  }
  if (words.length == 1) {
    final word = words.first;
    return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
  }
  return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
}
