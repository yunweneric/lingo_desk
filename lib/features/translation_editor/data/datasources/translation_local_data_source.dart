import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/exceptions.dart';

/// Local storage for an app's translation entries.
///
/// The stored blob has the shape:
/// ```json
/// {
///   "lastModified": "2026-08-18T10:00:00.000",
///   "entries": {"nav.home": {"en": "Home", "fr": "Accueil"}}
/// }
/// ```
abstract class TranslationLocalDataSource {
  /// Returns `key -> {language: value}` for the app (empty when none).
  Future<Map<String, Map<String, String>>> getEntries(String appId);

  /// Replaces the stored entries and refreshes `lastModified`.
  Future<void> saveEntries(
    String appId,
    Map<String, Map<String, String>> entries,
  );
}

class TranslationLocalDataSourceImpl implements TranslationLocalDataSource {
  const TranslationLocalDataSourceImpl({required this.preferences});

  final SharedPreferences preferences;

  @override
  Future<Map<String, Map<String, String>>> getEntries(String appId) async {
    final raw = preferences.getString(StorageKeys.translations(appId));
    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final blob = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final entriesJson = Map<String, dynamic>.from(
        blob['entries'] as Map? ?? {},
      );
      return entriesJson.map((key, value) {
        final values = Map<String, dynamic>.from(value as Map);
        return MapEntry(
          key,
          values.map(
            (language, cell) => MapEntry(language, cell?.toString() ?? ''),
          ),
        );
      });
    } on FormatException catch (e) {
      throw CacheException('Stored translations are corrupted: ${e.message}');
    }
  }

  @override
  Future<void> saveEntries(
    String appId,
    Map<String, Map<String, String>> entries,
  ) async {
    final blob = {
      'lastModified': DateTime.now().toIso8601String(),
      'entries': entries,
    };
    final saved = await preferences.setString(
      StorageKeys.translations(appId),
      jsonEncode(blob),
    );
    if (!saved) {
      throw const CacheException('Could not write translations to storage.');
    }
  }
}
