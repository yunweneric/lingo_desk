import 'scanned_project_data.dart';

/// No-op scanner for platforms without `dart:io` (web), where there is
/// no folder to walk.
Future<List<RawScannedFile>> scanProjectDirectory(String root) async =>
    const [];
