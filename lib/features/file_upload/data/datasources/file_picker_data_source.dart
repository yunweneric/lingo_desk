import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../../../../core/errors/exceptions.dart';

/// Raw picked file data (name + decoded text content).
class PickedFileData {
  const PickedFileData({required this.fileName, required this.content});

  final String fileName;
  final String content;
}

/// Wraps the `file_picker` plugin for multi-select JSON picking.
abstract class FilePickerDataSource {
  /// Returns the selected files, or an empty list when canceled.
  Future<List<PickedFileData>> pickJsonFiles();
}

class FilePickerDataSourceImpl implements FilePickerDataSource {
  const FilePickerDataSourceImpl();

  @override
  Future<List<PickedFileData>> pickJsonFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select translation files',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        allowMultiple: true,
        withData: true,
      );

      if (result == null) {
        return [];
      }

      final files = <PickedFileData>[];
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null) {
          continue;
        }
        files.add(
          PickedFileData(
            fileName: file.name,
            content: utf8.decode(bytes, allowMalformed: true),
          ),
        );
      }
      return files;
    } on Exception catch (e) {
      throw FileException('Could not open the file picker: $e');
    }
  }
}
