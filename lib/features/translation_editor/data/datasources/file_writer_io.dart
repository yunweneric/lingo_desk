import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Writes [bytes] to [path] on IO platforms (desktop/mobile), creating
/// any missing parent directories first.
Future<void> writeBytes(String path, List<int> bytes) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
}

/// Absolute path of the user's Downloads folder.
///
/// `getDownloadsDirectory` covers macOS, Windows and Linux; the home
/// fallback is there for the platforms where it returns null rather than
/// leaving the export with nowhere to go.
Future<String?> downloadsDirectoryPath() async {
  try {
    final directory = await getDownloadsDirectory();
    if (directory != null) {
      return directory.path;
    }
    // Platforms without a Downloads folder throw UnsupportedError rather
    // than returning null, so Errors are caught here alongside
    // Exceptions before falling through to the home directory.
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {}

  final environment = Platform.environment;
  final home =
      Platform.isWindows ? environment['USERPROFILE'] : environment['HOME'];
  if (home == null || home.isEmpty) {
    return null;
  }
  return '$home${Platform.pathSeparator}Downloads';
}

/// Whether something already exists at [path].
Future<bool> pathExists(String path) async =>
    File(path).existsSync() || Directory(path).existsSync();
