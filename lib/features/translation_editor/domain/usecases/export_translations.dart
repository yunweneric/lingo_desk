import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/translation_repository.dart';

class ExportTranslationsParams {
  const ExportTranslationsParams({
    required this.appId,
    required this.languages,
    required this.archiveName,
  });

  final String appId;
  final List<String> languages;

  /// File name of the archive, e.g. `customer-portal-translations.zip`.
  final String archiveName;
}

/// Exports the selected languages as one zip of nested JSON files.
///
/// Returns the number of files bundled (0 when the user cancels).
class ExportTranslations implements UseCase<int, ExportTranslationsParams> {
  ExportTranslations(this.repository);

  final TranslationRepository repository;

  @override
  Future<Either<Failure, int>> call(ExportTranslationsParams params) {
    if (params.languages.isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure(message: 'Select at least one language to export.'),
        ),
      );
    }
    return repository.exportTranslations(
      params.appId,
      params.languages,
      params.archiveName,
    );
  }
}

/// Turns an app name into a safe archive file name.
///
/// `Customer Portal` -> `customer-portal-translations.zip`.
String archiveNameFor(String appName) {
  final slug = appName
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
  return slug.isEmpty ? 'translations.zip' : '$slug-translations.zip';
}
