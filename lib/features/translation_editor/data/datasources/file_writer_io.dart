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

/// Shows [path] in the platform's file manager.
///
/// A file is revealed with its folder open around it where the platform
/// can do that; a folder is simply opened.
Future<void> revealInFileManager(String path) async {
  final isDirectory = Directory(path).existsSync();

  if (Platform.isMacOS) {
    await _run('open', isDirectory ? [path] : ['-R', path]);
    return;
  }
  if (Platform.isWindows) {
    // Explorer reports failure even when it worked, so its exit code is
    // not worth reading; the comma in `/select,` is part of the flag.
    await Process.run('explorer', [
      if (!isDirectory) '/select,$path' else path,
    ]);
    return;
  }
  // xdg-open cannot select a file, so a file opens the folder holding it.
  await _run('xdg-open', [isDirectory ? path : _parentOf(path)]);
}

Future<void> _run(String executable, List<String> arguments) async {
  final ProcessResult result;
  try {
    result = await Process.run(executable, arguments);
  } on ProcessException catch (e) {
    throw FileSystemException('Could not launch $executable: ${e.message}');
  }
  if (result.exitCode != 0) {
    throw FileSystemException(
      '$executable failed: ${result.stderr}'.trim(),
      arguments.last,
    );
  }
}

/// The directory holding [path], or [path] itself when it has no parent.
String _parentOf(String path) {
  final index = path.lastIndexOf(Platform.pathSeparator);
  return index <= 0 ? path : path.substring(0, index);
}
