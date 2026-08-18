import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/errors/exceptions.dart';
import 'file_writer_stub.dart' if (dart.library.io) 'file_writer_io.dart';

/// Saves the exported JSON files as one `.zip` via the platform save
/// dialog (a download on web).
abstract class FileExportDataSource {
  /// Bundles [jsonFiles] (`en.json -> nested map`) into a single archive
  /// named [fileName].
  ///
  /// Returns `true` when the archive was saved, `false` when the user
  /// canceled the dialog.
  Future<bool> saveZipFile(
    String fileName,
    Map<String, Map<String, dynamic>> jsonFiles,
  );
}

class FileExportDataSourceImpl implements FileExportDataSource {
  const FileExportDataSourceImpl();

  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  Future<bool> saveZipFile(
    String fileName,
    Map<String, Map<String, dynamic>> jsonFiles,
  ) async {
    final archive = Archive();
    jsonFiles.forEach((entryName, json) {
      final bytes = utf8.encode('${_encoder.convert(json)}\n');
      archive.addFile(ArchiveFile.bytes(entryName, bytes));
    });

    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));

    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export $fileName',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        bytes: bytes,
      );

      if (path == null) {
        return false;
      }

      // Desktop save dialogs return the path without writing the bytes.
      if (!kIsWeb) {
        await writeBytes(path, bytes);
      }
      return true;
    } on Exception catch (e) {
      throw FileException('Could not save $fileName: $e');
    }
  }
}
