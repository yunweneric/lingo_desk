import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/errors/exceptions.dart';
import 'file_writer_stub.dart' if (dart.library.io) 'file_writer_io.dart';

/// Writes exported translation files to disk.
///
/// Three destinations, all fed the same `path -> nested JSON map` shape:
/// a zip in the Downloads folder, loose files under a folder, and the
/// folder picker that names the third one.
abstract class FileExportDataSource {
  /// Bundles [jsonFiles] (`en.json -> nested map`) into an archive named
  /// [fileName] in the user's Downloads folder.
  ///
  /// Returns the absolute path written. A name already taken gains a
  /// ` (2)` suffix rather than overwriting an earlier download.
  Future<String> saveZipToDownloads(
    String fileName,
    Map<String, Map<String, dynamic>> jsonFiles,
  );

  /// Writes each entry of [jsonFiles] (`relative path -> nested map`)
  /// under [rootPath], creating directories as needed.
  ///
  /// Returns the absolute paths written.
  Future<List<String>> writeJsonFiles(
    String rootPath,
    Map<String, Map<String, dynamic>> jsonFiles,
  );

  /// Asks for a destination folder, opening at [initialDirectory] when
  /// one is given. Returns null when the user cancels.
  Future<String?> pickDestinationFolder({String? initialDirectory});

  /// Shows [path] in the platform's file manager, so an export can be
  /// found without hunting for it.
  Future<void> revealLocation(String path);
}

class FileExportDataSourceImpl implements FileExportDataSource {
  const FileExportDataSourceImpl();

  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  Future<String> saveZipToDownloads(
    String fileName,
    Map<String, Map<String, dynamic>> jsonFiles,
  ) async {
    final downloads = await downloadsDirectoryPath();
    if (downloads == null) {
      throw const FileException(
        'Could not find your Downloads folder on this platform.',
      );
    }

    final archive = Archive();
    jsonFiles.forEach((entryName, json) {
      archive.addFile(ArchiveFile.bytes(entryName, _encode(json)));
    });
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));

    try {
      final path = await _freePath(_join(downloads, fileName));
      await writeBytes(path, bytes);
      return path;
    } on FileException {
      rethrow;
    } on Exception catch (e) {
      throw FileException('Could not save $fileName: $e');
    }
  }

  @override
  Future<List<String>> writeJsonFiles(
    String rootPath,
    Map<String, Map<String, dynamic>> jsonFiles,
  ) async {
    final written = <String>[];
    try {
      for (final file in jsonFiles.entries) {
        final path = _join(rootPath, file.key);
        await writeBytes(path, _encode(file.value));
        written.add(path);
      }
    } on Exception catch (e) {
      throw FileException('Could not write to $rootPath: $e');
    }
    return written;
  }

  @override
  Future<String?> pickDestinationFolder({String? initialDirectory}) async {
    try {
      final path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose where to export the translations',
        initialDirectory: initialDirectory,
      );
      return (path == null || path.isEmpty) ? null : path;
    } on Exception catch (e) {
      throw FileException('Could not open the folder picker: $e');
    }
  }

  @override
  Future<void> revealLocation(String path) async {
    try {
      await revealInFileManager(path);
    } on Exception catch (e) {
      throw FileException('Could not open $path: $e');
      // The web stub reports an unsupported platform as an Error rather
      // than an Exception, and it still belongs in the toast.
      // ignore: avoid_catching_errors
    } on UnsupportedError catch (e) {
      throw FileException(e.message ?? 'Not available on this platform.');
    }
  }

  /// Pretty-printed JSON with the trailing newline editors expect.
  List<int> _encode(Map<String, dynamic> json) =>
      utf8.encode('${_encoder.convert(json)}\n');

  /// [path], or the first ` (n)` variant of it that is free.
  ///
  /// Overwriting an earlier download silently is worse than handing back
  /// a suffixed name, so exports never clobber one another.
  Future<String> _freePath(String path) async {
    if (!await pathExists(path)) {
      return path;
    }
    final dot = path.lastIndexOf('.');
    final stem = dot == -1 ? path : path.substring(0, dot);
    final extension = dot == -1 ? '' : path.substring(dot);
    for (var index = 2; index < 100; index++) {
      final candidate = '$stem ($index)$extension';
      if (!await pathExists(candidate)) {
        return candidate;
      }
    }
    return path;
  }

  /// Joins a root and a relative path, normalising to `/` so a scanned
  /// Windows path and a fresh `<lang>.json` behave the same.
  static String _join(String root, String relative) {
    final trimmedRoot = root.replaceAll(RegExp(r'[/\\]+$'), '');
    final trimmedRelative = relative.replaceAll(RegExp(r'^[/\\]+'), '');
    return '$trimmedRoot/$trimmedRelative';
  }
}
