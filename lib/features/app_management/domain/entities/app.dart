/// A localization project ("App"): a group of translation files that
/// share one source language and a set of target languages.
class App {
  const App({
    required this.id,
    required this.name,
    required this.sourceLanguage,
    required this.targetLanguages,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String sourceLanguage;
  final List<String> targetLanguages;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Source language followed by the target languages.
  List<String> get allLanguages => [sourceLanguage, ...targetLanguages];
}
