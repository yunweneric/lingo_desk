import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/translation_repository.dart';

class UpdateTranslationParams {
  const UpdateTranslationParams({
    required this.appId,
    required this.key,
    required this.language,
    required this.value,
  });

  final String appId;
  final String key;
  final String language;
  final String value;
}

/// Updates one translation cell (key + language).
class UpdateTranslation implements UseCase<void, UpdateTranslationParams> {
  UpdateTranslation(this.repository);

  final TranslationRepository repository;

  @override
  Future<Either<Failure, void>> call(UpdateTranslationParams params) {
    return repository.updateTranslation(
      params.appId,
      params.key,
      params.language,
      params.value,
    );
  }
}
