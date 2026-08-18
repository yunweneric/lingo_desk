import '../../../../core/widgets/lingo_desk_toast.dart';
import '../../../app_management/domain/entities/app.dart';
import '../../domain/entities/translation_entry.dart';

/// A running AI translation pass over the grid.
///
/// Progress is counted in cells rather than requests, because that is what
/// the grid shows: the tally lines up with the missing counts in the language
/// tiles as they fall.
class AiJob {
  const AiJob({
    required this.total,
    required this.label,
    this.pendingCells = const {},
    this.completed = 0,
    this.failed = 0,
    this.isCanceling = false,
    this.lastError,
  });

  /// Cells currently in flight, as `<key>::<language>` — the grid uses this
  /// to put a spinner on exactly the cells being written.
  final Set<String> pendingCells;

  final int completed;
  final int failed;
  final int total;

  /// What the banner names as the target: a language, or "3 languages".
  final String label;

  final bool isCanceling;

  /// Why the most recent batch failed, carried into the closing summary so
  /// the run reports a reason and not just a count.
  final String? lastError;

  int get settled => completed + failed;

  double get progress => total == 0 ? 0 : settled / total;

  static String cellId(String key, String language) => '$key::$language';

  bool isPending(String key, String language) =>
      pendingCells.contains(cellId(key, language));

  AiJob copyWith({
    Set<String>? pendingCells,
    int? completed,
    int? failed,
    int? total,
    String? label,
    bool? isCanceling,
    String? lastError,
  }) {
    return AiJob(
      pendingCells: pendingCells ?? this.pendingCells,
      completed: completed ?? this.completed,
      failed: failed ?? this.failed,
      total: total ?? this.total,
      label: label ?? this.label,
      isCanceling: isCanceling ?? this.isCanceling,
      lastError: lastError ?? this.lastError,
    );
  }
}

abstract class TranslationEditorState {}

class TranslationEditorInitial extends TranslationEditorState {}

class TranslationEditorLoading extends TranslationEditorState {}

class TranslationEditorLoaded extends TranslationEditorState {
  TranslationEditorLoaded({
    required this.app,
    required this.entries,
    this.showMissingOnly = false,
    this.query = '',
    this.notice,
    this.aiJob,
    this.isExporting = false,
  });

  final App app;

  /// All entries, sorted by key.
  final List<TranslationEntry> entries;

  final bool showMissingOnly;
  final String query;
  final ToastNotice? notice;

  /// The AI pass currently filling cells, or null when none is running.
  final AiJob? aiJob;

  /// True while an export is picking a folder or writing files, so a
  /// second click cannot start one on top of it.
  final bool isExporting;

  /// Rows after applying search + missing-only filters.
  List<TranslationEntry> get filteredEntries {
    final needle = query.trim().toLowerCase();
    return entries.where((entry) {
      if (showMissingOnly && !entry.isMissingForAny(app.targetLanguages)) {
        return false;
      }
      if (needle.isEmpty) {
        return true;
      }
      if (entry.key.toLowerCase().contains(needle)) {
        return true;
      }
      return entry.values.values.any(
        (value) => value.toLowerCase().contains(needle),
      );
    }).toList();
  }

  /// Completion ratio for one language across all keys.
  double completionFor(String language) {
    if (entries.isEmpty) {
      return 0;
    }
    final translated =
        entries.where((entry) => !entry.isMissingFor(language)).length;
    return translated / entries.length;
  }

  int missingCountFor(String language) =>
      entries.where((entry) => entry.isMissingFor(language)).length;

  /// Total empty target cells.
  int get totalMissing => app.targetLanguages.fold(
    0,
    (sum, language) => sum + missingCountFor(language),
  );

  /// Missing target cells that the AI could fill: the source value has to
  /// exist for there to be anything to translate from.
  int get translatableMissing {
    var count = 0;
    for (final entry in entries) {
      if (entry.valueFor(app.sourceLanguage).trim().isEmpty) {
        continue;
      }
      for (final language in app.targetLanguages) {
        if (entry.isMissingFor(language)) {
          count++;
        }
      }
    }
    return count;
  }

  /// Same count, for one language.
  int translatableMissingFor(String language) {
    return entries
        .where(
          (entry) =>
              entry.isMissingFor(language) &&
              entry.valueFor(app.sourceLanguage).trim().isNotEmpty,
        )
        .length;
  }

  TranslationEditorLoaded copyWith({
    App? app,
    List<TranslationEntry>? entries,
    bool? showMissingOnly,
    String? query,
    ToastNotice? notice,
    bool clearNotice = false,
    AiJob? aiJob,
    bool clearAiJob = false,
    bool? isExporting,
  }) {
    return TranslationEditorLoaded(
      app: app ?? this.app,
      entries: entries ?? this.entries,
      showMissingOnly: showMissingOnly ?? this.showMissingOnly,
      query: query ?? this.query,
      notice: clearNotice ? null : (notice ?? this.notice),
      aiJob: clearAiJob ? null : (aiJob ?? this.aiJob),
      isExporting: isExporting ?? this.isExporting,
    );
  }
}

class TranslationEditorError extends TranslationEditorState {
  TranslationEditorError(this.message);

  final String message;
}
