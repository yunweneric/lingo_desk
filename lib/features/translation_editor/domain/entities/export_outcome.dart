/// What an export actually did, so the editor can name it.
class ExportOutcome {
  const ExportOutcome({required this.location, required this.paths});

  /// Where the files landed: the archive path for a zip, the destination
  /// folder for a write.
  final String location;

  /// Absolute path of every file written.
  final List<String> paths;

  int get fileCount => paths.length;
}
