import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/export_outcome.dart';
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

  /// Bundles one nested JSON file per language into an archive named
  /// [archiveName] in the user's Downloads folder.
  Future<Either<Failure, ExportOutcome>> exportZipToDownloads(
    String appId,
    List<String> languages,
    String archiveName,
  );

  /// Writes one nested JSON file per language under [rootPath].
  ///
  /// [languageFiles] gives the path below [rootPath] for a language, so
  /// a save back to an imported project lands on the files it came from.
  /// Languages missing from it are written as `<lang>.json` in the root.
  Future<Either<Failure, ExportOutcome>> exportToFolder(
    String appId,
    List<String> languages,
    String rootPath,
    Map<String, String> languageFiles,
  );

  /// Asks for a destination folder, opening at [initialDirectory] when
  /// one is given. Returns null when the user cancels.
  Future<Either<Failure, String?>> pickExportFolder({String? initialDirectory});
}
