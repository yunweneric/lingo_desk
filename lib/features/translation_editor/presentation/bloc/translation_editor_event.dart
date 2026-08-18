abstract class TranslationEditorEvent {}

/// Loads the app and its translation entries into the workspace.
class LoadEditorEvent extends TranslationEditorEvent {
  LoadEditorEvent(this.appId);

  final String appId;
}

/// Updates one cell (key + language) with a new value.
class UpdateCellEvent extends TranslationEditorEvent {
  UpdateCellEvent({
    required this.key,
    required this.language,
    required this.value,
  });

  final String key;
  final String language;
  final String value;
}

/// Adds a new key across all languages.
class AddKeyEvent extends TranslationEditorEvent {
  AddKeyEvent({required this.key, this.sourceValue = ''});

  final String key;
  final String sourceValue;
}

/// Deletes a key across all languages.
class DeleteKeyEvent extends TranslationEditorEvent {
  DeleteKeyEvent(this.key);

  final String key;
}

/// Toggles the "show missing only" filter.
class ToggleMissingOnlyEvent extends TranslationEditorEvent {}

/// Filters rows by key or value text.
class SearchKeysEvent extends TranslationEditorEvent {
  SearchKeysEvent(this.query);

  final String query;
}

/// Exports the selected languages as one zip of nested JSON files.
class ExportTranslationsEvent extends TranslationEditorEvent {
  ExportTranslationsEvent(this.languages);

  final List<String> languages;
}
