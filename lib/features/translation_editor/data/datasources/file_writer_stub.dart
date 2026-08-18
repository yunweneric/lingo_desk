/// No-op file writer used on platforms without `dart:io` (web).
///
/// On web, `FilePicker.saveFile` already downloads the provided bytes,
/// so nothing is written here.
Future<void> writeBytes(String path, List<int> bytes) async {}
