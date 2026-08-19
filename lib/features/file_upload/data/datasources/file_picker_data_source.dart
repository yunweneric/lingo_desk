import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../../../../core/errors/exceptions.dart';
import 'project_scanner_stub.dart'
    if (dart.library.io) 'project_scanner_io.dart';
import 'scanned_project_data.dart';
import '../../../../core/localization/export.dart';

/// Raw picked file data (name + decoded text content).
class PickedFileData {
  const PickedFileData({required this.fileName, required this.content});

  final String fileName;
  final String content;
}

/// Wraps the `file_picker` plugin for JSON picking and folder scanning.
abstract class FilePickerDataSource {
  /// Returns the selected files, or an empty list when canceled.
  Future<List<PickedFileData>> pickJsonFiles();

  /// Asks for a project folder and walks it for translation files.
  ///
  /// Returns `null` when the user cancels the folder picker.
  Future<ScannedProjectData?> pickProjectFolder();
}

class FilePickerDataSourceImpl implements FilePickerDataSource {
  const FilePickerDataSourceImpl();

  @override
  Future<List<PickedFileData>> pickJsonFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: LocaleKeys.uploadPickFilesTitle.tr(),
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
      throw FileException(
        LocaleKeys.errorsFilePickerOpen.tr(namedArgs: {'error': '$e'}),
      );
    }
  }

  @override
  Future<ScannedProjectData?> pickProjectFolder() async {
    final String? root;
    try {
      root = await FilePicker.platform.getDirectoryPath(
        dialogTitle: LocaleKeys.uploadPickFolderTitle.tr(),
      );
    } on Exception catch (e) {
      throw FileException(
        LocaleKeys.errorsFolderPickerOpen.tr(namedArgs: {'error': '$e'}),
      );
    }

    if (root == null || root.isEmpty) {
      return null;
    }

    try {
      return ScannedProjectData(
        rootPath: root,
        projectName: _folderName(root),
        files: await scanProjectDirectory(root),
      );
    } on Exception catch (e) {
      throw FileException(
        LocaleKeys.errorsProjectFolderRead.tr(namedArgs: {'error': '$e'}),
      );
    }
  }

  /// Last non-empty segment of [path], for either separator style.
  static String _folderName(String path) {
    final segments = path
        .split(RegExp(r'[/\\]'))
        .where((segment) => segment.isNotEmpty);
    return segments.isEmpty
        ? LocaleKeys.uploadDefaultImportName.tr()
        : segments.last;
  }
}
