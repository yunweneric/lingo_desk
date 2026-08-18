import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/translation_repository.dart';

class ExportTranslationsParams {
  const ExportTranslationsParams({
    required this.appId,
    required this.languages,
  });

  final String appId;
  final List<String> languages;
}

/// Exports the selected languages as nested JSON files.
///
/// Returns the number of files actually saved (0 when the user cancels).
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
    return repository.exportTranslations(params.appId, params.languages);
  }
}
