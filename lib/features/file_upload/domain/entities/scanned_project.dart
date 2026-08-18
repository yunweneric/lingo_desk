/// One language's worth of translations discovered inside a project
/// folder.
///
/// A language can come from several files when the project uses locale
/// directories (`translations/en/common.json`, `.../errors.json`); those
/// are merged into a single flat map.
class ScannedLanguageGroup {
  const ScannedLanguageGroup({
    required this.languageCode,
    required this.relativePaths,
    required this.translations,
    this.conflictCount = 0,
  });

  final String languageCode;

  /// Paths the group was built from, relative to the project root.
  final List<String> relativePaths;

  /// Merged flattened `dot.key -> value` content.
  final Map<String, String> translations;

  /// Keys that appeared in more than one merged file.
  final int conflictCount;

  int get keyCount => translations.length;

  /// Keys with a non-blank value.
  int get filledKeyCount =>
      translations.values.where((value) => value.trim().isNotEmpty).length;
}

/// A file the scan found but could not import, and why.
class SkippedScanFile {
  const SkippedScanFile({required this.relativePath, required this.reason});

  final String relativePath;
  final String reason;
}

/// The result of scanning a project folder for translation files.
class ScannedProject {
  const ScannedProject({
    required this.rootPath,
    required this.projectName,
    required this.groups,
    required this.skipped,
  });

  final String rootPath;

  /// Folder name, used as the name of the app the import creates.
  final String projectName;

  /// One entry per detected language, sorted by language code.
  final List<ScannedLanguageGroup> groups;

  final List<SkippedScanFile> skipped;

  bool get isEmpty => groups.isEmpty;

  List<String> get languages => [
    for (final group in groups) group.languageCode,
  ];

  /// Union of every key across all languages.
  Set<String> get allKeys => {
    for (final group in groups) ...group.translations.keys,
  };

  /// Language to preselect as the source: English when present,
  /// otherwise the language with the most keys.
  String get suggestedSource {
    if (groups.isEmpty) {
      return 'en';
    }
    if (languages.contains('en')) {
      return 'en';
    }
    final sorted = [...groups]
      ..sort((a, b) => b.keyCount.compareTo(a.keyCount));
    return sorted.first.languageCode;
  }

  ScannedLanguageGroup? groupFor(String languageCode) {
    for (final group in groups) {
      if (group.languageCode == languageCode) {
        return group;
      }
    }
    return null;
  }
}
