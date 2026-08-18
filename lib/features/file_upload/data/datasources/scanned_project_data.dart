/// A `.json` file found inside a project's translation folder.
class RawScannedFile {
  const RawScannedFile({
    required this.relativePath,
    required this.fileName,
    required this.parentDirName,
    required this.content,
  });

  /// Path below the project root, e.g. `src/translations/en/common.json`.
  final String relativePath;

  final String fileName;

  /// Name of the directory holding the file, used to resolve locale
  /// folders like `translations/en/`.
  final String parentDirName;

  /// Raw UTF-8 decoded file content.
  final String content;
}

/// Everything the folder picker + scanner learned about a project.
class ScannedProjectData {
  const ScannedProjectData({
    required this.rootPath,
    required this.projectName,
    required this.files,
  });

  final String rootPath;

  /// Folder name of [rootPath].
  final String projectName;

  final List<RawScannedFile> files;
}
