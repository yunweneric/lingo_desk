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

/// Adds a new key across all languages, with an optional initial value
/// per language code.
class AddKeyEvent extends TranslationEditorEvent {
  AddKeyEvent({required this.key, this.values = const {}});

  final String key;
  final Map<String, String> values;
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

/// Exports the selected languages as one zip in the Downloads folder.
class ExportToDownloadsEvent extends TranslationEditorEvent {
  ExportToDownloadsEvent(this.languages);

  final List<String> languages;
}

/// Writes the selected languages back into the project the app was
/// imported from, over the files they came from.
class ExportToProjectEvent extends TranslationEditorEvent {
  ExportToProjectEvent(this.languages);

  final List<String> languages;
}

/// Asks for a destination folder, then writes one `<lang>.json` per
/// selected language into it.
class ExportToFolderEvent extends TranslationEditorEvent {
  ExportToFolderEvent(this.languages);

  final List<String> languages;
}

/// Fills one missing cell with an AI translation.
class AiTranslateCellEvent extends TranslationEditorEvent {
  AiTranslateCellEvent({required this.key, required this.language});

  final String key;
  final String language;
}

/// Fills every missing cell in [languages] with AI translations.
///
/// One language for a progress-tile action, all targets for the toolbar
/// action; [keys] narrows the pass to a single row when set.
class AiTranslateEvent extends TranslationEditorEvent {
  AiTranslateEvent(this.languages, {this.keys});

  final List<String> languages;
  final Set<String>? keys;
}

/// Stops the running AI pass after the batch in flight.
class CancelAiTranslationEvent extends TranslationEditorEvent {}
