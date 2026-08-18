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

  /// Adds a new key with its initial [values] (language code -> value);
  /// languages left out of the map stay missing.
  Future<Either<Failure, void>> addKey(
    String appId,
    String key,
    Map<String, String> values,
  );

  Future<Either<Failure, void>> deleteKey(String appId, String key);

  /// Bundles one nested JSON file per language into a single archive
  /// named [archiveName] and saves it via one save dialog.
  ///
  /// Returns the number of files bundled (0 when canceled).
  Future<Either<Failure, int>> exportTranslations(
    String appId,
    List<String> languages,
    String archiveName,
  );
}
