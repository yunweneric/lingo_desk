import 'dart:convert';
import 'dart:io';

import 'scanned_project_data.dart';

/// Folder names that hold translation files. A file counts when any
/// segment of its path below the project root matches one of these,
/// which covers both `/translations` at the root and `*/translations`
/// nested anywhere in the tree.
const _translationDirs = {'translation', 'translations', 'languages'};

/// Directories never worth walking into. Dot-directories are skipped
/// separately.
const _ignoredDirs = {
  'node_modules',
  'build',
  'dist',
  'out',
  'coverage',
  'vendor',
  'Pods',
  '__pycache__',
  'venv',
};

/// How deep below the project root the walk goes.
const _maxDepth = 8;

/// Upper bound on files read, so picking a huge folder cannot hang the UI.
const _maxFiles = 500;

/// Walks [root] and returns every `.json` file that sits inside a
/// translation folder.
///
/// The walk is synchronous: it is bounded by [_maxDepth] and [_maxFiles]
/// and runs once per folder pick, so it stays well under a frame.
Future<List<RawScannedFile>> scanProjectDirectory(String root) async {
  final rootDir = Directory(root);
  if (!rootDir.existsSync()) {
    return const [];
  }

  final files = <RawScannedFile>[];
  _walk(rootDir, root, depth: 0, inTranslationDir: false, files: files);
  files.sort((a, b) => a.relativePath.compareTo(b.relativePath));
  return files;
}

void _walk(
  Directory dir,
  String root, {
  required int depth,
  required bool inTranslationDir,
  required List<RawScannedFile> files,
}) {
  if (depth > _maxDepth || files.length >= _maxFiles) {
    return;
  }

  final List<FileSystemEntity> entities;
  try {
    entities = dir.listSync(followLinks: false);
  } on FileSystemException {
    return; // Unreadable directory (permissions); skip it.
  }
  entities.sort((a, b) => a.path.compareTo(b.path));

  for (final entity in entities) {
    if (files.length >= _maxFiles) {
      return;
    }
    final name = _basename(entity.path);

    if (entity is Directory) {
      if (name.startsWith('.') || _ignoredDirs.contains(name)) {
        continue;
      }
      _walk(
        entity,
        root,
        depth: depth + 1,
        inTranslationDir:
            inTranslationDir || _translationDirs.contains(name.toLowerCase()),
        files: files,
      );
    } else if (entity is File) {
      if (!inTranslationDir || !name.toLowerCase().endsWith('.json')) {
        continue;
      }
      try {
        final bytes = entity.readAsBytesSync();
        files.add(
          RawScannedFile(
            relativePath: _relativeTo(root, entity.path),
            fileName: name,
            parentDirName: _basename(dir.path),
            content: utf8.decode(bytes, allowMalformed: true),
          ),
        );
      } on FileSystemException {
        continue; // Unreadable file; skip it.
      }
    }
  }
}

String _basename(String path) =>
    path.split(Platform.pathSeparator).where((part) => part.isNotEmpty).last;

String _relativeTo(String root, String path) {
  if (!path.startsWith(root)) {
    return path;
  }
  final relative = path.substring(root.length);
  return relative.startsWith(Platform.pathSeparator)
      ? relative.substring(1)
      : relative;
}
