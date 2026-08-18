import '../../domain/entities/translation_entry.dart';

class TranslationEntryModel extends TranslationEntry {
  const TranslationEntryModel({required super.key, required super.values});

  factory TranslationEntryModel.fromEntity(TranslationEntry entry) {
    return TranslationEntryModel(key: entry.key, values: entry.values);
  }

  /// Builds a model from one entry of the stored blob:
  /// `key -> {language: value}`.
  factory TranslationEntryModel.fromJson(
    String key,
    Map<String, dynamic> json,
  ) {
    return TranslationEntryModel(
      key: key,
      values: json.map(
        (language, value) => MapEntry(language, value?.toString() ?? ''),
      ),
    );
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(values);
}
