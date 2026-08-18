/// One string handed to the model: the flattened key plus its source text.
///
/// The key travels with the text because the dot notation says where the
/// string sits in the UI (`apps.table.empty.title`), which is often the only
/// clue for disambiguating a short source string like "Open" or "Post".
class AiTranslationItem {
  const AiTranslationItem({required this.key, required this.sourceText});

  final String key;
  final String sourceText;
}
