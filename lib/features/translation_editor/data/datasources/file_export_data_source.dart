import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/errors/exceptions.dart';
import 'file_writer_stub.dart' if (dart.library.io) 'file_writer_io.dart';

/// Saves exported JSON files via the platform save dialog
/// (a download on web).
abstract class FileExportDataSource {
  /// Returns `true` when the file was saved, `false` when the user
  /// canceled the dialog.
  Future<bool> saveJsonFile(String fileName, Map<String, dynamic> json);
}

class FileExportDataSourceImpl implements FileExportDataSource {
  const FileExportDataSourceImpl();

  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  Future<bool> saveJsonFile(String fileName, Map<String, dynamic> json) async {
    final bytes = Uint8List.fromList(
      utf8.encode('${_encoder.convert(json)}\n'),
    );

    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export $fileName',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['json'],
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
