import 'entities/scanned_project.dart';

/// Where an import's translation files sat on disk.
///
/// Kept on the created app so an export can write the translations back
/// into the codebase they came from instead of asking for a destination.
class ProjectSource {
  const ProjectSource({required this.rootPath, required this.languageFiles});

  /// Absolute path of the folder that was scanned.
  final String rootPath;

  /// Language code -> path below [rootPath] to write that language to.
  final Map<String, String> languageFiles;
}

/// Works out where each of [included] should be written back to.
///
/// A language read from a single file keeps that exact path, so the
/// round trip lands on the file the project already has. A language
/// merged from several files cannot be split back apart, so it collapses
/// to one `<lang>.json` in the deepest directory those files shared —
/// which keeps locale folders (`locales/en/`) intact.
///
/// Returns null when there is no folder to write back to, i.e. the files
/// were picked by hand rather than scanned.
ProjectSource? projectSourceFrom(
  ScannedProject project,
  Iterable<ScannedLanguageGroup> included,
) {
  if (project.rootPath.isEmpty) {
    return null;
  }

  final languageFiles = <String, String>{};
  for (final group in included) {
    final paths = group.relativePaths;
    if (paths.isEmpty) {
      continue;
    }
    if (paths.length == 1) {
      languageFiles[group.languageCode] = paths.first;
      continue;
    }
    final directory = _commonDirectory(paths);
    languageFiles[group.languageCode] = directory.isEmpty
        ? '${group.languageCode}.json'
        : '$directory/${group.languageCode}.json';
  }

  return ProjectSource(
    rootPath: project.rootPath,
    languageFiles: languageFiles,
  );
}

/// The deepest directory every path in [paths] sits under, as a
/// `/`-joined relative path (empty when they share none).
String _commonDirectory(List<String> paths) {
  List<String>? common;
  for (final path in paths) {
    final segments = _segmentsOf(path);
    // Drop the file name; only the directories can be shared.
    final directories = segments.sublist(0, segments.length - 1);
    if (common == null) {
      common = directories;
      continue;
    }
    var shared = 0;
    while (shared < common.length &&
        shared < directories.length &&
        common[shared] == directories[shared]) {
      shared++;
    }
    common = common.sublist(0, shared);
  }
  return (common ?? const []).join('/');
}

/// Splits a relative path on either separator style, dropping empties.
List<String> _segmentsOf(String path) => path
    .split(RegExp(r'[/\\]'))
    .where((segment) => segment.isNotEmpty)
    .toList();
