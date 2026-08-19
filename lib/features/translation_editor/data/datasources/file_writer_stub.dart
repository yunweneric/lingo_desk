import '../../../../core/localization/export.dart';

/// No-op file writer used on platforms without `dart:io` (web).
///
/// Nothing on web can be written to a path, so the export data source
/// reports the platform as unsupported rather than silently doing
/// nothing.
Future<void> writeBytes(String path, List<int> bytes) async {}

/// Web has no Downloads path to write to.
Future<String?> downloadsDirectoryPath() async => null;

Future<bool> pathExists(String path) async => false;

/// Web has no file manager to show a path in.
Future<void> revealInFileManager(String path) async {
  throw UnsupportedError(LocaleKeys.errorsRevealUnsupported.tr());
}
