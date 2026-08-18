import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/translation_entry.dart';
import '../repositories/translation_repository.dart';

class SaveTranslationsParams {
  const SaveTranslationsParams({
    required this.appId,
    required this.filesByLanguage,
  });

  final String appId;

  /// Language code -> flattened `dot.key -> value` map.
  final Map<String, Map<String, String>> filesByLanguage;
}

/// Merges uploaded translation files into the app's stored entries.
class SaveTranslations
    implements UseCase<List<TranslationEntry>, SaveTranslationsParams> {
  SaveTranslations(this.repository);

  final TranslationRepository repository;

  @override
  Future<Either<Failure, List<TranslationEntry>>> call(
    SaveTranslationsParams params,
  ) {
    if (params.filesByLanguage.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'No files to import.')),
      );
    }
    return repository.importTranslations(params.appId, params.filesByLanguage);
  }
}
