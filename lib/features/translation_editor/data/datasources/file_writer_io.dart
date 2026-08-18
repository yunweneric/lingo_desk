import 'dart:io';

/// Writes [bytes] to [path] on IO platforms (desktop/mobile), where
/// `FilePicker.saveFile` returns the chosen path without writing.
Future<void> writeBytes(String path, List<int> bytes) async {
  await File(path).writeAsBytes(bytes, flush: true);
}
