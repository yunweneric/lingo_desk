import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/export_outcome.dart';
import '../repositories/translation_repository.dart';
import '../../../../core/localization/export.dart';

class ExportToDownloadsParams {
  const ExportToDownloadsParams({
    required this.appId,
    required this.languages,
    required this.archiveName,
  });

  final String appId;
  final List<String> languages;

  /// File name of the archive, e.g. `customer-portal-translations.zip`.
  final String archiveName;
}

/// Exports the selected languages as one zip in the Downloads folder.
class ExportTranslationsToDownloads
    implements UseCase<ExportOutcome, ExportToDownloadsParams> {
  ExportTranslationsToDownloads(this.repository);

  final TranslationRepository repository;

  @override
  Future<Either<Failure, ExportOutcome>> call(ExportToDownloadsParams params) {
    final invalid = _validateLanguages(params.languages);
    if (invalid != null) {
      return Future.value(Left(invalid));
    }
    return repository.exportZipToDownloads(
      params.appId,
      params.languages,
      params.archiveName,
    );
  }
}

class ExportToFolderParams {
  const ExportToFolderParams({
    required this.appId,
    required this.languages,
    required this.rootPath,
    this.languageFiles = const {},
  });

  final String appId;
  final List<String> languages;

  /// Folder the files are written under: the remembered project root for
  /// a save back to the project, or the folder the user just picked.
  final String rootPath;

  /// Language code -> path below [rootPath]. Empty for a plain folder
  /// export, where every language lands at `<lang>.json`.
  final Map<String, String> languageFiles;
}

/// Writes the selected languages as loose JSON files under a folder.
///
/// Backs both exports that touch a folder: saving to the imported
/// project passes its remembered layout, picking a destination passes
/// none.
class ExportTranslationsToFolder
    implements UseCase<ExportOutcome, ExportToFolderParams> {
  ExportTranslationsToFolder(this.repository);

  final TranslationRepository repository;

  @override
  Future<Either<Failure, ExportOutcome>> call(ExportToFolderParams params) {
    final invalid = _validateLanguages(params.languages);
    if (invalid != null) {
      return Future.value(Left(invalid));
    }
    if (params.rootPath.trim().isEmpty) {
      return Future.value(
        Left(
          ValidationFailure(message: LocaleKeys.errorsChooseFolder.tr()),
        ),
      );
    }
    return repository.exportToFolder(
      params.appId,
      params.languages,
      params.rootPath,
      params.languageFiles,
    );
  }
}

class PickExportFolderParams {
  const PickExportFolderParams({this.initialDirectory});

  /// Folder the picker opens at — the app's project when it has one.
  final String? initialDirectory;
}

/// Asks where an export should go. Returns null when canceled.
class PickExportFolder implements UseCase<String?, PickExportFolderParams> {
  PickExportFolder(this.repository);

  final TranslationRepository repository;

  @override
  Future<Either<Failure, String?>> call(PickExportFolderParams params) {
    return repository.pickExportFolder(
      initialDirectory: params.initialDirectory,
    );
  }
}

/// Shows a finished export's location in the file manager.
class RevealExportLocation implements UseCase<void, String> {
  RevealExportLocation(this.repository);

  final TranslationRepository repository;

  @override
  Future<Either<Failure, void>> call(String path) =>
      repository.revealExportLocation(path);
}

Failure? _validateLanguages(List<String> languages) {
  if (languages.isEmpty) {
    return ValidationFailure(message: LocaleKeys.errorsSelectLanguage.tr());
  }
  return null;
}

/// Turns an app name into a safe archive file name.
///
/// `Customer Portal` -> `customer-portal-translations.zip`.
String archiveNameFor(String appName) {
  final slug = appName
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'translations.zip' : '$slug-translations.zip';
}
