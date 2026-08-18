import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/translation_entry.dart';

/// Data operations for an app's translation workspace.
abstract class TranslationRepository {
  Future<Either<Failure, List<TranslationEntry>>> getTranslations(String appId);

  /// Merges uploaded files into the stored entries (union of keys;
  /// uploaded values overwrite) and returns the merged list.
  ///
  /// [filesByLanguage] maps a language code to a flattened
  /// `dot.key -> value` map.
  Future<Either<Failure, List<TranslationEntry>>> importTranslations(
    String appId,
    Map<String, Map<String, String>> filesByLanguage,
  );

  Future<Either<Failure, void>> updateTranslation(
    String appId,
    String key,
    String language,
    String value,
  );

  /// Adds a new key with a value for [language] (usually the source).
  Future<Either<Failure, void>> addKey(
    String appId,
    String key,
    String language,
    String value,
  );

  Future<Either<Failure, void>> deleteKey(String appId, String key);

  /// Exports one nested JSON file per language via a save dialog.
  ///
  /// Returns the number of files actually saved (0 when canceled).
  Future<Either<Failure, int>> exportTranslations(
    String appId,
    List<String> languages,
  );
}
