import 'app.dart';

/// Dashboard summary of an [App] combined with its translation stats.
class AppOverview {
  const AppOverview({
    required this.app,
    required this.keyCount,
    required this.missingCount,
    required this.missingByLanguage,
    required this.lastActivity,
  });

  final App app;

  /// Number of translation keys in the app.
  final int keyCount;

  /// Number of empty target-language cells across all keys.
  final int missingCount;

  /// Empty cells per target language code.
  final Map<String, int> missingByLanguage;

  /// Most recent of metadata update and translation edit.
  final DateTime lastActivity;

  /// Total target cells (keys x target languages).
  int get totalCells => keyCount * app.targetLanguages.length;

  /// Completion ratio in `[0, 1]`; 0 when the app has no keys yet.
  double get progress {
    if (totalCells == 0) {
      return 0;
    }
    return (totalCells - missingCount) / totalCells;
  }

  bool get isComplete => keyCount > 0 && missingCount == 0;

  /// Translation files the app exports: one JSON per language, source
  /// included.
  int get fileCount => app.allLanguages.length;

  /// Files with no empty values. The source file is always complete once
  /// the app has keys; an app without keys has nothing to export.
  int get completeFileCount {
    if (keyCount == 0) {
      return 0;
    }
    final completeTargets = app.targetLanguages.where(
      (language) => (missingByLanguage[language] ?? 0) == 0,
    );
    return 1 + completeTargets.length;
  }
}
