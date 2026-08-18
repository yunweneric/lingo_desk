import '../../../app_management/domain/entities/app.dart';
import '../../domain/entities/translation_entry.dart';

/// Transient feedback surfaced by the editor (snackbars).
///
/// Compared by identity, so re-emitting a new instance always notifies.
class EditorNotice {
  const EditorNotice(this.message, {this.isError = false});

  final String message;
  final bool isError;
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
  });

  final App app;

  /// All entries, sorted by key.
  final List<TranslationEntry> entries;

  final bool showMissingOnly;
  final String query;
  final EditorNotice? notice;

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

  TranslationEditorLoaded copyWith({
    App? app,
    List<TranslationEntry>? entries,
    bool? showMissingOnly,
    String? query,
    EditorNotice? notice,
    bool clearNotice = false,
  }) {
    return TranslationEditorLoaded(
      app: app ?? this.app,
      entries: entries ?? this.entries,
      showMissingOnly: showMissingOnly ?? this.showMissingOnly,
      query: query ?? this.query,
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }
}

class TranslationEditorError extends TranslationEditorState {
  TranslationEditorError(this.message);

  final String message;
}
