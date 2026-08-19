import 'entities/scanned_project.dart';
import 'language_resolver.dart';
import 'usecases/parse_translation_file.dart';
import '../../../core/localization/export.dart';

/// A file waiting to be grouped: from a folder scan or picked by hand.
class GroupingCandidate {
  const GroupingCandidate({
    required this.displayPath,
    required this.fileName,
    required this.content,
    this.parentDirName = '',
  });

  /// What the preview shows — a project-relative path, or just the file
  /// name for hand-picked files.
  final String displayPath;

  final String fileName;

  /// Directory holding the file, so locale folders (`translations/en/`)
  /// resolve. Empty when the file was picked individually.
  final String parentDirName;

  final String content;
}

/// Accumulates translation files into one group per language.
///
/// Folder scans and hand-picked files both go through this, so a preview
/// built from a scan can be extended by picking more files (and the other
/// way round). Files that cannot be resolved to a supported language, or
/// that fail to parse, land in [skipped] instead of failing the batch.
class TranslationGrouper {
  TranslationGrouper(this._parse);

  final ParseTranslationFile _parse;

  final _translations = <String, Map<String, String>>{};
  final _paths = <String, List<String>>{};
  final _conflicts = <String, int>{};
  final _skipped = <SkippedScanFile>[];

  /// Restores previously grouped languages so a later batch merges into
  /// them rather than replacing them.
  void seed(Iterable<ScannedLanguageGroup> groups) {
    for (final group in groups) {
      _translations[group.languageCode] = {...group.translations};
      _paths[group.languageCode] = [...group.relativePaths];
      _conflicts[group.languageCode] = group.conflictCount;
    }
  }

  Future<void> add(GroupingCandidate candidate) async {
    final language = resolveLanguage(
      fileName: candidate.fileName,
      parentDirName: candidate.parentDirName,
    );

    if (language == null) {
      _skip(
        candidate.displayPath,
        LocaleKeys.errorsUnknownLanguage.tr(),
      );
      return;
    }

    final parsed = await _parse(
      ParseTranslationFileParams(content: candidate.content),
    );

    parsed.fold((failure) => _skip(candidate.displayPath, failure.message), (
      flat,
    ) {
      final target = _translations.putIfAbsent(language, () => {});
      final paths = _paths.putIfAbsent(language, () => []);

      // Already merged in an earlier batch; merging again would only
      // inflate the conflict count.
      if (paths.contains(candidate.displayPath)) {
        return;
      }

      var conflicts = _conflicts[language] ?? 0;
      flat.forEach((key, value) {
        if (target.containsKey(key)) {
          conflicts++;
        }
        target[key] = value;
      });
      _conflicts[language] = conflicts;
      paths.add(candidate.displayPath);
    });
  }

  List<ScannedLanguageGroup> get groups => [
    for (final language in _translations.keys)
      ScannedLanguageGroup(
        languageCode: language,
        relativePaths: _paths[language] ?? const [],
        translations: _translations[language]!,
        conflictCount: _conflicts[language] ?? 0,
      ),
  ]..sort((a, b) => a.languageCode.compareTo(b.languageCode));

  List<SkippedScanFile> get skipped => List.unmodifiable(_skipped);

  void _skip(String path, String reason) {
    _skipped.removeWhere((file) => file.relativePath == path);
    _skipped.add(SkippedScanFile(relativePath: path, reason: reason));
  }
}
