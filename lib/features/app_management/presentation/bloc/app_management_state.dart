import '../../domain/entities/app_overview.dart';

abstract class AppManagementState {}

class AppManagementInitial extends AppManagementState {}

class AppManagementLoading extends AppManagementState {}

class AppManagementLoaded extends AppManagementState {
  AppManagementLoaded({required this.overviews, this.query = ''});

  /// All apps, sorted by most recent activity.
  final List<AppOverview> overviews;

  /// Current search query (matched against app names).
  final String query;

  /// Apps matching [query].
  List<AppOverview> get filteredOverviews {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return overviews;
    }
    return overviews
        .where((overview) => overview.app.name.toLowerCase().contains(needle))
        .toList();
  }

  int get totalKeys =>
      overviews.fold(0, (sum, overview) => sum + overview.keyCount);

  int get totalMissing =>
      overviews.fold(0, (sum, overview) => sum + overview.missingCount);

  int get totalCells =>
      overviews.fold(0, (sum, overview) => sum + overview.totalCells);

  /// Translation files across all apps (one JSON per language).
  int get totalFiles =>
      overviews.fold(0, (sum, overview) => sum + overview.fileCount);

  /// Translation files with no missing values.
  int get completeFiles =>
      overviews.fold(0, (sum, overview) => sum + overview.completeFileCount);

  /// Overall completion across every app's target cells.
  double get coverage {
    final cells = totalCells;
    if (cells == 0) {
      return 0;
    }
    return (cells - totalMissing) / cells;
  }

  /// Distinct target languages across all apps.
  Set<String> get activeLanguages =>
      overviews.expand((overview) => overview.app.targetLanguages).toSet();

  /// Aggregated per-language stats for the language health card,
  /// sorted by coverage ascending (weakest locale first).
  List<LanguageHealth> get languageHealth {
    final totals = <String, int>{};
    final missing = <String, int>{};

    for (final overview in overviews) {
      for (final language in overview.app.targetLanguages) {
        totals[language] = (totals[language] ?? 0) + overview.keyCount;
        missing[language] =
            (missing[language] ?? 0) +
            (overview.missingByLanguage[language] ?? 0);
      }
    }

    final stats = [
      for (final language in totals.keys)
        LanguageHealth(
          language: language,
          totalKeys: totals[language]!,
          missing: missing[language] ?? 0,
        ),
    ]..sort((a, b) => a.progress.compareTo(b.progress));
    return stats;
  }

  AppManagementLoaded copyWith({List<AppOverview>? overviews, String? query}) {
    return AppManagementLoaded(
      overviews: overviews ?? this.overviews,
      query: query ?? this.query,
    );
  }
}

class AppManagementError extends AppManagementState {
  AppManagementError(this.message);

  final String message;
}

/// Aggregated coverage stats for one target language across all apps.
class LanguageHealth {
  const LanguageHealth({
    required this.language,
    required this.totalKeys,
    required this.missing,
  });

  final String language;
  final int totalKeys;
  final int missing;

  double get progress {
    if (totalKeys == 0) {
      return 0;
    }
    return (totalKeys - missing) / totalKeys;
  }
}
